# 🚀 Workshop ClusterAPI Express - 2 Heures

## **De Zéro à Production : ClusterAPI et k0smotron en 2 Heures**

[![ClusterAPI](https://img.shields.io/badge/ClusterAPI-v1.10.6-blue)](https://cluster-api.sigs.k8s.io/)
[![k0smotron](https://img.shields.io/badge/k0smotron-v1.7.0-green)](https://k0smotron.io/)
[![Duration](https://img.shields.io/badge/Duration-120%20minutes-orange)]()
[![Format](https://img.shields.io/badge/Format-Hands--on%20Guided-success)]()

---

## 📋 **Vue d'Ensemble**

Bienvenue dans ce workshop **hands-on guidé** où vous allez apprendre à orchestrer des clusters Kubernetes avec **ClusterAPI** et **k0smotron** en seulement **2 heures** !

### **Ce que vous allez accomplir**
✅ Créer votre premier cluster Kubernetes avec ClusterAPI
✅ Installer automatiquement le CNI Calico avec ClusterResourceSets
✅ Découvrir k0smotron et ses économies de ressources (55%)
✅ Déployer simultanément multiples clusters avec Helm
✅ Automatiser le déploiement d'applications multi-clusters
✅ Mettre à jour plusieurs clusters en parallèle
✅ Scaler et monitorer vos clusters

### **Format du Workshop**
- **Durée totale:** 120 minutes (2 heures)
- **Format:** 8 modules guidés pas-à-pas
- **Style:** Démonstration + action immédiate
- **Niveau:** Débutant à Intermédiaire
- **Prérequis:** Connaissances Kubernetes de base

---

## 🎯 **Structure des Modules**

| Module | Titre | Durée | Objectif |
|--------|-------|-------|----------|
| [00-introduction](./00-introduction/) | Introduction & Outils | 10 min | Comprendre ClusterAPI + vérifier outils |
| [00-setup](./00-setup-management/) | **Setup Management Cluster** | 15 min | **Créer cluster kind + installer ClusterAPI** |
| [01](./01-premier-cluster/) | Premier Cluster ClusterAPI | 15 min | Créer un cluster Docker provider fonctionnel |
| [02](./02-networking-calico/) | Networking avec Calico | 15 min | Installer Calico CNI automatiquement |
| [03](./03-k0smotron/) | k0smotron Control Planes | 15 min | Créer cluster k0smotron + comparer ressources |
| [04](./04-multi-cluster-deployment/) | **Déploiement Multi-Cluster** | 15 min | **Déployer 3 clusters simultanément via Helm** |
| [05](./05-automation-helm/) | Automation avec Helm | 20 min | Déployer apps avec HelmChartProxy |
| [06](./06-cluster-upgrades/) | **Upgrades Multi-Cluster** | 15 min | **Mettre à jour plusieurs clusters en parallèle** |
| [07](./07-operations-cleanup/) | Operations & Cleanup | 15 min | Scaler, monitorer, nettoyer |

**Progression:**
Outils → **Management** → Premier Cluster → Networking → k0smotron → **Multi-Cluster** → Automation → **Upgrades** → Operations

---

## 🔧 **Prérequis Techniques**

### **Outils Requis**

Avant de commencer le workshop, vous devez avoir installé:

```bash
✅ Docker Desktop (ou Docker Engine)
✅ kubectl (CLI Kubernetes)
✅ kind (Kubernetes IN Docker)
✅ clusterctl (CLI ClusterAPI)
✅ helm (Package manager Kubernetes)
✅ jq (Parser JSON en ligne de commande)
✅ tree (Visualisation arborescente de répertoires)
```

### **Validation des Outils**

Module 00-introduction vous guide pour vérifier l'installation:

```bash
cd workshop-express/00-introduction
./verification.sh
```

**Résultat attendu:**
```
✅ Docker installé (version 27.4.0+)
✅ kind installé (version 0.30.0+)
✅ kubectl installé (version 1.32.0+)
✅ clusterctl installé (version 1.11.1+)
✅ helm installé (version 3.19.0+)
✅ jq installé
✅ tree installé
🎉 Tous les outils sont prêts pour le workshop!
```

### **Configuration des Limites Système (IMPORTANT)**

Le workshop crée de nombreux clusters et containers. Vous **DEVEZ** augmenter les limites système pour éviter les erreurs.

**Script automatique (recommandé) :**

```bash
cd workshop-express/00-introduction
./configure-system-limits.sh
```

**Configuration manuelle rapide (Linux) :**

```bash
# Limites kernel
echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.conf
echo "fs.file-max=2097152" | sudo tee -a /etc/sysctl.conf
echo "kernel.pid_max=4194304" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Limites utilisateur
cat << EOF | sudo tee -a /etc/security/limits.conf
*    soft    nofile    1048576
*    hard    nofile    1048576
EOF

# Docker limits
sudo mkdir -p /etc/systemd/system/docker.service.d
cat << EOF | sudo tee /etc/systemd/system/docker.service.d/limits.conf
[Service]
LimitNOFILE=1048576
LimitNPROC=infinity
EOF
sudo systemctl daemon-reload && sudo systemctl restart docker
```

**Configuration macOS :**

```bash
sudo launchctl limit maxfiles 1048576 1048576
# Puis configurez Docker Desktop → Resources (8GB+ RAM, 4+ CPUs)
```

**⚠️ Reconnectez-vous après la configuration pour appliquer les limites !**

### **Installation du Management Cluster**

Module 00-setup-management vous guide pour créer l'infrastructure:

```bash
cd workshop-express/00-setup-management
cat commands.md  # Instructions complètes
```

Vous installerez:
- ✅ Cluster kind de management
- ✅ ClusterAPI v1.10.6 + Docker Provider
- ✅ k0smotron operator v1.7.0
- ✅ Helm Addon Provider v0.3.2
- ✅ cert-manager

---

## 🚦 **Comment Utiliser ce Workshop**

### **Mode Guidé (Recommandé)**

Chaque module suit le pattern **Voir → Faire → Comprendre**:

1. **Voir:** Le formateur démontre (projeté sur écran)
2. **Faire:** Vous reproduisez immédiatement sur votre terminal
3. **Comprendre:** Le formateur explique les concepts

### **Navigation par Module**

```bash
# Aller dans un module
cd workshop-express/XX-nom-module/

# Lire les instructions pas-à-pas
cat commands.md

# Suivre les instructions du formateur
# ... exécuter les commandes ...

# Valider votre progression
./validation.sh
```

### **Checkpoints Automatiques**

Chaque module a un script de validation:

```bash
./validation.sh
```

**Attendez le feu vert** avant de passer au module suivant:
```
✅ Tous les tests PASSED
🎉 Module XX terminé avec succès!
```

---

## 📚 **Détail des Modules**

### **Module 00: Introduction & Setup (10 min)**
- Architecture ClusterAPI (Management + Workload clusters)
- Concepts clés (Cluster, Machine, Provider)
- Vérification environnement

### **Module 01: Premier Cluster ClusterAPI (15 min)**
- Créer un cluster Docker provider (`dev-cluster`)
- Observer la création en temps réel (Cluster, Machines)
- Récupérer le kubeconfig
- Comprendre pourquoi les nodes sont NotReady

### **Module 02: Networking avec Calico (15 min)**
- Diagnostiquer le problème CNI manquant
- Créer un ClusterResourceSet pour Calico
- Observer l'installation automatique
- Valider les nodes Ready

### **Module 03: k0smotron Control Planes (15 min)**
- Comprendre les control planes virtuels
- Créer un cluster k0smotron (`k0s-demo-cluster`)
- Comparer les ressources vs Docker provider
- Mesurer les économies (55% nodes, 50% memory)

### **Module 04: Déploiement Multi-Cluster (15 min) [NOUVEAU]**
- Utiliser un Helm chart pour déployer 3 clusters simultanément
- Observer la création parallèle vs séquentielle
- Comprendre le templating Helm pour ClusterAPI
- Mesurer les gains de temps (67% plus rapide)

### **Module 05: Automation avec Helm (20 min)**
- Comprendre HelmChartProxy et GitOps
- Déployer nginx automatiquement sur plusieurs clusters
- Observer le déploiement multi-clusters
- Tester l'application déployée
- Faire une mise à jour déclarative

### **Module 06: Upgrades Multi-Cluster (15 min) [NOUVEAU]**
- Mettre à jour simultanément plusieurs clusters Kubernetes
- Observer le rolling upgrade zero-downtime
- Comprendre le drain/upgrade/rejoin automatisé
- Vérifier la santé post-upgrade

### **Module 07: Operations & Cleanup (15 min)**
- Scaler les workers dynamiquement
- Monitorer les ressources des clusters
- Cleanup complet de l'environnement
- Ressources pour aller plus loin

---

## 🏗️ **Architecture Créée**

À la fin du workshop, vous aurez déployé:

```
┌─────────────────────────────────────────────────────────┐
│           Management Cluster (kind)                     │
│   ┌────────────┐  ┌──────────┐  ┌──────────────────┐   │
│   │ ClusterAPI │  │k0smotron │  │ Helm Addon       │   │
│   │ Controllers│  │ Operator │  │ Provider         │   │
│   └────────────┘  └──────────┘  └──────────────────┘   │
│                                                         │
│   Workload Clusters Créés:                             │
│   ┌──────────────────┐  ┌──────────────────┐          │
│   │  dev-cluster     │  │ k0s-demo-cluster │          │
│   │  (Docker)        │  │ (k0smotron)      │          │
│   │  1 CP + 4 workers│  │ 3 CP pods + 2 wk │          │
│   │  Calico CNI      │  │ Calico CNI       │          │
│   │  nginx app       │  │ nginx app        │          │
│   └──────────────────┘  └──────────────────┘          │
└─────────────────────────────────────────────────────────┘

Total: 7 nodes (5 Docker + 2 k0smotron workers) + 3 CP pods
Économie k0smotron: 55% vs architecture traditionnelle
```

---

## 📖 **Commandes Essentielles**

### **Gestion des Clusters**

```bash
# Lister les clusters
kubectl get clusters

# Détails d'un cluster
kubectl describe cluster <cluster-name>

# Lister les machines
kubectl get machines

# Status des machines
kubectl get kubeadmcontrolplane
kubectl get machinedeployment
```

### **Accès aux Workload Clusters**

```bash
# Récupérer le kubeconfig
clusterctl get kubeconfig <cluster-name> > <cluster-name>.kubeconfig

# Utiliser le kubeconfig
kubectl --kubeconfig <cluster-name>.kubeconfig get nodes
kubectl --kubeconfig <cluster-name>.kubeconfig get pods -A
```

### **Monitoring**

```bash
# Surveiller la création
watch -n 2 'kubectl get clusters,machines'

# Logs des controllers ClusterAPI
kubectl logs -n capi-system deployment/capi-controller-manager -f

# Ressources Docker
docker ps | grep cluster
```

---

## 🎓 **Concepts Clés Appris**

### **ClusterAPI**
- **Declarative:** Clusters définis en YAML
- **Kubernetes-native:** CRDs standard
- **Provider-agnostic:** Docker, AWS, Azure, GCP, etc.
- **Lifecycle management:** Create, scale, upgrade, delete

### **k0smotron**
- **Virtual Control Planes:** CP tournent comme pods
- **Économies:** 55% nodes, 50% memory, 2x plus rapide
- **HA simplifié:** Pods Kubernetes natifs
- **Cas d'usage:** Dev, CI/CD, multi-tenancy

### **ClusterResourceSets**
- **Automatic addons:** Déploiement automatique CNI, CSI, etc.
- **Label-based:** Sélection par labels de clusters
- **ConfigMap-driven:** Manifestes stockés dans ConfigMaps

### **HelmChartProxy**
- **GitOps:** Déploiement déclaratif multi-clusters
- **ClusterSelector:** Ciblage par labels
- **Lifecycle:** Helm Provider gère install, upgrade, rollback

---

## 🔍 **Troubleshooting**

### **Nodes NotReady**
```bash
# Vérifier si le CNI est installé
kubectl --kubeconfig <cluster>.kubeconfig get pods -n kube-system

# Si pas de Calico, vérifier le label du cluster
kubectl get cluster <cluster-name> --show-labels
# Doit avoir: cni=calico

# Si label manquant
kubectl label cluster <cluster-name> cni=calico
```

### **Cluster ne se crée pas**
```bash
# Vérifier les logs ClusterAPI
kubectl logs -n capi-system deployment/capi-controller-manager

# Vérifier les machines
kubectl get machines
kubectl describe machine <machine-name>

# Vérifier Docker
docker ps
docker logs <container-id>
```

### **HelmChartProxy ne déploie pas**
```bash
# Vérifier le HelmChartProxy
kubectl get helmchartproxy
kubectl describe helmchartproxy <name>

# Vérifier les HelmReleaseProxy
kubectl get helmreleaseproxy -A

# Logs du Helm Provider
kubectl logs -n capi-addon-system deployment/capi-addon-helm-controller-manager
```

---

## 📊 **Résultats Attendus**

À la fin du workshop, vous aurez:

| Composant | Quantité | État |
|-----------|----------|------|
| **Workload Clusters** | 2 | Provisioned, Ready |
| **Control Plane Nodes** | 1 (Docker) | Running |
| **Control Plane Pods** | 3 (k0smotron) | Running |
| **Worker Nodes** | 6 (4+2) | Ready |
| **Applications Déployées** | 2 (nginx) | Running |
| **ClusterResourceSets** | 1 (Calico) | Applied |
| **HelmChartProxy** | 1 (nginx) | Deployed |

**Ressources consommées:**
- Docker: ~6GB RAM, 4 CPU cores
- k0smotron: ~3GB RAM, 2 CPU cores
- **Économie totale:** ~50% vs architecture traditionnelle

---

## 🌟 **Aller Plus Loin**

### **Workshop Complet (11 heures)**

Ce workshop express est un condensé du **workshop complet** disponible dans le repo parent:

```bash
cd ../modules/
```

**Contenu du workshop complet:**
- **Phase 1:** Fondations ClusterAPI (Modules 00-04) - 3h45
- **Phase 2:** k0smotron avancé (Modules 05-07) - 2h15
- **Phase 3:** Automation (Modules 08-10) - 2h45
- **Phase 4:** Production Ready (Observability, Security, DR) - 3h00

### **Ressources Externes**

- [ClusterAPI Documentation](https://cluster-api.sigs.k8s.io/)
- [k0smotron Documentation](https://docs.k0smotron.io/)
- [k0s Documentation](https://docs.k0sproject.io/)
- [Calico Documentation](https://docs.tigera.io/calico/latest/)
- [Helm Addon Provider](https://github.com/kubernetes-sigs/cluster-api-addon-provider-helm)

### **Cas d'Usage Réels**

**ClusterAPI en Production:**
- Gestion de flottes de clusters (10-1000+)
- Multi-cloud (AWS + Azure + GCP)
- Self-service cluster provisioning
- CI/CD ephemeral clusters

**k0smotron en Production:**
- Environnements de développement
- CI/CD pipelines (clusters temporaires)
- Multi-tenancy (isolation par cluster)
- Edge computing (clusters légers)

---

## 🤝 **Support et Questions**

### **Pendant le Workshop**
- Levez la main pour l'assistance du formateur
- Les scripts de validation vous guident
- Les fichiers `commands.md` contiennent toutes les commandes

### **Après le Workshop**
- Consultez le workshop complet pour approfondir
- Rejoignez la communauté ClusterAPI (Slack, GitHub)
- Testez en production avec un environnement test

---

## 📜 **Récapitulatif du Parcours**

```
Module 0 (10min)  → Comprendre ClusterAPI
Module 1 (15min)  → Créer premier cluster
Module 2 (15min)  → Installer CNI automatiquement
Module 3 (15min)  → Découvrir k0smotron
Module 4 (15min)  → Déployer 3 clusters en parallèle [NOUVEAU]
Module 5 (20min)  → Automatiser avec Helm
Module 6 (15min)  → Upgrader clusters simultanément [NOUVEAU]
Module 7 (15min)  → Operations & Cleanup
                     ↓
        🎉 Expert ClusterAPI en 2 heures!
```

---

## 🚀 **Prêt à Commencer?**

```bash
cd 00-introduction/
cat commands.md
```

**Bon workshop! 🎓**

---

*Workshop Express ClusterAPI - Version 1.0*
*Basé sur ClusterAPI v1.10.6 | k0smotron v1.7.0 | Kubernetes v1.32.8 | Helm v3.19.0*