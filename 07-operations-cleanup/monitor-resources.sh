#!/bin/bash

set -e

echo "📊 ClusterAPI Resource Monitor"
echo "============================="
echo "Appuyez sur Ctrl+C pour arrêter"
echo ""

# Function to get container stats
get_container_stats() {
    local cluster_name=$1
    local container_count=0
    local total_cpu=0
    local total_mem=0

    for container in $(docker ps --filter "label=io.x-k8s.kind.cluster=$cluster_name" --format "{{.ID}}" 2>/dev/null); do
        if [ -n "$container" ]; then
            container_count=$((container_count + 1))
            # Get CPU and memory usage
            stats=$(docker stats --no-stream --format "{{.CPUPerc}},{{.MemUsage}}" $container 2>/dev/null || echo "0%,0MiB / 0MiB")
            cpu=$(echo $stats | cut -d',' -f1 | sed 's/%//')
            mem=$(echo $stats | cut -d',' -f2 | awk '{print $1}' | sed 's/MiB//g')

            total_cpu=$(echo "$total_cpu + $cpu" | bc 2>/dev/null || echo "$total_cpu")
            total_mem=$(echo "$total_mem + $mem" | bc 2>/dev/null || echo "$total_mem")
        fi
    done

    printf "%2d     %6.1f%%   %6.0fMB" "$container_count" "$total_cpu" "$total_mem"
}

# Function to get node count
get_node_count() {
    local kubeconfig=$1
    if [ -f "$kubeconfig" ]; then
        kubectl --kubeconfig "$kubeconfig" get nodes --no-headers 2>/dev/null | wc -l
    else
        echo "0"
    fi
}

# Function to get pod count
get_pod_count() {
    local kubeconfig=$1
    if [ -f "$kubeconfig" ]; then
        kubectl --kubeconfig "$kubeconfig" get pods --all-namespaces --no-headers 2>/dev/null | wc -l
    else
        echo "0"
    fi
}

# Monitor loop
while true; do
    clear
    echo "📊 ClusterAPI Resource Monitor - $(date '+%H:%M:%S')"
    echo "============================="
    echo ""
    printf "%-20s %-6s %-8s %-8s %-8s %-10s\n" "Cluster" "Nodes" "Pods" "Containers" "CPU%" "Memory"
    printf "%-20s %-6s %-8s %-8s %-8s %-10s\n" "--------------------" "------" "--------" "--------" "--------" "----------"

    # Management cluster
    mgmt_nodes=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
    mgmt_pods=$(kubectl get pods --all-namespaces --no-headers 2>/dev/null | wc -l)
    printf "%-20s %-6s %-8s " "management" "$mgmt_nodes" "$mgmt_pods"
    get_container_stats "capi-management"
    echo ""

    # dev-cluster
    if kubectl get cluster dev-cluster &>/dev/null; then
        dev_nodes=$(get_node_count "../01-premier-cluster/dev-cluster.kubeconfig")
        dev_pods=$(get_pod_count "../01-premier-cluster/dev-cluster.kubeconfig")
        printf "%-20s %-6s %-8s " "dev-cluster" "$dev_nodes" "$dev_pods"
        get_container_stats "dev-cluster"
        echo ""
    fi

    # k0s-demo-cluster
    if kubectl get cluster k0s-demo-cluster &>/dev/null; then
        k0s_nodes=$(get_node_count "../03-k0smotron/k0s-demo-cluster.kubeconfig")
        k0s_pods=$(get_pod_count "../03-k0smotron/k0s-demo-cluster.kubeconfig")
        printf "%-20s %-6s %-8s " "k0s-demo-cluster" "$k0s_nodes" "$k0s_pods"
        get_container_stats "k0s-demo-cluster"
        echo ""
    fi

    echo ""
    echo "📈 Statistiques additionnelles:"

    # ClusterAPI objects
    cluster_count=$(kubectl get clusters --no-headers 2>/dev/null | wc -l)
    machine_count=$(kubectl get machines --no-headers 2>/dev/null | wc -l)
    echo "   Clusters: $cluster_count | Machines: $machine_count"

    # k0smotron control plane pods
    k0s_cp_pods=$(kubectl get pods -n kube-system -l app=k0smotron --no-headers 2>/dev/null | wc -l)
    if [ "$k0s_cp_pods" -gt 0 ]; then
        echo "   k0smotron Control Plane Pods: $k0s_cp_pods"
    fi

    # HelmReleaseProxy
    hrp_count=$(kubectl get helmreleaseproxy --no-headers 2>/dev/null | wc -l)
    if [ "$hrp_count" -gt 0 ]; then
        echo "   HelmReleaseProxy: $hrp_count"
    fi

    echo ""
    echo "🔄 Mise à jour toutes les 5 secondes..."
    echo "   Ctrl+C pour arrêter le monitoring"

    sleep 5
done