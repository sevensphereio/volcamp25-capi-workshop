#!/bin/bash

set -e

echo "🧹 ClusterAPI Workshop Cleanup"
echo "=============================="
echo ""

# Check if any workload clusters exist
CLUSTERS=$(kubectl get clusters --no-headers -o custom-columns=NAME:.metadata.name 2>/dev/null | grep -v "capi-management" || echo "")

if [ -z "$CLUSTERS" ]; then
    echo "✅ Aucun workload cluster à nettoyer"
    echo ""
    echo "État actuel:"
    kubectl get clusters,machines 2>/dev/null || echo "Aucune ressource ClusterAPI trouvée"
    exit 0
fi

echo "🔍 Workload clusters trouvés:"
for cluster in $CLUSTERS; do
    echo "   - $cluster"
done
echo ""

# Warn user
echo "⚠️  ATTENTION: Cette opération va supprimer TOUS les workload clusters!"
echo ""
echo "Clusters qui seront supprimés:"
echo "$CLUSTERS"
echo ""

# Ask for confirmation (skip in automation)
if [ "${AUTO_CONFIRM:-false}" != "true" ]; then
    read -p "Êtes-vous sûr de vouloir continuer? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Opération annulée"
        exit 1
    fi
    echo ""
fi

# Delete HelmChartProxy first to avoid orphaned releases
echo "🗑️  Suppression des HelmChartProxy..."
HELM_CHART_PROXIES=$(kubectl get helmchartproxy --no-headers -o custom-columns=NAME:.metadata.name 2>/dev/null || echo "")
if [ -n "$HELM_CHART_PROXIES" ]; then
    for hcp in $HELM_CHART_PROXIES; do
        echo "   Suppression HelmChartProxy: $hcp"
        kubectl delete helmchartproxy "$hcp" --ignore-not-found=true
    done
    echo "   ✅ HelmChartProxy supprimés"
else
    echo "   ℹ️  Aucun HelmChartProxy trouvé"
fi

echo ""

# Delete all workload clusters
echo "🗑️  Suppression des workload clusters..."
for cluster in $CLUSTERS; do
    echo "   Suppression cluster: $cluster"
    kubectl delete cluster "$cluster" --ignore-not-found=true
done

echo "   ✅ Commandes de suppression envoyées"
echo ""

# Monitor deletion progress
echo "👀 Monitoring de la suppression..."
echo "   Appuyez sur Ctrl+C pour arrêter le monitoring (suppression continue en arrière-plan)"
echo ""

start_time=$(date +%s)
while true; do
    remaining_clusters=$(kubectl get clusters --no-headers 2>/dev/null | grep -v "capi-management" | wc -l)
    remaining_machines=$(kubectl get machines --no-headers 2>/dev/null | wc -l)

    elapsed_time=$(( $(date +%s) - start_time ))

    printf "\r⏱️  %02d:%02d - Clusters restants: %d | Machines restantes: %d" \
        $((elapsed_time / 60)) $((elapsed_time % 60)) \
        "$remaining_clusters" "$remaining_machines"

    if [ "$remaining_clusters" -eq 0 ] && [ "$remaining_machines" -eq 0 ]; then
        echo ""
        echo ""
        echo "🎉 Suppression terminée avec succès!"
        break
    fi

    # Timeout after 10 minutes
    if [ $elapsed_time -gt 600 ]; then
        echo ""
        echo ""
        echo "⚠️  Timeout après 10 minutes"
        echo "   La suppression peut continuer en arrière-plan"
        break
    fi

    sleep 3
done

echo ""
echo "🔍 Vérification finale..."

# Check remaining resources
REMAINING_CLUSTERS=$(kubectl get clusters --no-headers 2>/dev/null | grep -v "capi-management" | wc -l)
REMAINING_MACHINES=$(kubectl get machines --no-headers 2>/dev/null | wc -l)
REMAINING_HRP=$(kubectl get helmreleaseproxy --no-headers 2>/dev/null | wc -l)

echo ""
echo "📊 État final:"
echo "   Clusters workload: $REMAINING_CLUSTERS"
echo "   Machines: $REMAINING_MACHINES"
echo "   HelmReleaseProxy: $REMAINING_HRP"

# Check Docker containers
DEV_CONTAINERS=$(docker ps --filter "label=io.x-k8s.kind.cluster=dev-cluster" --format "{{.ID}}" 2>/dev/null | wc -l)
K0S_CONTAINERS=$(docker ps --filter "label=io.x-k8s.kind.cluster=k0s-demo-cluster" --format "{{.ID}}" 2>/dev/null | wc -l)
MGMT_CONTAINERS=$(docker ps --filter "label=io.x-k8s.kind.cluster=capi-management" --format "{{.ID}}" 2>/dev/null | wc -l)

echo "   Docker containers:"
echo "     Management cluster: $MGMT_CONTAINERS"
echo "     dev-cluster: $DEV_CONTAINERS"
echo "     k0s-demo-cluster: $K0S_CONTAINERS"

echo ""

# Verify management cluster is still operational
echo "🔍 Vérification du management cluster..."
if kubectl get nodes &>/dev/null; then
    mgmt_nodes=$(kubectl get nodes --no-headers | wc -l)
    mgmt_ready=$(kubectl get nodes --no-headers | grep -c " Ready " || echo "0")
    echo "   ✅ Management cluster opérationnel ($mgmt_ready/$mgmt_nodes nodes Ready)"
else
    echo "   ❌ Management cluster inaccessible"
fi

echo ""

if [ "$REMAINING_CLUSTERS" -eq 0 ] && [ "$REMAINING_MACHINES" -eq 0 ]; then
    echo "🎉 Cleanup terminé avec succès!"
    echo ""
    echo "Ressources nettoyées:"
    echo "   ✅ Tous les workload clusters supprimés"
    echo "   ✅ Toutes les machines supprimées"
    echo "   ✅ HelmReleaseProxy nettoyés"
    echo "   ✅ Management cluster préservé"
    echo ""
    echo "🔍 Pour vérifier l'état complet:"
    echo "   kubectl get clusters,machines,helmreleaseproxy"
    echo "   docker ps"
    echo ""
    echo "🎓 Workshop Express ClusterAPI terminé! 🎉"
else
    echo "⚠️  Cleanup partiel"
    echo ""
    echo "Ressources restantes:"
    if [ "$REMAINING_CLUSTERS" -gt 0 ]; then
        echo "   Clusters: $REMAINING_CLUSTERS"
        kubectl get clusters --no-headers | grep -v "capi-management" || true
    fi
    if [ "$REMAINING_MACHINES" -gt 0 ]; then
        echo "   Machines: $REMAINING_MACHINES"
        kubectl get machines --no-headers || true
    fi
    echo ""
    echo "🔧 Pour forcer la suppression:"
    echo "   kubectl delete clusters --all"
    echo "   kubectl delete machines --all"
    echo "   kubectl patch clusters <name> -p '{\"metadata\":{\"finalizers\":[]}}' --type=merge"
fi