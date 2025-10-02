#!/bin/bash

echo "🔍 Monitoring Cluster Upgrades"
echo "================================"
echo ""

while true; do
    clear
    echo "🔍 Monitoring Cluster Upgrades - $(date +%H:%M:%S)"
    echo "================================"
    echo ""

    # Get all clusters
    CLUSTERS=$(kubectl get clusters -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)

    for cluster in $CLUSTERS; do
        echo "Cluster: $cluster"

        # Control Plane version and status
        CP_VERSION=$(kubectl get kubeadmcontrolplane ${cluster}-control-plane -o jsonpath='{.spec.version}' 2>/dev/null || echo "N/A")
        CP_READY=$(kubectl get kubeadmcontrolplane ${cluster}-control-plane -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
        CP_REPLICAS=$(kubectl get kubeadmcontrolplane ${cluster}-control-plane -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
        CP_UPDATED=$(kubectl get kubeadmcontrolplane ${cluster}-control-plane -o jsonpath='{.status.updatedReplicas}' 2>/dev/null || echo "0")

        echo "  Control Plane: $CP_VERSION ($CP_READY/$CP_REPLICAS ready, $CP_UPDATED updated)"

        # Workers version and status
        MD_VERSION=$(kubectl get machinedeployment ${cluster}-md-0 -o jsonpath='{.spec.template.spec.version}' 2>/dev/null || echo "N/A")
        MD_READY=$(kubectl get machinedeployment ${cluster}-md-0 -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
        MD_REPLICAS=$(kubectl get machinedeployment ${cluster}-md-0 -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
        MD_UPDATED=$(kubectl get machinedeployment ${cluster}-md-0 -o jsonpath='{.status.updatedReplicas}' 2>/dev/null || echo "0")

        echo "  Workers: $MD_VERSION ($MD_READY/$MD_REPLICAS ready, $MD_UPDATED updated)"

        # Determine status
        if [ "$CP_READY" = "$CP_REPLICAS" ] && [ "$MD_READY" = "$MD_REPLICAS" ] && \
           [ "$CP_UPDATED" = "$CP_REPLICAS" ] && [ "$MD_UPDATED" = "$MD_REPLICAS" ]; then
            echo "  Status: ✅ Stable"
        elif [ "$CP_UPDATED" != "$CP_REPLICAS" ] || [ "$MD_UPDATED" != "$MD_REPLICAS" ]; then
            echo "  Status: 🔄 Upgrading"
        else
            echo "  Status: ⏳ Pending"
        fi

        echo ""
    done

    echo "================================"
    echo "Press Ctrl+C to exit"
    echo "Refreshing every 5 seconds..."

    sleep 5
done
