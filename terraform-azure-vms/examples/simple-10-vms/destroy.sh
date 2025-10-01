#!/bin/bash
# =============================================================================
# Script de destruction de l'infrastructure
# =============================================================================
# Détruit toutes les ressources créées par Terraform de manière sécurisée
# =============================================================================

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# FONCTIONS
# =============================================================================

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

check_state() {
    print_header "Vérification de l'état Terraform"

    cd "${SCRIPT_DIR}"

    if [ ! -f "terraform.tfstate" ] && [ ! -f ".terraform/terraform.tfstate" ]; then
        print_error "Aucun état Terraform trouvé"
        print_info "Il n'y a rien à détruire, ou l'infrastructure a déjà été détruite"
        exit 1
    fi

    print_success "État Terraform trouvé"
}

show_resources() {
    print_header "Ressources à détruire"

    cd "${SCRIPT_DIR}"

    echo ""
    print_info "Liste des ressources qui seront détruites:"
    echo ""

    terraform state list | sed 's/^/  /'

    echo ""
    local resource_count=$(terraform state list | wc -l)
    print_warning "${resource_count} ressources seront supprimées"
}

confirm_destruction() {
    echo ""
    print_header "⚠️  CONFIRMATION REQUISE"
    echo ""
    print_warning "Cette action est IRRÉVERSIBLE !"
    print_warning "Toutes les VMs et leurs données seront définitivement supprimées"
    echo ""
    print_info "Ressources qui seront détruites:"
    echo "  - Toutes les VMs et leurs disques"
    echo "  - Les IPs publiques"
    echo "  - Les interfaces réseau"
    echo "  - Le réseau virtuel et subnet"
    echo "  - Le groupe de ressources"
    echo "  - Tous les autres composants créés"
    echo ""

    read -p "Tapez 'yes' pour confirmer la destruction: " confirmation

    if [ "${confirmation}" != "yes" ]; then
        print_info "Destruction annulée"
        exit 0
    fi

    echo ""
    read -p "Êtes-vous absolument sûr ? (yes/NO): " final_confirmation

    if [ "${final_confirmation}" != "yes" ]; then
        print_info "Destruction annulée"
        exit 0
    fi
}

backup_state() {
    print_header "Sauvegarde de l'état Terraform"

    cd "${SCRIPT_DIR}"

    local backup_file="terraform.tfstate.backup-$(date +%Y%m%d-%H%M%S)"

    if [ -f "terraform.tfstate" ]; then
        cp terraform.tfstate "${backup_file}"
        print_success "État sauvegardé: ${backup_file}"
    else
        print_info "Aucun fichier d'état à sauvegarder"
    fi
}

destroy_infrastructure() {
    print_header "Destruction de l'infrastructure"

    cd "${SCRIPT_DIR}"

    print_info "Destruction en cours (2-3 minutes)..."
    echo ""

    local start_time=$(date +%s)

    # Désactiver la confirmation interactive (déjà faite manuellement)
    terraform destroy -auto-approve

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    print_success "Infrastructure détruite en ${duration} secondes"
}

cleanup_files() {
    print_header "Nettoyage des fichiers locaux"

    cd "${SCRIPT_DIR}"

    local files_to_remove=(
        "workshop_key.pem"
        "inventory.txt"
        "tfplan"
        ".terraform.lock.hcl"
    )

    for file in "${files_to_remove[@]}"; do
        if [ -f "${file}" ]; then
            rm -f "${file}"
            print_success "Supprimé: ${file}"
        fi
    done

    # Demander si on supprime le dossier .terraform
    echo ""
    read -p "Supprimer le dossier .terraform ? (y/N) " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf .terraform
        print_success "Dossier .terraform supprimé"
    else
        print_info "Dossier .terraform conservé"
    fi
}

display_summary() {
    print_header "Résumé"

    echo ""
    echo -e "${GREEN}🎉 Destruction terminée avec succès !${NC}"
    echo ""

    print_info "Toutes les ressources Azure ont été supprimées"
    print_info "Les fichiers locaux ont été nettoyés"
    echo ""

    print_warning "Note: Les sauvegardes de l'état Terraform (*.backup-*) ont été conservées"
    print_info "Vous pouvez les supprimer manuellement si nécessaire"
    echo ""
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    clear

    print_header "Destruction de l'infrastructure Azure"
    echo ""

    check_state
    echo ""

    show_resources
    echo ""

    confirm_destruction
    echo ""

    backup_state
    echo ""

    destroy_infrastructure
    echo ""

    cleanup_files
    echo ""

    display_summary

    print_success "Script terminé"
}

# Exécuter le script principal
main "$@"
