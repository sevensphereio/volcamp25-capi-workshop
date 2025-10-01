#!/bin/bash

set -e

# Configuration
NEW_VERSION="${1:-v1.33.0}"  # Target version (argument or default)
CLUSTERS=("dev-cluster" "multi-01" "multi-02" "multi-03")

echo "🔄 Multi-Cluster Kubernetes Upgrade"
echo "===================================="
echo ""
echo "Target version: $NEW_VERSION"
echo "Clusters: ${CLUSTERS[@]}"
echo ""
read -p "Proceed with upgrade? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "❌ Upgrade cancelled"
    exit 1
fi

echo ""
echo "🚀 Starting parallel upgrade..."
echo ""

# Upgrade all clusters in parallel
for cluster in "${CLUSTERS[@]}"; do
    # Check if cluster exists
    if ! kubectl get cluster $cluster &>/dev/null; then
        echo "⚠️  Cluster $cluster not found, skipping"
        continue
    fi

    echo "🔄 Upgrading cluster: $cluster to $NEW_VERSION"

    # Upgrade Control Plane
    kubectl patch kubeadmcontrolplane ${cluster}-control-plane \
        --type=merge \
        -p "{\"spec\":{\"version\":\"${NEW_VERSION}\"}}" 2>/dev/null || {
            echo "⚠️  Failed to upgrade control plane for $cluster"
            continue
        }

    # Upgrade Workers
    kubectl patch machinedeployment ${cluster}-md-0 \
        --type=merge \
        -p "{\"spec\":{\"template\":{\"spec\":{\"version\":\"${NEW_VERSION}\"}}}}" 2>/dev/null || {
            echo "⚠️  Failed to upgrade workers for $cluster"
            continue
        }

    echo "✅ Upgrade initiated for $cluster"
    echo ""
done

echo "=========================================="
echo "✅ Upgrade commands sent to all clusters!"
echo ""
echo "Monitor progress with:"
echo "  watch -n 2 'kubectl get machines'"
echo "  ./monitor-upgrades.sh"
echo ""
echo "Upgrades will complete in ~5-10 minutes"
echo "=========================================="
