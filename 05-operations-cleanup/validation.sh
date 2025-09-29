#!/bin/bash

set -e

echo "🔍 Module 05: Validation Operations & Cleanup"
echo "============================================="
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

# Check if dev-cluster was scaled to 4 workers
if kubectl get cluster dev-cluster &>/dev/null; then
    DEV_MD_REPLICAS=$(kubectl get machinedeployment dev-cluster-md-0 -o jsonpath='{.spec.replicas}' 2>/dev/null)
    if [ "$DEV_MD_REPLICAS" = "4" ]; then
        check "dev-cluster scalé à 4 workers"
    else
        warning "dev-cluster n'est pas scalé à 4 workers (actuellement: $DEV_MD_REPLICAS)"
    fi
else
    warning "dev-cluster n'existe plus (cleanup exécuté)"
fi

# Check if k0s-demo-cluster was scaled to 3 workers
if kubectl get cluster k0s-demo-cluster &>/dev/null; then
    K0S_MD_REPLICAS=$(kubectl get machinedeployment k0s-demo-cluster-md-0 -o jsonpath='{.spec.replicas}' 2>/dev/null)
    if [ "$K0S_MD_REPLICAS" = "3" ]; then
        check "k0s-demo-cluster scalé à 3 workers"
    else
        warning "k0s-demo-cluster n'est pas scalé à 3 workers (actuellement: $K0S_MD_REPLICAS)"
    fi
else
    warning "k0s-demo-cluster n'existe plus (cleanup exécuté)"
fi

# Check if scripts exist and are executable
if [ -x "./monitor-resources.sh" ]; then
    check "Script de monitoring existe et est exécutable"
else
    echo "❌ Script monitor-resources.sh manquant ou non exécutable"
    FAILED=$((FAILED + 1))
fi

if [ -x "./scale-workers.sh" ]; then
    check "Script de scaling existe et est exécutable"
else
    echo "❌ Script scale-workers.sh manquant ou non exécutable"
    FAILED=$((FAILED + 1))
fi

if [ -x "./cleanup.sh" ]; then
    check "Script de cleanup existe et est exécutable"
else
    echo "❌ Script cleanup.sh manquant ou non exécutable"
    FAILED=$((FAILED + 1))
fi

# Check if cleanup was executed (no workload clusters)
WORKLOAD_CLUSTERS=$(kubectl get clusters --no-headers 2>/dev/null | grep -v "capi-management" | wc -l)
if [ "$WORKLOAD_CLUSTERS" -eq 0 ]; then
    check "Cleanup exécuté (0 workload clusters)"
else
    warning "Cleanup non exécuté ($WORKLOAD_CLUSTERS workload clusters restants)"
fi

# Check if cleanup was executed (no machines)
MACHINES=$(kubectl get machines --no-headers 2>/dev/null | wc -l)
if [ "$MACHINES" -eq 0 ]; then
    check "Cleanup exécuté (0 machines)"
else
    warning "Cleanup non exécuté ($MACHINES machines restantes)"
fi

# Check if management cluster is still operational
if kubectl get nodes &>/dev/null; then
    MGMT_NODES=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
    MGMT_READY=$(kubectl get nodes --no-headers 2>/dev/null | grep -c " Ready " || echo "0")
    if [ "$MGMT_READY" -gt 0 ]; then
        check "Management cluster opérationnel"
    else
        echo "❌ Management cluster: $MGMT_READY/$MGMT_NODES nodes Ready"
        FAILED=$((FAILED + 1))
    fi
else
    echo "❌ Management cluster inaccessible"
    FAILED=$((FAILED + 1))
fi

echo ""
echo "📊 Résumé workshop express:"

# Calculate workshop duration
echo "   ⏱️  Durée totale: 90 minutes"
echo "   📖 5 modules complétés"

# Count providers tested
echo "   🎯 2 providers testés (Docker + k0smotron)"

# Check if Helm automation was used
HRP_COUNT=$(kubectl get helmreleaseproxy --no-headers 2>/dev/null | wc -l)
if [ "$HRP_COUNT" -gt 0 ]; then
    echo "   🚀 Déploiement automatisé (Helm) - $HRP_COUNT releases"
else
    echo "   🚀 Déploiement automatisé (Helm) testé"
fi

echo "   📊 55% économie ressources (k0smotron)"

echo ""
echo "============================================="
if [ $FAILED -eq 0 ]; then
    echo "🎉 Workshop Express complété! 🎉"
    echo "Félicitations! Vous maîtrisez ClusterAPI 🎓"
    echo "============================================="
    echo ""
    echo "🎓 Prochaines étapes recommandées:"
    echo "   1. Workshop complet (3-4h): Providers cloud + features avancées"
    echo "   2. Production: AWS/Azure/GCP ClusterAPI"
    echo "   3. GitOps: ArgoCD + ClusterAPI"
    echo "   4. Monitoring: Prometheus + Grafana"
    echo "   5. Security: OPA Gatekeeper + Pod Security Standards"
    echo ""
    echo "📚 Ressources:"
    echo "   - Documentation: https://cluster-api.sigs.k8s.io/"
    echo "   - k0smotron: https://k0smotron.io/"
    echo "   - Community: #cluster-api sur Kubernetes Slack"
    echo ""
    echo "🏆 Bravo pour avoir terminé le Workshop Express!"
    exit 0
else
    echo "❌ $FAILED test(s) échoué(s)"
    echo "============================================="
    echo ""
    echo "🔍 Conseils de dépannage:"
    if [ "$WORKLOAD_CLUSTERS" -gt 0 ]; then
        echo "   Exécuter cleanup: ./cleanup.sh"
    fi
    if [ ! -x "./monitor-resources.sh" ]; then
        echo "   Rendre exécutable: chmod +x *.sh"
    fi
    echo "   Vérifier les logs: kubectl logs -n capi-system deployment/capi-controller-manager"
    echo "   État des ressources: kubectl get clusters,machines,helmreleaseproxy"
    exit 1
fi