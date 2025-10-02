# Module 01: Premier Cluster ClusterAPI

**Durée:** 15 minutes | **Objectif:** Créer votre premier cluster Kubernetes avec ClusterAPI Docker provider

---

## 🎯 Ce que vous allez faire

Dans ce module, vous allez :
1. **Générer** un manifeste de cluster avec `clusterctl generate`
2. **Créer** un cluster Kubernetes déclarativement
3. **Observer** la création automatique du control plane et des workers
4. **Comprendre** l'architecture à 7 objets interconnectés
5. **Accéder** au cluster créé

---

## 📁 Fichiers du Module

- **[commands.md](commands.md)** - Instructions détaillées avec théorie et pratique
- **[QUICKSTART.md](QUICKSTART.md)** - Guide rapide (commandes uniquement)
- **[create-cluster.sh](create-cluster.sh)** - 🆕 Script de création automatique complet
- **[validation.sh](validation.sh)** - Script de validation automatique
- **dev-cluster.yaml** - Manifeste généré (créé durant le module)
- **dev-cluster.kubeconfig** - Fichier kubeconfig du cluster (créé durant le module)

---

## ⚡ Quick Start

### Option 1 : Script Automatique (Recommandé)

```bash
cd /home/volcampdev/workshop-express/01-premier-cluster
./create-cluster.sh
```

Le script `create-cluster.sh` automatise toutes les étapes :
- Génère le manifeste avec `clusterctl generate`
- Crée le cluster
- Attend que le cluster soit provisionné
- Récupère le kubeconfig
- Exécute la validation

### Option 2 : Commandes Manuelles

```bash
cd /home/volcampdev/workshop-express/01-premier-cluster

# Générer le manifeste
clusterctl generate cluster dev-cluster \
  --flavor development \
  --kubernetes-version v1.32.8 \
  --control-plane-machine-count=1 \
  --worker-machine-count=2 \
  > dev-cluster.yaml

# Créer le cluster
kubectl apply -f dev-cluster.yaml

# Observer la création (Ctrl+C pour arrêter)
watch -n 2 'kubectl get clusters,machines'

# Valider
./validation.sh
```

---

## 🏗️ Architecture : 1 Manifeste = 7 Objets

Le fichier `dev-cluster.yaml` généré contient **7 objets ClusterAPI** interconnectés :

```
1. Cluster                    → Chef d'orchestre (coordonne tout)
2. DockerCluster              → Infrastructure (réseau, load balancer)
3. KubeadmControlPlane        → Définition du control plane
4. DockerMachineTemplate (CP) → Template pour créer les CP nodes
5. MachineDeployment          → Définition des workers (scalable!)
6. DockerMachineTemplate (W)  → Template pour créer les workers
7. KubeadmConfigTemplate      → Configuration bootstrap des workers
```

**Pourquoi 7 objets ?** Séparation des responsabilités. Chaque objet a un rôle précis, permettant :
- **Modularité** : Changer la version K8s = modifier 1 objet
- **Réutilisabilité** : Même template pour plusieurs déploiements
- **Portabilité** : Changer de provider = remplacer 2 objets sur 7

---

## 🚀 Configuration du Cluster

Le cluster généré avec `clusterctl generate` a les caractéristiques suivantes :

| Paramètre | Valeur | Justification |
|-----------|--------|---------------|
| **Flavor** | `development` | Optimisé pour dev local (ressources minimales) |
| **Version K8s** | `v1.32.8` | Version stable récente |
| **Control Plane** | 1 node | Suffisant pour dev/test |
| **Workers** | 2 nodes | Permet de tester la distribution de pods |
| **Provider** | Docker (CAPD) | Rapide, local, sans coût |

**En production :**
- Control plane: 3 nodes (HA)
- Workers: 3+ nodes (selon charge)
- Provider: AWS/Azure/GCP

---

## 🔄 Workflow de Création

Après `kubectl apply -f dev-cluster.yaml` :

```
T+0s   : kubectl envoie les 7 objets à l'API server
T+1s   : ClusterAPI controller détecte le nouveau Cluster
T+2s   : DockerCluster controller crée le load balancer
T+5s   : KubeadmControlPlane crée la première Machine pour le CP
T+10s  : Docker provider crée un container pour le CP
T+30s  : Kubeadm bootstrap installe Kubernetes dans le container
T+60s  : Control plane UP! API server accessible
T+65s  : MachineDeployment crée 2 Machines workers
T+70s  : Docker provider crée 2 containers pour les workers
T+120s : Workers joignent le control plane
T+180s : 🎉 Cluster Provisioned! (nodes NotReady - pas de CNI)
```

**Durée totale :** ~3 minutes (containers vs 5-8min avec VMs cloud)

---

## ✅ Validation

```bash
./validation.sh
```

**Résultat attendu :**
```
✅ Cluster dev-cluster existe
✅ Cluster phase = Provisioned
✅ Control plane ready (1/1)
✅ 3 Machines en phase Running
✅ Kubeconfig récupérable
✅ 3 nodes visibles dans le workload cluster
⚠️  Nodes NotReady (normal - CNI manquant)
```

---

## ⚠️ État NotReady : C'est Normal !

Les nodes sont en état `NotReady` car :
- **Aucun CNI installé** : Pas de plugin réseau
- **Pas de communication pod-to-pod** : Les pods ne peuvent pas se parler
- **CoreDNS bloqué** : Attend le réseau pour démarrer

**Solution :** Le **Module 02** installera Calico CNI via ClusterResourceSet automatiquement !

---

## 📊 Commandes Utiles

### Observer les ressources
```bash
# Voir les clusters
kubectl get clusters

# Voir les machines (CP + workers)
kubectl get machines -o wide

# Voir le control plane
kubectl get kubeadmcontrolplane

# Voir le déploiement de workers
kubectl get machinedeployment

# Voir les containers Docker
docker ps | grep dev-cluster
```

### Accéder au workload cluster
```bash
# Récupérer le kubeconfig
clusterctl get kubeconfig dev-cluster > dev-cluster.kubeconfig

# Voir les nodes
kubectl --kubeconfig dev-cluster.kubeconfig get nodes

# Voir les pods (CoreDNS sera Pending)
kubectl --kubeconfig dev-cluster.kubeconfig get pods -A
```

### Scaling (après création)
```bash
# Scaler les workers de 2 à 5
kubectl scale machinedeployment dev-cluster-md-0 --replicas=5

# Observer le scaling
watch -n 2 'kubectl get machines'
```

---

## 🔧 Dépannage

### Cluster reste en Pending

**Diagnostic :**
```bash
kubectl describe cluster dev-cluster
kubectl logs -n capi-system deployment/capi-controller-manager -f
kubectl logs -n capd-system deployment/capd-controller-manager -f
```

**Causes fréquentes :**
- Docker daemon inaccessible
- Ressources insuffisantes
- Port déjà utilisé (load balancer)

### Machine ne démarre pas

**Diagnostic :**
```bash
kubectl describe machine <machine-name>
docker ps -a | grep dev-cluster
docker logs <container-name>
```

### Kubeconfig inaccessible

**Vérifier que le cluster est Provisioned :**
```bash
kubectl get cluster dev-cluster -o jsonpath='{.status.phase}'
# Doit afficher : Provisioned
```

---

## 🎓 Points Clés à Retenir

✅ **clusterctl generate** : Génère des manifestes avec bonnes pratiques
✅ **1 YAML = 7 objets** : Séparation des responsabilités
✅ **Machine ≠ Node** : Machine (CRD) crée une infra qui devient un Node (K8s)
✅ **MachineDeployment** : Comme un Deployment K8s mais pour nodes
✅ **NotReady = Normal** : Le CNI sera installé au Module 02

---

## ⏭️ Prochaine Étape

Une fois la validation réussie :

```bash
cd ../02-networking-calico
cat commands.md
```

**Module 02 (15 min) :** Installer Calico CNI automatiquement
- Comprendre ClusterResourceSets
- Automatiser le déploiement de Calico
- Passer les nodes à Ready

---

**Temps total :** ~15 minutes | **Difficulté :** ⭐⭐☆☆☆
