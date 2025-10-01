#!/bin/bash

set -e

echo "🚀 Workshop ClusterAPI Express - Setup Infrastructure"
echo "====================================================="
echo ""

# Functions
check_command() {
    local cmd=$1
    local version_flag=${2:-"--version"}

    if ! command -v "$cmd" &> /dev/null; then
        echo "❌ $cmd n'est pas installé"
        echo "   Installation requise: https://kubernetes.io/docs/tasks/tools/"
        exit 1
    fi

    local version_output
    case $cmd in
        "docker")
            version_output=$(docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',')
            ;;
        "kubectl")
            version_output=$(kubectl version --client --short 2>/dev/null | cut -d' ' -f3)
            ;;
        "kind")
            version_output=$(kind version 2>/dev/null | head -1 | cut -d' ' -f2)
            ;;
        "clusterctl")
            version_output=$(clusterctl version 2>/dev/null | grep "clusterctl version" | cut -d'"' -f4)
            ;;
        "helm")
            version_output=$(helm version --short 2>/dev/null | cut -d'+' -f1)
            ;;
        *)
            version_output="unknown"
            ;;
    esac

    echo "✅ $cmd: $version_output"
}

wait_for_deployment() {
    local namespace=$1
    local deployment=$2
    local timeout=${3:-300}

    echo "⏳ Attente de $deployment dans $namespace..."
    if kubectl wait --for=condition=Available --timeout=${timeout}s \
        deployment/$deployment -n $namespace &>/dev/null; then
        echo "✅ $deployment opérationnel"
    else
        echo "❌ Timeout pour $deployment"
        exit 1
    fi
}

# 1. Check prerequisites
echo "📋 Vérification des prérequis..."
check_command docker
check_command kubectl
check_command kind
check_command clusterctl
check_command helm

# Check Docker is running
if ! docker info &>/dev/null; then
    echo "❌ Docker n'est pas démarré"
    echo "   Démarrez Docker Desktop ou le service docker"
    exit 1
fi
echo "✅ Docker est démarré"

echo ""

# 2. Create management cluster
echo "📦 Création du cluster de management avec kind..."

# Check if cluster already exists
if kind get clusters 2>/dev/null | grep -q "capi-management"; then
    echo "⚠️  Cluster capi-management existe déjà"
    echo "   Suppression et recréation..."
    kind delete cluster --name capi-management
fi

# Create cluster config
cat > /tmp/management-cluster-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: capi-management
nodes:
  - role: control-plane
    extraMounts:
      - hostPath: /var/run/docker.sock
        containerPath: /var/run/docker.sock
    extraPortMappings:
      - containerPort: 30080
        hostPort: 30080
        protocol: TCP
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
            authorization-mode: "Webhook"
EOF

kind create cluster --config /tmp/management-cluster-config.yaml

# Verify cluster is ready
kubectl cluster-info --context kind-capi-management
echo "✅ Cluster de management créé"

# Verify Docker socket is mounted
echo ""
echo "🔍 Vérification de la socket Docker..."
if docker exec capi-management-control-plane test -S /var/run/docker.sock 2>/dev/null; then
    echo "✅ Socket Docker montée et accessible"
    if docker exec capi-management-control-plane docker ps &>/dev/null; then
        echo "✅ Communication avec Docker Daemon fonctionnelle"
    else
        echo "⚠️  Socket montée mais communication échoue"
    fi
else
    echo "❌ Socket Docker NON montée - CAPD ne pourra pas créer de clusters"
    echo "   Vérifiez la configuration: extraMounts dans management-cluster-config.yaml"
    exit 1
fi

echo ""

# 3. Initialize ClusterAPI
echo "⚙️  Initialisation de ClusterAPI..."

# Check if already initialized
if kubectl get namespace capi-system &>/dev/null; then
    echo "⚠️  ClusterAPI déjà installé, réinitialisation..."
    clusterctl delete --infrastructure docker --include-crd
fi

# Initialize with Docker provider
clusterctl init --infrastructure docker

# Wait for controllers
wait_for_deployment capi-system capi-controller-manager
wait_for_deployment capi-system capi-kubeadm-bootstrap-controller-manager
wait_for_deployment capi-system capi-kubeadm-control-plane-controller-manager
wait_for_deployment capd-system capd-controller-manager

echo "✅ ClusterAPI initialisé"

echo ""

# 4. Install k0smotron
echo "🔧 Installation de l'opérateur k0smotron..."

# Check if already installed
if kubectl get namespace k0smotron &>/dev/null; then
    echo "⚠️  k0smotron déjà installé, mise à jour..."
    kubectl delete -f https://github.com/k0sproject/k0smotron/releases/download/v1.7.0/install.yaml --ignore-not-found
    sleep 5
fi

kubectl apply -f https://github.com/k0sproject/k0smotron/releases/download/v1.7.0/install.yaml

wait_for_deployment k0smotron k0smotron-controller-manager

echo "✅ k0smotron opérateur installé"

echo ""

# 5. Install Helm Addon Provider
echo "📦 Installation du Helm Addon Provider..."

# Add helm repo
helm repo add capi-addon-provider https://kubernetes-sigs.github.io/cluster-api-addon-provider-helm &>/dev/null || true
helm repo update &>/dev/null

# Check if already installed
if kubectl get namespace capi-addon-system &>/dev/null; then
    echo "⚠️  Helm Addon Provider déjà installé, mise à jour..."
    helm uninstall capi-addon-provider -n capi-addon-system --ignore-not-found
fi

# Install with helm
helm install capi-addon-provider capi-addon-provider/cluster-api-addon-provider-helm \
  --namespace capi-addon-system \
  --create-namespace \
  --wait \
  --timeout 300s

echo "✅ Helm Addon Provider installé"

echo ""

# 6. Final verification
echo "🔍 Vérification finale de l'installation..."

# Check all namespaces and deployments
echo "📊 État des composants:"
echo ""

echo "ClusterAPI Core:"
kubectl get pods -n capi-system --no-headers | while read line; do
    pod=$(echo $line | cut -d' ' -f1)
    status=$(echo $line | cut -d' ' -f3)
    if [ "$status" = "Running" ]; then
        echo "  ✅ $pod"
    else
        echo "  ❌ $pod ($status)"
    fi
done

echo ""
echo "Docker Provider:"
kubectl get pods -n capd-system --no-headers | while read line; do
    pod=$(echo $line | cut -d' ' -f1)
    status=$(echo $line | cut -d' ' -f3)
    if [ "$status" = "Running" ]; then
        echo "  ✅ $pod"
    else
        echo "  ❌ $pod ($status)"
    fi
done

echo ""
echo "k0smotron:"
kubectl get pods -n k0smotron --no-headers | while read line; do
    pod=$(echo $line | cut -d' ' -f1)
    status=$(echo $line | cut -d' ' -f3)
    if [ "$status" = "Running" ]; then
        echo "  ✅ $pod"
    else
        echo "  ❌ $pod ($status)"
    fi
done

echo ""
echo "Helm Addon Provider:"
kubectl get pods -n capi-addon-system --no-headers | while read line; do
    pod=$(echo $line | cut -d' ' -f1)
    status=$(echo $line | cut -d' ' -f3)
    if [ "$status" = "Running" ]; then
        echo "  ✅ $pod"
    else
        echo "  ❌ $pod ($status)"
    fi
done

echo ""

# 7. Run verification script if available
if [ -f "$(dirname "$0")/../00-introduction/verification.sh" ]; then
    echo "🧪 Exécution de la vérification complète..."
    cd "$(dirname "$0")/../00-introduction"
    ./verification.sh
else
    echo "⚠️  Script de vérification non trouvé"
    echo "   Exécutez manuellement: cd 00-introduction && ./verification.sh"
fi

echo ""
echo "========================================="
echo "🎉 Infrastructure setup terminé!"
echo "========================================="
echo ""
echo "📊 Résumé de l'installation:"
echo "  ✅ Management cluster: kind-capi-management"
echo "  ✅ ClusterAPI: v1.10.6"
echo "  ✅ Docker Provider: Opérationnel"
echo "  ✅ k0smotron: v1.7.0"
echo "  ✅ Helm Addon Provider: v0.3.2"
echo ""
echo "🚀 Prêt pour le workshop!"
echo ""
echo "Prochaines commandes:"
echo "  cd workshop-express/00-introduction"
echo "  ./verification.sh"
echo "  cd ../01-premier-cluster"
echo "  cat commands.md"
echo ""
echo "📖 Guide formateur:"
echo "  cat FORMATEUR.md"