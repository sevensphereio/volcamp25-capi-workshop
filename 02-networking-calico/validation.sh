#!/bin/bash

set -e

echo "🔍 Module 02: Validation Networking Calico"
echo "==========================================="
echo ""

FAILED=0
KUBECONFIG="../01-premier-cluster/dev-cluster.kubeconfig"

check() {
    if [ $? -eq 0 ]; then
        echo "✅ $1"
    else
        echo "❌ $1"
        FAILED=$((FAILED + 1))
    fi
}

# Vérifier que le ClusterResourceSet existe
kubectl get clusterresourceset calico-cni &>/dev/null
check "ClusterResourceSet calico-cni existe"

# Vérifier que le ConfigMap existe
kubectl get configmap calico-crs-configmap &>/dev/null
check "ConfigMap calico-addon existe"

# Vérifier que le cluster a le label
LABEL=$(kubectl get cluster dev-cluster -o jsonpath='{.metadata.labels.cni}' 2>/dev/null)
if [ "$LABEL" = "calico" ]; then
    echo "✅ Cluster dev-cluster a le label cni=calico"
else
    echo "❌ Cluster dev-cluster n'a pas le label cni=calico"
    echo "   Exécutez: kubectl label cluster dev-cluster cni=calico"
    FAILED=$((FAILED + 1))
fi

# Vérifier que le CRS a été appliqué
CRS_STATUS=$(kubectl get clusterresourceset calico-cni -o jsonpath='{.status.conditions[?(@.type=="ResourcesApplied")].status}' 2>/dev/null)
if [ "$CRS_STATUS" = "True" ]; then
    echo "✅ CRS appliqué sur le cluster"
else
    echo "⚠️  CRS pas encore appliqué (peut prendre 1-2 minutes)"
    FAILED=$((FAILED + 1))
fi

# Vérifier le workload cluster
if [ -f "$KUBECONFIG" ]; then
    # Vérifier les pods Calico
    CALICO_CONTROLLERS=$(kubectl --kubeconfig "$KUBECONFIG" get pods -n kube-system -l k8s-app=calico-kube-controllers --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
    CALICO_NODES=$(kubectl --kubeconfig "$KUBECONFIG" get pods -n kube-system -l k8s-app=calico-node --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)

    TOTAL_CALICO=$((CALICO_CONTROLLERS + CALICO_NODES))
    if [ "$TOTAL_CALICO" -ge 4 ]; then
        echo "✅ Calico pods Running ($TOTAL_CALICO/4)"
    else
        echo "❌ Calico pods: $TOTAL_CALICO/4 Running"
        echo "   Attendez 1-2 minutes ou vérifiez les logs"
        FAILED=$((FAILED + 1))
    fi

    # Vérifier les nodes Ready
    READY_NODES=$(kubectl --kubeconfig "$KUBECONFIG" get nodes --no-headers 2>/dev/null | grep -c " Ready " 2>/dev/null || true)
    TOTAL_NODES=$(kubectl --kubeconfig "$KUBECONFIG" get nodes --no-headers 2>/dev/null | wc -l)

    if [ -z "$READY_NODES" ]; then
        READY_NODES=0
    fi

    if [ "$READY_NODES" -eq "$TOTAL_NODES" ] && [ "$READY_NODES" -eq 3 ]; then
        echo "✅ $READY_NODES/$TOTAL_NODES nodes Ready"
    else
        echo "❌ Nodes Ready: $READY_NODES/$TOTAL_NODES"
        FAILED=$((FAILED + 1))
    fi

    # Vérifier CoreDNS
    COREDNS=$(kubectl --kubeconfig "$KUBECONFIG" get pods -n kube-system -l k8s-app=kube-dns --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
    if [ "$COREDNS" -eq 2 ]; then
        echo "✅ CoreDNS pods Running ($COREDNS/2)"
    else
        echo "⚠️  CoreDNS: $COREDNS/2 Running (peut prendre quelques secondes)"
        FAILED=$((FAILED + 1))
    fi
else
    echo "❌ Kubeconfig non trouvé: $KUBECONFIG"
    FAILED=$((FAILED + 1))
fi

echo ""
echo "==========================================="
if [ $FAILED -eq 0 ]; then
    echo "🎉 Module 02 terminé avec succès!"
    echo "🚀 Prêt pour Module 03: k0smotron Control Planes"
    echo "==========================================="
    echo ""
    echo "Prochaine commande:"
    echo "  cd ../03-k0smotron"
    echo "  cat commands.md"
    exit 0
else
    echo "❌ $FAILED test(s) échoué(s)"
    echo "==========================================="
    echo ""
    echo "Troubleshooting:"
    echo "  kubectl get clusterresourceset calico-cni"
    echo "  kubectl describe clusterresourceset calico-cni"
    echo "  kubectl --kubeconfig $KUBECONFIG get pods -n kube-system"
    exit 1
fi