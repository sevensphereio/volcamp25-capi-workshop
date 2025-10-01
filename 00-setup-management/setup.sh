#!/bin/bash

set -e

echo "🚀 Module 00-setup: Installation du Cluster de Management"
echo "=========================================================="
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Verify tools
echo "📋 Étape 1/4: Vérification des outils..."
echo ""

for tool in docker kind kubectl clusterctl helm; do
  if command -v $tool &> /dev/null; then
    version=$($tool version 2>/dev/null | head -1 || echo "installé")
    echo -e "${GREEN}✅${NC} $tool: $version"
  else
    echo -e "${RED}❌${NC} $tool: NON INSTALLÉ"
    echo ""
    echo "Retournez au Module 00-introduction pour l'installer"
    exit 1
  fi
done

echo ""
echo -e "${GREEN}✅${NC} Tous les outils sont prêts!"
echo ""

# Step 2: Create management cluster
echo "📋 Étape 2/4: Création du cluster de management kind..."
echo ""

if kind get clusters 2>/dev/null | grep -q "capi-management"; then
    echo -e "${YELLOW}⚠️${NC} Cluster 'capi-management' existe déjà"
    read -p "Voulez-vous le recréer? (y/N) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Suppression du cluster existant..."
        kind delete cluster --name capi-management
    else
        echo "Utilisation du cluster existant"
    fi
fi

if ! kind get clusters 2>/dev/null | grep -q "capi-management"; then
    cat > management-cluster-config.yaml << 'EOF'
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

    kind create cluster --config management-cluster-config.yaml

    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✅${NC} Cluster de management créé avec succès"
    else
        echo ""
        echo -e "${RED}❌${NC} Erreur lors de la création du cluster"
        exit 1
    fi
fi

echo ""

# Step 3: Initialize ClusterAPI
echo "📋 Étape 3/4: Initialisation de ClusterAPI avec Docker Provider..."
echo ""

# Export required feature gates
export CLUSTER_TOPOLOGY=true
export EXP_CLUSTER_RESOURCE_SET=true

echo "Variables d'environnement configurées:"
echo "  CLUSTER_TOPOLOGY=true"
echo "  EXP_CLUSTER_RESOURCE_SET=true"
echo ""

# Check if already initialized
if kubectl get namespace capi-system &>/dev/null; then
    echo -e "${YELLOW}⚠️${NC} ClusterAPI semble déjà initialisé"
    read -p "Voulez-vous réinitialiser? (y/N) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Réinitialisation de ClusterAPI..."
        clusterctl delete --infrastructure docker --include-crd || true
        sleep 2
    else
        echo "Passage à l'étape suivante"
    fi
fi

if ! kubectl get namespace capi-system &>/dev/null; then
    clusterctl init --infrastructure docker:v1.10.6

    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✅${NC} ClusterAPI initialisé avec succès"
    else
        echo ""
        echo -e "${RED}❌${NC} Erreur lors de l'initialisation de ClusterAPI"
        exit 1
    fi
fi

echo ""
echo "⏳ Attente que tous les pods soient prêts (peut prendre 1-2 minutes)..."

# Wait for all pods to be ready
kubectl wait --for=condition=available --timeout=300s \
  deployment/capi-controller-manager -n capi-system 2>/dev/null || true

kubectl wait --for=condition=available --timeout=300s \
  deployment/capd-controller-manager -n capd-system 2>/dev/null || true

kubectl wait --for=condition=available --timeout=300s \
  deployment/cert-manager -n cert-manager 2>/dev/null || true

echo ""
echo -e "${GREEN}✅${NC} Tous les composants sont prêts"
echo ""

# Step 4: Verification
echo "📋 Étape 4/4: Vérification de l'installation..."
echo ""

./validation.sh

echo ""
echo "=========================================================="
echo -e "${GREEN}🎉 Module 00-setup terminé avec succès!${NC}"
echo "=========================================================="
echo ""
echo "📝 Pour utiliser ces exports dans votre session:"
echo "   export CLUSTER_TOPOLOGY=true"
echo "   export EXP_CLUSTER_RESOURCE_SET=true"
echo ""
echo "⏭️  Prochaine étape:"
echo "   cd ../01-premier-cluster"
echo "   cat commands.md"
echo ""
