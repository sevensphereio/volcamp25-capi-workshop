#!/bin/bash

# ==============================================================================
# Module 00: Script d'Installation Automatique des Outils Workshop
# ==============================================================================
# Ce script installe automatiquement tous les outils nécessaires au workshop:
# - Docker Engine
# - kind
# - kubectl
# - kubectl plugins (ctx, ns, slice, klock) via krew
# - clusterctl
# - Helm
# - jq
# - yq
# - tree
#
# Usage: ./setup.sh
# ==============================================================================

set -e  # Arrêt immédiat en cas d'erreur

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Versions des outils
KIND_VERSION="v0.30.0"
CLUSTERCTL_VERSION="v1.11.1"
HELM_VERSION="v3.19.0"
YQ_VERSION="v4.44.6"

# ==============================================================================
# Fonctions utilitaires
# ==============================================================================

print_header() {
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=================================================${NC}"
}

print_step() {
    echo -e "${GREEN}▶ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

check_command() {
    if command -v "$1" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# ==============================================================================
# Détection de l'OS et de l'architecture
# ==============================================================================

detect_os_arch() {
    print_step "Détection du système d'exploitation et de l'architecture..."

    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)

    case "$ARCH" in
        x86_64)
            ARCH="amd64"
            ;;
        aarch64)
            ARCH="arm64"
            ;;
        arm64)
            ARCH="arm64"
            ;;
        *)
            print_error "Architecture non supportée: $ARCH"
            exit 1
            ;;
    esac

    print_success "Système détecté: $OS $ARCH"
    echo ""
}

# ==============================================================================
# Installation Docker
# ==============================================================================

install_docker() {
    print_header "Installation Docker Engine"

    if check_command docker; then
        DOCKER_VERSION=$(docker --version 2>/dev/null | awk '{print $3}' | sed 's/,//')
        print_warning "Docker déjà installé (version $DOCKER_VERSION)"
        echo ""
        return 0
    fi

    if [ "$OS" = "linux" ]; then
        print_step "Installation Docker sur Linux..."

        # Détection de la distribution
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            DISTRO=$ID
        else
            print_error "Distribution Linux non détectée"
            exit 1
        fi

        case "$DISTRO" in
            ubuntu|debian)
                print_step "Installation des dépendances..."
                sudo apt-get update
                sudo apt-get install -y ca-certificates curl gnupg lsb-release

                print_step "Ajout de la clé GPG Docker..."
                sudo mkdir -p /etc/apt/keyrings
                curl -fsSL https://download.docker.com/linux/$DISTRO/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

                print_step "Ajout du repository Docker..."
                echo \
                  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$DISTRO \
                  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

                print_step "Installation de Docker Engine..."
                sudo apt-get update
                sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

                print_step "Ajout de l'utilisateur au groupe docker..."
                sudo usermod -aG docker $USER

                print_success "Docker installé avec succès!"
                print_warning "Vous devrez peut-être vous reconnecter pour utiliser Docker sans sudo"
                ;;
            *)
                print_error "Distribution non supportée: $DISTRO"
                print_warning "Veuillez installer Docker manuellement: https://docs.docker.com/engine/install/"
                ;;
        esac

    elif [ "$OS" = "darwin" ]; then
        print_step "Installation Docker Desktop sur macOS..."

        if check_command brew; then
            brew install --cask docker
            print_success "Docker Desktop installé via Homebrew"
            print_warning "Lancez Docker Desktop depuis Applications avant de continuer"
        else
            print_error "Homebrew non installé"
            print_warning "Installez Docker Desktop manuellement: https://www.docker.com/products/docker-desktop/"
            print_warning "Ou installez Homebrew d'abord: https://brew.sh/"
        fi
    fi

    echo ""
}

# ==============================================================================
# Installation kind
# ==============================================================================

install_kind() {
    print_header "Installation kind"

    if check_command kind; then
        KIND_CURRENT=$(kind --version 2>/dev/null | awk '{print $3}')
        print_warning "kind déjà installé (version $KIND_CURRENT)"
        echo ""
        return 0
    fi

    print_step "Téléchargement de kind $KIND_VERSION..."

    if [ "$OS" = "linux" ]; then
        curl -Lo ./kind "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-${ARCH}"
    elif [ "$OS" = "darwin" ]; then
        if check_command brew; then
            print_step "Installation via Homebrew..."
            brew install kind
            print_success "kind installé via Homebrew"
            echo ""
            return 0
        else
            curl -Lo ./kind "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-darwin-${ARCH}"
        fi
    fi

    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind

    print_success "kind $KIND_VERSION installé avec succès!"
    echo ""
}

# ==============================================================================
# Installation kubectl
# ==============================================================================

install_kubectl() {
    print_header "Installation kubectl"

    if check_command kubectl; then
        KUBECTL_VERSION=$(kubectl version --client 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        print_warning "kubectl déjà installé (version $KUBECTL_VERSION)"
        echo ""
        return 0
    fi

    print_step "Téléchargement de kubectl..."

    KUBECTL_STABLE=$(curl -L -s https://dl.k8s.io/release/stable.txt)

    if [ "$OS" = "linux" ]; then
        curl -LO "https://dl.k8s.io/release/${KUBECTL_STABLE}/bin/linux/${ARCH}/kubectl"
    elif [ "$OS" = "darwin" ]; then
        if check_command brew; then
            print_step "Installation via Homebrew..."
            brew install kubectl
            print_success "kubectl installé via Homebrew"
            echo ""
            return 0
        else
            curl -LO "https://dl.k8s.io/release/${KUBECTL_STABLE}/bin/darwin/${ARCH}/kubectl"
        fi
    fi

    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/

    print_success "kubectl installé avec succès!"
    echo ""
}

# ==============================================================================
# Installation krew et plugins kubectl
# ==============================================================================

install_krew_and_plugins() {
    print_header "Installation krew et plugins kubectl"

    # Vérifier si krew est déjà installé
    if [ -d "${HOME}/.krew" ]; then
        print_warning "krew déjà installé"
    else
        print_step "Installation de krew..."

        (
            set -x
            cd "$(mktemp -d)"
            OS_KREW="$(uname | tr '[:upper:]' '[:lower:]')"
            ARCH_KREW="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')"
            KREW="krew-${OS_KREW}_${ARCH_KREW}"
            curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz"
            tar zxvf "${KREW}.tar.gz"
            ./"${KREW}" install krew
        )

        print_success "krew installé avec succès!"
    fi

    # Ajouter krew au PATH pour cette session
    export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

    # Ajouter krew au PATH de manière permanente
    SHELL_RC=""
    if [ -n "$BASH_VERSION" ]; then
        SHELL_RC="$HOME/.bashrc"
    elif [ -n "$ZSH_VERSION" ]; then
        SHELL_RC="$HOME/.zshrc"
    fi

    if [ -n "$SHELL_RC" ] && [ -f "$SHELL_RC" ]; then
        if ! grep -q "KREW_ROOT" "$SHELL_RC"; then
            print_step "Ajout de krew au PATH dans $SHELL_RC..."
            echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' >> "$SHELL_RC"
        fi
    fi

    # Installation des plugins
    print_step "Installation des plugins kubectl..."

    PLUGINS=("ctx" "ns" "slice" "klock")
    for plugin in "${PLUGINS[@]}"; do
        if kubectl krew list | grep -q "^${plugin}$" 2>/dev/null; then
            print_warning "Plugin kubectl-${plugin} déjà installé"
        else
            print_step "Installation du plugin kubectl-${plugin}..."
            kubectl krew install "$plugin"
            print_success "Plugin kubectl-${plugin} installé"
        fi
    done

    echo ""
}

# ==============================================================================
# Installation clusterctl
# ==============================================================================

install_clusterctl() {
    print_header "Installation clusterctl"

    if check_command clusterctl; then
        CLUSTERCTL_CURRENT=$(clusterctl version 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        print_warning "clusterctl déjà installé (version $CLUSTERCTL_CURRENT)"
        echo ""
        return 0
    fi

    print_step "Téléchargement de clusterctl $CLUSTERCTL_VERSION..."

    if [ "$OS" = "linux" ]; then
        curl -L "https://github.com/kubernetes-sigs/cluster-api/releases/download/${CLUSTERCTL_VERSION}/clusterctl-linux-${ARCH}" -o clusterctl
    elif [ "$OS" = "darwin" ]; then
        if check_command brew; then
            print_step "Installation via Homebrew..."
            brew install clusterctl
            print_success "clusterctl installé via Homebrew"
            echo ""
            return 0
        else
            curl -L "https://github.com/kubernetes-sigs/cluster-api/releases/download/${CLUSTERCTL_VERSION}/clusterctl-darwin-${ARCH}" -o clusterctl
        fi
    fi

    chmod +x ./clusterctl
    sudo mv ./clusterctl /usr/local/bin/clusterctl

    print_success "clusterctl $CLUSTERCTL_VERSION installé avec succès!"
    echo ""
}

# ==============================================================================
# Installation Helm
# ==============================================================================

install_helm() {
    print_header "Installation Helm"

    if check_command helm; then
        HELM_CURRENT=$(helm version --short 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        print_warning "Helm déjà installé (version $HELM_CURRENT)"
        echo ""
        return 0
    fi

    print_step "Téléchargement de Helm $HELM_VERSION..."

    if [ "$OS" = "linux" ]; then
        curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-${ARCH}.tar.gz" -o helm.tar.gz
        tar -zxvf helm.tar.gz
        sudo mv linux-${ARCH}/helm /usr/local/bin/helm
        rm -rf linux-${ARCH} helm.tar.gz
    elif [ "$OS" = "darwin" ]; then
        if check_command brew; then
            print_step "Installation via Homebrew..."
            brew install helm
            print_success "Helm installé via Homebrew"
            echo ""
            return 0
        else
            curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-darwin-${ARCH}.tar.gz" -o helm.tar.gz
            tar -zxvf helm.tar.gz
            sudo mv darwin-${ARCH}/helm /usr/local/bin/helm
            rm -rf darwin-${ARCH} helm.tar.gz
        fi
    fi

    print_success "Helm $HELM_VERSION installé avec succès!"
    echo ""
}

# ==============================================================================
# Installation jq
# ==============================================================================

install_jq() {
    print_header "Installation jq"

    if check_command jq; then
        JQ_VERSION=$(jq --version 2>/dev/null | sed 's/jq-//')
        print_warning "jq déjà installé (version $JQ_VERSION)"
        echo ""
        return 0
    fi

    print_step "Installation de jq..."

    if [ "$OS" = "linux" ]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            DISTRO=$ID
        fi

        case "$DISTRO" in
            ubuntu|debian)
                sudo apt-get update
                sudo apt-get install -y jq
                ;;
            *)
                print_error "Distribution non supportée pour installation automatique de jq"
                print_warning "Installez jq manuellement: https://stedolan.github.io/jq/download/"
                return 1
                ;;
        esac

    elif [ "$OS" = "darwin" ]; then
        if check_command brew; then
            brew install jq
        else
            print_error "Homebrew non installé"
            print_warning "Installez jq manuellement ou installez Homebrew d'abord"
            return 1
        fi
    fi

    print_success "jq installé avec succès!"
    echo ""
}

# ==============================================================================
# Installation yq
# ==============================================================================

install_yq() {
    print_header "Installation yq"

    if check_command yq; then
        YQ_CURRENT=$(yq --version 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        print_warning "yq déjà installé (version $YQ_CURRENT)"
        echo ""
        return 0
    fi

    print_step "Téléchargement de yq $YQ_VERSION..."

    if [ "$OS" = "linux" ]; then
        curl -L "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${ARCH}" -o yq
        chmod +x yq
        sudo mv yq /usr/local/bin/yq
    elif [ "$OS" = "darwin" ]; then
        if check_command brew; then
            print_step "Installation via Homebrew..."
            brew install yq
            print_success "yq installé via Homebrew"
            echo ""
            return 0
        else
            curl -L "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_darwin_${ARCH}" -o yq
            chmod +x yq
            sudo mv yq /usr/local/bin/yq
        fi
    fi

    print_success "yq $YQ_VERSION installé avec succès!"
    echo ""
}

# ==============================================================================
# Installation tree
# ==============================================================================

install_tree() {
    print_header "Installation tree"

    if check_command tree; then
        TREE_VERSION=$(tree --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        print_warning "tree déjà installé (version $TREE_VERSION)"
        echo ""
        return 0
    fi

    print_step "Installation de tree..."

    if [ "$OS" = "linux" ]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            DISTRO=$ID
        fi

        case "$DISTRO" in
            ubuntu|debian)
                sudo apt-get update
                sudo apt-get install -y tree
                ;;
            *)
                print_error "Distribution non supportée pour installation automatique de tree"
                print_warning "Installez tree manuellement avec votre package manager"
                return 1
                ;;
        esac

    elif [ "$OS" = "darwin" ]; then
        if check_command brew; then
            brew install tree
        else
            print_error "Homebrew non installé"
            print_warning "Installez tree manuellement ou installez Homebrew d'abord"
            return 1
        fi
    fi

    print_success "tree installé avec succès!"
    echo ""
}

# ==============================================================================
# Configuration de l'autocomplétion kubectl
# ==============================================================================

setup_kubectl_completion() {
    print_header "Configuration de l'autocomplétion kubectl"

    SHELL_RC=""
    COMPLETION_CMD=""

    if [ -n "$BASH_VERSION" ]; then
        SHELL_RC="$HOME/.bashrc"
        COMPLETION_CMD='source <(kubectl completion bash)'
    elif [ -n "$ZSH_VERSION" ]; then
        SHELL_RC="$HOME/.zshrc"
        COMPLETION_CMD='source <(kubectl completion zsh)'
    fi

    if [ -n "$SHELL_RC" ] && [ -f "$SHELL_RC" ]; then
        if ! grep -q "kubectl completion" "$SHELL_RC"; then
            print_step "Ajout de l'autocomplétion kubectl dans $SHELL_RC..."
            echo "$COMPLETION_CMD" >> "$SHELL_RC"
            print_success "Autocomplétion kubectl configurée"
        else
            print_warning "Autocomplétion kubectl déjà configurée"
        fi
    else
        print_warning "Impossible de détecter le shell, autocomplétion non configurée"
    fi

    echo ""
}

# ==============================================================================
# Ajout d'alias kubectl
# ==============================================================================

add_kubectl_aliases() {
    print_header "Ajout d'alias kubectl (optionnel)"

    SHELL_RC=""
    if [ -n "$BASH_VERSION" ]; then
        SHELL_RC="$HOME/.bashrc"
    elif [ -n "$ZSH_VERSION" ]; then
        SHELL_RC="$HOME/.zshrc"
    fi

    if [ -n "$SHELL_RC" ] && [ -f "$SHELL_RC" ]; then
        if ! grep -q "alias k='kubectl'" "$SHELL_RC"; then
            print_step "Ajout des alias kubectl dans $SHELL_RC..."

            cat >> "$SHELL_RC" << 'EOF'

# Alias kubectl pour productivité
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgn='kubectl get nodes'
alias kdp='kubectl describe pod'
alias kl='kubectl logs'
alias kex='kubectl exec -it'
EOF
            print_success "Alias kubectl ajoutés"
        else
            print_warning "Alias kubectl déjà configurés"
        fi
    fi

    echo ""
}

# ==============================================================================
# Validation finale
# ==============================================================================

validate_installation() {
    print_header "Validation de l'installation"

    print_step "Exécution du script de validation..."
    echo ""

    # Exécuter le script de validation
    if [ -f "./verification.sh" ]; then
        bash ./verification.sh
    else
        print_error "Script verification.sh non trouvé"
        exit 1
    fi
}

# ==============================================================================
# Programme principal
# ==============================================================================

main() {
    clear

    print_header "Module 00: Installation Automatique des Outils Workshop"
    echo ""
    echo "Ce script va installer automatiquement tous les outils nécessaires:"
    echo "  • Docker Engine"
    echo "  • kind ($KIND_VERSION)"
    echo "  • kubectl (dernière version stable)"
    echo "  • kubectl plugins (ctx, ns, slice, klock) via krew"
    echo "  • clusterctl ($CLUSTERCTL_VERSION)"
    echo "  • Helm ($HELM_VERSION)"
    echo "  • jq"
    echo "  • yq ($YQ_VERSION)"
    echo "  • tree"
    echo ""

    read -p "Voulez-vous continuer? (y/n) " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Installation annulée"
        exit 0
    fi

    echo ""

    # Détection OS et architecture
    detect_os_arch

    # Installations
    install_docker
    install_kind
    install_kubectl
    install_krew_and_plugins
    install_clusterctl
    install_helm
    install_jq
    install_yq
    install_tree

    # Configuration
    setup_kubectl_completion
    add_kubectl_aliases

    # Validation
    validate_installation

    # Configuration limites système
    echo ""
    print_header "Configuration des Limites Système"
    echo ""
    echo "Le workshop nécessite d'augmenter les limites système pour:"
    echo "  • Supporter de nombreux containers et clusters"
    echo "  • Éviter les erreurs 'too many open files'"
    echo "  • Optimiser les performances"
    echo ""
    read -p "Voulez-vous configurer les limites système maintenant? (recommandé) (y/n) " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -f "./configure-system-limits.sh" ]; then
            bash ./configure-system-limits.sh
        else
            print_warning "Script configure-system-limits.sh non trouvé"
            print_warning "Vous pouvez le lancer manuellement plus tard: ./configure-system-limits.sh"
        fi
    else
        print_warning "Configuration des limites système ignorée"
        print_warning "⚠️  Sans cette configuration, vous pourriez rencontrer des problèmes!"
        echo ""
        echo "Pour configurer plus tard, exécutez:"
        echo "  ./configure-system-limits.sh"
    fi

    # Message final
    echo ""
    print_header "Installation Terminée!"
    echo ""
    print_success "Tous les outils ont été installés avec succès!"
    echo ""
    print_warning "Actions requises:"
    echo "  1. Rechargez votre shell: source ~/.bashrc (ou ~/.zshrc)"
    echo "  2. Si Docker a été installé, reconnectez-vous ou exécutez: newgrp docker"
    if [ "$OS" = "darwin" ]; then
        echo "  3. Lancez Docker Desktop depuis Applications"
    fi
    echo "  4. Si limites configurées, reconnectez-vous pour les appliquer"
    echo ""
    print_success "Prochaine étape: cd ../00-setup-management"
    echo ""
}

# Exécution du programme principal
main
