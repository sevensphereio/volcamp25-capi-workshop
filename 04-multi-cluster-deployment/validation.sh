#!/bin/bash

set -e

echo "🔍 Module 04: Validation Multi-Cluster Deployment"
echo "=================================================="
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

# Check Helm release exists
helm status multi-clusters &>/dev/null
check "Helm release 'multi-clusters' déployé"

# Check 3 clusters exist
CLUSTER_COUNT=$(kubectl get clusters -l environment=demo --no-headers 2>/dev/null | grep "multi-" | wc -l)
if [ "$CLUSTER_COUNT" -eq 3 ]; then
    check "3 Clusters créés (multi-01, multi-02, multi-03)"
else
    echo "❌ Clusters trouvés: $CLUSTER_COUNT/3"
    FAILED=$((FAILED + 1))
fi

# Check all clusters are Provisioned
PROVISIONED_COUNT=$(kubectl get clusters -l environment=demo -o jsonpath='{range .items[?(@.metadata.name=="multi-01")]}{.status.phase}{"\n"}{end}' 2>/dev/null | grep -c "Provisioned" || echo "0")
PROVISIONED_COUNT=$((PROVISIONED_COUNT + $(kubectl get clusters -l environment=demo -o jsonpath='{range .items[?(@.metadata.name=="multi-02")]}{.status.phase}{"\n"}{end}' 2>/dev/null | grep -c "Provisioned" || echo "0")))
PROVISIONED_COUNT=$((PROVISIONED_COUNT + $(kubectl get clusters -l environment=demo -o jsonpath='{range .items[?(@.metadata.name=="multi-03")]}{.status.phase}{"\n"}{end}' 2>/dev/null | grep -c "Provisioned" || echo "0")))

if [ "$PROVISIONED_COUNT" -eq 3 ]; then
    check "3 Clusters en phase Provisioned"
else
    echo "❌ Clusters Provisioned: $PROVISIONED_COUNT/3"
    FAILED=$((FAILED + 1))
fi

# Check control planes
CP_COUNT=0
for cluster in multi-01 multi-02 multi-03; do
    CP_READY=$(kubectl get kubeadmcontrolplane ${cluster}-control-plane -o jsonpath='{.status.ready}' 2>/dev/null || echo "false")
    if [ "$CP_READY" = "true" ]; then
        CP_COUNT=$((CP_COUNT + 1))
    fi
done

if [ "$CP_COUNT" -eq 3 ]; then
    check "3 Control planes ready"
else
    echo "❌ Control planes ready: $CP_COUNT/3"
    FAILED=$((FAILED + 1))
fi

# Check machines
MACHINE_COUNT=$(kubectl get machines --no-headers 2>/dev/null | grep "multi-" | wc -l)
RUNNING_COUNT=$(kubectl get machines -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.status.phase}{"\n"}{end}' 2>/dev/null | grep "multi-" | grep -c "Running" || echo "0")

if [ "$MACHINE_COUNT" -eq 9 ] && [ "$RUNNING_COUNT" -eq 9 ]; then
    check "9 Machines en phase Running"
else
    echo "❌ Machines: $RUNNING_COUNT/9 Running (total: $MACHINE_COUNT)"
    FAILED=$((FAILED + 1))
fi

# Check Docker containers
CONTAINER_COUNT=$(docker ps 2>/dev/null | grep -c "multi-" || echo "0")
if [ "$CONTAINER_COUNT" -eq 9 ]; then
    check "9 containers Docker actifs"
else
    echo "⚠️  Containers Docker: $CONTAINER_COUNT/9"
    warning "Attendez quelques secondes que tous les containers démarrent"
fi

# Check kubeconfigs
KUBECONFIG_COUNT=0
for cluster in multi-01 multi-02 multi-03; do
    if clusterctl get kubeconfig $cluster &>/dev/null; then
        KUBECONFIG_COUNT=$((KUBECONFIG_COUNT + 1))
    fi
done

if [ "$KUBECONFIG_COUNT" -eq 3 ]; then
    check "Kubeconfigs accessibles"
else
    echo "⚠️  Kubeconfigs accessibles: $KUBECONFIG_COUNT/3"
fi

echo ""
echo "=================================================="
if [ $FAILED -eq 0 ]; then
    echo "🎉 Module 04 terminé avec succès!"
    echo "🚀 Prêt pour Module 05: Automation Helm"
    echo "=================================================="
    echo ""
    echo "Prochaine commande:"
    echo "  cd ../05-automation-helm"
    echo "  cat commands.md"
    exit 0
else
    echo "❌ $FAILED test(s) échoué(s)"
    echo "=================================================="
    echo ""
    echo "Vérifiez les logs:"
    echo "  helm status multi-clusters"
    echo "  kubectl get clusters"
    echo "  kubectl get machines"
    exit 1
fi
