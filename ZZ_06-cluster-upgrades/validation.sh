#!/bin/bash

set -e

echo "🔍 Module 06: Validation Cluster Upgrades"
echo "=========================================="
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

# Check clusters exist
CLUSTER_COUNT=$(kubectl get clusters --no-headers 2>/dev/null | wc -l)
if [ "$CLUSTER_COUNT" -ge 2 ]; then
    check "$CLUSTER_COUNT Clusters existent"
else
    echo "❌ Clusters trouvés: $CLUSTER_COUNT (attendu: ≥2)"
    FAILED=$((FAILED + 1))
fi

# Check all clusters are Provisioned
PROVISIONED_COUNT=$(kubectl get clusters -o jsonpath='{range .items[*]}{.status.phase}{"\n"}{end}' 2>/dev/null | grep -c "Provisioned" || echo "0")
if [ "$PROVISIONED_COUNT" -eq "$CLUSTER_COUNT" ]; then
    check "Tous les clusters sont Provisioned"
else
    echo "❌ Clusters Provisioned: $PROVISIONED_COUNT/$CLUSTER_COUNT"
    FAILED=$((FAILED + 1))
fi

# Check all control planes are ready
CP_COUNT=$(kubectl get kubeadmcontrolplane --no-headers 2>/dev/null | wc -l)
CP_READY=0
for cp in $(kubectl get kubeadmcontrolplane -o name 2>/dev/null); do
    READY=$(kubectl get $cp -o jsonpath='{.status.ready}' 2>/dev/null || echo "false")
    if [ "$READY" = "true" ]; then
        CP_READY=$((CP_READY + 1))
    fi
done

if [ "$CP_READY" -eq "$CP_COUNT" ]; then
    check "Tous les control planes sont ready ($CP_READY/$CP_COUNT)"
else
    echo "❌ Control planes ready: $CP_READY/$CP_COUNT"
    FAILED=$((FAILED + 1))
fi

# Check no machines are stuck in Deleting
DELETING_COUNT=$(kubectl get machines -o jsonpath='{range .items[*]}{.status.phase}{"\n"}{end}' 2>/dev/null | grep -c "Deleting" || echo "0")
if [ "$DELETING_COUNT" -eq 0 ]; then
    check "Aucune machine en phase Deleting"
else
    warning "$DELETING_COUNT machine(s) en phase Deleting (peut être temporaire)"
fi

# Check all machines are Running
MACHINE_COUNT=$(kubectl get machines --no-headers 2>/dev/null | wc -l)
RUNNING_COUNT=$(kubectl get machines -o jsonpath='{range .items[*]}{.status.phase}{"\n"}{end}' 2>/dev/null | grep -c "Running" || echo "0")

if [ "$RUNNING_COUNT" -eq "$MACHINE_COUNT" ]; then
    check "Toutes les machines sont Running ($RUNNING_COUNT/$MACHINE_COUNT)"
else
    echo "⚠️  Machines Running: $RUNNING_COUNT/$MACHINE_COUNT"
    warning "Certaines machines peuvent être en cours d'upgrade"
fi

# Check workload clusters are accessible
ACCESSIBLE=0
for cluster in $(kubectl get clusters -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
    if clusterctl get kubeconfig $cluster &>/dev/null; then
        ACCESSIBLE=$((ACCESSIBLE + 1))
    fi
done

if [ "$ACCESSIBLE" -eq "$CLUSTER_COUNT" ]; then
    check "Workload clusters accessibles ($ACCESSIBLE/$CLUSTER_COUNT)"
else
    echo "⚠️  Clusters accessibles: $ACCESSIBLE/$CLUSTER_COUNT"
fi

# Check nodes Ready in workload clusters
READY_CLUSTERS=0
for cluster in $(kubectl get clusters -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
    if [ -f "${cluster}.kubeconfig" ]; then
        NODE_COUNT=$(kubectl --kubeconfig ${cluster}.kubeconfig get nodes --no-headers 2>/dev/null | wc -l || echo "0")
        READY_NODES=$(kubectl --kubeconfig ${cluster}.kubeconfig get nodes --no-headers 2>/dev/null | grep -c " Ready " || echo "0")

        if [ "$NODE_COUNT" -eq "$READY_NODES" ] && [ "$NODE_COUNT" -gt 0 ]; then
            READY_CLUSTERS=$((READY_CLUSTERS + 1))
        fi
    fi
done

if [ "$READY_CLUSTERS" -ge 1 ]; then
    check "Nodes Ready dans les workload clusters vérifiés ($READY_CLUSTERS)"
else
    warning "Impossible de vérifier les nodes (kubeconfigs manquants?)"
fi

echo ""
echo "=========================================="
if [ $FAILED -eq 0 ]; then
    echo "🎉 Module 06 terminé avec succès!"
    echo "🚀 Prêt pour Module 07: Operations & Cleanup"
    echo "=========================================="
    echo ""
    echo "Prochaine commande:"
    echo "  cd ../07-operations-cleanup"
    echo "  cat commands.md"
    exit 0
else
    echo "❌ $FAILED test(s) échoué(s)"
    echo "=========================================="
    echo ""
    echo "Vérifiez les logs:"
    echo "  kubectl get clusters"
    echo "  kubectl get kubeadmcontrolplane"
    echo "  kubectl get machines"
    exit 1
fi
