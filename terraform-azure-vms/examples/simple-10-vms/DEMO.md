# 🎬 Démonstration Rapide - Déploiement 10 VMs

## 🎯 Objectif

Déployer **10 VMs Azure** en **3 minutes** avec personnalisation complète.

## 🚀 Démo en 3 étapes (3 minutes)

### Étape 1 : Configuration (30 secondes)

```bash
cd terraform-azure-vms/examples/simple-10-vms

# Éditez la configuration
nano terraform.tfvars
```

**Modifiez ces 5 lignes seulement :**

```hcl
vm_count                = 10              # Nombre de VMs (changez à 5, 15, 20...)
vm_name_prefix          = "demo-vm"       # Préfixe des noms
default_vm_size         = "Standard_B2s"  # Taille (B1s, B2s, D2s_v3...)
default_os_disk_size_gb = 50              # Taille disque (30-4095 GB)
location                = "westeurope"    # Région (francecentral, eastus...)
```

### Étape 2 : Déploiement (2-3 minutes)

```bash
./deploy.sh
```

**Le script fait TOUT automatiquement :**
- ✅ Vérifie les prérequis (Terraform, Azure CLI)
- ✅ Initialise Terraform
- ✅ Affiche le plan
- ✅ Déploie les 10 VMs en parallèle
- ✅ Sauvegarde la clé SSH
- ✅ Crée l'inventaire
- ✅ Teste la connectivité

### Étape 3 : Connexion (immédiat)

```bash
# Voir toutes les VMs
./list-vms.sh

# Se connecter à une VM
ssh -i workshop_key.pem azureuser@<IP>
```

## 🎬 Démo vidéo (script pour présentation)

### Slide 1 : Problème

> "Comment déployer rapidement 10 VMs identiques pour un workshop ?"

**Problèmes classiques :**
- ❌ Créer manuellement via portail Azure : 10-15 min par VM = 2h30 !
- ❌ Scripts Bash/PowerShell : Complexe, non reproductible
- ❌ Terraform brut : Beaucoup de code, configuration difficile

### Slide 2 : Solution

> "Notre module Terraform simplifié : 1 fichier à éditer, 1 commande"

**Avantages :**
- ✅ **3 minutes** pour déployer 10 VMs
- ✅ **5 paramètres** à configurer seulement
- ✅ **Infrastructure as Code** reproductible
- ✅ **Destruction en 1 clic** après l'événement

### Slide 3 : Démonstration live

**Terminal 1 - Configuration (montrer le fichier)**

```bash
cat terraform.tfvars
```

```hcl
vm_count       = 10              # ← Changez à 15 pour 15 VMs
vm_name_prefix = "workshop-vm"   # ← Nom des VMs
default_vm_size = "Standard_B2s" # ← Taille des VMs
location = "westeurope"          # ← Région Azure
```

**Terminal 2 - Déploiement**

```bash
time ./deploy.sh
```

> "Regardez : Terraform déploie les 10 VMs EN PARALLÈLE"
> "Temps estimé : 3 minutes"

**Pendant le déploiement, expliquer :**
- Infrastructure créée : VNet, Subnet, NSG, 10 VMs, 10 IPs publiques
- Coût : ~$400/mois si 24/7, mais ~$2 pour un workshop de 2h
- Scripts fournis : deploy.sh, destroy.sh, list-vms.sh, configure.sh

**Terminal 3 - Résultats (après déploiement)**

```bash
./list-vms.sh
```

Montre :
- ✅ 10 VMs déployées
- ✅ Leurs IPs publiques
- ✅ Commandes SSH prêtes à copier

**Test de connexion :**

```bash
ssh -i workshop_key.pem azureuser@<IP> "hostname && uptime"
```

### Slide 4 : Personnalisation

> "Besoin de 15 VMs plus puissantes dans une autre région ?"

**Éditer terraform.tfvars :**

```hcl
vm_count        = 15               # 15 au lieu de 10
default_vm_size = "Standard_D2s_v3"  # Plus puissant
location        = "francecentral"    # Région France
```

**Appliquer les changements :**

```bash
terraform apply
```

> "Terraform ajoute 5 VMs supplémentaires automatiquement (infrastructure drift detection)"

### Slide 5 : Cas d'usage

**1. Workshops/Formations**
- 10-50 participants
- VMs identiques pour tous
- Déploiement J-1, destruction le soir même
- Coût : ~$1-5 pour l'événement

**2. Environnements de test**
- Tests de charge
- Cluster temporaire
- POC/Démos clients

**3. CI/CD Runners**
- 5-10 runners identiques
- Auto-scaling via Terraform

**4. Cluster Kubernetes DIY**
- 1 master + 3-5 workers
- Installation manuelle de K8s
- Learning/Training

### Slide 6 : Nettoyage

> "Après l'événement : destruction en 1 clic"

```bash
./destroy.sh
```

> "Confirmation manuelle pour éviter les erreurs"
> "Détruit TOUTES les ressources en 2-3 minutes"
> "Coût : $0 après destruction"

## 📊 Tableaux de comparaison (pour slides)

### Comparaison méthodes de déploiement

| Méthode | Temps 10 VMs | Difficulté | Reproductible | Coût compétence |
|---------|--------------|------------|---------------|-----------------|
| **Portail Azure (manuel)** | 2h30 | Facile | ❌ Non | Bas |
| **Scripts Bash/PowerShell** | 30 min | Moyen | ⚠️ Partiel | Moyen |
| **Terraform brut** | 1h (dev) + 5 min | Difficile | ✅ Oui | Élevé |
| **Notre module** | 5 min | Facile | ✅ Oui | Bas |

### Comparaison coûts

| Scénario | Taille VM | Durée | Coût |
|----------|-----------|-------|------|
| Workshop 2h (10 VMs) | Standard_B2s | 2 heures | ~$2 |
| Workshop 8h (10 VMs) | Standard_B2s | 8 heures | ~$8 |
| Dev continu (5 VMs) | Standard_B2s | 1 mois | ~$200 |
| Production (10 VMs) | Standard_D2s_v3 | 1 mois | ~$700 |

## 🎤 Points clés à mentionner

### Pour les décideurs
- ✅ **ROI immédiat** : Économie de 2h15 de temps administrateur par déploiement
- ✅ **Reproductibilité** : Infrastructure as Code, pas d'erreur humaine
- ✅ **Coûts maîtrisés** : Destruction après usage = $0
- ✅ **Scalabilité** : De 1 à 100 VMs sans changer le code

### Pour les techniciens
- ✅ **Terraform best practices** : Variables avec validation, outputs structurés
- ✅ **Déploiement parallèle** : `for_each` au lieu de `count` pour performance
- ✅ **Sécurité** : NSG rules, clés SSH auto-générées, IP filtering
- ✅ **Maintenance** : Scripts de gestion inclus (deploy, destroy, list, configure)

### Pour les DevOps
- ✅ **CI/CD ready** : Variables d'environnement, remote state support
- ✅ **Modularité** : Module réutilisable, configuration externalisée
- ✅ **Observabilité** : Outputs structurés, inventaires Ansible/JSON/CSV
- ✅ **Évolutivité** : Ajout de zones, load balancer, data disks supportés

## 🎁 Bonus : Démonstrations avancées

### Démo 1 : Scaling horizontal

```bash
# Déploiement initial : 5 VMs
vm_count = 5
terraform apply

# 10 minutes plus tard : besoin de 10 VMs
vm_count = 10
terraform apply  # Ajoute 5 VMs sans toucher les 5 premières
```

### Démo 2 : Multi-région

```bash
# Déploiement région 1 : Europe
cd deployment-eu/
location = "westeurope"
vm_name_prefix = "eu-vm"
terraform apply

# Déploiement région 2 : USA
cd ../deployment-us/
location = "eastus"
vm_name_prefix = "us-vm"
terraform apply
```

### Démo 3 : Configuration interactive

```bash
./configure.sh
# Assistant pose 6 questions
# Génère automatiquement terraform.tfvars
# Calcule les coûts estimés
# Lance le déploiement
```

### Démo 4 : Export inventaires

```bash
./list-vms.sh
# Choisir option 5 : Export
# Génère :
#   - inventory.txt
#   - inventory.json
#   - inventory.csv
#   - ansible_inventory.ini

# Utilisation avec Ansible
ansible -i ansible_inventory.ini workshop_vms -m ping
```

## 📝 Notes pour le présentateur

**Timing recommandé :**
- Introduction : 2 min
- Problème/Solution : 2 min
- Démo live : 5 min (3 min déploiement + 2 min montrer résultats)
- Personnalisation : 2 min
- Cas d'usage : 2 min
- Questions : 2 min
- **Total : 15 minutes**

**Checklist avant démo :**
- [ ] Azure CLI authentifié (`az login`)
- [ ] Terraform installé et dans le PATH
- [ ] Dossier `simple-10-vms` cloné
- [ ] Terminaux préparés (3 onglets)
- [ ] Fichier terraform.tfvars pré-configuré
- [ ] Connexion internet stable
- [ ] Quotas Azure vérifiés (20+ vCPUs disponibles)

**En cas de problème pendant la démo :**
- Déploiement lent (>5 min) : "Dépend de la charge Azure, normalement 3 min"
- Erreur de quota : "Démo préparée avec 5 VMs au lieu de 10"
- Connexion SSH refuse : "Les VMs démarrent, prend 1-2 min de plus"

**Messages clés à répéter :**
1. "3 minutes pour 10 VMs"
2. "5 paramètres à configurer"
3. "Destruction en 1 clic = $0 après l'événement"
4. "Infrastructure as Code = Reproductible"

---

**🎬 Prêt pour la démo !**
