# Azure Multi-VM Terraform Module

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.5.0-623CE4?logo=terraform)](https://www.terraform.io/)
[![Azure](https://img.shields.io/badge/Azure-Provider%203.x-0078D4?logo=microsoftazure)](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Un module Terraform production-ready pour déployer plusieurs machines virtuelles Azure en parallèle avec networking, sécurité et haute disponibilité.

## 📋 Table des Matières

- [Caractéristiques](#-caractéristiques)
- [Architecture](#-architecture)
- [Prérequis](#-prérequis)
- [Démarrage Rapide](#-démarrage-rapide)
- [Exemples](#-exemples)
- [Configuration](#-configuration)
- [Bonnes Pratiques](#-bonnes-pratiques)
- [Troubleshooting](#-troubleshooting)
- [Contribution](#-contribution)

## ✨ Caractéristiques

### Déploiement Parallèle
✅ Déploiement simultané de **1 à 100 VMs**
✅ Utilisation de `for_each` pour performance maximale
✅ Provisioning en **moins de 5 minutes** (petites VMs)

### Networking Complet
✅ Virtual Network (VNet) avec CIDR configurable
✅ Subnet avec gestion automatique
✅ Network Security Group (NSG) avec règles prédéfinies
✅ Public IPs optionnelles (static ou dynamic)
✅ Azure Load Balancer optionnel

### Sécurité Renforcée
✅ Génération automatique de clés SSH (ou BYO)
✅ NSG rules: SSH, HTTP, HTTPS, K8s API (6443), NodePorts
✅ Source IP filtering par CIDR
✅ System-assigned managed identities
✅ Règles NSG personnalisables

### Haute Disponibilité
✅ Support des Availability Zones
✅ Azure Load Balancer avec health probes
✅ Distribution multi-zones automatique
✅ Backend address pools

### Configuration Flexible
✅ VM sizes configurables par instance
✅ OS disk sizing (30-4095 GB)
✅ Data disks optionnels par VM
✅ Cloud-init / custom_data support
✅ Tags par VM ou globaux
✅ Boot diagnostics

### Production Ready
✅ Variables avec validation
✅ Outputs structurés et complets
✅ Remote state support (Azure Storage)
✅ Lifecycle management
✅ Naming conventions standards
✅ Idempotence garantie

## 🏗️ Architecture

### Ressources Créées

```
┌─────────────────────────────────────────────────────────────┐
│                    Azure Resource Group                     │
│                                                             │
│  ┌────────────────────────────────────────────────────┐    │
│  │              Virtual Network (VNet)                │    │
│  │                10.0.0.0/16                         │    │
│  │                                                    │    │
│  │  ┌──────────────────────────────────────────┐     │    │
│  │  │          Subnet (10.0.1.0/24)            │     │    │
│  │  │                                          │     │    │
│  │  │  ┌────────┐  ┌────────┐  ┌────────┐    │     │    │
│  │  │  │  VM 1  │  │  VM 2  │  │  VM 3  │    │     │    │
│  │  │  │  NIC   │  │  NIC   │  │  NIC   │    │     │    │
│  │  │  └───┬────┘  └───┬────┘  └───┬────┘    │     │    │
│  │  │      │           │           │          │     │    │
│  │  └──────┼───────────┼───────────┼──────────┘     │    │
│  │         │           │           │                │    │
│  └─────────┼───────────┼───────────┼────────────────┘    │
│            │           │           │                     │
│  ┌─────────┴───────────┴───────────┴────────────────┐    │
│  │         Network Security Group (NSG)             │    │
│  │  Rules: SSH, HTTP, HTTPS, K8s API, NodePorts    │    │
│  └──────────────────────────────────────────────────┘    │
│                                                           │
│  ┌──────────────────────────────────────────────────┐    │
│  │    Public IPs (optional per VM)                  │    │
│  │    Static or Dynamic allocation                  │    │
│  └──────────────────────────────────────────────────┘    │
│                                                           │
│  ┌──────────────────────────────────────────────────┐    │
│  │    Azure Load Balancer (optional)                │    │
│  │    Health Probes + Backend Pool                  │    │
│  └──────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

### Composants

| Ressource | Quantité | Description |
|-----------|----------|-------------|
| **Resource Group** | 1 | Conteneur logique pour toutes les ressources |
| **Virtual Network** | 1 | Réseau privé Azure (ex: 10.0.0.0/16) |
| **Subnet** | 1 | Sous-réseau pour les VMs (ex: 10.0.1.0/24) |
| **NSG** | 1 | Firewall avec règles de sécurité |
| **VMs** | 1-100 | Machines virtuelles Linux (Ubuntu 22.04 par défaut) |
| **NICs** | 1 par VM | Interface réseau par VM |
| **Public IPs** | 0-100 | IPs publiques optionnelles |
| **Managed Disks** | 1+ par VM | OS disk + data disks optionnels |
| **Load Balancer** | 0-1 | Répartiteur de charge optionnel |

## 📦 Prérequis

### Logiciels Requis

```bash
# Terraform >= 1.5.0
terraform version

# Azure CLI
az version

# Connexion Azure
az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

### Permissions Azure

Votre compte Azure doit avoir les permissions suivantes:
- `Microsoft.Compute/*` - Virtual Machines
- `Microsoft.Network/*` - Networking
- `Microsoft.Resources/*` - Resource Groups
- `Microsoft.Storage/*` - Storage (si remote state)

Rôle recommandé: **Contributor** sur la subscription ou le Resource Group

## 🚀 Démarrage Rapide

### 1. Cloner ou Copier le Module

```bash
cd workshop-express/terraform-azure-vms
```

### 2. Créer un Fichier de Configuration

Créez `terraform.tfvars`:

```hcl
project_name = "my-project"
environment  = "dev"
location     = "westeurope"

vm_instances = {
  vm1 = {
    name             = "app-server-01"
    size             = "Standard_B2s"
    enable_public_ip = true
    os_disk_size_gb  = 50
  }

  vm2 = {
    name             = "app-server-02"
    size             = "Standard_B2s"
    enable_public_ip = true
    os_disk_size_gb  = 50
  }
}
```

### 3. Déployer

```bash
# Initialiser Terraform
terraform init

# Planifier le déploiement
terraform plan

# Appliquer
terraform apply

# Récupérer les informations de connexion
terraform output ssh_connection_strings
terraform output ssh_private_key > ~/.ssh/azure_vms.pem
chmod 600 ~/.ssh/azure_vms.pem
```

### 4. Se Connecter aux VMs

```bash
# Obtenir les IPs publiques
terraform output vm_public_ips

# Se connecter
ssh -i ~/.ssh/azure_vms.pem azureuser@<PUBLIC_IP>
```

### 5. Détruire les Ressources

```bash
terraform destroy
```

## 📚 Exemples

### Exemple 1: Déploiement Basique (3 VMs)

**Use Case:** Environnement de développement simple

```bash
cd examples/basic
terraform init
terraform apply
```

**Ressources créées:**
- 3 VMs (Standard_B2s - 2 vCPUs, 4 GB RAM)
- 1 VNet + Subnet
- 1 NSG avec règles SSH/HTTP/HTTPS
- 3 Public IPs
- **Coût estimé:** ~€60/mois

**Configuration:**

```hcl
vm_instances = {
  vm1 = {
    name = "capi-mgmt-01"
    size = "Standard_B2s"
  }
  vm2 = {
    name = "capi-worker-01"
    size = "Standard_B2s"
  }
  vm3 = {
    name = "capi-worker-02"
    size = "Standard_B2s"
  }
}
```

### Exemple 2: Production avec Haute Disponibilité

**Use Case:** Environnement de production multi-zones avec Load Balancer

```bash
cd examples/production
terraform init
terraform apply
```

**Ressources créées:**
- 6 VMs réparties sur 3 Availability Zones
- 1 Management node (4 vCPUs, 16 GB RAM, Premium SSD)
- 5 Worker nodes (2 vCPUs, 8 GB RAM, Standard SSD)
- Azure Load Balancer (Standard SKU)
- Data disks additionnels (etcd, container storage)
- Cloud-init scripts automatiques
- **Coût estimé:** ~€400/mois

**Fonctionnalités:**
- ✅ Distribution multi-zones (1, 2, 3)
- ✅ Load Balancer avec health probes
- ✅ Premium storage pour management node
- ✅ Data disks pour données persistantes
- ✅ Cloud-init pour configuration automatique
- ✅ Monitoring et NSG rules avancées

### Exemple 3: Multi-Environnements avec Workspaces

**Use Case:** Gérer Dev, Staging, Prod avec une seule configuration

```bash
cd examples/multi-env

# Créer les workspaces
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Déployer Dev (2 VMs)
terraform workspace select dev
terraform apply

# Déployer Staging (3 VMs + LB)
terraform workspace select staging
terraform apply

# Déployer Prod (5 VMs + LB + Premium disks)
terraform workspace select prod
terraform apply
```

**Configuration dynamique par environnement:**

| Environnement | VMs | VM Size | Disk Type | Load Balancer | Coût/mois |
|---------------|-----|---------|-----------|---------------|-----------|
| **Dev** | 2 | B2s | Standard | ❌ | ~€40 |
| **Staging** | 3 | D2s_v3 | Standard SSD | ✅ | ~€200 |
| **Prod** | 5 | D4s_v3 | Premium | ✅ | ~€500 |

## ⚙️ Configuration

### Variables Principales

#### General Configuration

```hcl
variable "project_name" {
  description = "Nom du projet (utilisé pour le naming)"
  type        = string
}

variable "environment" {
  description = "Environnement (dev/staging/prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod"
  }
}

variable "location" {
  description = "Région Azure"
  type        = string
  default     = "westeurope"
}

variable "tags" {
  description = "Tags additionnels"
  type        = map(string)
  default     = {}
}
```

#### VM Configuration

```hcl
variable "vm_instances" {
  description = "Map des VMs à créer"
  type = map(object({
    name               = string           # Nom de la VM
    size               = string           # Taille (ex: Standard_B2s)
    zone               = optional(string) # Zone (1, 2, 3)
    admin_username     = optional(string) # Défaut: azureuser
    enable_public_ip   = optional(bool)   # Défaut: true
    os_disk_size_gb    = optional(number) # Défaut: 30 GB
    os_disk_type       = optional(string) # Défaut: Standard_LRS

    # Data disks optionnels
    data_disks = optional(list(object({
      name    = string
      size_gb = number
      lun     = number
      caching = optional(string)
    })))

    custom_data = optional(string) # Cloud-init script
    tags        = optional(map(string))
  }))
}
```

**Exemple VM avec data disk:**

```hcl
vm_instances = {
  database = {
    name             = "postgres-01"
    size             = "Standard_D4s_v3"
    zone             = "1"
    os_disk_size_gb  = 100
    os_disk_type     = "Premium_LRS"

    data_disks = [
      {
        name    = "postgres-data"
        size_gb = 500
        lun     = 0
        caching = "ReadWrite"
      },
      {
        name    = "postgres-logs"
        size_gb = 100
        lun     = 1
        caching = "None"
      }
    ]

    custom_data = file("cloud-init-postgres.yaml")
  }
}
```

#### Networking Configuration

```hcl
variable "vnet_address_space" {
  description = "CIDR du Virtual Network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefixes" {
  description = "CIDR du Subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "enable_public_ip" {
  description = "Activer les IPs publiques par défaut"
  type        = bool
  default     = true
}
```

#### Security Configuration

```hcl
variable "ssh_public_key" {
  description = "Clé SSH publique (si vide, auto-générée)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "allowed_ssh_cidrs" {
  description = "CIDRs autorisés pour SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # ⚠️ SÉCURISER EN PRODUCTION
}

variable "allowed_http_cidrs" {
  description = "CIDRs autorisés pour HTTP/HTTPS"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "additional_nsg_rules" {
  description = "Règles NSG additionnelles"
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  default = []
}
```

#### High Availability Configuration

```hcl
variable "enable_availability_zones" {
  description = "Activer les Availability Zones"
  type        = bool
  default     = false
}

variable "enable_load_balancer" {
  description = "Créer un Azure Load Balancer"
  type        = bool
  default     = false
}

variable "load_balancer_sku" {
  description = "SKU du Load Balancer (Basic/Standard)"
  type        = string
  default     = "Standard"
}
```

### Outputs

Le module expose de nombreux outputs:

```hcl
# Informations générales
output "resource_group_name"       # Nom du Resource Group
output "vnet_id"                   # ID du VNet
output "deployment_summary"        # Résumé du déploiement

# VMs
output "vm_ids"                    # Map: vm_key => VM ID
output "vm_names"                  # Liste des noms de VMs
output "vm_private_ips"            # Map: vm_name => Private IP
output "vm_public_ips"             # Map: vm_name => Public IP
output "vm_principal_ids"          # Map: vm_name => Managed Identity ID

# SSH
output "ssh_private_key"           # Clé privée générée (sensitive)
output "ssh_public_key"            # Clé publique
output "ssh_connection_strings"    # Commandes SSH prêtes à l'emploi

# Load Balancer
output "load_balancer_public_ip"   # IP publique du LB
output "load_balancer_id"          # ID du LB
```

**Utilisation des outputs:**

```bash
# Afficher les connection strings
terraform output ssh_connection_strings

# Sauvegarder la clé privée
terraform output -raw ssh_private_key > ~/.ssh/azure.pem
chmod 600 ~/.ssh/azure.pem

# Obtenir l'IP du Load Balancer
terraform output -raw load_balancer_public_ip

# JSON de toutes les IPs
terraform output -json vm_public_ips
```

### VM Sizes Recommandées

#### Développement

| Size | vCPUs | RAM | Prix/mois | Use Case |
|------|-------|-----|-----------|----------|
| **Standard_B1s** | 1 | 1 GB | ~€7 | Tests légers |
| **Standard_B2s** | 2 | 4 GB | ~€24 | Dev, small apps |
| **Standard_B2ms** | 2 | 8 GB | ~€48 | Dev, medium apps |

#### Production

| Size | vCPUs | RAM | Prix/mois | Use Case |
|------|-------|-----|-----------|----------|
| **Standard_D2s_v3** | 2 | 8 GB | ~€80 | Workers, web servers |
| **Standard_D4s_v3** | 4 | 16 GB | ~€160 | App servers, databases |
| **Standard_D8s_v3** | 8 | 32 GB | ~€320 | High performance |
| **Standard_E4s_v3** | 4 | 32 GB | ~€200 | Memory-intensive |

Prix indicatifs pour West Europe (pay-as-you-go). Utilisez [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) pour estimation précise.

## 🎯 Bonnes Pratiques

### 1. Sécurité

#### ✅ Restreindre l'accès SSH

```hcl
# ❌ NE PAS FAIRE (accès mondial)
allowed_ssh_cidrs = ["0.0.0.0/0"]

# ✅ FAIRE (accès restreint)
allowed_ssh_cidrs = [
  "203.0.113.0/24",  # VPN d'entreprise
  "198.51.100.5/32"  # IP personnelle
]
```

#### ✅ Utiliser SSH Key personnalisée

```hcl
# Générer une clé SSH
ssh-keygen -t rsa -b 4096 -f ~/.ssh/azure_workshop -N ""

# Utiliser dans Terraform
ssh_public_key = file("~/.ssh/azure_workshop.pub")
```

#### ✅ Tags de sécurité

```hcl
tags = {
  Environment = "production"
  Compliance  = "SOC2"
  DataClass   = "confidential"
  Backup      = "daily"
}
```

### 2. Remote State

#### Configuration Azure Storage Backend

```bash
# Créer le backend
az group create -n terraform-state-rg -l westeurope
az storage account create -n tfstateXXXXX -g terraform-state-rg -l westeurope --sku Standard_LRS
az storage container create -n tfstate --account-name tfstateXXXXX
```

**versions.tf:**

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstateXXXXX"
    container_name       = "tfstate"
    key                  = "workshop-vms.tfstate"
  }
}
```

### 3. Naming Conventions

Le module utilise des conventions de nommage standards:

```
{project_name}-{environment}-{resource_type}
```

**Exemples:**
- Resource Group: `capi-workshop-dev-rg`
- VNet: `capi-workshop-dev-vnet`
- Subnet: `capi-workshop-dev-subnet`
- NSG: `capi-workshop-dev-nsg`
- VM: `capi-mgmt-01` (custom name)
- NIC: `capi-mgmt-01-nic`
- Public IP: `capi-mgmt-01-pip`

### 4. Cost Optimization

#### Utiliser les VM Sizes appropriées

```hcl
# Dev: B-series (burstable, moins cher)
size = "Standard_B2s"

# Prod: D-series (performance constante)
size = "Standard_D2s_v3"
```

#### Optimiser les disks

```hcl
# Dev: Standard HDD
os_disk_type = "Standard_LRS"

# Staging: Standard SSD
os_disk_type = "StandardSSD_LRS"

# Prod: Premium SSD (seulement si nécessaire)
os_disk_type = "Premium_LRS"
```

#### Arrêter les VMs hors heures

```bash
# Deallocate VMs pour arrêter la facturation compute
az vm deallocate --ids $(terraform output -json vm_ids | jq -r '.[]')

# Redémarrer
az vm start --ids $(terraform output -json vm_ids | jq -r '.[]')
```

### 5. Haute Disponibilité

#### Distribuer sur plusieurs zones

```hcl
enable_availability_zones = true

vm_instances = {
  vm1 = { name = "app-01", zone = "1" }
  vm2 = { name = "app-02", zone = "2" }
  vm3 = { name = "app-03", zone = "3" }
}
```

#### Load Balancer pour failover

```hcl
enable_load_balancer = true
load_balancer_sku    = "Standard"  # Required for zones
```

### 6. Cloud-Init Scripts

#### Exemple: Installation Docker

**cloud-init-docker.yaml:**

```yaml
#cloud-config
package_update: true
package_upgrade: true

packages:
  - docker.io
  - kubectl

runcmd:
  - systemctl enable docker
  - systemctl start docker
  - usermod -aG docker azureuser

write_files:
  - path: /etc/docker/daemon.json
    content: |
      {
        "log-driver": "json-file",
        "log-opts": {
          "max-size": "10m",
          "max-file": "3"
        }
      }
```

**Utilisation:**

```hcl
vm_instances = {
  vm1 = {
    name        = "docker-host"
    size        = "Standard_B2s"
    custom_data = file("cloud-init-docker.yaml")
  }
}
```

## 🔧 Troubleshooting

### Erreur: "VM size not available"

**Symptôme:**
```
Error: creating Linux Virtual Machine: compute.VirtualMachinesClient#CreateOrUpdate:
The requested VM size Standard_B2s is not available in location westeurope
```

**Solution:**

```bash
# Vérifier les tailles disponibles
az vm list-sizes --location westeurope --output table

# Ou vérifier une taille spécifique
az vm list-skus --location westeurope --size Standard_B2s --all
```

### Erreur: "Quota exceeded"

**Symptôme:**
```
Error: creating Linux Virtual Machine: compute.VirtualMachinesClient#CreateOrUpdate:
Operation could not be completed as it results in exceeding approved Standard cores quota
```

**Solution:**

```bash
# Vérifier les quotas
az vm list-usage --location westeurope --output table

# Demander une augmentation de quota
# Azure Portal > Subscriptions > Usage + quotas
```

### Erreur: "SSH connection refused"

**Symptôme:**
```bash
$ ssh azureuser@20.103.45.67
ssh: connect to host 20.103.45.67 port 22: Connection refused
```

**Solutions:**

1. **Vérifier que la VM est démarrée:**

```bash
az vm show -g $(terraform output -raw resource_group_name) -n vm-name --query "powerState"
```

2. **Vérifier le NSG:**

```bash
# Lister les règles NSG
az network nsg rule list -g $(terraform output -raw resource_group_name) --nsg-name $(terraform output -raw nsg_id | awk -F/ '{print $NF}') --output table

# Vérifier si votre IP est autorisée
curl -s ifconfig.me
```

3. **Vérifier les Serial Console logs:**

```bash
az vm boot-diagnostics get-boot-log -g RG_NAME -n VM_NAME
```

### VMs créées mais pas accessible

**Vérifier l'état:**

```bash
# Via Terraform
terraform state list | grep azurerm_linux_virtual_machine

# Via Azure CLI
az vm list -g $(terraform output -raw resource_group_name) --query "[].{Name:name, State:provisioningState, PowerState:powerState}" --output table
```

**Obtenir les logs cloud-init:**

```bash
# Se connecter à la VM
ssh azureuser@<IP>

# Vérifier les logs cloud-init
sudo cloud-init status --long
sudo cat /var/log/cloud-init-output.log
```

### Erreur: "Public IP not allocated"

**Symptôme:**
```
terraform output vm_public_ips
{
  "vm1": null,
  "vm2": null
}
```

**Causes:**

1. **Public IP désactivée:**

```hcl
# Vérifier dans vm_instances
enable_public_ip = true  # Doit être true
```

2. **Allocation Dynamic pas encore assignée:**

```hcl
# Utiliser Static allocation
public_ip_allocation_method = "Static"
```

3. **Attendre quelques secondes:**

```bash
# Rafraîchir Terraform
terraform refresh
terraform output vm_public_ips
```

### Validation du Déploiement

**Script de validation complète:**

```bash
#!/bin/bash
# validate-deployment.sh

echo "🔍 Validation du déploiement Terraform..."

# 1. Vérifier Terraform state
echo "✓ Checking Terraform state..."
terraform state list | grep azurerm_linux_virtual_machine || exit 1

# 2. Vérifier Resource Group
RG=$(terraform output -raw resource_group_name)
echo "✓ Resource Group: $RG"
az group show -n $RG || exit 1

# 3. Vérifier VMs
echo "✓ Checking VMs..."
az vm list -g $RG --query "[].{Name:name, State:provisioningState}" -o table

# 4. Tester SSH sur chaque VM
echo "✓ Testing SSH connectivity..."
terraform output -json vm_public_ips | jq -r '.[]' | while read IP; do
  if [ "$IP" != "null" ]; then
    echo "  Testing $IP..."
    ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no azureuser@$IP "echo SSH OK" || echo "  ⚠️  SSH failed for $IP"
  fi
done

echo "✅ Validation completed!"
```

**Utilisation:**

```bash
chmod +x validate-deployment.sh
./validate-deployment.sh
```

## 📊 Monitoring et Logs

### Boot Diagnostics

Les boot diagnostics sont activés par défaut (`enable_boot_diagnostics = true`).

**Consulter les logs:**

```bash
# Serial console output
az vm boot-diagnostics get-boot-log \
  -g $(terraform output -raw resource_group_name) \
  -n VM_NAME

# Screenshot de la console
az vm boot-diagnostics get-boot-log-uris \
  -g $(terraform output -raw resource_group_name) \
  -n VM_NAME
```

### Métriques VM

```bash
# CPU usage (dernière heure)
az monitor metrics list \
  --resource $(terraform output -json vm_ids | jq -r '.vm1') \
  --metric "Percentage CPU" \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --interval PT5M \
  --output table

# Network In/Out
az monitor metrics list \
  --resource $(terraform output -json vm_ids | jq -r '.vm1') \
  --metric "Network In Total" \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --interval PT5M \
  --output table
```

## 🚀 Roadmap / Améliorations Futures

- [ ] Support pour Windows VMs
- [ ] Application Security Groups (ASG)
- [ ] Azure Bastion integration
- [ ] VM Scale Sets support
- [ ] Azure Monitor Agents déploiement automatique
- [ ] Backup policies automatiques
- [ ] Spot Instances support
- [ ] Custom images (Packer)

## 🤝 Contribution

Les contributions sont les bienvenues!

1. Fork le projet
2. Créer une branche (`git checkout -b feature/amazing-feature`)
3. Commit les changements (`git commit -m 'Add amazing feature'`)
4. Push vers la branche (`git push origin feature/amazing-feature`)
5. Ouvrir une Pull Request

## 📄 Licence

MIT License - voir le fichier [LICENSE](LICENSE) pour plus de détails.

## 🙏 Remerciements

Créé pour le **CAPI Workshop** par l'équipe Virtual Development Team:
- @Cloud-Architect - Architecture et conception
- @DevOps-Engineer - Implémentation Terraform
- @Technical-Writer - Documentation

## 📞 Support

- **Issues:** [GitHub Issues](https://github.com/your-repo/issues)
- **Discussions:** [GitHub Discussions](https://github.com/your-repo/discussions)
- **Email:** support@example.com

---

**Prêt à déployer?** 🚀

```bash
cd terraform-azure-vms
terraform init
terraform plan
terraform apply
```