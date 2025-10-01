# Déploiement Simple de 10 VMs Identiques

Cet exemple montre comment déployer rapidement **10 VMs identiques** sur Azure avec un minimum de configuration, parfait pour des environnements de workshop ou de test.

## 🎯 Cas d'usage

- **Workshops/Formations** : VMs identiques pour chaque participant
- **Environnements de test** : Clusters de développement rapides
- **Labs temporaires** : Infrastructure éphémère pour expérimentation

## 🚀 Démarrage rapide

### 1. Authentification Azure

```bash
# Option 1: Azure CLI (recommandé pour développement local)
az login
az account set --subscription "votre-subscription-id"

# Option 2: Service Principal (recommandé pour CI/CD)
export ARM_CLIENT_ID="xxx"
export ARM_CLIENT_SECRET="xxx"
export ARM_TENANT_ID="xxx"
export ARM_SUBSCRIPTION_ID="xxx"
```

### 2. Configuration (NOUVEAU !)

**Méthode simple** : Éditez le fichier `terraform.tfvars` pour personnaliser votre déploiement :

```bash
cd terraform-azure-vms/examples/simple-10-vms

# Ouvrir le fichier de configuration
nano terraform.tfvars

# Modifiez les valeurs selon vos besoins:
# - vm_count              : Nombre de VMs (1-100)
# - vm_name_prefix        : Préfixe des noms
# - default_vm_size       : Taille des VMs
# - default_os_disk_size_gb : Taille du disque
# - location              : Région Azure
```

### 3. Déploiement

```bash
# Initialiser
terraform init

# Prévisualiser les changements
terraform plan

# Déployer (temps estimé: 3-5 minutes)
terraform apply
```

### 4. Connexion aux VMs

```bash
# Obtenir les informations de connexion
terraform output vm_ssh_connections

# Sauvegarder la clé privée SSH
terraform output -raw ssh_private_key > workshop_key.pem
chmod 600 workshop_key.pem

# Se connecter à une VM
ssh -i workshop_key.pem azureuser@<ip-publique>
```

### 5. Nettoyage

```bash
terraform destroy
```

## 📋 Configuration

### Configuration par défaut (terraform.tfvars)

Le fichier `terraform.tfvars` contient tous les paramètres modifiables :

| Paramètre | Valeur par défaut | Description |
|-----------|-------------------|-------------|
| `vm_count` | 10 | Nombre de VMs (1-100) |
| `vm_name_prefix` | `workshop-vm` | Préfixe des noms (`workshop-vm-01`, ...) |
| `default_vm_size` | `Standard_B2s` | Taille VM (2 vCPU, 4 GB RAM) |
| `default_os_disk_size_gb` | 50 | Taille du disque OS (GB) |
| `default_os_disk_type` | `Standard_LRS` | Type de disque (HDD/SSD) |
| `location` | `westeurope` | Région Azure |
| `allowed_ssh_cidrs` | `["0.0.0.0/0"]` | IPs autorisées pour SSH |

### 🎛️ Personnalisation rapide

Toutes les modifications se font dans **`terraform.tfvars`** :

#### Changer le nombre de VMs

```hcl
vm_count = 15  # 15 VMs au lieu de 10
```

#### Changer la région

```hcl
location = "francecentral"  # Ou: eastus, northeurope, etc.
```

#### Changer la taille des VMs

```hcl
default_vm_size = "Standard_D2s_v3"  # 2 vCPU, 8 GB RAM

# Autres options populaires:
# Standard_B1s    : 1 vCPU, 1 GB   (~$10/mois)  - Économique
# Standard_B2s    : 2 vCPU, 4 GB   (~$40/mois)  - Équilibré
# Standard_D2s_v3 : 2 vCPU, 8 GB   (~$70/mois)  - Performant
# Standard_D4s_v3 : 4 vCPU, 16 GB  (~$140/mois) - Haute performance
```

#### Changer la taille du disque

```hcl
default_os_disk_size_gb = 100  # 100 GB au lieu de 50 GB

default_os_disk_type = "Premium_LRS"  # SSD Premium
# Options:
# - Standard_LRS    : HDD Standard    (~$5/100GB/mois)
# - StandardSSD_LRS : SSD Standard    (~$10/100GB/mois)
# - Premium_LRS     : SSD Premium     (~$20/100GB/mois)
```

#### Changer le préfixe des noms

```hcl
vm_name_prefix = "participant"  # Génère: participant-01, participant-02, ...
```

#### Restreindre l'accès SSH (RECOMMANDÉ pour production)

```hcl
allowed_ssh_cidrs = ["203.0.113.0/24"]  # IP de votre entreprise
# Ou pour une seule IP:
# allowed_ssh_cidrs = ["203.0.113.10/32"]
```

## 📊 Ressources créées

Le déploiement crée automatiquement :

- ✅ **1 Resource Group** : `workshop-dev-rg`
- ✅ **1 Virtual Network** : `workshop-dev-vnet` (10.0.0.0/16)
- ✅ **1 Subnet** : `workshop-dev-subnet` (10.0.1.0/24)
- ✅ **1 Network Security Group** : Règles SSH (22), HTTP (80), HTTPS (443)
- ✅ **10 Virtual Machines** : `workshop-vm-01` à `workshop-vm-10`
- ✅ **10 Network Interfaces** : Une par VM
- ✅ **10 Public IPs** : Une par VM (dynamiques)
- ✅ **10 OS Disks** : Disques système managés
- ✅ **1 SSH Key Pair** : Généré automatiquement

**Total estimé** : ~€100-150/mois si les VMs tournent 24/7

## 🌍 Régions Azure disponibles

Liste des régions populaires pour le déploiement :

| Région | Code | Localisation |
|--------|------|--------------|
| Europe Ouest | `westeurope` | Pays-Bas (Amsterdam) |
| France Centrale | `francecentral` | France (Paris) |
| Europe Nord | `northeurope` | Irlande (Dublin) |
| USA Est | `eastus` | USA (Virginie) |
| USA Est 2 | `eastus2` | USA (Virginie) |
| USA Ouest | `westus` | USA (Californie) |
| UK Sud | `uksouth` | UK (Londres) |
| Allemagne Ouest Centre | `germanywestcentral` | Allemagne (Francfort) |
| Asie Sud-Est | `southeastasia` | Singapour |
| Australie Est | `australiaeast` | Australie (Sydney) |

**Comment changer la région** : Modifiez `location = "westeurope"` dans `terraform.tfvars`

**Note** : Certaines tailles de VM ne sont pas disponibles dans toutes les régions. En cas d'erreur, choisissez une autre région ou une autre taille de VM.

## 💡 Astuces

### Déploiement rapide sans prompts

```bash
terraform apply -auto-approve
```

### Obtenir uniquement les IPs

```bash
terraform output -json vm_public_ips | jq
```

### Générer un fichier d'inventaire Ansible

```bash
terraform output -json vm_public_ips | jq -r 'to_entries[] | .value' > inventory.txt
```

### Tester la connectivité SSH sur toutes les VMs

```bash
terraform output -json vm_public_ips | jq -r 'to_entries[] | .value' | while read ip; do
  echo "Testing $ip..."
  ssh -i workshop_key.pem -o StrictHostKeyChecking=no azureuser@$ip "hostname"
done
```

### Exécuter une commande sur toutes les VMs

```bash
# Installer Docker sur toutes les VMs
terraform output -json vm_public_ips | jq -r 'to_entries[] | .value' | xargs -I {} \
  ssh -i workshop_key.pem azureuser@{} "sudo apt update && sudo apt install -y docker.io"
```

## 🔧 Dépannage

### Problème : Quota de vCPUs dépassé

```
Error: creating Linux Virtual Machine: compute.VirtualMachinesClient#CreateOrUpdate
```

**Solution** : Demandez une augmentation de quota Azure ou utilisez des VMs plus petites (`Standard_B1s`)

### Problème : Région non supportée

**Solution** : Changez la région dans `main.tf` :
```hcl
location = "eastus"  # ou francecentral, northeurope, etc.
```

### Problème : Clé SSH non trouvée

**Solution** : Régénérez la clé :
```bash
terraform output -raw ssh_private_key > workshop_key.pem
chmod 600 workshop_key.pem
```

## 📚 Pour aller plus loin

### Mode avancé avec configuration par VM

Si vous avez besoin de VMs avec des configurations différentes, utilisez `vm_instances` au lieu de `vm_count` :

```hcl
module "workshop_vms" {
  source = "../.."

  vm_instances = {
    "master" = {
      name    = "k8s-master"
      size    = "Standard_D2s_v3"
      os_disk_size_gb = 100
    }
    "worker-1" = {
      name    = "k8s-worker-1"
      size    = "Standard_B2s"
      os_disk_size_gb = 50
    }
    "worker-2" = {
      name    = "k8s-worker-2"
      size    = "Standard_B2s"
      os_disk_size_gb = 50
    }
  }
}
```

Voir l'exemple `production` pour plus de détails.

## 🔗 Ressources

- [Documentation du module parent](../../README.md)
- [Exemple Basic](../basic/)
- [Exemple Production](../production/)
- [Tailles de VMs Azure](https://learn.microsoft.com/azure/virtual-machines/sizes)
- [Pricing Calculator](https://azure.microsoft.com/pricing/calculator/)
