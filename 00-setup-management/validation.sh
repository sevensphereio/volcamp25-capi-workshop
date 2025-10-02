#!/bin/bash

set -e

echo "🔍 Module 00-setup: Validation Cluster de Management"
echo "===================================================="
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_TOTAL=0

# Test function
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected="$3"

    TESTS_TOTAL=$((TESTS_TOTAL + 1))

    if eval "$test_command" &>/dev/null; then
        echo -e "${GREEN}✅${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}❌${NC} $test_name"
        return 1
    fi
}

# 1. Check kind cluster exists
echo "🔧 Vérification Cluster kind..."
run_test "Cluster de management kind existe: capi-management" \
    "kind get clusters 2>/dev/null | grep -q 'capi-management'"

# 2. Check kubectl context
run_test "Contexte kubectl correctement configuré: kind-capi-management" \
    "kubectl config current-context | grep -q 'kind-capi-management'"

# 3. Check cluster is accessible
run_test "Cluster Kubernetes accessible" \
    "kubectl cluster-info &>/dev/null"

# 4. Check node is Ready
run_test "Node de management Ready" \
    "kubectl get nodes -o jsonpath='{.items[0].status.conditions[?(@.type==\"Ready\")].status}' | grep -q 'True'"

echo ""
echo "📦 Vérification Composants ClusterAPI..."

# 5. Check ClusterAPI namespaces
run_test "ClusterAPI Core installé (capi-system)" \
    "kubectl get namespace capi-system"

run_test "Bootstrap Provider installé (capi-kubeadm-bootstrap-system)" \
    "kubectl get namespace capi-kubeadm-bootstrap-system"

run_test "Control Plane Provider installé (capi-kubeadm-control-plane-system)" \
    "kubectl get namespace capi-kubeadm-control-plane-system"

run_test "Docker Provider installé (capd-system)" \
    "kubectl get namespace capd-system"

run_test "cert-manager installé" \
    "kubectl get namespace cert-manager"

echo ""
echo "🔍 Vérification Deployments..."

# 6. Check deployments are running
check_deployment() {
    local namespace=$1
    local deployment=$2
    local name="$3"

    TESTS_TOTAL=$((TESTS_TOTAL + 1))

    if kubectl get deployment -n $namespace $deployment &>/dev/null; then
        local ready=$(kubectl get deployment -n $namespace $deployment -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
        local desired=$(kubectl get deployment -n $namespace $deployment -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "1")

        if [ "$ready" == "$desired" ] && [ "$ready" != "0" ]; then
            echo -e "${GREEN}✅${NC} $name ($ready/$desired ready)"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return 0
        else
            echo -e "${RED}❌${NC} $name ($ready/$desired ready)"
            return 1
        fi
    else
        echo -e "${RED}❌${NC} $name (deployment manquant)"
        return 1
    fi
}

check_deployment "capi-system" "capi-controller-manager" "ClusterAPI Core controller"
check_deployment "capi-kubeadm-bootstrap-system" "capi-kubeadm-bootstrap-controller-manager" "Bootstrap controller"
check_deployment "capi-kubeadm-control-plane-system" "capi-kubeadm-control-plane-controller-manager" "Control Plane controller"
check_deployment "capd-system" "capd-controller-manager" "Docker Provider controller"
check_deployment "cert-manager" "cert-manager" "cert-manager"
check_deployment "cert-manager" "cert-manager-webhook" "cert-manager webhook"
check_deployment "cert-manager" "cert-manager-cainjector" "cert-manager cainjector"

echo ""
echo "🎯 Vérification CRDs ClusterAPI..."

# 7. Check critical CRDs
run_test "CRD Cluster installé" \
    "kubectl get crd clusters.cluster.x-k8s.io"

run_test "CRD Machine installé" \
    "kubectl get crd machines.cluster.x-k8s.io"

run_test "CRD MachineDeployment installé" \
    "kubectl get crd machinedeployments.cluster.x-k8s.io"

run_test "CRD DockerCluster installé" \
    "kubectl get crd dockerclusters.infrastructure.cluster.x-k8s.io"

run_test "CRD KubeadmControlPlane installé" \
    "kubectl get crd kubeadmcontrolplanes.controlplane.cluster.x-k8s.io"

echo ""
echo "📊 Vérification Versions..."

# 8. Check versions
CAPI_VERSION=$(kubectl get deployment -n capi-system capi-controller-manager -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null | grep -oP 'v\d+\.\d+\.\d+' || echo "unknown")
CERTMGR_VERSION=$(kubectl get deployment -n cert-manager cert-manager -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null | grep -oP 'v\d+\.\d+\.\d+' || echo "unknown")

echo "  ℹ️  ClusterAPI: $CAPI_VERSION"
echo "  ℹ️  cert-manager: $CERTMGR_VERSION"

echo ""
echo "===================================================="

# Final summary
if [ $TESTS_PASSED -eq $TESTS_TOTAL ]; then
    echo -e "${GREEN}🎉 Module 00-setup terminé avec succès!${NC}"
    echo -e "${GREEN}🚀 Management cluster prêt à créer des workload clusters${NC}"
    echo "===================================================="
    echo ""
    echo "📊 Résumé des Composants:"
    echo "  ✅ ClusterAPI: $CAPI_VERSION"
    echo "  ✅ Docker Provider: Opérationnel"
    echo "  ✅ cert-manager: $CERTMGR_VERSION"
    echo ""
    echo "Prochaine commande:"
    echo "  cd ../01-premier-cluster"
    echo "  cat commands.md"
    echo ""
    exit 0
else
    echo -e "${RED}❌ Validation échouée${NC}"
    echo "Tests réussis: $TESTS_PASSED/$TESTS_TOTAL"
    echo ""
    echo "🔧 Actions de dépannage:"
    echo "  1. Vérifier les logs: kubectl get pods -A | grep -v Running"
    echo "  2. Réexécuter l'installation: cd ../scripts && ./setup-infrastructure.sh"
    echo "  3. Consulter commands.md pour installation manuelle"
    echo ""
    exit 1
fi
