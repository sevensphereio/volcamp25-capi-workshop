# 🚀 Workshop ClusterAPI Express - 90 Minutes

## **De Zéro à Production : ClusterAPI et k0smotron en 90 Minutes**

[![ClusterAPI](https://img.shields.io/badge/ClusterAPI-v1.5.3-blue)](https://cluster-api.sigs.k8s.io/)
[![k0smotron](https://img.shields.io/badge/k0smotron-v1.8.0-green)](https://k0smotron.io/)
[![Duration](https://img.shields.io/badge/Duration-90%20minutes-orange)]()
[![Format](https://img.shields.io/badge/Format-Hands--on%20Guided-success)]()

---

## 📋 **Vue d'Ensemble**

Bienvenue dans ce workshop **hands-on guidé** où vous allez apprendre à orchestrer des clusters Kubernetes avec **ClusterAPI** et **k0smotron** en seulement **90 minutes** !

### **Ce que vous allez accomplir**
✅ Créer votre premier cluster Kubernetes avec ClusterAPI
✅ Installer automatiquement le CNI Calico avec ClusterResourceSets
✅ Découvrir k0smotron et ses économies de ressources (55%)
✅ Automatiser le déploiement d'applications avec Helm
✅ Scaler et monitorer vos clusters

### **Format du Workshop**
- **Durée totale:** 90 minutes
- **Format:** 6 modules guidés pas-à-pas
- **Style:** Démonstration + action immédiate
- **Niveau:** Débutant à Intermédiaire
- **Prérequis:** Connaissances Kubernetes de base

---

## 🎯 **Structure des Modules**

| Module | Titre | Durée | Objectif |
|--------|-------|-------|----------|
| [00](./00-introduction/) | Introduction & Setup | 10 min | Comprendre ClusterAPI + vérifier environnement |
| [01](./01-premier-cluster/) | Premier Cluster ClusterAPI | 15 min | Créer un cluster Docker provider fonctionnel |
| [02](./02-networking-calico/) | Networking avec Calico | 15 min | Installer Calico CNI automatiquement |
| [03](./03-k0smotron/) | k0smotron Control Planes | 15 min | Créer cluster k0smotron + comparer ressources |
| [04](./04-automation-helm/) | Automation avec Helm | 20 min | Déployer apps avec HelmChartProxy |
| [05](./05-operations-cleanup/) | Operations & Cleanup | 15 min | Scaler, monitorer, nettoyer |

**Progression:**
Fondations → Networking → k0smotron → Automation → Operations

---

## 🔧 **Prérequis Techniques**

### **Infrastructure Pré-provisionnée**

Votre environnement de workshop dispose déjà de:

```bash
✅ Management Cluster (kind) opérationnel
✅ ClusterAPI v1.5.3 installé
✅ Docker Provider configuré
✅ k0smotron operator déployé
✅ Helm Addon Provider installé
```

### **Validation de l'Environnement**

Avant de commencer, vérifiez votre accès:

```bash
cd workshop-express/00-introduction
./verification.sh
```

**Résultat attendu:**
```
✅ kubectl accessible
✅ Management cluster accessible
✅ ClusterAPI installé (v1.5.3)
✅ Docker provider ready
✅ k0smotron operator running
✅ Helm provider ready
🎉 Environnement prêt pour le workshop!
```

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

### **Module 04: Automation avec Helm (20 min)**
- Comprendre HelmChartProxy et GitOps
- Déployer nginx automatiquement sur plusieurs clusters
- Observer le déploiement multi-clusters
- Tester l'application déployée
- Faire une mise à jour déclarative

### **Module 05: Operations & Cleanup (15 min)**
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
Module 4 (20min)  → Automatiser avec Helm
Module 5 (15min)  → Operations & Cleanup
                     ↓
        🎉 Expert ClusterAPI en 90 minutes!
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
*Basé sur ClusterAPI v1.5.3 | k0smotron v1.8.0 | Kubernetes v1.28+*