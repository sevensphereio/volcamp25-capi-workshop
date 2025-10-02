# Workshop ClusterAPI Express

Bienvenue dans le workshop ClusterAPI ! Ce workshop vous guide à travers la création et la gestion de clusters Kubernetes avec ClusterAPI (CAPI).

## 🎯 Objectifs du Workshop

Ce workshop vous apprendra à :
- Installer et configurer un management cluster avec ClusterAPI
- Créer des workload clusters Kubernetes dynamiquement
- Configurer le networking avec Calico
- Déployer des applications sur plusieurs clusters
- Automatiser les déploiements avec Helm

## 📋 Prérequis

- **OS :** Linux (Ubuntu/Debian) ou macOS
- **CPU :** 4+ cores recommandés
- **RAM :** 8+ GB recommandés
- **Disque :** 50+ GB disponibles
- **Droits :** Accès sudo pour l'installation des outils

## 🚀 Démarrage Rapide

### 1️⃣ Installation des Outils (Module 00)

Naviguez vers le module d'introduction et installez tous les outils nécessaires :

```bash
cd 00-introduction
cat 00-introduction.md  # Lire les instructions complètes
```

**Installation rapide (script automatique) :**
```bash
chmod +x setup.sh
./setup.sh
```

**Vérification de l'installation :**
```bash
./verification.sh
```

Les outils installés :
- Docker Engine (runtime containers)
- kind (Kubernetes IN Docker)
- kubectl (CLI Kubernetes)
- kubectl plugins (ctx, ns, slice, klock)
- clusterctl (CLI ClusterAPI)
- Helm (gestionnaire de packages)
- jq, yq (parsers JSON/YAML)
- tree (visualisation arborescente)

### 2️⃣ Déroulement des Modules

Une fois l'installation terminée, suivez les modules dans l'ordre :

### Option A:
Utilisation du docker labspace project (beta)

```
docker compose -f oci://rzarouali/labspace-volcamp25 up -d
```

==> ouvrez un onglet navigateur web sur http://localhost:3030

### Option B:
#### **Module 00-setup-management** : Configuration du Management Cluster
```bash
cd 00-setup-management
cat commands.md
```
Créez votre cluster de gestion kind et initialisez ClusterAPI.

#### **Module 01-premier-cluster** : Création du Premier Workload Cluster
```bash
cd 01-premier-cluster
cat commands.md
```
Déployez votre premier cluster Kubernetes géré par ClusterAPI.

#### **Module 02-networking-calico** : Configuration du Networking
```bash
cd 02-networking-calico
cat commands.md
```
Installez et configurez Calico pour la gestion réseau.

#### **Module 04-multi-cluster-deployment** : Déploiement Multi-Cluster
```bash
cd 04-multi-cluster-deployment
cat commands.md
```
Déployez des applications sur plusieurs clusters simultanément.

#### **Module 05-automation-helm** : Automatisation avec Helm
```bash
cd 05-automation-helm
cat commands.md
```
Automatisez vos déploiements avec Helm charts.

## 📁 Structure du Workshop

```
workshop-express/
├── README.md                          # Ce fichier
├── .labspace/                         # Documentation des modules
│   ├── 00-introduction.md
│   ├── 00-setup-management.md
│   ├── 01-premier-cluster.md
│   ├── 02-networking-calico.md
│   ├── 04-multi-cluster-deployment.md
│   └── 05-automation-helm.md
├── 00-introduction/                   # Installation des outils
│   ├── setup.sh
│   ├── verification.sh
│   └── configure-system-limits.sh
├── 00-setup-management/               # Management cluster
├── 01-premier-cluster/                # Premier workload cluster
├── 02-networking-calico/              # Configuration réseau
├── 04-multi-cluster-deployment/       # Multi-cluster
└── 05-automation-helm/                # Automatisation Helm
```

## 🔧 Commandes Utiles

### Gestion des Contextes
```bash
kubectl ctx                    # Lister les contextes disponibles
kubectl ctx <nom-contexte>     # Changer de contexte
kubectl ns <namespace>         # Changer de namespace
```

### Surveillance des Clusters
```bash
kubectl get clusters -A        # Lister tous les clusters CAPI
kubectl get machines -A        # Lister toutes les machines
clusterctl describe cluster <nom>  # Détails d'un cluster
```

### Debugging
```bash
kubectl logs <pod>             # Logs d'un pod
kubectl describe pod <pod>     # Détails d'un pod
kubectl get events -A          # Événements du cluster
```

## 🆘 Dépannage

### Docker : Permission denied
```bash
sudo usermod -aG docker $USER
newgrp docker
```

### kubectl plugin non trouvé
```bash
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Erreurs "too many open files"
Vérifiez que les limites système sont correctement configurées :
```bash
cd 00-introduction
./configure-system-limits.sh
```

## 📚 Ressources

- [Documentation ClusterAPI](https://cluster-api.sigs.k8s.io/)
- [Documentation Kubernetes](https://kubernetes.io/docs/)
- [Documentation Calico](https://docs.tigera.io/calico/latest/about/)
- [Documentation Helm](https://helm.sh/docs/)

## 🎓 Support

Pour toute question ou problème :
1. Consultez la section Dépannage du module concerné
2. Relancez les scripts de vérification
3. Consultez les logs des composants

## ⚖️ Licence

Ce workshop est fourni à des fins éducatives.

---

**Bon workshop ! 🚀**
