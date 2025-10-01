#!/bin/bash
# =============================================================================
# Configuration interactive pour le déploiement de VMs Azure
# =============================================================================
# Ce script aide à générer un fichier terraform.tfvars personnalisé
# =============================================================================

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TFVARS_FILE="${SCRIPT_DIR}/terraform.tfvars"

# =============================================================================
# FONCTIONS UTILITAIRES
# =============================================================================

print_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"

    echo -e "${CYAN}${prompt}${NC}"
    echo -e "${YELLOW}  [Défaut: ${default}]${NC}"
    read -p "  > " input
    eval "${var_name}='${input:-$default}'"
}

# =============================================================================
# CONFIGURATION
# =============================================================================

configure_basic() {
    print_header "1/6 - Configuration de base"

    print_info "Combien de VMs souhaitez-vous déployer ?"
    echo "  Exemples:"
    echo "    - Workshop 10 personnes: 10"
    echo "    - Workshop 15 personnes: 15"
    echo "    - Cluster K8s (1 master + 3 workers): 4"
    prompt_with_default "Nombre de VMs (1-100)" "10" "VM_COUNT"

    print_info "Quel préfixe pour les noms de VMs ?"
    echo "  Les VMs seront nommées: {préfixe}-01, {préfixe}-02, etc."
    echo "  Exemples: workshop-vm, participant, k8s-node, test"
    prompt_with_default "Préfixe des noms" "workshop-vm" "VM_PREFIX"

    print_info "Nom du projet (pour les tags et le resource group)"
    prompt_with_default "Nom du projet" "workshop" "PROJECT_NAME"
}

configure_vm_size() {
    print_header "2/6 - Taille des VMs"

    echo "Choisissez la taille des VMs :"
    echo ""
    echo "  1) Standard_B1s    : 1 vCPU,  1 GB RAM  (~\$10/mois)  - Économique"
    echo "  2) Standard_B2s    : 2 vCPU,  4 GB RAM  (~\$40/mois)  - Équilibré (recommandé)"
    echo "  3) Standard_D2s_v3 : 2 vCPU,  8 GB RAM  (~\$70/mois)  - Performant"
    echo "  4) Standard_D4s_v3 : 4 vCPU, 16 GB RAM  (~\$140/mois) - Haute performance"
    echo "  5) Autre (saisir manuellement)"
    echo ""
    read -p "  Votre choix (1-5) [2]: " size_choice

    case "${size_choice:-2}" in
        1) VM_SIZE="Standard_B1s" ;;
        2) VM_SIZE="Standard_B2s" ;;
        3) VM_SIZE="Standard_D2s_v3" ;;
        4) VM_SIZE="Standard_D4s_v3" ;;
        5)
            read -p "  Saisissez la taille de VM: " VM_SIZE
            ;;
        *) VM_SIZE="Standard_B2s" ;;
    esac

    print_success "Taille sélectionnée: ${VM_SIZE}"
}

configure_disk() {
    print_header "3/6 - Configuration du disque"

    print_info "Taille du disque OS (minimum 30 GB)"
    echo "  Exemples:"
    echo "    - Léger: 30-40 GB"
    echo "    - Standard: 50 GB"
    echo "    - Large: 100+ GB"
    prompt_with_default "Taille du disque (GB)" "50" "DISK_SIZE"

    echo ""
    echo "Type de disque :"
    echo ""
    echo "  1) Standard_LRS    : HDD Standard  (~\$5/100GB/mois)  - Économique"
    echo "  2) StandardSSD_LRS : SSD Standard  (~\$10/100GB/mois) - Équilibré (recommandé)"
    echo "  3) Premium_LRS     : SSD Premium   (~\$20/100GB/mois) - Performant"
    echo ""
    read -p "  Votre choix (1-3) [1]: " disk_choice

    case "${disk_choice:-1}" in
        1) DISK_TYPE="Standard_LRS" ;;
        2) DISK_TYPE="StandardSSD_LRS" ;;
        3) DISK_TYPE="Premium_LRS" ;;
        *) DISK_TYPE="Standard_LRS" ;;
    esac

    print_success "Disque: ${DISK_SIZE} GB, Type: ${DISK_TYPE}"
}

configure_location() {
    print_header "4/6 - Région Azure"

    echo "Choisissez la région Azure :"
    echo ""
    echo "  Europe:"
    echo "    1) westeurope        - Pays-Bas (Amsterdam)"
    echo "    2) francecentral     - France (Paris)"
    echo "    3) northeurope       - Irlande (Dublin)"
    echo "    4) germanywestcentral- Allemagne (Francfort)"
    echo "    5) uksouth           - UK (Londres)"
    echo ""
    echo "  Amérique:"
    echo "    6) eastus            - USA Est (Virginie)"
    echo "    7) eastus2           - USA Est 2 (Virginie)"
    echo "    8) westus            - USA Ouest (Californie)"
    echo ""
    echo "  Asie/Pacifique:"
    echo "    9) southeastasia     - Singapour"
    echo "    10) australiaeast    - Australie (Sydney)"
    echo ""
    echo "  11) Autre (saisir manuellement)"
    echo ""
    read -p "  Votre choix (1-11) [1]: " location_choice

    case "${location_choice:-1}" in
        1) LOCATION="westeurope" ;;
        2) LOCATION="francecentral" ;;
        3) LOCATION="northeurope" ;;
        4) LOCATION="germanywestcentral" ;;
        5) LOCATION="uksouth" ;;
        6) LOCATION="eastus" ;;
        7) LOCATION="eastus2" ;;
        8) LOCATION="westus" ;;
        9) LOCATION="southeastasia" ;;
        10) LOCATION="australiaeast" ;;
        11)
            read -p "  Saisissez le code de la région: " LOCATION
            ;;
        *) LOCATION="westeurope" ;;
    esac

    print_success "Région sélectionnée: ${LOCATION}"
}

configure_security() {
    print_header "5/6 - Sécurité SSH"

    print_warning "Configuration de l'accès SSH"
    echo ""
    echo "  ⚠️  IMPORTANT: Restreindre l'accès SSH améliore la sécurité"
    echo ""
    echo "  1) Accès depuis n'importe où (0.0.0.0/0)"
    echo "     → Pratique pour workshops/démos"
    echo "     → ⚠️  Moins sécurisé"
    echo ""
    echo "  2) Accès depuis mon IP uniquement"
    echo "     → Plus sécurisé"
    echo "     → Nécessite de connaître votre IP publique"
    echo ""
    echo "  3) Accès depuis un réseau spécifique"
    echo "     → Pour entreprises (ex: 203.0.113.0/24)"
    echo ""
    read -p "  Votre choix (1-3) [1]: " security_choice

    case "${security_choice:-1}" in
        1)
            SSH_CIDRS='["0.0.0.0/0"]'
            print_warning "Accès SSH autorisé depuis n'importe où"
            ;;
        2)
            print_info "Récupération de votre IP publique..."
            MY_IP=$(curl -s ifconfig.me || curl -s icanhazip.com || echo "unknown")
            if [ "${MY_IP}" = "unknown" ]; then
                print_warning "Impossible de détecter votre IP"
                read -p "  Saisissez votre IP publique: " MY_IP
            else
                print_success "IP détectée: ${MY_IP}"
            fi
            SSH_CIDRS="[\"${MY_IP}/32\"]"
            ;;
        3)
            read -p "  Saisissez le CIDR du réseau (ex: 203.0.113.0/24): " CUSTOM_CIDR
            SSH_CIDRS="[\"${CUSTOM_CIDR}\"]"
            ;;
        *)
            SSH_CIDRS='["0.0.0.0/0"]'
            ;;
    esac
}

configure_tags() {
    print_header "6/6 - Tags personnalisés (optionnel)"

    print_info "Ajoutez des tags pour l'organisation (appuyez sur Entrée pour ignorer)"
    echo ""

    read -p "  Workshop/Formation: " TAG_WORKSHOP
    read -p "  Équipe/Département: " TAG_TEAM
    read -p "  Durée (ex: 2-hours): " TAG_DURATION
    read -p "  Budget/CostCenter: " TAG_COST

    TAGS="{"
    [ -n "${TAG_WORKSHOP}" ] && TAGS="${TAGS}\n  Workshop     = \"${TAG_WORKSHOP}\""
    [ -n "${TAG_TEAM}" ] && TAGS="${TAGS}\n  Team         = \"${TAG_TEAM}\""
    [ -n "${TAG_DURATION}" ] && TAGS="${TAGS}\n  Duration     = \"${TAG_DURATION}\""
    [ -n "${TAG_COST}" ] && TAGS="${TAGS}\n  CostCenter   = \"${TAG_COST}\""
    TAGS="${TAGS}\n  CreatedBy    = \"configure-script\""
    TAGS="${TAGS}\n}"
}

generate_tfvars() {
    print_header "Génération du fichier terraform.tfvars"

    # Backup si le fichier existe
    if [ -f "${TFVARS_FILE}" ]; then
        local backup_file="${TFVARS_FILE}.backup-$(date +%Y%m%d-%H%M%S)"
        cp "${TFVARS_FILE}" "${backup_file}"
        print_warning "Ancien fichier sauvegardé: ${backup_file}"
    fi

    # Calculer les coûts estimés
    local cost_per_vm=40
    case "${VM_SIZE}" in
        "Standard_B1s") cost_per_vm=10 ;;
        "Standard_B2s") cost_per_vm=40 ;;
        "Standard_D2s_v3") cost_per_vm=70 ;;
        "Standard_D4s_v3") cost_per_vm=140 ;;
    esac
    local total_cost=$((cost_per_vm * VM_COUNT))

    # Générer le fichier
    cat > "${TFVARS_FILE}" <<EOF
# =============================================================================
# CONFIGURATION TERRAFORM - Générée automatiquement
# =============================================================================
# Généré le: $(date)
# Coût estimé: ~\$${total_cost}/mois (24/7) ou ~\$${total_cost}/30/jour
# =============================================================================

# Nombre et nommage des VMs
vm_count       = ${VM_COUNT}
vm_name_prefix = "${VM_PREFIX}"

# Taille et configuration
default_vm_size         = "${VM_SIZE}"
default_os_disk_size_gb = ${DISK_SIZE}
default_os_disk_type    = "${DISK_TYPE}"

# Région Azure
location = "${LOCATION}"

# Projet
project_name = "${PROJECT_NAME}"
environment  = "dev"

# Sécurité
allowed_ssh_cidrs = ${SSH_CIDRS}

# Tags
tags = ${TAGS}
EOF

    print_success "Fichier terraform.tfvars créé avec succès !"
}

display_summary() {
    print_header "Résumé de la configuration"

    echo ""
    echo -e "${GREEN}Configuration créée avec succès !${NC}"
    echo ""
    echo -e "${BLUE}Paramètres:${NC}"
    echo "  • VMs: ${VM_COUNT} × ${VM_SIZE}"
    echo "  • Noms: ${VM_PREFIX}-01 à ${VM_PREFIX}-$(printf "%02d" ${VM_COUNT})"
    echo "  • Disque: ${DISK_SIZE} GB (${DISK_TYPE})"
    echo "  • Région: ${LOCATION}"
    echo "  • Projet: ${PROJECT_NAME}"
    echo ""

    # Calculer le coût
    local cost_per_vm=40
    case "${VM_SIZE}" in
        "Standard_B1s") cost_per_vm=10 ;;
        "Standard_B2s") cost_per_vm=40 ;;
        "Standard_D2s_v3") cost_per_vm=70 ;;
        "Standard_D4s_v3") cost_per_vm=140 ;;
    esac
    local total_cost=$((cost_per_vm * VM_COUNT))
    local daily_cost=$((total_cost / 30))

    echo -e "${YELLOW}Coûts estimés:${NC}"
    echo "  • \$${cost_per_vm}/mois par VM"
    echo "  • \$${total_cost}/mois total (24/7)"
    echo "  • \$${daily_cost}/jour approximatif"
    echo ""

    print_info "Fichier créé: ${TFVARS_FILE}"
    echo ""
    echo -e "${BLUE}Prochaines étapes:${NC}"
    echo ""
    echo "  1. Vérifier la configuration:"
    echo "     cat terraform.tfvars"
    echo ""
    echo "  2. Déployer l'infrastructure:"
    echo "     ./deploy.sh"
    echo ""
    echo "  3. Ou manuellement:"
    echo "     terraform init"
    echo "     terraform apply"
    echo ""
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    clear

    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                           ║${NC}"
    echo -e "${GREEN}║     Configuration Interactive - Déploiement Azure VMs     ║${NC}"
    echo -e "${GREEN}║                                                           ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    print_info "Ce script va générer un fichier terraform.tfvars personnalisé"
    echo ""
    read -p "Appuyez sur Entrée pour continuer..."

    configure_basic
    configure_vm_size
    configure_disk
    configure_location
    configure_security
    configure_tags

    generate_tfvars
    display_summary

    echo ""
    print_success "Configuration terminée !"
    echo ""
}

# Exécuter le script
main "$@"
