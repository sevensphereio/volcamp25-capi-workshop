#!/bin/bash

set -e

echo "🚀 Module 01: Création du Premier Cluster"
echo "=========================================="
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
CLUSTER_NAME="dev-cluster"
FLAVOR="development"
K8S_VERSION="v1.32.8"
CONTROL_PLANE_COUNT=1
WORKER_COUNT=2

# Step 1: Check if cluster already exists
echo "📋 Étape 1/5: Vérification cluster existant..."
echo ""

if kubectl get cluster $CLUSTER_NAME &>/dev/null; then
    echo -e "${YELLOW}⚠️${NC} Cluster '$CLUSTER_NAME' existe déjà"
    read -p "Voulez-vous le supprimer et recréer? (y/N) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Suppression du cluster existant..."
        kubectl delete cluster $CLUSTER_NAME
        echo "Attente de la suppression complète (30 secondes)..."
        sleep 30
    else
        echo "Utilisation du cluster existant"
        exit 0
    fi
fi

echo -e "${GREEN}✅${NC} Prêt à créer un nouveau cluster"
echo ""

# Step 2: Generate cluster manifest
echo "📋 Étape 2/5: Génération du manifeste avec clusterctl..."
echo ""

echo "Configuration du cluster:"
echo "  Nom: $CLUSTER_NAME"
echo "  Flavor: $FLAVOR"
echo "  Version Kubernetes: $K8S_VERSION"
echo "  Control Plane: $CONTROL_PLANE_COUNT node(s)"
echo "  Workers: $WORKER_COUNT node(s)"
echo ""

clusterctl generate cluster $CLUSTER_NAME \
  --flavor $FLAVOR \
  --kubernetes-version $K8S_VERSION \
  --control-plane-machine-count=$CONTROL_PLANE_COUNT \
  --worker-machine-count=$WORKER_COUNT \
  > ${CLUSTER_NAME}.yaml

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅${NC} Manifeste généré: ${CLUSTER_NAME}.yaml"

    # Show manifest stats
    OBJECT_COUNT=$(grep -c "^kind:" ${CLUSTER_NAME}.yaml)
    FILE_SIZE=$(ls -lh ${CLUSTER_NAME}.yaml | awk '{print $5}')
    echo "   Objets: $OBJECT_COUNT"
    echo "   Taille: $FILE_SIZE"

    echo ""
    echo "Types d'objets générés:"
    grep "^kind:" ${CLUSTER_NAME}.yaml | sort | uniq -c
else
    echo -e "${RED}❌${NC} Erreur lors de la génération du manifeste"
    exit 1
fi

echo ""

# Step 3: Apply cluster manifest
echo "📋 Étape 3/5: Création du cluster..."
echo ""

kubectl apply -f ${CLUSTER_NAME}.yaml

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅${NC} Cluster créé avec succès"
else
    echo ""
    echo -e "${RED}❌${NC} Erreur lors de la création du cluster"
    exit 1
fi

echo ""

# Step 4: Wait for cluster to be provisioned
echo "📋 Étape 4/5: Attente du provisioning (peut prendre 3-5 minutes)..."
echo ""

echo "Phases attendues:"
echo "  1. Pending → Création des objets"
echo "  2. Provisioning → Création du control plane"
echo "  3. Provisioned → Cluster prêt"
echo ""

# Monitor cluster creation
TIMEOUT=300  # 5 minutes
ELAPSED=0
INTERVAL=10

while [ $ELAPSED -lt $TIMEOUT ]; do
    PHASE=$(kubectl get cluster $CLUSTER_NAME -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")

    if [ "$PHASE" = "Provisioned" ]; then
        echo -e "${GREEN}✅${NC} Cluster provisioned!"
        break
    fi

    echo "   Phase actuelle: $PHASE (${ELAPSED}s écoulées)"
    sleep $INTERVAL
    ELAPSED=$((ELAPSED + INTERVAL))
done

if [ "$PHASE" != "Provisioned" ]; then
    echo -e "${RED}❌${NC} Timeout: Le cluster n'est pas encore provisioned après ${TIMEOUT}s"
    echo ""
    echo "État actuel:"
    kubectl get clusters,machines
    echo ""
    echo "Pour continuer à observer:"
    echo "  watch -n 2 'kubectl get clusters,machines'"
    exit 1
fi

echo ""

# Step 5: Get kubeconfig and validation
echo "📋 Étape 5/5: Récupération du kubeconfig et validation..."
echo ""

clusterctl get kubeconfig $CLUSTER_NAME > ${CLUSTER_NAME}.kubeconfig

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅${NC} Kubeconfig récupéré: ${CLUSTER_NAME}.kubeconfig"
else
    echo -e "${RED}❌${NC} Erreur lors de la récupération du kubeconfig"
    exit 1
fi

echo ""

# Show cluster info
echo "📊 Résumé du cluster:"
echo "===================="
echo ""

echo "Cluster:"
kubectl get cluster $CLUSTER_NAME

echo ""
echo "Machines:"
kubectl get machines -l cluster.x-k8s.io/cluster-name=$CLUSTER_NAME

echo ""
echo "Control Plane:"
kubectl get kubeadmcontrolplane

echo ""
echo "Workers:"
kubectl get machinedeployment

echo ""
echo "Nodes (workload cluster):"
kubectl --kubeconfig ${CLUSTER_NAME}.kubeconfig get nodes

echo ""
echo "Containers Docker:"
docker ps | grep $CLUSTER_NAME | awk '{print $1, $2, $NF}'

echo ""
echo "=========================================="
echo -e "${GREEN}🎉 Module 01 terminé avec succès!${NC}"
echo "=========================================="
echo ""

echo "📝 Notes importantes:"
echo "  ⚠️  Les nodes sont NotReady (NORMAL - CNI manquant)"
echo "  ⚠️  CoreDNS est Pending (NORMAL - attend le réseau)"
echo ""

echo "📊 Commandes utiles:"
echo "  # Observer le cluster"
echo "  kubectl get clusters,machines"
echo ""
echo "  # Accéder au workload cluster"
echo "  kubectl --kubeconfig ${CLUSTER_NAME}.kubeconfig get nodes"
echo "  kubectl --kubeconfig ${CLUSTER_NAME}.kubeconfig get pods -A"
echo ""
echo "  # Scaler les workers"
echo "  kubectl scale machinedeployment ${CLUSTER_NAME}-md-0 --replicas=5"
echo ""

echo "⏭️  Prochaine étape:"
echo "  cd ../02-networking-calico"
echo "  cat commands.md"
echo ""

# Run validation if script exists
if [ -f "./validation.sh" ]; then
    echo "Exécution de la validation automatique..."
    echo ""
    ./validation.sh
fi
