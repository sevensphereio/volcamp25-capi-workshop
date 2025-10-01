# 🎯 COMMENCEZ ICI !

Bienvenue dans le module de déploiement simplifié de VMs Azure.

## 📚 Quel fichier lire ?

Choisissez selon votre besoin :

### 🚀 Je veux déployer MAINTENANT (5 minutes)
👉 Lisez **[QUICKSTART.md](QUICKSTART.md)**

### 📖 Je veux comprendre toutes les options
👉 Lisez **[README.md](README.md)**

### 🗺️ Je veux une vue d'ensemble complète
👉 Lisez **[INDEX.md](INDEX.md)**

### 🎬 Je prépare une démonstration
👉 Lisez **[DEMO.md](DEMO.md)**

### 💡 Je veux voir des exemples de configurations
👉 Lisez **[terraform.tfvars.examples](terraform.tfvars.examples)**

## ⚡ Déploiement ultra-rapide (3 commandes)

```bash
# 1. Configuration (optionnel)
./configure.sh  # OU: nano terraform.tfvars

# 2. Déploiement (3-5 minutes)
./deploy.sh

# 3. Connexion
ssh -i workshop_key.pem azureuser@<IP>
```

## 🎛️ Paramètres principaux à personnaliser

Ouvrez `terraform.tfvars` et modifiez :

```hcl
vm_count                = 10              # Nombre de VMs (1-100)
vm_name_prefix          = "workshop-vm"   # Préfixe des noms
default_vm_size         = "Standard_B2s"  # Taille des VMs
default_os_disk_size_gb = 50              # Taille du disque (GB)
location                = "westeurope"    # Région Azure
```

## 🆘 Besoin d'aide ?

- **Documentation complète** : [README.md](README.md)
- **Guide de dépannage** : Section "Troubleshooting" dans README.md
- **Exemples** : [terraform.tfvars.examples](terraform.tfvars.examples)

## 📊 Coûts estimés

| Configuration | Coût (24/7) | Coût (2h workshop) |
|---------------|-------------|-------------------|
| 10 × B2s | ~$400/mois | ~$2 |
| 10 × B1s | ~$100/mois | ~$0.50 |
| 10 × D2s_v3 | ~$700/mois | ~$3.50 |

💡 **Astuce** : Détruisez après usage avec `./destroy.sh` pour payer $0 !

---

**Prêt ?** → [QUICKSTART.md](QUICKSTART.md)
