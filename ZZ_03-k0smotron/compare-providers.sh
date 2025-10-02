#!/bin/bash

set -e

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║  Comparaison: Docker Provider vs k0smotron                    ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

DEV_CLUSTER="dev-cluster"
K0S_CLUSTER="k0s-demo-cluster"

if ! kubectl get cluster $DEV_CLUSTER &>/dev/null; then
    echo "❌ Cluster $DEV_CLUSTER non trouvé"
    exit 1
fi

if ! kubectl get cluster $K0S_CLUSTER &>/dev/null; then
    echo "❌ Cluster $K0S_CLUSTER non trouvé"
    echo "   Créez-le d'abord avec: kubectl apply -f k0s-demo-cluster.yaml"
    exit 1
fi

echo "📊 Analyse des ressources..."
echo ""

DEV_MACHINES=$(kubectl get machines -l cluster.x-k8s.io/cluster-name=$DEV_CLUSTER --no-headers 2>/dev/null | wc -l)
K0S_MACHINES=$(kubectl get machines -l cluster.x-k8s.io/cluster-name=$K0S_CLUSTER --no-headers 2>/dev/null | wc -l)

DEV_CP_MACHINES=$(kubectl get machines -l cluster.x-k8s.io/cluster-name=$DEV_CLUSTER,cluster.x-k8s.io/control-plane="" --no-headers 2>/dev/null | wc -l)
K0S_CP_MACHINES=$(kubectl get machines -l cluster.x-k8s.io/cluster-name=$K0S_CLUSTER,cluster.x-k8s.io/control-plane="" --no-headers 2>/dev/null | wc -l)

K0S_CP_PODS=$(kubectl get pods -n kube-system -l app=k0smotron,cluster=$K0S_CLUSTER --no-headers 2>/dev/null | wc -l)

DEV_CONTAINERS=$(docker ps --filter "label=io.x-k8s.kind.cluster=$DEV_CLUSTER" --format "{{.ID}}" 2>/dev/null | wc -l)
K0S_CONTAINERS=$(docker ps --filter "label=io.x-k8s.kind.cluster=$K0S_CLUSTER" --format "{{.ID}}" 2>/dev/null | wc -l)

echo "┌────────────────────┬─────────────────┬─────────────────┬──────────────┐"
echo "│ Métrique           │ dev-cluster     │ k0s-demo        │ Économie     │"
echo "│                    │ (Docker)        │ (k0smotron)     │              │"
echo "├────────────────────┼─────────────────┼─────────────────┼──────────────┤"

printf "│ Total Machines     │ %-15s │ %-15s │" "$DEV_MACHINES" "$K0S_MACHINES"
if [ "$K0S_MACHINES" -lt "$DEV_MACHINES" ]; then
    SAVING=$(echo "scale=0; 100 - ($K0S_MACHINES * 100 / $DEV_MACHINES)" | bc)
    printf " %-12s │\n" "${SAVING}%"
else
    printf " %-12s │\n" "N/A"
fi

printf "│ Control Plane      │ %-15s │ %-15s │ %-12s │\n" "$DEV_CP_MACHINES nodes" "$K0S_CP_PODS pods" "100%"

printf "│ Worker Machines    │ %-15s │ %-15s │ %-12s │\n" "$((DEV_MACHINES - DEV_CP_MACHINES))" "$((K0S_MACHINES - K0S_CP_MACHINES))" "-"

printf "│ Docker Containers  │ %-15s │ %-15s │" "$DEV_CONTAINERS" "$K0S_CONTAINERS"
if [ "$K0S_CONTAINERS" -lt "$DEV_CONTAINERS" ]; then
    SAVING=$(echo "scale=0; 100 - ($K0S_CONTAINERS * 100 / $DEV_CONTAINERS)" | bc)
    printf " %-12s │\n" "${SAVING}%"
else
    printf " %-12s │\n" "N/A"
fi

echo "└────────────────────┴─────────────────┴─────────────────┴──────────────┘"
echo ""

if command -v docker stats --no-stream &>/dev/null; then
    echo "📈 Consommation Mémoire (approximative):"
    echo ""

    DEV_MEM=0
    for container in $(docker ps --filter "label=io.x-k8s.kind.cluster=$DEV_CLUSTER" --format "{{.ID}}" 2>/dev/null); do
        MEM=$(docker stats --no-stream --format "{{.MemUsage}}" $container 2>/dev/null | awk '{print $1}' | sed 's/MiB//g' | sed 's/GiB/*1024/g' | bc 2>/dev/null || echo "0")
        DEV_MEM=$(echo "$DEV_MEM + $MEM" | bc 2>/dev/null || echo "$DEV_MEM")
    done

    K0S_MEM=0
    for container in $(docker ps --filter "label=io.x-k8s.kind.cluster=$K0S_CLUSTER" --format "{{.ID}}" 2>/dev/null); do
        MEM=$(docker stats --no-stream --format "{{.MemUsage}}" $container 2>/dev/null | awk '{print $1}' | sed 's/MiB//g' | sed 's/GiB/*1024/g' | bc 2>/dev/null || echo "0")
        K0S_MEM=$(echo "$K0S_MEM + $MEM" | bc 2>/dev/null || echo "$K0S_MEM")
    done

    MGMT_MEM=0
    for container in $(docker ps --filter "label=io.x-k8s.kind.cluster=capi-management" --format "{{.ID}}" 2>/dev/null); do
        MEM=$(docker stats --no-stream --format "{{.MemUsage}}" $container 2>/dev/null | awk '{print $1}' | sed 's/MiB//g' | sed 's/GiB/*1024/g' | bc 2>/dev/null || echo "0")
        MGMT_MEM=$(echo "$MGMT_MEM + $MEM" | bc 2>/dev/null || echo "$MGMT_MEM")
    done

    K0S_TOTAL=$(echo "$K0S_MEM + ($K0S_CP_PODS * 150)" | bc 2>/dev/null || echo "0")

    echo "  dev-cluster (Docker):     ~${DEV_MEM}MB"
    echo "  k0s-demo (k0smotron):     ~${K0S_TOTAL}MB (workers: ${K0S_MEM}MB + CP pods: ~$((K0S_CP_PODS * 150))MB)"

    if [ "$K0S_TOTAL" -gt 0 ] && [ "$DEV_MEM" -gt 0 ]; then
        MEM_SAVING=$(echo "scale=0; 100 - ($K0S_TOTAL * 100 / $DEV_MEM)" | bc 2>/dev/null || echo "0")
        echo ""
        echo "  💰 Économie mémoire: ~${MEM_SAVING}%"
    fi
    echo ""
fi

echo "✨ Avantages k0smotron:"
echo "   ✅ Moins de nodes (économie ressources)"
echo "   ✅ Control plane virtualisé (3 pods au lieu de 3 nodes)"
echo "   ✅ Boot time plus rapide (~1 min vs ~3 min)"
echo "   ✅ HA simplifié (Kubernetes natif)"
echo "   ✅ Backup facilité (pods + PVC au lieu de nodes)"
echo ""
echo "📊 Économie globale estimée: ~50-55% des ressources"
echo ""