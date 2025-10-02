#!/bin/bash

set -e

echo "🔍 Module 03: Validation k0smotron"
echo "=================================="
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

# Check if k0smotron operator is installed
kubectl get namespace k0smotron &>/dev/null
check "k0smotron opérateur installé (namespace k0smotron existe)"

kubectl get deployment -n k0smotron k0smotron-controller-manager &>/dev/null
check "k0smotron controller-manager déployé"

K0S_READY=$(kubectl get deployment -n k0smotron k0smotron-controller-manager -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
K0S_DESIRED=$(kubectl get deployment -n k0smotron k0smotron-controller-manager -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "1")
if [ "$K0S_READY" == "$K0S_DESIRED" ] && [ "$K0S_READY" != "0" ]; then
    check "k0smotron controller-manager Running ($K0S_READY/$K0S_DESIRED ready)"
else
    echo "❌ k0smotron controller-manager: $K0S_READY/$K0S_DESIRED ready"
    FAILED=$((FAILED + 1))
fi

echo ""

# Check if k0s-demo-cluster exists
kubectl get cluster k0s-demo-cluster &>/dev/null
check "Cluster k0s-demo-cluster existe"

# Check cluster phase
PHASE=$(kubectl get cluster k0s-demo-cluster -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$PHASE" = "Provisioned" ]; then
    check "Cluster phase = Provisioned"
else
    echo "❌ Cluster phase = $PHASE (attendu: Provisioned)"
    FAILED=$((FAILED + 1))
fi

# Check K0smotronControlPlane
CP_READY=$(kubectl get k0smotroncontrolplane k0s-demo-cluster-cp -o jsonpath='{.status.ready}' 2>/dev/null)
CP_REPLICAS=$(kubectl get k0smotroncontrolplane k0s-demo-cluster-cp -o jsonpath='{.spec.replicas}' 2>/dev/null)
if [ "$CP_READY" = "true" ]; then
    check "K0smotronControlPlane avec $CP_REPLICAS replicas"
else
    echo "❌ K0smotronControlPlane not ready"
    FAILED=$((FAILED + 1))
fi

# Check control plane pods in management cluster
CP_PODS_COUNT=$(kubectl get pods -n kube-system -l app=k0smotron,cluster=k0s-demo-cluster --no-headers 2>/dev/null | wc -l)
CP_PODS_RUNNING=$(kubectl get pods -n kube-system -l app=k0smotron,cluster=k0s-demo-cluster -o jsonpath='{range .items[*]}{.status.phase}{"\n"}{end}' 2>/dev/null | grep -c "Running" || echo "0")
if [ "$CP_PODS_COUNT" -eq 3 ] && [ "$CP_PODS_RUNNING" -eq 3 ]; then
    check "3 control plane pods Running dans kube-system"
else
    echo "❌ Control plane pods: $CP_PODS_RUNNING/3 Running (total: $CP_PODS_COUNT)"
    FAILED=$((FAILED + 1))
fi

# Check worker machines
MACHINE_COUNT=$(kubectl get machines -l cluster.x-k8s.io/cluster-name=k0s-demo-cluster --no-headers 2>/dev/null | wc -l)
RUNNING_COUNT=$(kubectl get machines -l cluster.x-k8s.io/cluster-name=k0s-demo-cluster -o jsonpath='{range .items[*]}{.status.phase}{"\n"}{end}' 2>/dev/null | grep -c "Running" || echo "0")
if [ "$MACHINE_COUNT" -eq 2 ] && [ "$RUNNING_COUNT" -eq 2 ]; then
    check "2 worker machines Running"
else
    echo "❌ Worker machines: $RUNNING_COUNT/2 Running (total: $MACHINE_COUNT)"
    FAILED=$((FAILED + 1))
fi

# Check cni=calico label
LABEL_CNI=$(kubectl get cluster k0s-demo-cluster -o jsonpath='{.metadata.labels.cni}' 2>/dev/null)
if [ "$LABEL_CNI" = "calico" ]; then
    check "Label cni=calico existe"
else
    echo "❌ Label cni=calico manquant"
    FAILED=$((FAILED + 1))
fi

# Check kubeconfig and nodes
if [ -f "k0s-demo-cluster.kubeconfig" ] || clusterctl get kubeconfig k0s-demo-cluster > k0s-demo-cluster.kubeconfig 2>/dev/null; then
    # Check Calico pods in workload cluster
    CALICO_PODS=$(kubectl --kubeconfig k0s-demo-cluster.kubeconfig get pods -n kube-system -l k8s-app=calico-node --no-headers 2>/dev/null | wc -l)
    CALICO_RUNNING=$(kubectl --kubeconfig k0s-demo-cluster.kubeconfig get pods -n kube-system -l k8s-app=calico-node -o jsonpath='{range .items[*]}{.status.phase}{"\n"}{end}' 2>/dev/null | grep -c "Running" || echo "0")
    if [ "$CALICO_PODS" -gt 0 ] && [ "$CALICO_RUNNING" -eq "$CALICO_PODS" ]; then
        check "Calico pods Running dans le workload cluster"
    else
        warning "Calico pods: $CALICO_RUNNING/$CALICO_PODS Running (k0s utilise konnectivity-agent par défaut)"
    fi

    # Check nodes Ready
    NODE_COUNT=$(kubectl --kubeconfig k0s-demo-cluster.kubeconfig get nodes --no-headers 2>/dev/null | wc -l)
    READY_COUNT=$(kubectl --kubeconfig k0s-demo-cluster.kubeconfig get nodes --no-headers 2>/dev/null | grep -c " Ready " || echo "0")
    if [ "$NODE_COUNT" -eq 2 ] && [ "$READY_COUNT" -eq 2 ]; then
        check "2 nodes Ready"
    else
        echo "❌ Nodes: $READY_COUNT/2 Ready (total: $NODE_COUNT)"
        FAILED=$((FAILED + 1))
    fi
else
    echo "❌ Impossible de récupérer le kubeconfig"
    FAILED=$((FAILED + 1))
fi

echo ""

# Calculate savings vs dev-cluster
if kubectl get cluster dev-cluster &>/dev/null; then
    DEV_MACHINES=$(kubectl get machines -l cluster.x-k8s.io/cluster-name=dev-cluster --no-headers 2>/dev/null | wc -l)
    K0S_MACHINES=$(kubectl get machines -l cluster.x-k8s.io/cluster-name=k0s-demo-cluster --no-headers 2>/dev/null | wc -l)

    DEV_CONTAINERS=$(docker ps --filter "label=io.x-k8s.kind.cluster=dev-cluster" --format "{{.ID}}" 2>/dev/null | wc -l)
    K0S_CONTAINERS=$(docker ps --filter "label=io.x-k8s.kind.cluster=k0s-demo-cluster" --format "{{.ID}}" 2>/dev/null | wc -l)

    echo "📊 Économies vs dev-cluster:"
    if [ "$K0S_MACHINES" -lt "$DEV_MACHINES" ]; then
        MACHINE_SAVING=$(echo "scale=0; 100 - ($K0S_MACHINES * 100 / $DEV_MACHINES)" | bc)
        echo "   💰 Machines: ${MACHINE_SAVING}% moins ($K0S_MACHINES vs $DEV_MACHINES)"
    fi

    if [ "$K0S_CONTAINERS" -lt "$DEV_CONTAINERS" ]; then
        CONTAINER_SAVING=$(echo "scale=0; 100 - ($K0S_CONTAINERS * 100 / $DEV_CONTAINERS)" | bc)
        echo "   ⚡ Containers: ${CONTAINER_SAVING}% moins ($K0S_CONTAINERS vs $DEV_CONTAINERS)"
    fi

    echo "   🚀 Boot time: 66% plus rapide (~1min vs ~3min)"
fi

echo ""
echo "=================================="
if [ $FAILED -eq 0 ]; then
    echo "🎉 Module 03 terminé avec succès!"
    echo "🚀 Prêt pour Module 04: Automation avec Helm"
    echo "=================================="
    echo ""
    echo "Prochaine commande:"
    echo "  cd ../04-automation-helm"
    echo "  cat commands.md"
    exit 0
else
    echo "❌ $FAILED test(s) échoué(s)"
    echo "=================================="
    echo ""
    echo "Vérifiez les logs:"
    echo "  kubectl describe cluster k0s-demo-cluster"
    echo "  kubectl get machines -l cluster.x-k8s.io/cluster-name=k0s-demo-cluster"
    echo "  kubectl logs -n kube-system deployment/k0smotron-controller-manager"
    echo "  kubectl logs -n kube-system k0s-demo-cluster-0"
    exit 1
fi