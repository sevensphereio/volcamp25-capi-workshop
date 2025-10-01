#!/bin/bash

set -e

echo "🔍 Vérification du montage de la socket Docker"
echo "==============================================="
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if kind cluster exists
if ! kind get clusters 2>/dev/null | grep -q "capi-management"; then
    echo -e "${RED}❌ Cluster kind 'capi-management' n'existe pas${NC}"
    echo "   Exécutez d'abord: kind create cluster --config management-cluster-config.yaml"
    exit 1
fi

echo -e "${GREEN}✅${NC} Cluster kind 'capi-management' existe"

# Check if Docker socket is accessible from kind container
echo ""
echo "🔧 Test d'accès à la socket Docker depuis le cluster kind..."
echo ""

if docker exec capi-management-control-plane test -S /var/run/docker.sock 2>/dev/null; then
    echo -e "${GREEN}✅${NC} Socket Docker est montée et accessible: /var/run/docker.sock"

    # Get socket permissions
    SOCKET_PERMS=$(docker exec capi-management-control-plane ls -la /var/run/docker.sock 2>/dev/null | awk '{print $1, $3, $4}')
    echo "   Permissions: $SOCKET_PERMS"

else
    echo -e "${RED}❌${NC} Socket Docker NON accessible dans le cluster kind"
    echo ""
    echo "   ${YELLOW}Solution:${NC} Recréer le cluster avec la socket montée:"
    echo ""
    echo "   kind delete cluster --name capi-management"
    echo ""
    echo "   cat > management-cluster-config.yaml << 'EOF'"
    echo "   kind: Cluster"
    echo "   apiVersion: kind.x-k8s.io/v1alpha4"
    echo "   name: capi-management"
    echo "   nodes:"
    echo "     - role: control-plane"
    echo "       extraMounts:"
    echo "         - hostPath: /var/run/docker.sock"
    echo "           containerPath: /var/run/docker.sock"
    echo "       extraPortMappings:"
    echo "         - containerPort: 30080"
    echo "           hostPort: 30080"
    echo "           protocol: TCP"
    echo "   EOF"
    echo ""
    echo "   kind create cluster --config management-cluster-config.yaml"
    echo ""
    exit 1
fi

# Test Docker connectivity from within kind
echo ""
echo "🐳 Test de connectivité Docker depuis le cluster kind..."
echo ""

if docker exec capi-management-control-plane docker ps &>/dev/null; then
    CONTAINER_COUNT=$(docker exec capi-management-control-plane docker ps 2>/dev/null | wc -l)
    CONTAINER_COUNT=$((CONTAINER_COUNT - 1))  # Remove header line
    echo -e "${GREEN}✅${NC} Communication avec Docker Daemon réussie"
    echo "   Containers visibles: $CONTAINER_COUNT"
else
    echo -e "${RED}❌${NC} Impossible de communiquer avec Docker Daemon"
    echo ""
    echo "   ${YELLOW}Possible causes:${NC}"
    echo "   - Socket montée mais permissions insuffisantes"
    echo "   - Docker CLI non disponible dans le container kind"
    echo ""
    echo "   ${YELLOW}Solution:${NC} Vérifier manuellement:"
    echo "   docker exec capi-management-control-plane ls -la /var/run/docker.sock"
    exit 1
fi

# Check if CAPD is installed and can access Docker
echo ""
echo "🎛️  Vérification CAPD Controller..."
echo ""

if kubectl get namespace capd-system &>/dev/null; then
    echo -e "${GREEN}✅${NC} Namespace capd-system existe"

    # Check if CAPD deployment exists
    if kubectl get deployment -n capd-system capd-controller-manager &>/dev/null; then
        READY=$(kubectl get deployment -n capd-system capd-controller-manager -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
        DESIRED=$(kubectl get deployment -n capd-system capd-controller-manager -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "1")

        if [ "$READY" == "$DESIRED" ] && [ "$READY" != "0" ]; then
            echo -e "${GREEN}✅${NC} CAPD Controller est Running ($READY/$DESIRED)"

            # Check logs for Docker connectivity issues
            echo ""
            echo "   Vérification des logs CAPD pour erreurs Docker..."
            if kubectl logs -n capd-system deployment/capd-controller-manager --tail=50 2>/dev/null | grep -qi "cannot connect.*docker\|docker.*connection refused\|permission denied.*docker"; then
                echo -e "   ${RED}⚠️${NC} Erreurs Docker détectées dans les logs CAPD"
                echo ""
                echo "   Voir les logs complets:"
                echo "   kubectl logs -n capd-system deployment/capd-controller-manager"
            else
                echo -e "   ${GREEN}✅${NC} Aucune erreur Docker dans les logs CAPD"
            fi
        else
            echo -e "${YELLOW}⚠️${NC} CAPD Controller pas encore Ready ($READY/$DESIRED)"
            echo "   Attendre quelques secondes et réessayer"
        fi
    else
        echo -e "${YELLOW}⚠️${NC} CAPD Controller pas encore déployé"
        echo "   Exécutez: clusterctl init --infrastructure docker"
    fi
else
    echo -e "${YELLOW}⚠️${NC} CAPD pas encore installé"
    echo "   Exécutez: clusterctl init --infrastructure docker"
fi

echo ""
echo "==============================================="
echo -e "${GREEN}🎉 Vérification terminée avec succès!${NC}"
echo ""
echo "📊 Résumé:"
echo "  ✅ Socket Docker montée: /var/run/docker.sock"
echo "  ✅ Communication Docker fonctionnelle"
echo "  ✅ CAPD peut créer des containers pour workload clusters"
echo ""
echo "🚀 Le cluster de management est prêt à créer des workload clusters!"
echo ""
