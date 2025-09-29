#!/bin/bash

set -e

echo "🔍 Module 00: Validation Environnement"
echo "========================================"
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

kubectl version --client &>/dev/null
check "kubectl accessible"

kubectl cluster-info --context kind-capi-management &>/dev/null
check "Management cluster accessible"

kubectl get deployments -n capi-system capi-controller-manager &>/dev/null
check "ClusterAPI installé"

VERSION=$(kubectl get deployments -n capi-system capi-controller-manager -o jsonpath='{.metadata.labels.cluster\.x-k8s\.io/provider}' 2>/dev/null || echo "unknown")
if [ "$VERSION" != "unknown" ]; then
    echo "   Version: cluster-api"
fi

kubectl get deployments -n capi-system capd-controller-manager &>/dev/null
check "Docker provider ready"

kubectl get pods -n k0smotron -l control-plane=controller-manager --field-selector=status.phase=Running &>/dev/null
check "k0smotron operator running"

kubectl get deployments -n capi-addon-system capi-addon-helm-controller-manager &>/dev/null 2>&1
if [ $? -eq 0 ]; then
    check "Helm provider ready"
else
    echo "⚠️  Helm provider not found (optional for Module 01-03)"
fi

CLUSTER_COUNT=$(kubectl get clusters --no-headers 2>/dev/null | wc -l)
if [ "$CLUSTER_COUNT" -eq 0 ]; then
    check "No existing workload clusters (clean slate)"
else
    echo "⚠️  Warning: $CLUSTER_COUNT workload cluster(s) already exist"
fi

echo ""
echo "========================================"
if [ $FAILED -eq 0 ]; then
    echo "🎉 Module 00 terminé avec succès!"
    echo "🚀 Prêt pour Module 01: Premier Cluster ClusterAPI"
    echo "========================================"
    echo ""
    echo "Prochaine commande:"
    echo "  cd ../01-premier-cluster"
    echo "  cat commands.md"
    exit 0
else
    echo "❌ $FAILED test(s) échoué(s)"
    echo "========================================"
    echo ""
    echo "Contactez le formateur pour résoudre les problèmes."
    exit 1
fi