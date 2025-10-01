#!/bin/bash

set -e

echo "🔍 Module 00: Validation Installation Outils"
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

check_version() {
    TOOL=$1
    VERSION=$2
    if [ -n "$VERSION" ] && [ "$VERSION" != "unknown" ]; then
        echo "✅ $TOOL installé (version $VERSION)"
    else
        echo "❌ $TOOL non trouvé"
        FAILED=$((FAILED + 1))
    fi
}

# Vérifier Docker
DOCKER_VERSION=$(docker --version 2>/dev/null | awk '{print $3}' | sed 's/,//')
check_version "Docker" "$DOCKER_VERSION"

# Vérifier kind
KIND_VERSION=$(kind --version 2>/dev/null | awk '{print $3}')
check_version "kind" "$KIND_VERSION"

# Vérifier kubectl
KUBECTL_VERSION=$(kubectl version --client --short 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1)
if [ -z "$KUBECTL_VERSION" ]; then
    KUBECTL_VERSION=$(kubectl version --client 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1)
fi
check_version "kubectl" "$KUBECTL_VERSION"

# Vérifier kubectl plugins
kubectl ctx --help &>/dev/null
check "kubectl plugin: ctx installé"

kubectl ns --help &>/dev/null
check "kubectl plugin: ns installé"

kubectl slice --help &>/dev/null
check "kubectl plugin: slice installé"

kubectl klock --help &>/dev/null
check "kubectl plugin: klock installé"

# Vérifier clusterctl
CLUSTERCTL_VERSION=$(clusterctl version 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1)
check_version "clusterctl" "$CLUSTERCTL_VERSION"

# Vérifier Helm
HELM_VERSION=$(helm version --short 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1)
check_version "Helm" "$HELM_VERSION"

# Vérifier jq
JQ_VERSION=$(jq --version 2>/dev/null | sed 's/jq-//')
check_version "jq" "$JQ_VERSION"

# Vérifier yq
YQ_VERSION=$(yq --version 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1 | sed 's/v//')
check_version "yq" "$YQ_VERSION"

# Vérifier tree
TREE_VERSION=$(tree --version 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1 | sed 's/v//')
if [ -z "$TREE_VERSION" ]; then
    TREE_VERSION=$(tree --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
fi
check_version "tree" "$TREE_VERSION"

echo ""
echo "============================================="
if [ $FAILED -eq 0 ]; then
    echo "🎉 Module 00 terminé avec succès!"
    echo "🚀 Tous les outils sont prêts pour le workshop"
    echo "============================================="
    echo ""
    echo "Prochaine commande:"
    echo "  cd ../00-setup-management"
    echo "  cat commands.md"
    exit 0
else
    echo "❌ $FAILED test(s) échoué(s)"
    echo "============================================="
    echo ""
    echo "Retournez dans commands.md pour installer les outils manquants."
    exit 1
fi