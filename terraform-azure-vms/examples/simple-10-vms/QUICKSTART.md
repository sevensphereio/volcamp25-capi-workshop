# 🚀 Démarrage Ultra-Rapide - 10 VMs Azure

Déployez 10 VMs identiques en **5 minutes** avec 3 commandes !

## ⚡ Méthode automatique (RECOMMANDÉ)

```bash
cd terraform-azure-vms/examples/simple-10-vms

# 1. Personnalisez la configuration (optionnel)
nano terraform.tfvars

# 2. Déployez tout automatiquement
./deploy.sh
```

Le script `deploy.sh` fait **tout automatiquement** :
- ✅ Vérifie les prérequis
- ✅ Initialise Terraform
- ✅ Affiche le plan de déploiement
- ✅ Déploie l'infrastructure (3-5 min)
- ✅ Sauvegarde la clé SSH
- ✅ Crée l'inventaire des VMs
- ✅ Teste la connectivité

## 📋 Méthode manuelle

```bash
cd terraform-azure-vms/examples/simple-10-vms

# 1. Personnalisez (optionnel)
nano terraform.tfvars

# 2. Initialisez
terraform init

# 3. Déployez
terraform apply

# 4. Récupérez la clé SSH
terraform output -raw ssh_private_key > workshop_key.pem
chmod 600 workshop_key.pem

# 5. Connectez-vous
ssh -i workshop_key.pem azureuser@<IP>
```

## 🎛️ Personnalisation rapide (terraform.tfvars)

Ouvrez `terraform.tfvars` et modifiez :

```hcl
# Nombre de VMs (1-100)
vm_count = 10

# Nom des VMs: workshop-vm-01, workshop-vm-02, ...
vm_name_prefix = "workshop-vm"

# Taille des VMs
default_vm_size = "Standard_B2s"  # 2 vCPU, 4 GB RAM

# Taille du disque (GB)
default_os_disk_size_gb = 50

# Région Azure
location = "westeurope"
```

### Exemples de tailles de VMs

| Taille | vCPU | RAM | Prix/mois | Usage |
|--------|------|-----|-----------|-------|
| `Standard_B1s` | 1 | 1 GB | ~$10 | Dev/Test léger |
| `Standard_B2s` | 2 | 4 GB | ~$40 | Workshop/Dev |
| `Standard_D2s_v3` | 2 | 8 GB | ~$70 | Production légère |
| `Standard_D4s_v3` | 4 | 16 GB | ~$140 | Production |

### Exemples de régions

```hcl
location = "westeurope"      # Europe Ouest (Pays-Bas)
location = "francecentral"   # France Centrale (Paris)
location = "northeurope"     # Europe Nord (Irlande)
location = "eastus"          # USA Est (Virginie)
location = "eastus2"         # USA Est 2 (Virginie)
```

## 🗑️ Nettoyage

### Méthode automatique
```bash
./destroy.sh
```

### Méthode manuelle
```bash
terraform destroy
```

## 📊 Commandes utiles

```bash
# Voir toutes les IPs
terraform output vm_public_ips

# Voir les commandes SSH
terraform output vm_ssh_connections

# Voir le résumé
terraform output deployment_info

# Tester toutes les VMs
terraform output -json vm_public_ips | jq -r '.[]' | while read ip; do
  ssh -i workshop_key.pem azureuser@$ip "hostname"
done
```

## ⏱️ Temps estimés

- **Déploiement** : 3-5 minutes
- **Destruction** : 2-3 minutes
- **Initialisation** : 30 secondes

## 💰 Coûts estimés (24/7)

| Configuration | Coût/mois |
|---------------|-----------|
| 10 × Standard_B1s (1 vCPU, 1 GB) | ~$100 |
| 10 × Standard_B2s (2 vCPU, 4 GB) | ~$400 |
| 10 × Standard_D2s_v3 (2 vCPU, 8 GB) | ~$700 |

**💡 Astuce** : Arrêtez les VMs quand vous ne les utilisez pas pour économiser !

```bash
# Arrêter toutes les VMs (via Azure CLI)
az vm list -g workshop-dev-rg --query "[].name" -o tsv | xargs -I {} az vm stop -g workshop-dev-rg -n {}

# Redémarrer toutes les VMs
az vm list -g workshop-dev-rg --query "[].name" -o tsv | xargs -I {} az vm start -g workshop-dev-rg -n {}
```

## 🆘 Aide

**Documentation complète** : Voir [README.md](README.md)

**Problèmes courants** :
- `Error: Quota exceeded` → Réduire `vm_count` ou changer `default_vm_size`
- `Error: Region not available` → Changer `location` dans terraform.tfvars
- `SSH connection failed` → Attendre 1-2 min que les VMs démarrent complètement
