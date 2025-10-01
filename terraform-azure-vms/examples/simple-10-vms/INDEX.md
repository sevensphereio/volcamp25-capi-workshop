# 📑 Guide Complet - Déploiement Simplifié de VMs Azure

## 🎯 Vue d'ensemble

Ce module permet de déployer **1 à 100 VMs identiques** sur Azure en quelques minutes, avec personnalisation complète du nombre, nom, taille, disque et région.

## 📂 Fichiers disponibles

| Fichier | Description | Usage |
|---------|-------------|-------|
| **QUICKSTART.md** | Guide ultra-rapide (5 min) | 🚀 Commencez ici ! |
| **README.md** | Documentation complète | 📚 Référence détaillée |
| **INDEX.md** | Ce fichier - Vue d'ensemble | 🗺️ Navigation |
| `terraform.tfvars` | Configuration personnalisable | ✏️ Modifiez vos paramètres |
| `terraform.tfvars.examples` | 8 exemples de configurations | 💡 Inspirez-vous |
| `configure.sh` | Configuration interactive | 🎛️ Assistant pas-à-pas |
| `deploy.sh` | Déploiement automatisé | ⚡ Un clic pour déployer |
| `destroy.sh` | Destruction sécurisée | 🗑️ Nettoyage complet |
| `main.tf` | Module Terraform principal | 🔧 Code infrastructure |
| `versions.tf` | Versions Terraform/Provider | 📦 Dépendances |

## 🚀 3 Méthodes de déploiement

### Méthode 1 : Assistant interactif (RECOMMANDÉ pour débutants)

```bash
./configure.sh  # Configure via assistant
./deploy.sh     # Déploie automatiquement
```

**Avantages** : Guidé, pas d'erreur de syntaxe, calcul de coûts

### Méthode 2 : Configuration manuelle + déploiement automatisé

```bash
nano terraform.tfvars  # Éditez la configuration
./deploy.sh            # Déploie automatiquement
```

**Avantages** : Contrôle total, modifications rapides

### Méthode 3 : Terraform natif (pour experts)

```bash
nano terraform.tfvars
terraform init
terraform plan
terraform apply
```

**Avantages** : Contrôle complet, intégration CI/CD

## ⚙️ Paramètres configurables

### Paramètres principaux (terraform.tfvars)

```hcl
# NOMBRE DE VMs
vm_count = 10                    # 1-100 VMs

# NOMMAGE
vm_name_prefix = "workshop-vm"   # Préfixe: {prefix}-01, {prefix}-02, ...
project_name = "workshop"        # Nom du projet

# TAILLE DES VMs
default_vm_size = "Standard_B2s" # Voir tableau ci-dessous

# DISQUE
default_os_disk_size_gb = 50     # 30-4095 GB
default_os_disk_type = "Standard_LRS"  # HDD/SSD

# RÉGION
location = "westeurope"          # Voir liste ci-dessous

# SÉCURITÉ
allowed_ssh_cidrs = ["0.0.0.0/0"]  # IPs autorisées
```

### Tailles de VMs disponibles

| Taille | vCPU | RAM | Coût/VM/mois | Usage recommandé |
|--------|------|-----|--------------|------------------|
| `Standard_B1s` | 1 | 1 GB | ~$10 | Dev/Test léger |
| `Standard_B2s` | 2 | 4 GB | ~$40 | Workshop/Formation |
| `Standard_D2s_v3` | 2 | 8 GB | ~$70 | Production légère |
| `Standard_D4s_v3` | 4 | 16 GB | ~$140 | Production/Performance |
| `Standard_D8s_v3` | 8 | 32 GB | ~$280 | Haute performance |

### Régions Azure populaires

| Code | Localisation | Latence EU |
|------|--------------|------------|
| `westeurope` | Pays-Bas (Amsterdam) | Faible |
| `francecentral` | France (Paris) | Très faible |
| `northeurope` | Irlande (Dublin) | Faible |
| `germanywestcentral` | Allemagne (Francfort) | Faible |
| `uksouth` | UK (Londres) | Faible |
| `eastus` | USA Est (Virginie) | Moyenne |
| `eastus2` | USA Est 2 (Virginie) | Moyenne |

Liste complète : `az account list-locations -o table`

## 📊 Scénarios d'utilisation

### Scénario 1 : Workshop avec 10 participants (par défaut)

```bash
# terraform.tfvars
vm_count = 10
vm_name_prefix = "workshop-vm"
default_vm_size = "Standard_B2s"
```

**Coût** : ~$400/mois (24/7) ou ~$1/participant pour 2h

### Scénario 2 : Workshop économique (15 participants)

```bash
# terraform.tfvars
vm_count = 15
vm_name_prefix = "participant"
default_vm_size = "Standard_B1s"
```

**Coût** : ~$150/mois (24/7) ou ~$0.50/participant pour 2h

### Scénario 3 : Cluster Kubernetes (1 master + 3 workers)

```bash
# terraform.tfvars
vm_count = 4
vm_name_prefix = "k8s-node"
default_vm_size = "Standard_D2s_v3"
default_os_disk_size_gb = 80
```

**Coût** : ~$280/mois

### Scénario 4 : CI/CD Runners (8 runners)

```bash
# terraform.tfvars
vm_count = 8
vm_name_prefix = "runner"
default_vm_size = "Standard_B2s"
enable_public_ip = false  # Accès privé
```

**Coût** : ~$320/mois

Voir `terraform.tfvars.examples` pour 8 exemples complets

## 🔒 Sécurité

### Niveaux de sécurité SSH

**Niveau 1 - Ouvert (dev/workshop uniquement)**
```hcl
allowed_ssh_cidrs = ["0.0.0.0/0"]
```

**Niveau 2 - IP unique (recommandé pour test)**
```bash
MY_IP=$(curl -s ifconfig.me)
allowed_ssh_cidrs = ["${MY_IP}/32"]
```

**Niveau 3 - Réseau d'entreprise (production)**
```hcl
allowed_ssh_cidrs = ["203.0.113.0/24"]
```

**Niveau 4 - Sans IP publique (haute sécurité)**
```hcl
enable_public_ip = false
# Accès via Bastion Host ou VPN uniquement
```

## 💰 Gestion des coûts

### Estimation des coûts

| Configuration | Coût 24/7 | Coût 8h/jour | Coût 2h workshop |
|---------------|-----------|--------------|------------------|
| 10 × B1s | ~$100/mois | ~$33/mois | ~$0.50 |
| 10 × B2s | ~$400/mois | ~$133/mois | ~$2 |
| 10 × D2s_v3 | ~$700/mois | ~$233/mois | ~$3.50 |

### Réduire les coûts

**1. Arrêter les VMs quand non utilisées**
```bash
# Arrêter toutes les VMs
az vm list -g workshop-dev-rg --query "[].name" -o tsv | \
  xargs -I {} az vm stop -g workshop-dev-rg -n {}

# Démarrer toutes les VMs
az vm list -g workshop-dev-rg --query "[].name" -o tsv | \
  xargs -I {} az vm start -g workshop-dev-rg -n {}
```

**2. Auto-shutdown (via portail Azure)**
- Configure automatic shutdown at 19:00 every day
- Save ~70% if using only during business hours

**3. Détruire après usage**
```bash
./destroy.sh  # Supprime tout
```

## 📈 Workflow recommandé

### Pour workshops/formations

```bash
# Avant l'événement (J-1)
./configure.sh          # Configure interactivement
./deploy.sh            # Déploie (3-5 min)
# Distribuer les IPs aux participants

# Pendant l'événement
# Les VMs sont utilisées

# Après l'événement (même jour)
./destroy.sh           # Détruit tout
```

**Coût pour workshop 2h** : ~$2-5

### Pour développement continu

```bash
# Initialisation
nano terraform.tfvars
terraform init
terraform apply

# Modifications
nano terraform.tfvars
terraform plan
terraform apply

# Scaling
terraform apply -var="vm_count=15"  # Augmente de 10 à 15 VMs

# Nettoyage
terraform destroy
```

## 🧪 Tests et validation

### Tester la connectivité

```bash
# Via deploy.sh (automatique)
./deploy.sh  # Inclut le test de connectivité

# Manuellement
terraform output -json vm_public_ips | jq -r '.[]' | while read ip; do
  echo "Testing $ip..."
  ssh -i workshop_key.pem azureuser@$ip "hostname"
done
```

### Vérifier les ressources

```bash
# Liste des ressources Terraform
terraform state list

# Détails d'une ressource
terraform state show 'module.workshop_vms.azurerm_linux_virtual_machine.vm["vm-01"]'

# Ressources Azure via CLI
az resource list -g workshop-dev-rg -o table
```

## 🐛 Dépannage

### Problème : Quota de vCPUs dépassé

**Symptôme** :
```
Error: creating Linux Virtual Machine: compute.VirtualMachinesClient#CreateOrUpdate
Code="OperationNotAllowed" Message="Operation results in exceeding quota limits of Core"
```

**Solutions** :
1. Réduire `vm_count`
2. Choisir une taille plus petite (`Standard_B1s`)
3. Changer de région (`location`)
4. Demander augmentation de quota (portail Azure)

### Problème : Taille de VM non disponible dans la région

**Symptôme** :
```
Error: The requested VM size Standard_D4s_v3 is not available in region westeurope
```

**Solutions** :
1. Changer de région
2. Choisir une autre taille de VM
3. Vérifier disponibilité : `az vm list-skus --location westeurope --output table`

### Problème : Connexion SSH refuse

**Symptômes** :
- `Connection refused`
- `Connection timed out`

**Solutions** :
1. Attendre 1-2 minutes (VMs en cours de démarrage)
2. Vérifier `allowed_ssh_cidrs` inclut votre IP
3. Vérifier NSG : `az network nsg rule list -g workshop-dev-rg --nsg-name workshop-dev-nsg -o table`
4. Tester avec : `ssh -vvv -i workshop_key.pem azureuser@<IP>`

## 📚 Ressources supplémentaires

### Documentation

- [README.md](README.md) - Guide complet
- [QUICKSTART.md](QUICKSTART.md) - Démarrage rapide
- [terraform.tfvars.examples](terraform.tfvars.examples) - 8 exemples

### Outils

- [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/)
- [Azure Regions](https://azure.microsoft.com/global-infrastructure/geographies/)
- [VM Sizes Documentation](https://docs.microsoft.com/azure/virtual-machines/sizes)

### Scripts

```bash
./configure.sh  # Assistant de configuration
./deploy.sh     # Déploiement automatisé
./destroy.sh    # Destruction sécurisée
```

## ❓ FAQ

**Q: Puis-je déployer dans plusieurs régions simultanément ?**
R: Oui, mais nécessite plusieurs déploiements séparés avec différents `project_name`

**Q: Comment ajouter des VMs à un déploiement existant ?**
R: Augmentez `vm_count` dans `terraform.tfvars` puis `terraform apply`

**Q: Les VMs ont-elles des IPs fixes ?**
R: Par défaut non (Dynamic). Changez `public_ip_allocation_method = "Static"` dans main.tf

**Q: Puis-je utiliser mes propres clés SSH ?**
R: Oui, définissez `ssh_public_key` dans terraform.tfvars

**Q: Comment installer des logiciels au déploiement ?**
R: Utilisez cloud-init (voir exemple production dans le dossier parent)

**Q: Combien de temps prend le déploiement ?**
R: 3-5 minutes pour 10 VMs, proportionnel au nombre

## 🎯 Prochaines étapes

1. **Lire** : [QUICKSTART.md](QUICKSTART.md) (5 min)
2. **Configurer** : `./configure.sh` ou éditer `terraform.tfvars`
3. **Déployer** : `./deploy.sh`
4. **Utiliser** : Connectez-vous aux VMs
5. **Nettoyer** : `./destroy.sh`

---

**📞 Support** : Voir [README.md](README.md) pour troubleshooting détaillé
