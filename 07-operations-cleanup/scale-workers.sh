#!/bin/bash

set -e

if [ $# -ne 2 ]; then
    echo "Usage: $0 <cluster-name> <replicas>"
    echo ""
    echo "Exemples:"
    echo "  $0 dev-cluster 4"
    echo "  $0 k0s-demo-cluster 3"
    exit 1
fi

CLUSTER_NAME=$1
REPLICAS=$2

echo "🔧 Scaling workers pour cluster: $CLUSTER_NAME"
echo "   Nouvelle taille: $REPLICAS replicas"
echo ""

# Check if cluster exists
if ! kubectl get cluster "$CLUSTER_NAME" &>/dev/null; then
    echo "❌ Cluster '$CLUSTER_NAME' n'existe pas"
    echo ""
    echo "Clusters disponibles:"
    kubectl get clusters --no-headers -o custom-columns=NAME:.metadata.name 2>/dev/null || echo "Aucun cluster trouvé"
    exit 1
fi

# Find MachineDeployment for this cluster
MD_NAME=$(kubectl get machinedeployment -l cluster.x-k8s.io/cluster-name="$CLUSTER_NAME" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$MD_NAME" ]; then
    echo "❌ Aucun MachineDeployment trouvé pour le cluster '$CLUSTER_NAME'"
    exit 1
fi

echo "📋 MachineDeployment trouvé: $MD_NAME"

# Get current replicas
CURRENT_REPLICAS=$(kubectl get machinedeployment "$MD_NAME" -o jsonpath='{.spec.replicas}' 2>/dev/null)
echo "   Replicas actuelles: $CURRENT_REPLICAS"

if [ "$CURRENT_REPLICAS" -eq "$REPLICAS" ]; then
    echo "⚠️  Le cluster a déjà $REPLICAS replicas"
    exit 0
fi

# Scale the MachineDeployment
echo ""
echo "🚀 Scaling MachineDeployment..."
kubectl scale machinedeployment "$MD_NAME" --replicas="$REPLICAS"

if [ $? -eq 0 ]; then
    echo "✅ Commande de scaling envoyée"
else
    echo "❌ Échec de la commande de scaling"
    exit 1
fi

echo ""
echo "👀 Monitoring du scaling..."
echo "   Appuyez sur Ctrl+C pour arrêter le monitoring"
echo ""

# Monitor until all machines are running
start_time=$(date +%s)
while true; do
    current_machines=$(kubectl get machines -l cluster.x-k8s.io/cluster-name="$CLUSTER_NAME" --no-headers 2>/dev/null | wc -l)
    running_machines=$(kubectl get machines -l cluster.x-k8s.io/cluster-name="$CLUSTER_NAME" -o jsonpath='{range .items[*]}{.status.phase}{"\n"}{end}' 2>/dev/null | grep -c "Running" || echo "0")

    elapsed_time=$(( $(date +%s) - start_time ))

    printf "\r⏱️  %02d:%02d - Machines: %d/%d Running" \
        $((elapsed_time / 60)) $((elapsed_time % 60)) \
        "$running_machines" "$REPLICAS"

    if [ "$current_machines" -eq "$REPLICAS" ] && [ "$running_machines" -eq "$REPLICAS" ]; then
        echo ""
        echo ""
        echo "🎉 Scaling terminé avec succès!"
        break
    fi

    # Timeout after 10 minutes
    if [ $elapsed_time -gt 600 ]; then
        echo ""
        echo ""
        echo "⚠️  Timeout après 10 minutes"
        echo "   Machines courantes: $running_machines/$REPLICAS Running"
        break
    fi

    sleep 2
done

echo ""
echo "📊 État final:"
kubectl get machines -l cluster.x-k8s.io/cluster-name="$CLUSTER_NAME" -o wide

echo ""
echo "🔍 Vérification dans le workload cluster:"

# Try to get kubeconfig and check nodes
case "$CLUSTER_NAME" in
    "dev-cluster")
        KUBECONFIG_PATH="../01-premier-cluster/dev-cluster.kubeconfig"
        ;;
    "k0s-demo-cluster")
        KUBECONFIG_PATH="../03-k0smotron/k0s-demo-cluster.kubeconfig"
        ;;
    *)
        KUBECONFIG_PATH="${CLUSTER_NAME}.kubeconfig"
        clusterctl get kubeconfig "$CLUSTER_NAME" > "$KUBECONFIG_PATH" 2>/dev/null || true
        ;;
esac

if [ -f "$KUBECONFIG_PATH" ]; then
    node_count=$(kubectl --kubeconfig "$KUBECONFIG_PATH" get nodes --no-headers 2>/dev/null | wc -l)
    ready_count=$(kubectl --kubeconfig "$KUBECONFIG_PATH" get nodes --no-headers 2>/dev/null | grep -c " Ready " || echo "0")

    echo "   Nodes dans le cluster: $ready_count/$node_count Ready"

    if [ "$ready_count" -gt 0 ]; then
        kubectl --kubeconfig "$KUBECONFIG_PATH" get nodes
    fi
else
    echo "   ⚠️  Kubeconfig non disponible pour vérification"
fi

echo ""
echo "✅ Scaling de $CLUSTER_NAME terminé: $CURRENT_REPLICAS → $REPLICAS replicas"