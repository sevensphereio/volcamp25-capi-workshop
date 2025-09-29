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

kubectl get cluster dev-cluster &>/dev/null
check "Cluster dev-cluster existe"

PHASE=$(kubectl get cluster dev-cluster -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$PHASE" = "Provisioned" ]; then
    check "Cluster phase = Provisioned"
else
    echo "❌ Cluster phase = $PHASE (attendu: Provisioned)"
    FAILED=$((FAILED + 1))
fi

CP_READY=$(kubectl get kubeadmcontrolplane dev-cluster-control-plane -o jsonpath='{.status.ready}' 2>/dev/null)
CP_REPLICAS=$(kubectl get kubeadmcontrolplane dev-cluster-control-plane -o jsonpath='{.spec.replicas}' 2>/dev/null)
if [ "$CP_READY" = "true" ]; then
    check "Control plane ready ($CP_REPLICAS/$CP_REPLICAS)"
else
    echo "❌ Control plane not ready"
    FAILED=$((FAILED + 1))
fi

MACHINE_COUNT=$(kubectl get machines -l cluster.x-k8s.io/cluster-name=dev-cluster --no-headers 2>/dev/null | wc -l)
RUNNING_COUNT=$(kubectl get machines -l cluster.x-k8s.io/cluster-name=dev-cluster -o jsonpath='{range .items[*]}{.status.phase}{"\n"}{end}' 2>/dev/null | grep -c "Running" || echo "0")
if [ "$MACHINE_COUNT" -eq 3 ] && [ "$RUNNING_COUNT" -eq 3 ]; then
    check "3 Machines en phase Running"
else
    echo "❌ Machines: $RUNNING_COUNT/3 Running (total: $MACHINE_COUNT)"
    FAILED=$((FAILED + 1))
fi

if [ -f "dev-cluster.kubeconfig" ]; then
    check "Kubeconfig récupérable"
else
    echo "⚠️  Kubeconfig non trouvé. Exécutez: clusterctl get kubeconfig dev-cluster > dev-cluster.kubeconfig"
    clusterctl get kubeconfig dev-cluster > dev-cluster.kubeconfig 2>/dev/null
    if [ -f "dev-cluster.kubeconfig" ]; then
        check "Kubeconfig récupéré automatiquement"
    else
        echo "❌ Impossible de récupérer le kubeconfig"
        FAILED=$((FAILED + 1))
    fi
fi

if [ -f "dev-cluster.kubeconfig" ]; then
    NODE_COUNT=$(kubectl --kubeconfig dev-cluster.kubeconfig get nodes --no-headers 2>/dev/null | wc -l)
    if [ "$NODE_COUNT" -eq 3 ]; then
        check "3 nodes visibles dans le workload cluster"
    else
        echo "❌ Nodes: $NODE_COUNT/3 visibles"
        FAILED=$((FAILED + 1))
    fi

    READY_COUNT=$(kubectl --kubeconfig dev-cluster.kubeconfig get nodes --no-headers 2>/dev/null | grep -c " Ready " || echo "0")
    if [ "$READY_COUNT" -eq 0 ]; then
        warning "Nodes NotReady (normal - CNI manquant)"
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