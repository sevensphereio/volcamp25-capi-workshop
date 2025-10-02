#!/bin/bash

set -e

echo "🔍 Module 01: Validation Premier Cluster"
echo "========================================="
echo ""

FAILED=0

check() {
    if [ $? -eq 0 ]; then
        echo "✅ $1"
    else
        echo "❌ $1"
        FAILED=$((FAILED + 1))
    fi
}

warning() {
    echo "⚠️  $1"
}

# Vérifier que le cluster existe
kubectl get cluster dev-cluster &>/dev/null
check "Cluster dev-cluster existe"

# Vérifier la phase du cluster
PHASE=$(kubectl get cluster dev-cluster -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$PHASE" = "Provisioned" ]; then
    echo "✅ Cluster phase = Provisioned"
else
    echo "❌ Cluster phase = $PHASE (attendu: Provisioned)"
    FAILED=$((FAILED + 1))
fi

# Vérifier le control plane (récupérer le nom dynamiquement)
CP_NAME=$(kubectl get cluster dev-cluster -o jsonpath='{.spec.controlPlaneRef.name}' 2>/dev/null)

if [ -z "$CP_NAME" ]; then
    echo "❌ Impossible de récupérer le nom du control plane"
    FAILED=$((FAILED + 1))
else
    # Vérifier que le control plane est initialisé et disponible (pas nécessairement Ready car les nodes peuvent être NotReady sans CNI)
    CP_INITIALIZED=$(kubectl get kubeadmcontrolplane "$CP_NAME" -o jsonpath='{.status.initialized}' 2>/dev/null)
    CP_REPLICAS=$(kubectl get kubeadmcontrolplane "$CP_NAME" -o jsonpath='{.spec.replicas}' 2>/dev/null)
    CP_UPDATED_REPLICAS=$(kubectl get kubeadmcontrolplane "$CP_NAME" -o jsonpath='{.status.updatedReplicas}' 2>/dev/null)

    if [ "$CP_INITIALIZED" = "true" ] && [ "$CP_UPDATED_REPLICAS" = "$CP_REPLICAS" ]; then
        echo "✅ Control plane ready ($CP_UPDATED_REPLICAS/$CP_REPLICAS)"
    else
        echo "❌ Control plane not ready (initialized: $CP_INITIALIZED, updated: $CP_UPDATED_REPLICAS/$CP_REPLICAS)"
        FAILED=$((FAILED + 1))
    fi
fi

# Vérifier les machines
MACHINE_COUNT=$(kubectl get machines -l cluster.x-k8s.io/cluster-name=dev-cluster --no-headers 2>/dev/null | wc -l)
RUNNING_COUNT=$(kubectl get machines -l cluster.x-k8s.io/cluster-name=dev-cluster -o jsonpath='{range .items[*]}{.status.phase}{"\n"}{end}' 2>/dev/null | grep -c "Running" || echo "0")

if [ "$MACHINE_COUNT" -eq 3 ] && [ "$RUNNING_COUNT" -eq 3 ]; then
    echo "✅ 3 Machines en phase Running"
else
    echo "❌ Machines: $RUNNING_COUNT/3 Running (total: $MACHINE_COUNT)"
    FAILED=$((FAILED + 1))
fi

# Vérifier le kubeconfig
if [ -f "dev-cluster.kubeconfig" ]; then
    echo "✅ Kubeconfig récupérable"
else
    # Essayer de récupérer le kubeconfig automatiquement
    clusterctl get kubeconfig dev-cluster > dev-cluster.kubeconfig 2>/dev/null
    if [ -f "dev-cluster.kubeconfig" ]; then
        echo "✅ Kubeconfig récupérable"
    else
        echo "❌ Impossible de récupérer le kubeconfig"
        FAILED=$((FAILED + 1))
    fi
fi

# Vérifier les nodes dans le workload cluster
if [ -f "dev-cluster.kubeconfig" ]; then
    NODE_COUNT=$(kubectl --kubeconfig dev-cluster.kubeconfig get nodes --no-headers 2>/dev/null | wc -l)
    if [ "$NODE_COUNT" -eq 3 ]; then
        echo "✅ 3 nodes visibles dans le workload cluster"
    else
        echo "❌ Nodes: $NODE_COUNT/3 visibles"
        FAILED=$((FAILED + 1))
    fi

    # Vérifier l'état des nodes (doivent être NotReady sans CNI)
    READY_COUNT=$(kubectl --kubeconfig dev-cluster.kubeconfig get nodes --no-headers 2>/dev/null | grep -c " Ready " 2>/dev/null || true)

    if [ -z "$READY_COUNT" ] || [ "$READY_COUNT" -eq 0 ]; then
        echo "⚠️  Nodes NotReady (normal - CNI manquant)"
    else
        echo "✅ $READY_COUNT nodes Ready"
    fi
fi

echo ""
echo "========================================="
if [ $FAILED -eq 0 ]; then
    echo "🎉 Module 01 terminé avec succès!"
    echo "🚀 Prêt pour Module 02: Networking avec Calico"
    echo "========================================="
    echo ""
    echo "Prochaine commande:"
    echo "  cd ../02-networking-calico"
    echo "  cat commands.md"
    exit 0
else
    echo "❌ $FAILED test(s) échoué(s)"
    echo "========================================="
    echo ""
    echo "Vérifiez les logs:"
    echo "  kubectl describe cluster dev-cluster"
    echo "  kubectl get machines"
    echo "  kubectl logs -n capi-system deployment/capi-controller-manager"
    exit 1
fi