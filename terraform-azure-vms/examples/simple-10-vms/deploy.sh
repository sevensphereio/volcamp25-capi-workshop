#!/bin/bash
# =============================================================================
# Script de déploiement rapide - 10 VMs Azure
# =============================================================================
# Ce script automatise le déploiement complet de l'infrastructure
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
SSH_KEY_FILE="${SCRIPT_DIR}/workshop_key.pem"
INVENTORY_FILE="${SCRIPT_DIR}/inventory.txt"

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

check_prerequisites() {
    print_header "Vérification des prérequis"

    # Terraform
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform n'est pas installé"
        echo "Installation: https://developer.hashicorp.com/terraform/downloads"
        exit 1
    fi
    print_success "Terraform $(terraform version -json | jq -r '.terraform_version') détecté"

    # Azure CLI
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI n'est pas installé"
        echo "Installation: https://docs.microsoft.com/cli/azure/install-azure-cli"
        exit 1
    fi
    print_success "Azure CLI détecté"

    # Authentification Azure
    if ! az account show &> /dev/null; then
        print_error "Vous n'êtes pas authentifié à Azure"
        print_info "Exécutez: az login"
        exit 1
    fi

    local subscription=$(az account show --query name -o tsv)
    print_success "Connecté à Azure: ${subscription}"

    # jq (optionnel)
    if ! command -v jq &> /dev/null; then
        print_warning "jq n'est pas installé (optionnel pour parsing JSON)"
    fi
}

show_configuration() {
    print_header "Configuration du déploiement"

    if [ -f "${SCRIPT_DIR}/terraform.tfvars" ]; then
        echo ""
        echo "Paramètres détectés dans terraform.tfvars:"
        echo ""
        grep -v "^#" "${SCRIPT_DIR}/terraform.tfvars" | grep -v "^$" | head -20
        echo ""
        print_warning "Vérifiez ces paramètres avant de continuer"
        echo ""
        read -p "Continuer avec cette configuration ? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Déploiement annulé. Modifiez terraform.tfvars et relancez."
            exit 0
        fi
    else
        print_warning "Fichier terraform.tfvars non trouvé"
        print_info "Les valeurs par défaut de main.tf seront utilisées"
    fi
}

initialize_terraform() {
    print_header "Initialisation de Terraform"

    cd "${SCRIPT_DIR}"

    if [ -d ".terraform" ]; then
        print_info "Terraform déjà initialisé, mise à jour..."
        terraform init -upgrade
    else
        print_info "Première initialisation..."
        terraform init
    fi

    print_success "Terraform initialisé"
}

plan_deployment() {
    print_header "Planification du déploiement"

    cd "${SCRIPT_DIR}"

    print_info "Génération du plan d'exécution..."
    terraform plan -out=tfplan

    print_success "Plan généré"
    echo ""
    print_warning "Vérifiez le plan ci-dessus avant de déployer"
    echo ""
    read -p "Voulez-vous déployer cette infrastructure ? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Déploiement annulé"
        rm -f tfplan
        exit 0
    fi
}

deploy_infrastructure() {
    print_header "Déploiement de l'infrastructure"

    cd "${SCRIPT_DIR}"

    print_info "Déploiement en cours (3-5 minutes)..."
    echo ""

    local start_time=$(date +%s)

    terraform apply tfplan

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    rm -f tfplan

    print_success "Infrastructure déployée en ${duration} secondes"
}

save_outputs() {
    print_header "Récupération des informations de connexion"

    cd "${SCRIPT_DIR}"

    # Sauvegarder la clé SSH
    print_info "Sauvegarde de la clé SSH privée..."
    terraform output -raw ssh_private_key > "${SSH_KEY_FILE}"
    chmod 600 "${SSH_KEY_FILE}"
    print_success "Clé SSH sauvegardée: ${SSH_KEY_FILE}"

    # Créer l'inventaire
    print_info "Création de l'inventaire des VMs..."
    if command -v jq &> /dev/null; then
        terraform output -json vm_public_ips | jq -r 'to_entries[] | "\(.key): \(.value)"' > "${INVENTORY_FILE}"
        print_success "Inventaire créé: ${INVENTORY_FILE}"
    else
        print_warning "jq non disponible, inventaire non créé"
    fi
}

display_summary() {
    print_header "Résumé du déploiement"

    cd "${SCRIPT_DIR}"

    echo ""
    echo -e "${GREEN}🎉 Déploiement terminé avec succès !${NC}"
    echo ""

    # Afficher les informations de connexion
    if terraform output vm_ssh_connections &> /dev/null; then
        echo -e "${BLUE}📋 Commandes de connexion SSH:${NC}"
        echo ""
        terraform output -json vm_ssh_connections | jq -r '.[]' | sed 's/^/  /'
        echo ""
    fi

    # Résumé des ressources
    echo -e "${BLUE}📊 Ressources créées:${NC}"
    terraform output -json deployment_info | jq -r 'to_entries[] | "  \(.key): \(.value)"' 2>/dev/null || echo "  Voir: terraform output deployment_info"
    echo ""

    # Instructions suivantes
    echo -e "${BLUE}🚀 Prochaines étapes:${NC}"
    echo ""
    echo "  1. Tester la connexion SSH:"
    echo "     ssh -i ${SSH_KEY_FILE} azureuser@<IP-VM>"
    echo ""
    echo "  2. Voir toutes les sorties:"
    echo "     terraform output"
    echo ""
    echo "  3. Se connecter à une VM spécifique:"
    echo "     terraform output -raw ssh_private_key > key.pem && chmod 600 key.pem"
    echo "     ssh -i key.pem azureuser@\$(terraform output -json vm_public_ips | jq -r '.\"vm-01\"')"
    echo ""
    echo "  4. Détruire l'infrastructure quand terminé:"
    echo "     ./destroy.sh  # ou: terraform destroy"
    echo ""
}

test_connectivity() {
    print_header "Test de connectivité (optionnel)"

    echo ""
    read -p "Voulez-vous tester la connexion SSH aux VMs ? (y/N) " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Test de connectivité ignoré"
        return
    fi

    cd "${SCRIPT_DIR}"

    print_info "Test des connexions SSH (peut prendre 1-2 minutes)..."
    echo ""

    local success=0
    local failed=0

    terraform output -json vm_public_ips | jq -r 'to_entries[] | "\(.key) \(.value)"' | while read vm_name vm_ip; do
        printf "  Testing %-15s (%s)... " "${vm_name}" "${vm_ip}"

        if timeout 10 ssh -i "${SSH_KEY_FILE}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 -o LogLevel=ERROR azureuser@${vm_ip} "hostname" &> /dev/null; then
            echo -e "${GREEN}✅ OK${NC}"
            ((success++))
        else
            echo -e "${RED}❌ FAILED${NC}"
            ((failed++))
        fi
    done

    echo ""
    if [ ${failed} -eq 0 ]; then
        print_success "Toutes les VMs sont accessibles"
    else
        print_warning "${success} VMs accessibles, ${failed} VMs en échec"
        print_info "Les VMs peuvent nécessiter quelques minutes supplémentaires pour démarrer"
    fi
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    clear

    print_header "Déploiement automatisé - 10 VMs Azure"
    echo ""

    check_prerequisites
    echo ""

    show_configuration
    echo ""

    initialize_terraform
    echo ""

    plan_deployment
    echo ""

    deploy_infrastructure
    echo ""

    save_outputs
    echo ""

    display_summary

    test_connectivity

    echo ""
    print_success "Script terminé"
}

# Exécuter le script principal
main "$@"
