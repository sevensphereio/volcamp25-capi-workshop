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

kubectl get clusterresourceset calico-cni &>/dev/null
check "ClusterResourceSet calico-cni existe"

kubectl get configmap calico-addon &>/dev/null
check "ConfigMap calico-addon existe"

LABEL=$(kubectl get cluster dev-cluster -o jsonpath='{.metadata.labels.cni}' 2>/dev/null)
if [ "$LABEL" = "calico" ]; then
    check "Cluster dev-cluster a le label cni=calico"
else
    echo "❌ Cluster dev-cluster n'a pas le label cni=calico"
    echo "   Exécutez: kubectl label cluster dev-cluster cni=calico"
    FAILED=$((FAILED + 1))
fi

CRS_STATUS=$(kubectl get clusterresourceset calico-cni -o jsonpath='{.status.conditions[?(@.type=="ResourcesApplied")].status}' 2>/dev/null)
if [ "$CRS_STATUS" = "True" ]; then
    check "CRS appliqué sur le cluster"
else
    echo "⚠️  CRS pas encore appliqué (peut prendre 1-2 minutes)"
fi

if [ -f "$KUBECONFIG" ]; then
    CALICO_CONTROLLERS=$(kubectl --kubeconfig "$KUBECONFIG" get pods -n kube-system -l k8s-app=calico-kube-controllers --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
    CALICO_NODES=$(kubectl --kubeconfig "$KUBECONFIG" get pods -n kube-system -l k8s-app=calico-node --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)

    TOTAL_CALICO=$((CALICO_CONTROLLERS + CALICO_NODES))
    if [ "$TOTAL_CALICO" -ge 4 ]; then
        check "Calico pods Running ($TOTAL_CALICO/4)"
        echo "   - calico-kube-controllers: $CALICO_CONTROLLERS/1"
        echo "   - calico-node DaemonSet: $CALICO_NODES/3"
    else
        echo "❌ Calico pods: $TOTAL_CALICO/4 Running"
        echo "   Attendez 1-2 minutes ou vérifiez les logs"
        FAILED=$((FAILED + 1))
    fi

    READY_NODES=$(kubectl --kubeconfig "$KUBECONFIG" get nodes --no-headers 2>/dev/null | grep -c " Ready " || echo "0")
    TOTAL_NODES=$(kubectl --kubeconfig "$KUBECONFIG" get nodes --no-headers 2>/dev/null | wc -l)
    if [ "$READY_NODES" -eq "$TOTAL_NODES" ] && [ "$READY_NODES" -eq 3 ]; then
        check "$READY_NODES/$TOTAL_NODES nodes Ready"
    else
        echo "❌ Nodes Ready: $READY_NODES/$TOTAL_NODES"
        FAILED=$((FAILED + 1))
    fi

    COREDNS=$(kubectl --kubeconfig "$KUBECONFIG" get pods -n kube-system -l k8s-app=kube-dns --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
    if [ "$COREDNS" -eq 2 ]; then
        check "CoreDNS pods Running ($COREDNS/2)"
    else
        echo "⚠️  CoreDNS: $COREDNS/2 Running"
    fi

    kubectl --kubeconfig "$KUBECONFIG" run test-networking --image=busybox --restart=Never --rm -it --timeout=10s -- ping -c 1 google.com &>/dev/null
    if [ $? -eq 0 ]; then
        check "Communication réseau fonctionnelle"
    else
        echo "⚠️  Test réseau non concluant (peut être normal si pas d'accès internet dans le cluster)"
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