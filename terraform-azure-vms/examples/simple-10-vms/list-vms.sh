#!/bin/bash
# =============================================================================
# Script de listing des VMs déployées
# =============================================================================
# Affiche les informations de toutes les VMs de manière formatée
# =============================================================================

set -e

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_header() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

check_deployment() {
    cd "${SCRIPT_DIR}"

    if [ ! -f "terraform.tfstate" ]; then
        echo -e "${YELLOW}❌ Aucun déploiement trouvé${NC}"
        echo ""
        echo "Déployez d'abord l'infrastructure avec:"
        echo "  ./deploy.sh"
        echo "  ou: terraform apply"
        exit 1
    fi
}

show_summary() {
    print_header "Résumé du déploiement"

    cd "${SCRIPT_DIR}"

    echo ""
    terraform output deployment_info 2>/dev/null || echo "Informations non disponibles"
    echo ""
}

show_vms_table() {
    print_header "Liste des VMs"

    cd "${SCRIPT_DIR}"

    if ! command -v jq &> /dev/null; then
        echo "Installation de jq recommandée pour un meilleur affichage"
        echo ""
        terraform output vm_public_ips
        return
    fi

    echo ""
    printf "%-15s %-20s %-15s\n" "VM" "IP Publique" "Commande SSH"
    printf "%-15s %-20s %-15s\n" "───────────────" "────────────────────" "───────────────"

    terraform output -json vm_public_ips | jq -r 'to_entries[] | "\(.key)|\(.value)"' | while IFS='|' read vm_name vm_ip; do
        printf "%-15s %-20s ssh -i workshop_key.pem azureuser@%s\n" "${vm_name}" "${vm_ip}" "${vm_ip}"
    done

    echo ""
}

show_ssh_commands() {
    print_header "Commandes de connexion SSH"

    cd "${SCRIPT_DIR}"

    echo ""
    terraform output -json vm_ssh_connections 2>/dev/null | jq -r '.[]' || terraform output vm_ssh_connections
    echo ""
}

show_detailed_info() {
    print_header "Informations détaillées"

    cd "${SCRIPT_DIR}"

    echo ""
    print_info "Resource Group:"
    terraform output -json deployment_info 2>/dev/null | jq -r '.resource_group' || echo "N/A"

    echo ""
    print_info "Région:"
    terraform output -json deployment_info 2>/dev/null | jq -r '.location' || echo "N/A"

    echo ""
    print_info "Réseau virtuel:"
    terraform output -json deployment_info 2>/dev/null | jq -r '.vnet_name' || echo "N/A"

    echo ""
    print_info "Nombre de VMs:"
    terraform output -json deployment_info 2>/dev/null | jq -r '.vm_count' || echo "N/A"

    echo ""
}

export_inventory() {
    print_header "Export de l'inventaire"

    cd "${SCRIPT_DIR}"

    if ! command -v jq &> /dev/null; then
        echo "jq est requis pour l'export"
        return
    fi

    # Format texte
    terraform output -json vm_public_ips | jq -r 'to_entries[] | "\(.key): \(.value)"' > inventory.txt
    print_success "Inventaire texte créé: inventory.txt"

    # Format JSON
    terraform output -json vm_public_ips > inventory.json
    print_success "Inventaire JSON créé: inventory.json"

    # Format CSV
    echo "vm_name,public_ip,ssh_command" > inventory.csv
    terraform output -json vm_public_ips | jq -r 'to_entries[] | "\(.key),\(.value),ssh -i workshop_key.pem azureuser@\(.value)"' >> inventory.csv
    print_success "Inventaire CSV créé: inventory.csv"

    # Ansible inventory
    cat > ansible_inventory.ini <<EOF
[workshop_vms]
EOF
    terraform output -json vm_public_ips | jq -r 'to_entries[] | "\(.value) ansible_user=azureuser ansible_ssh_private_key_file=workshop_key.pem"' >> ansible_inventory.ini
    print_success "Inventaire Ansible créé: ansible_inventory.ini"

    echo ""
}

test_connectivity() {
    print_header "Test de connectivité SSH"

    cd "${SCRIPT_DIR}"

    if [ ! -f "workshop_key.pem" ]; then
        echo "Clé SSH non trouvée. Récupération..."
        terraform output -raw ssh_private_key > workshop_key.pem
        chmod 600 workshop_key.pem
    fi

    echo ""
    print_info "Test de connexion à chaque VM..."
    echo ""

    local success=0
    local failed=0

    terraform output -json vm_public_ips | jq -r 'to_entries[] | "\(.key) \(.value)"' | while read vm_name vm_ip; do
        printf "  %-15s (%s)... " "${vm_name}" "${vm_ip}"

        if timeout 10 ssh -i workshop_key.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 -o LogLevel=ERROR azureuser@${vm_ip} "hostname" &> /dev/null; then
            echo -e "${GREEN}✅ OK${NC}"
            ((success++)) || true
        else
            echo -e "${YELLOW}❌ FAILED${NC}"
            ((failed++)) || true
        fi
    done

    echo ""
}

show_costs() {
    print_header "Estimation des coûts"

    cd "${SCRIPT_DIR}"

    if [ ! -f "terraform.tfvars" ]; then
        echo "Fichier terraform.tfvars non trouvé"
        return
    fi

    echo ""

    local vm_count=$(grep "^vm_count" terraform.tfvars | awk '{print $3}')
    local vm_size=$(grep "^default_vm_size" terraform.tfvars | awk -F'"' '{print $2}')

    # Coût par taille de VM
    local cost_per_vm=40
    case "${vm_size}" in
        "Standard_B1s") cost_per_vm=10 ;;
        "Standard_B2s") cost_per_vm=40 ;;
        "Standard_D2s_v3") cost_per_vm=70 ;;
        "Standard_D4s_v3") cost_per_vm=140 ;;
    esac

    local total_monthly=$((cost_per_vm * vm_count))
    local daily_cost=$((total_monthly / 30))
    local hourly_cost=$(echo "scale=2; ${total_monthly} / 730" | bc 2>/dev/null || echo "N/A")

    echo "Configuration:"
    echo "  • ${vm_count} VMs × ${vm_size}"
    echo ""
    echo "Coûts estimés (si VMs allumées 24/7):"
    echo "  • Par VM:  ~\$${cost_per_vm}/mois"
    echo "  • Total:   ~\$${total_monthly}/mois"
    echo "  • Par jour: ~\$${daily_cost}/jour"
    echo "  • Par heure: ~\$${hourly_cost}/heure"
    echo ""
    echo -e "${YELLOW}💡 Astuce: Arrêtez les VMs quand non utilisées pour économiser${NC}"
    echo ""
}

show_menu() {
    clear

    print_header "Gestion des VMs déployées"

    echo ""
    echo "Que souhaitez-vous faire ?"
    echo ""
    echo "  1) Voir le résumé du déploiement"
    echo "  2) Lister toutes les VMs (tableau)"
    echo "  3) Voir les commandes SSH"
    echo "  4) Voir les informations détaillées"
    echo "  5) Exporter l'inventaire (TXT/JSON/CSV/Ansible)"
    echo "  6) Tester la connectivité SSH"
    echo "  7) Estimer les coûts"
    echo "  8) Tout afficher"
    echo "  9) Quitter"
    echo ""
    read -p "  Votre choix (1-9): " choice

    echo ""

    case "${choice}" in
        1) show_summary ;;
        2) show_vms_table ;;
        3) show_ssh_commands ;;
        4) show_detailed_info ;;
        5) export_inventory ;;
        6) test_connectivity ;;
        7) show_costs ;;
        8)
            show_summary
            show_vms_table
            show_ssh_commands
            show_detailed_info
            show_costs
            ;;
        9) exit 0 ;;
        *)
            echo "Choix invalide"
            return
            ;;
    esac

    echo ""
    read -p "Appuyez sur Entrée pour continuer..."
    show_menu
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    check_deployment

    if [ $# -eq 0 ]; then
        # Mode interactif
        show_menu
    else
        # Mode direct avec argument
        case "$1" in
            summary) show_summary ;;
            list) show_vms_table ;;
            ssh) show_ssh_commands ;;
            details) show_detailed_info ;;
            export) export_inventory ;;
            test) test_connectivity ;;
            costs) show_costs ;;
            all)
                show_summary
                show_vms_table
                show_ssh_commands
                show_costs
                ;;
            *)
                echo "Usage: $0 [summary|list|ssh|details|export|test|costs|all]"
                echo "Sans argument: mode interactif"
                exit 1
                ;;
        esac
    fi
}

main "$@"
