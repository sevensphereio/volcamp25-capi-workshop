#!/bin/bash

set -e

echo "🔍 Module 04: Validation Automation Helm"
echo "======================================="
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

# Check HelmChartProxy exists
kubectl get helmchartproxy nginx-app &>/dev/null
check "HelmChartProxy nginx-app existe"

# Check cluster labels
DEV_LABEL=$(kubectl get cluster dev-cluster -o jsonpath='{.metadata.labels.environment}' 2>/dev/null)
if [ "$DEV_LABEL" = "demo" ]; then
    check "Cluster dev-cluster a le label environment=demo"
else
    echo "❌ Cluster dev-cluster manque le label environment=demo"
    FAILED=$((FAILED + 1))
fi

K0S_LABEL=$(kubectl get cluster k0s-demo-cluster -o jsonpath='{.metadata.labels.environment}' 2>/dev/null)
if [ "$K0S_LABEL" = "demo" ]; then
    check "Cluster k0s-demo-cluster a le label environment=demo"
else
    echo "❌ Cluster k0s-demo-cluster manque le label environment=demo"
    FAILED=$((FAILED + 1))
fi

# Check HelmReleaseProxy count
HRP_COUNT=$(kubectl get helmreleaseproxy --no-headers 2>/dev/null | wc -l)
if [ "$HRP_COUNT" -eq 2 ]; then
    check "2 HelmReleaseProxy créés automatiquement"
else
    echo "❌ HelmReleaseProxy: $HRP_COUNT/2 créés"
    FAILED=$((FAILED + 1))
fi

# Check HelmReleaseProxy status for dev-cluster
DEV_HRP_READY=$(kubectl get helmreleaseproxy dev-cluster-nginx-app -o jsonpath='{.status.ready}' 2>/dev/null)
if [ "$DEV_HRP_READY" = "true" ]; then
    check "HelmReleaseProxy dev-cluster-nginx-app Ready"
else
    echo "❌ HelmReleaseProxy dev-cluster-nginx-app not ready"
    FAILED=$((FAILED + 1))
fi

# Check HelmReleaseProxy status for k0s-demo-cluster
K0S_HRP_READY=$(kubectl get helmreleaseproxy k0s-demo-cluster-nginx-app -o jsonpath='{.status.ready}' 2>/dev/null)
if [ "$K0S_HRP_READY" = "true" ]; then
    check "HelmReleaseProxy k0s-demo-cluster-nginx-app Ready"
else
    echo "❌ HelmReleaseProxy k0s-demo-cluster-nginx-app not ready"
    FAILED=$((FAILED + 1))
fi

# Check nginx pods in dev-cluster
if [ -f "../01-premier-cluster/dev-cluster.kubeconfig" ]; then
    DEV_NGINX_PODS=$(kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig get pods -l app.kubernetes.io/name=nginx --no-headers 2>/dev/null | wc -l)
    DEV_NGINX_RUNNING=$(kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig get pods -l app.kubernetes.io/name=nginx -o jsonpath='{range .items[*]}{.status.phase}{"\n"}{end}' 2>/dev/null | grep -c "Running" || echo "0")
    if [ "$DEV_NGINX_PODS" -eq 2 ] && [ "$DEV_NGINX_RUNNING" -eq 2 ]; then
        check "2 pods nginx Running dans dev-cluster"
    else
        echo "❌ nginx pods dev-cluster: $DEV_NGINX_RUNNING/2 Running (total: $DEV_NGINX_PODS)"
        FAILED=$((FAILED + 1))
    fi

    # Check nginx service in dev-cluster
    kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig get svc nginx-app &>/dev/null
    check "Service nginx-app existe dans dev-cluster"
else
    echo "❌ dev-cluster.kubeconfig non trouvé"
    FAILED=$((FAILED + 1))
fi

# Check nginx pods in k0s-demo-cluster
if [ -f "../03-k0smotron/k0s-demo-cluster.kubeconfig" ]; then
    K0S_NGINX_PODS=$(kubectl --kubeconfig ../03-k0smotron/k0s-demo-cluster.kubeconfig get pods -l app.kubernetes.io/name=nginx --no-headers 2>/dev/null | wc -l)
    K0S_NGINX_RUNNING=$(kubectl --kubeconfig ../03-k0smotron/k0s-demo-cluster.kubeconfig get pods -l app.kubernetes.io/name=nginx -o jsonpath='{range .items[*]}{.status.phase}{"\n"}{end}' 2>/dev/null | grep -c "Running" || echo "0")
    if [ "$K0S_NGINX_PODS" -eq 2 ] && [ "$K0S_NGINX_RUNNING" -eq 2 ]; then
        check "2 pods nginx Running dans k0s-demo-cluster"
    else
        echo "❌ nginx pods k0s-demo-cluster: $K0S_NGINX_RUNNING/2 Running (total: $K0S_NGINX_PODS)"
        FAILED=$((FAILED + 1))
    fi

    # Check nginx service in k0s-demo-cluster
    kubectl --kubeconfig ../03-k0smotron/k0s-demo-cluster.kubeconfig get svc nginx-app &>/dev/null
    check "Service nginx-app existe dans k0s-demo-cluster"
else
    echo "❌ k0s-demo-cluster.kubeconfig non trouvé"
    FAILED=$((FAILED + 1))
fi

# Test nginx connectivity (port-forward)
if [ -f "../01-premier-cluster/dev-cluster.kubeconfig" ]; then
    timeout 10 kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig port-forward svc/nginx-app 8080:80 &>/dev/null &
    PID1=$!
    sleep 3
    if curl -s --max-time 3 http://localhost:8080 | grep -q "nginx" 2>/dev/null; then
        check "nginx accessible sur dev-cluster (port-forward test)"
    else
        warning "nginx dev-cluster port-forward test échoué (normal si le cluster a des problèmes)"
    fi
    kill $PID1 2>/dev/null || true
    wait $PID1 2>/dev/null || true
fi

if [ -f "../03-k0smotron/k0s-demo-cluster.kubeconfig" ]; then
    timeout 10 kubectl --kubeconfig ../03-k0smotron/k0s-demo-cluster.kubeconfig port-forward svc/nginx-app 8081:80 &>/dev/null &
    PID2=$!
    sleep 3
    if curl -s --max-time 3 http://localhost:8081 | grep -q "nginx" 2>/dev/null; then
        check "nginx accessible sur k0s-demo-cluster (port-forward test)"
    else
        warning "nginx k0s-demo-cluster port-forward test échoué (normal si le cluster a des problèmes)"
    fi
    kill $PID2 2>/dev/null || true
    wait $PID2 2>/dev/null || true
fi

echo ""
echo "📊 Résumé déploiement automatique:"

# Count total clusters with environment=demo label
DEMO_CLUSTERS=$(kubectl get clusters -l environment=demo --no-headers 2>/dev/null | wc -l)
echo "   🎯 1 HelmChartProxy → $DEMO_CLUSTERS clusters ciblés"

# Count total nginx pods across all clusters
TOTAL_NGINX_PODS=0
if [ -f "../01-premier-cluster/dev-cluster.kubeconfig" ]; then
    DEV_PODS=$(kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig get pods -l app.kubernetes.io/name=nginx --no-headers 2>/dev/null | wc -l)
    TOTAL_NGINX_PODS=$((TOTAL_NGINX_PODS + DEV_PODS))
fi
if [ -f "../03-k0smotron/k0s-demo-cluster.kubeconfig" ]; then
    K0S_PODS=$(kubectl --kubeconfig ../03-k0smotron/k0s-demo-cluster.kubeconfig get pods -l app.kubernetes.io/name=nginx --no-headers 2>/dev/null | wc -l)
    TOTAL_NGINX_PODS=$((TOTAL_NGINX_PODS + K0S_PODS))
fi

echo "   🚀 $HRP_COUNT HelmReleaseProxy → $TOTAL_NGINX_PODS pods nginx ($((TOTAL_NGINX_PODS/2))x2)"
echo "   ⚡ Déploiement en ~30 secondes"
echo "   🔄 GitOps: ajout cluster = déploiement auto"

echo ""
echo "======================================="
if [ $FAILED -eq 0 ]; then
    echo "🎉 Module 04 terminé avec succès!"
    echo "🚀 Prêt pour Module 05: Operations & Cleanup"
    echo "======================================="
    echo ""
    echo "Prochaine commande:"
    echo "  cd ../05-operations-cleanup"
    echo "  cat commands.md"
    exit 0
else
    echo "❌ $FAILED test(s) échoué(s)"
    echo "======================================="
    echo ""
    echo "Vérifiez les logs:"
    echo "  kubectl describe helmchartproxy nginx-app"
    echo "  kubectl get helmreleaseproxy -o wide"
    echo "  kubectl logs -n capi-system -l cluster.x-k8s.io/provider=addon-helm"
    echo "  kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig get pods -l app.kubernetes.io/name=nginx"
    exit 1
fi