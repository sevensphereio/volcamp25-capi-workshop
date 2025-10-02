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
echo "🔍 Vérification des limites système"
echo "============================================="
echo ""

# Détecter l'OS
OS_TYPE=$(uname -s)

if [ "$OS_TYPE" = "Linux" ]; then
    # Vérifier les limites kernel Linux
    INOTIFY_WATCHES=$(sysctl -n fs.inotify.max_user_watches 2>/dev/null || echo "0")
    INOTIFY_INSTANCES=$(sysctl -n fs.inotify.max_user_instances 2>/dev/null || echo "0")
    FILE_MAX=$(sysctl -n fs.file-max 2>/dev/null || echo "0")
    PID_MAX=$(sysctl -n kernel.pid_max 2>/dev/null || echo "0")
    SOMAXCONN=$(sysctl -n net.core.somaxconn 2>/dev/null || echo "0")

    # Vérifier fs.inotify.max_user_watches (minimum 524288)
    if [ "$INOTIFY_WATCHES" -ge 524288 ]; then
        echo "✅ fs.inotify.max_user_watches: $INOTIFY_WATCHES (>= 524288)"
    else
        echo "❌ fs.inotify.max_user_watches: $INOTIFY_WATCHES (requis >= 524288)"
        FAILED=$((FAILED + 1))
    fi

    # Vérifier fs.inotify.max_user_instances (minimum 512)
    if [ "$INOTIFY_INSTANCES" -ge 512 ]; then
        echo "✅ fs.inotify.max_user_instances: $INOTIFY_INSTANCES (>= 512)"
    else
        echo "❌ fs.inotify.max_user_instances: $INOTIFY_INSTANCES (requis >= 512)"
        FAILED=$((FAILED + 1))
    fi

    # Vérifier fs.file-max (minimum 2097152)
    if [ "$FILE_MAX" -ge 2097152 ]; then
        echo "✅ fs.file-max: $FILE_MAX (>= 2097152)"
    else
        echo "❌ fs.file-max: $FILE_MAX (requis >= 2097152)"
        FAILED=$((FAILED + 1))
    fi

    # Vérifier kernel.pid_max (minimum 4194304)
    if [ "$PID_MAX" -ge 4194304 ]; then
        echo "✅ kernel.pid_max: $PID_MAX (>= 4194304)"
    else
        echo "❌ kernel.pid_max: $PID_MAX (requis >= 4194304)"
        FAILED=$((FAILED + 1))
    fi

    # Vérifier net.core.somaxconn (minimum 32768)
    if [ "$SOMAXCONN" -ge 32768 ]; then
        echo "✅ net.core.somaxconn: $SOMAXCONN (>= 32768)"
    else
        echo "❌ net.core.somaxconn: $SOMAXCONN (requis >= 32768)"
        FAILED=$((FAILED + 1))
    fi

    # Vérifier ulimit -n (minimum 1048576)
    NOFILE_LIMIT=$(ulimit -n 2>/dev/null || echo "0")
    if [ "$NOFILE_LIMIT" = "unlimited" ] || [ "$NOFILE_LIMIT" -ge 1048576 ]; then
        echo "✅ ulimit -n (open files): $NOFILE_LIMIT (>= 1048576)"
    else
        echo "❌ ulimit -n (open files): $NOFILE_LIMIT (requis >= 1048576)"
        FAILED=$((FAILED + 1))
    fi

elif [ "$OS_TYPE" = "Darwin" ]; then
    # Vérifier les limites macOS
    MAXFILES=$(launchctl limit maxfiles 2>/dev/null | awk '{print $2}')
    NOFILE_LIMIT=$(ulimit -n 2>/dev/null || echo "0")

    if [ "$MAXFILES" -ge 1048576 ] 2>/dev/null; then
        echo "✅ launchctl maxfiles: $MAXFILES (>= 1048576)"
    else
        echo "❌ launchctl maxfiles: $MAXFILES (requis >= 1048576)"
        FAILED=$((FAILED + 1))
    fi

    if [ "$NOFILE_LIMIT" = "unlimited" ] || [ "$NOFILE_LIMIT" -ge 1048576 ] 2>/dev/null; then
        echo "✅ ulimit -n (open files): $NOFILE_LIMIT (>= 1048576)"
    else
        echo "❌ ulimit -n (open files): $NOFILE_LIMIT (requis >= 1048576)"
        FAILED=$((FAILED + 1))
    fi
fi

# Vérifier Docker daemon
docker info &>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ Docker daemon accessible et en cours d'exécution"
else
    echo "❌ Docker daemon non accessible (est-il démarré?)"
    FAILED=$((FAILED + 1))
fi

echo ""
echo "============================================="
if [ $FAILED -eq 0 ]; then
    echo "🎉 Module 00 terminé avec succès!"
    echo "🚀 Tous les outils et limites système sont prêts"
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
    echo "📋 Actions à effectuer:"
    if [ "$OS_TYPE" = "Linux" ]; then
        echo "  1. Configurer les limites système: voir Étape 11 dans commands.md"
        echo "  2. Redémarrer votre session ou exécuter: sudo sysctl -p"
        echo "  3. Relancer: ./verification.sh"
    elif [ "$OS_TYPE" = "Darwin" ]; then
        echo "  1. Configurer les limites macOS: voir Étape 11 dans commands.md"
        echo "  2. Redémarrer votre session"
        echo "  3. Relancer: ./verification.sh"
    fi
    echo ""
    echo "Retournez dans commands.md pour installer les outils manquants."
    exit 1
fi