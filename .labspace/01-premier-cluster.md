# Module 01: Premier Cluster ClusterAPI

**Durée:** 15 minutes. 
**Objectif:** Créer votre premier cluster Kubernetes avec ClusterAPI Docker provider

---

## 📑 Table des Matières

- [🎯 Objectifs & Concepts](#-objectifs--concepts)
- [📋 Actions Pas-à-Pas](#-actions-pas-à-pas)
- [💡 Comprendre en Profondeur](#-comprendre-en-profondeur)

---

## 🎯 Objectifs & Concepts

### Ce que vous allez apprendre

- ✅ Générer un manifeste de cluster avec clusterctl generate
- ✅ Créer un cluster Kubernetes déclarativement avec un fichier YAML
- ✅ Observer la création automatique du control plane et des workers
- ✅ Comprendre pourquoi 7 objets sont nécessaires pour 1 cluster
- ✅ Accéder au cluster créé et comprendre l'état "NotReady"

### Le Principe : 1 Manifeste = 7 Objets

**Pourquoi 7 objets ?** Séparation des responsabilités. Chaque objet a un rôle précis :

```
Cluster                    → Chef d'orchestre (coordonne tout)
├── DockerCluster          → Infrastructure (réseau, load balancer)
├── KubeadmControlPlane    → Définition du control plane
│   └── DockerMachineTemplate (CP) → Template pour créer les CP nodes
└── MachineDeployment      → Définition des workers (scalable!)
    ├── DockerMachineTemplate (Workers) → Template pour créer les workers
    └── KubeadmConfigTemplate → Configuration bootstrap des workers
```

**Avantage :** Modifier un aspect (ex: version K8s) = modifier 1 seul objet, pas tout refaire.

---

## 📋 Actions Pas-à-Pas

> **💡 Raccourci :** Pour un setup automatisé complet, utilisez `./create-cluster.sh` qui exécute toutes les étapes ci-dessous. Pour une compréhension détaillée, suivez les étapes manuelles.

### Étape 1 : Aller dans le répertoire du module

**Objectif :** Se positionner dans le dossier de travail

**Commande :**
```bash
cd ~/01-premier-cluster
```

**Explication :**
- `cd` : Change de répertoire
- Chemin absolu vers le module 01

---

### Étape 2 : Générer le manifeste dev-cluster.yaml avec clusterctl

**Objectif :** Utiliser clusterctl pour générer automatiquement un manifeste de cluster complet

**Commande :**
```bash
clusterctl generate cluster dev-cluster \
  --flavor development \
  --kubernetes-version v1.32.8 \
  --control-plane-machine-count=1 \
  --worker-machine-count=2 \
  > dev-cluster.yaml
```

**Explication de la commande :**
- `clusterctl generate cluster` : Commande pour générer un manifeste de cluster
- `dev-cluster` : Nom du cluster à créer
- `--flavor development` : Utilise le template "development" (optimisé pour dev local)
- `--kubernetes-version v1.32.8` : Version de Kubernetes à installer
- `--control-plane-machine-count=1` : 1 node control plane (suffisant pour dev)
- `--worker-machine-count=2` : 2 nodes workers
- `> dev-cluster.yaml` : Redirige la sortie vers un fichier

**Pourquoi cette approche ?**
- ✅ **Toujours à jour** : Templates maintenus par la communauté ClusterAPI
- ✅ **Bonnes pratiques** : Configuration optimale selon le provider
- ✅ **Flexible** : Facile de changer les paramètres (version, nombre de nodes)
- ✅ **Reproductible** : Même commande = même résultat

**Résultat attendu :** Fichier `dev-cluster.yaml` créé (~200 lignes)

**✅ Vérification :**
```bash
ls -lh dev-cluster.yaml
```

Vous devriez voir un fichier d'environ 7-8 KB

---

### Étape 3 : Examiner le manifeste généré

**Objectif :** Comprendre la structure du fichier avant de l'appliquer

**Commande :**
```bash
cat dev-cluster.yaml
```

**Explication :**
- `cat` : Affiche le contenu d'un fichier
- `dev-cluster.yaml` : Le manifeste contenant les 7 objets ClusterAPI

**Résultat attendu :** Un fichier YAML avec 7 sections (objets) séparées par `---`

**✅ Vérification :** Repérez les 7 types d'objets générés automatiquement :
1. `kind: Cluster` - Chef d'orchestre (coordonne tout)
2. `kind: DockerCluster` - Infrastructure (réseau, load balancer)
3. `kind: KubeadmControlPlane` - Définition du control plane
4. `kind: DockerMachineTemplate` pour CP - Template pour créer les CP nodes
5. `kind: MachineDeployment` - Définition des workers (scalable!)
6. `kind: DockerMachineTemplate` pour workers - Template pour créer les workers
7. `kind: KubeadmConfigTemplate` - Configuration bootstrap des workers

**🔍 Points clés à noter dans le manifeste généré :**
- **Cluster** : Contient uniquement des références (`controlPlaneRef`, `infrastructureRef`)
- **KubeadmControlPlane** : `replicas: 1` (1 control plane node) et `version: v1.32.8`
- **MachineDeployment** : `replicas: 2` (2 worker nodes)
- **Networking** : CIDR pour les pods et services pré-configuré

**Commandes d'exploration :**
```bash
# Compter le nombre d'objets
grep -c "^kind:" dev-cluster.yaml

# Lister tous les types d'objets
grep "^kind:" dev-cluster.yaml

# Voir uniquement le Cluster principal
yq eval 'select(.kind == "Cluster")' dev-cluster.yaml 2>/dev/null || head -n 20 dev-cluster.yaml
```

---

### Étape 4 : Créer le cluster

**Objectif :** Envoyer le manifeste à ClusterAPI pour créer le cluster

**Commande :**
```bash
kubectl apply -f dev-cluster.yaml
```

**Explication de la commande :**
- `kubectl apply` : Crée ou met à jour des ressources Kubernetes
- `-f` : Spécifie un fichier (file) à utiliser
- `dev-cluster.yaml` : Le fichier manifeste

**Résultat attendu :**
```
cluster.cluster.x-k8s.io/dev-cluster created
dockercluster.infrastructure.cluster.x-k8s.io/dev-cluster created
kubeadmcontrolplane.controlplane.cluster.x-k8s.io/dev-cluster-control-plane created
dockermachinetemplate.infrastructure.cluster.x-k8s.io/dev-cluster-control-plane created
machinedeployment.cluster.x-k8s.io/dev-cluster-md-0 created
dockermachinetemplate.infrastructure.cluster.x-k8s.io/dev-cluster-md-0 created
kubeadmconfigtemplate.bootstrap.cluster.x-k8s.io/dev-cluster-md-0 created
```

**✅ Vérification :** 7 objets créés confirmés

**🔍 Ce qui se passe :**
1. Les objets sont enregistrés dans l'API du management cluster
2. Les controllers ClusterAPI détectent les nouveaux objets
3. La création automatique démarre (containers, réseau, Kubernetes)

---

### Étape 5 : Observer la création en temps réel

**Objectif :** Suivre la progression de Pending → Provisioning → Provisioned

**Commande :**
```bash
watch -n 2 'kubectl get clusters,machines'
```

**Explication de la commande :**
- `watch` : Exécute une commande en boucle
- `-n 2` : Rafraîchit toutes les 2 secondes
- `kubectl get clusters,machines` : Liste les clusters et machines
- Guillemets simples pour protéger la commande entière

**Résultat attendu (progression sur 3 minutes) :**

**Minute 1 - Démarrage :**
```
NAME                                    PHASE      AGE
cluster.cluster.x-k8s.io/dev-cluster    Pending    30s

NAME                                                  CLUSTER       PHASE         AGE
machine.cluster.x-k8s.io/dev-cluster-control-plane-xxxx  dev-cluster   Provisioning  30s
machine.cluster.x-k8s.io/dev-cluster-md-0-yyyyy-zzzzz    dev-cluster   Pending       30s
machine.cluster.x-k8s.io/dev-cluster-md-0-yyyyy-aaaaa    dev-cluster   Pending       30s
```

**Minute 2 - Control plane up :**
```
NAME                                    PHASE           AGE
cluster.cluster.x-k8s.io/dev-cluster    Provisioning    2m

NAME                                                  CLUSTER       PHASE         AGE
machine.cluster.x-k8s.io/dev-cluster-control-plane-xxxx  dev-cluster   Running       2m
machine.cluster.x-k8s.io/dev-cluster-md-0-yyyyy-zzzzz    dev-cluster   Provisioning  2m
machine.cluster.x-k8s.io/dev-cluster-md-0-yyyyy-aaaaa    dev-cluster   Provisioning  2m
```

**Minute 3 - Cluster complet :**
```
NAME                                    PHASE         AGE
cluster.cluster.x-k8s.io/dev-cluster    Provisioned   3m

NAME                                                  CLUSTER       PHASE     AGE
machine.cluster.x-k8s.io/dev-cluster-control-plane-xxxx  dev-cluster   Running   3m
machine.cluster.x-k8s.io/dev-cluster-md-0-yyyyy-zzzzz    dev-cluster   Running   3m
machine.cluster.x-k8s.io/dev-cluster-md-0-yyyyy-aaaaa    dev-cluster   Running   3m
```

**✅ Vérification finale :** Cluster PHASE = Provisioned, 3 Machines PHASE = Running

**🔍 Phases expliquées :**
- **Pending** : Objet créé, en attente de provisioning
- **Provisioning** : Infrastructure en cours de création
- **Running** : Machine opérationnelle (pour Machine)
- **Provisioned** : Cluster complet et prêt (pour Cluster)

**Appuyez sur Ctrl+C pour arrêter le watch**

---

### Étape 6 : Vérifier les containers Docker créés

**Objectif :** Confirmer que 3 containers = 3 nodes Kubernetes

**Commande :**
```bash
docker ps | grep dev-cluster
```

**Explication de la commande :**
- `docker ps` : Liste les containers Docker en cours d'exécution
- `|` : Pipe (envoie la sortie vers la commande suivante)
- `grep dev-cluster` : Filtre uniquement les lignes contenant "dev-cluster"

**Résultat attendu :**
```
CONTAINER ID   IMAGE                  NAMES
xxxxxxxxxxxx   kindest/node:v1.32.8   dev-cluster-control-plane-xxxx
yyyyyyyyyyyy   kindest/node:v1.32.8   dev-cluster-md-0-yyyyy-zzzzz
zzzzzzzzzzzz   kindest/node:v1.32.8   dev-cluster-md-0-yyyyy-aaaaa
```

**✅ Vérification :** 3 containers listés

**🔍 Ce que cela signifie :**
- Chaque container Docker simule une machine virtuelle
- `kindest/node` : Image Docker pré-configurée avec Kubernetes
- 1 container pour le control plane + 2 containers pour les workers

---

### Étape 7 : Explorer les ressources ClusterAPI

**Objectif :** Vérifier l'état détaillé des composants

**Commandes :**

**6.1 - Voir le KubeadmControlPlane**
```bash
kubectl get kubeadmcontrolplane
```

**Explication :**
- `get kubeadmcontrolplane` : Liste les control planes gérés par ClusterAPI

**Résultat attendu :**
```
NAME                         CLUSTER       INITIALIZED   API SERVER   REPLICAS   READY   UPDATED
dev-cluster-control-plane    dev-cluster   true          true         1          1       1
```

**✅ Vérification :** INITIALIZED = true, API SERVER = true, READY = 1/1

---

**6.2 - Voir le MachineDeployment**
```bash
kubectl get machinedeployment
```

**Explication :**
- `get machinedeployment` : Liste les déploiements de workers (comme un Deployment K8s)

**Résultat attendu :**
```
NAME                 CLUSTER       REPLICAS   READY   UPDATED   UNAVAILABLE   PHASE     AGE
dev-cluster-md-0     dev-cluster   2          2       2         0             Running   3m
```

**✅ Vérification :** REPLICAS = 2, READY = 2, PHASE = Running

---

**6.3 - Voir les Machines détaillées**
```bash
kubectl get machines -o wide
```

**Explication :**
- `get machines` : Liste toutes les machines (CP + workers)
- `-o wide` : Format étendu avec plus d'informations (VERSION, NODENAME)

**Résultat attendu :**
```
NAME                                CLUSTER       PHASE     VERSION   NODENAME
dev-cluster-control-plane-xxxx      dev-cluster   Running   v1.32.8   dev-cluster-control-plane-xxxx
dev-cluster-md-0-yyyyy-zzzzz        dev-cluster   Running   v1.32.8   dev-cluster-md-0-yyyyy-zzzzz
dev-cluster-md-0-yyyyy-aaaaa        dev-cluster   Running   v1.32.8   dev-cluster-md-0-yyyyy-aaaaa
```

**✅ Vérification :** 3 machines en phase Running avec la version v1.32.8

---

### Étape 8 : Récupérer le kubeconfig du workload cluster

**Objectif :** Obtenir le fichier de configuration pour accéder au nouveau cluster

**Commande :**
```bash
clusterctl get kubeconfig dev-cluster > dev-cluster.kubeconfig
```

**Explication de la commande :**
- `clusterctl` : Outil CLI spécifique à ClusterAPI
- `get kubeconfig` : Extrait le fichier kubeconfig du cluster spécifié
- `dev-cluster` : Nom du cluster cible
- `>` : Redirige la sortie vers un fichier
- `dev-cluster.kubeconfig` : Nom du fichier de sortie

**Résultat attendu :** Pas de sortie (le fichier est créé silencieusement)

**✅ Vérification :**
```bash
ls -lh dev-cluster.kubeconfig
```

Vous devriez voir un fichier d'environ 5-6 KB

---

### Étape 9 : Accéder au workload cluster

**Objectif :** Voir les nodes dans le cluster nouvellement créé

**Commande :**
```bash
kubectl --kubeconfig dev-cluster.kubeconfig get nodes
```

**Explication de la commande :**
- `kubectl` : Commande habituelle
- `--kubeconfig dev-cluster.kubeconfig` : Utilise ce fichier au lieu du kubeconfig par défaut
- `get nodes` : Liste les nodes Kubernetes

**Résultat attendu :**
```
NAME                              STATUS     ROLES           AGE   VERSION
dev-cluster-control-plane-xxxx    NotReady   control-plane   3m    v1.32.8
dev-cluster-md-0-yyyyy-zzzzz      NotReady   <none>          2m    v1.32.8
dev-cluster-md-0-yyyyy-aaaaa      NotReady   <none>          2m    v1.32.8
```

**✅ Vérification :** 3 nodes listés avec VERSION v1.32.8

**⚠️ STATUS = NotReady est NORMAL !** Le CNI (Container Network Interface) n'est pas encore installé.

---

### Étape 10 : Comprendre pourquoi NotReady

**Objectif :** Vérifier l'absence du réseau pod

**Commande :**
```bash
kubectl --kubeconfig dev-cluster.kubeconfig get pods -A
```

**Explication de la commande :**
- `--kubeconfig dev-cluster.kubeconfig` : Utilise le workload cluster
- `get pods` : Liste les pods
- `-A` : Dans tous les namespaces (All)

**Résultat attendu :**
```
NAMESPACE     NAME                                                READY   STATUS
kube-system   coredns-xxx                                         0/1     Pending
kube-system   coredns-yyy                                         0/1     Pending
kube-system   etcd-dev-cluster-control-plane-xxxx                 1/1     Running
kube-system   kube-apiserver-dev-cluster-control-plane-xxxx       1/1     Running
kube-system   kube-controller-manager-dev-cluster-...             1/1     Running
kube-system   kube-proxy-...                                      1/1     Running
kube-system   kube-scheduler-dev-cluster-control-plane-xxxx       1/1     Running
```

**✅ Vérification :**
- Control plane pods (etcd, apiserver, etc.) = Running
- CoreDNS pods = Pending

**🔍 Diagnostic :**
- CoreDNS ne peut pas démarrer sans réseau pod
- Les nodes ne peuvent pas communiquer entre eux sans CNI
- **Module 02 résoudra ce problème avec Calico CNI**

---

### Étape 11 : Valider le module

**Objectif :** Exécuter le script de validation automatique

**Commande :**
```bash
./validation.sh
```

**Explication :**
- `./` : Exécute un script dans le répertoire courant
- `validation.sh` : Script bash qui teste tous les prérequis

**Résultat attendu :**
```
🔍 Module 01: Validation Premier Cluster
=========================================

✅ Cluster dev-cluster existe
✅ Cluster phase = Provisioned
✅ Control plane ready (1/1)
✅ 3 Machines en phase Running
✅ Kubeconfig récupérable
✅ 3 nodes visibles dans le workload cluster
⚠️  Nodes NotReady (normal - CNI manquant)

=========================================
🎉 Module 01 terminé avec succès!
🚀 Prêt pour Module 02: Networking avec Calico
=========================================
```

**✅ Si tous les tests passent :** Vous êtes prêt pour le Module 02 !

---

## 🎓 Points Clés à Retenir

✅ **1 YAML = 7 objets interconnectés** - Séparation des responsabilités
✅ **Machine ≠ Node** - Machine (CRD ClusterAPI) crée une infra qui devient un Node (objet K8s)
✅ **Phases du Lifecycle** : Pending → Provisioning → Running/Provisioned
✅ **MachineDeployment = Deployment pour nodes** - Scaling : `kubectl scale machinedeployment`
✅ **NotReady est normal ici** - Le CNI (réseau) sera installé au Module 02

### Tableau Récapitulatif des Objets

| Objet | Rôle | Analogie |
|-------|------|----------|
| **Cluster** | Chef d'orchestre (références seulement) | Chef de projet qui coordonne |
| **DockerCluster** | Infrastructure (LB, réseau) | Terrain et fondations |
| **KubeadmControlPlane** | Définition du control plane | Direction générale (CEO, CTO) |
| **DockerMachineTemplate (CP)** | Template pour créer les CP nodes | Moule à gâteau CP |
| **MachineDeployment** | Définition des workers (scalable) | Manager des workers |
| **DockerMachineTemplate (Workers)** | Template pour créer les workers | Moule à gâteau workers |
| **KubeadmConfigTemplate** | Configuration bootstrap workers | Script d'onboarding |

---

## ⏭️ Prochaine Étape

**Module 02-networking-calico (15 min) :** Installer Calico CNI automatiquement
- Comprendre ClusterResourceSets
- Automatiser le déploiement de Calico
- Passer les nodes à Ready


---

## 💡 Comprendre en Profondeur

> **Note :** Cette section approfondit les concepts techniques. Vous pouvez la sauter et y revenir plus tard.

### Workflow Complet "Sous le Capot"

**Ce qui se passe après `kubectl apply` :**

```
T+0s   : kubectl envoie les 7 objets à l'API server du management cluster
T+1s   : ClusterAPI controller détecte le nouveau Cluster → démarre reconciliation
T+2s   : DockerCluster controller crée le load balancer (container haproxy)
T+5s   : KubeadmControlPlane controller crée la première Machine pour le CP
T+10s  : Docker provider crée un container kindest/node pour le CP
T+30s  : Kubeadm bootstrap installe Kubernetes dans le container
T+60s  : Control plane UP! API server accessible
T+65s  : MachineDeployment détecte CP ready → crée 2 Machines workers
T+70s  : Docker provider crée 2 containers pour les workers
T+120s : Workers joignent le control plane via kubeadm join
T+180s : 🎉 Cluster Provisioned! (Mais nodes NotReady - pas de CNI encore)
```

**Pourquoi c'est rapide (3 minutes) ?**
- **Containers vs VMs** : 10x plus rapide
- **Images pré-built** : kindest/node pré-configuré avec K8s
- **Parallélisation** : Workers créés en parallèle
- **En prod (AWS)** : Comptez 5-8 minutes (provisioning VMs + cloud API)

---

### Anatomie Complète des 7 Objets

#### 1️⃣ Cluster - Le Chef d'Orchestre

**Rôle :** Coordination de haut niveau

```yaml
apiVersion: cluster.x-k8s.io/v1beta1
kind: Cluster
metadata:
  name: dev-cluster
spec:
  clusterNetwork:
    pods:
      cidrBlocks: ["192.168.0.0/16"]   # Réseau pour 65k pods
  controlPlaneRef:
    kind: KubeadmControlPlane          # Référence au CP
    name: dev-cluster-control-plane
  infrastructureRef:
    kind: DockerCluster                # Référence à l'infra
    name: dev-cluster
```

**Points clés :**
- Ne contient QUE des références (pas d'implémentation)
- Définit le réseau pod (important pour CNI)
- Controller ClusterAPI surveille cet objet pour orchestrer

**Pourquoi des références ?**
- **Modularité** : Changer de provider = changer 1 référence
- **Réutilisabilité** : Même DockerCluster pour plusieurs Clusters
- **Séparation** : Logique métier vs implémentation

---

#### 2️⃣ DockerCluster - L'Infrastructure Concrète

**Rôle :** Créer l'infrastructure réseau et load balancer

```yaml
kind: DockerCluster
metadata:
  name: dev-cluster
spec: {}  # Vide pour Docker, contiendrait VPC/subnets pour AWS
```

**Ce qu'il fait réellement :**
- Crée un container **haproxy** pour load balancer l'API server
- Configure le réseau Docker pour la communication inter-containers
- En prod (AWS) : définirait VPC, subnets, security groups, internet gateway

**Portabilité :**
```yaml
# Production AWS
kind: AWSCluster
spec:
  region: us-west-2
  vpc:
    cidrBlock: "10.0.0.0/16"
```

---

#### 3️⃣ KubeadmControlPlane - Le Cerveau du Cluster

**Rôle :** Gérer le control plane (API server, etcd, scheduler, controller-manager)

```yaml
kind: KubeadmControlPlane
metadata:
  name: dev-cluster-control-plane
spec:
  replicas: 1           # Nombre de nodes CP (3 en prod pour HA)
  version: v1.32.8      # Version Kubernetes à installer
  machineTemplate:
    infrastructureRef:
      kind: DockerMachineTemplate
      name: dev-cluster-control-plane
  kubeadmConfigSpec:    # Configuration kubeadm pour initialiser K8s
    initConfiguration:
      nodeRegistration:
        criSocket: unix:///var/run/containerd/containerd.sock
```

**Responsabilités :**
- Crée les nodes control plane
- Gère les certificats CA du cluster
- Automatise `kubeadm init` et `kubeadm join` pour les CP
- HA automatique si replicas > 1 (quorum etcd)

**Scaling du Control Plane :**
```
replicas: 1 → Dev/Test (panne = cluster down)
replicas: 3 → Production (tolère 1 panne, quorum 2/3)
replicas: 5 → Mission-critical (tolère 2 pannes)
```

**Important :** Toujours un nombre **impair** pour le quorum etcd

---

#### 4️⃣ DockerMachineTemplate (CP) - Moule à Serveurs CP

**Rôle :** Template réutilisable pour créer les machines control plane

```yaml
kind: DockerMachineTemplate
metadata:
  name: dev-cluster-control-plane
spec:
  template:
    spec:
      extraMounts:
        - containerPath: /var/run/docker.sock
          hostPath: /var/run/docker.sock
```

**Points clés :**
- N'est PAS instancié directement (c'est un template)
- KubeadmControlPlane l'utilise pour créer des Machines
- Contient : ressources CPU/RAM, disques, configuration réseau
- En prod : type d'instance (t3.medium), AMI, security groups

---

#### 5️⃣ MachineDeployment - Manager des Workers

**Rôle :** Gérer les worker nodes (comme un Deployment K8s mais pour serveurs)

```yaml
kind: MachineDeployment
metadata:
  name: dev-cluster-md-0
spec:
  clusterName: dev-cluster
  replicas: 2                  # 2 worker nodes (scalable à tout moment)
  selector:
    matchLabels:
      cluster.x-k8s.io/cluster-name: dev-cluster
  template:
    spec:
      version: v1.32.8
      bootstrap:
        configRef:
          kind: KubeadmConfigTemplate
      infrastructureRef:
        kind: DockerMachineTemplate
```

**Fonctionnalités identiques à un Deployment K8s :**
- **Scaling** : `kubectl scale machinedeployment dev-cluster-md-0 --replicas=5`
- **Rolling updates** : Changement de version → update progressif
- **Self-healing** : Machine down = recréation automatique

**Pourquoi séparé du Control Plane ?**
```
Control Plane = Critique → KubeadmControlPlane (gestion spéciale, quorum)
Workers = Scalables → MachineDeployment (scaling facile, jetables)
```

---

#### 6️⃣ DockerMachineTemplate (Workers) - Moule à Workers

**Rôle :** Template pour créer les worker machines (même principe que template CP)

```yaml
kind: DockerMachineTemplate
metadata:
  name: dev-cluster-md-0
spec:
  template:
    spec:
      extraMounts:
        - containerPath: /var/run/docker.sock
          hostPath: /var/run/docker.sock
```

---

#### 7️⃣ KubeadmConfigTemplate - Script d'Installation Workers

**Rôle :** Automatiser le bootstrap (jointure) des workers au control plane

```yaml
kind: KubeadmConfigTemplate
metadata:
  name: dev-cluster-md-0
spec:
  template:
    spec:
      joinConfiguration:
        nodeRegistration:
          criSocket: unix:///var/run/containerd/containerd.sock
          kubeletExtraArgs:
            eviction-hard: nodefs.available<0%,nodefs.inodesFree<0%
```

**Ce qu'il fait :**
- Contient les commandes `kubeadm join` pré-configurées
- Injecte automatiquement certificats et tokens
- Configure kubelet avec les bonnes options

**Workflow automatique :**
1. MachineDeployment crée une nouvelle Machine
2. Docker provider crée un container
3. KubeadmConfigTemplate génère un cloud-init script
4. Script exécuté dans le container → `kubeadm join`
5. Worker rejoint automatiquement le cluster

---

### Différence Machine vs Node

**Confusion fréquente :** Les termes sont souvent mélangés, mais ils sont distincts !

| Aspect | Machine (CRD ClusterAPI) | Node (Objet Kubernetes) |
|--------|--------------------------|-------------------------|
| **Définition** | Définition déclarative d'un serveur | Serveur réel enregistré dans K8s |
| **Où vit-il ?** | Management cluster | Workload cluster |
| **Lifecycle** | Pending → Provisioning → Running | NotReady → Ready |
| **Gestion** | ClusterAPI controllers | Kubelet |
| **Commande** | `kubectl get machines` | `kubectl get nodes` |

**Workflow complet :**
```
1. MachineDeployment crée → 1 Machine (CRD)
2. Machine déclenche → Création infrastructure (VM/container)
3. Infrastructure démarre → Kubelet s'enregistre
4. Kubelet crée → 1 Node (objet K8s)
5. Machine.status.nodeRef pointe vers le Node
```

---

### Pourquoi NotReady est Normal

**Les nodes sont créés mais non fonctionnels car :**

1. **CNI manquant** : Pas de plugin réseau installé
2. **Pas de communication pod-to-pod** : Les pods ne peuvent pas se parler
3. **CoreDNS bloqué** : Attend le réseau pour démarrer

**Vérification :**
```bash
kubectl --kubeconfig dev-cluster.kubeconfig describe node <node-name> | grep -A 5 "Conditions:"
```

Vous verrez :
```
Conditions:
  Type             Status  Reason
  ----             ------  ------
  Ready            False   KubeletNotReady
  NetworkReady     False   NetworkPluginNotReady
```

**Solution :** Module 02 installera Calico CNI via ClusterResourceSet automatiquement !

---

### Scaling en Pratique

**Scaler les workers (MachineDeployment) :**

```bash
# Méthode 1 : kubectl scale
kubectl scale machinedeployment dev-cluster-md-0 --replicas=5

# Méthode 2 : kubectl patch
kubectl patch machinedeployment dev-cluster-md-0 -p '{"spec":{"replicas":5}}'

# Méthode 3 : Modifier le YAML et ré-appliquer
# Éditer dev-cluster.yaml : replicas: 5
kubectl apply -f dev-cluster.yaml
```

**Workflow automatique :**
1. MachineDeployment détecte `desired: 5, current: 2`
2. Crée 3 nouvelles Machines
3. Utilise DockerMachineTemplate pour les créer
4. Utilise KubeadmConfigTemplate pour les configurer
5. Machines joignent automatiquement le cluster
6. État final : 5 workers Running

**Observer le scaling :**
```bash
watch -n 2 'kubectl get machines'
```

---

### Upgrade de Version Kubernetes

**Changer la version K8s :**

```bash
# Upgrade le control plane
kubectl patch kubeadmcontrolplane dev-cluster-control-plane \
  -p '{"spec":{"version":"v1.33.0"}}' --type=merge

# Upgrade les workers
kubectl patch machinedeployment dev-cluster-md-0 \
  -p '{"spec":{"template":{"spec":{"version":"v1.33.0"}}}}' --type=merge
```

**Workflow automatique :**
1. **Control plane** : Rolling update (1 node à la fois si replicas > 1)
2. **Workers** : Rolling update (comme un Deployment K8s)
3. Chaque node est drainé → upgradé → rejoint le cluster
4. **Zero-downtime** si conçu pour HA

---

### Connexion Production

**En production AWS/Azure, seuls 2-3 objets changent :**

```yaml
# Au lieu de DockerCluster :
kind: AWSCluster
spec:
  region: us-west-2
  vpc:
    cidrBlock: "10.0.0.0/16"
    availabilityZones: ["us-west-2a", "us-west-2b", "us-west-2c"]

# Au lieu de DockerMachineTemplate :
kind: AWSMachineTemplate
spec:
  template:
    spec:
      instanceType: t3.medium
      ami:
        id: ami-0abcdef1234567890
      iamInstanceProfile: nodes.cluster-api-provider-aws.sigs.k8s.io
      sshKeyName: my-ssh-key

# Le reste (Cluster, KubeadmControlPlane, MachineDeployment) → IDENTIQUE !
```

**Portabilité réelle :**
- 80% du manifeste reste identique
- Changer de provider = remplacer 2 objets sur 7
- Même commande : `kubectl apply -f cluster.yaml`

---

### Troubleshooting

#### Cluster reste en Pending

**Diagnostic :**
```bash
# Vérifier les events du cluster
kubectl describe cluster dev-cluster

# Logs du controller ClusterAPI
kubectl logs -n capi-system deployment/capi-controller-manager -f

# Logs du Docker provider
kubectl logs -n capd-system deployment/capd-controller-manager -f
```

**Causes fréquentes :**
- Infrastructure provider down
- Référence incorrecte dans le manifeste
- Ressources insuffisantes (Docker)

---

#### Machine ne démarre pas

**Diagnostic :**
```bash
# Détails de la machine
kubectl describe machine <machine-name>

# Vérifier les containers Docker
docker ps -a | grep dev-cluster

# Logs du container si créé
docker logs <container-name>
```

**Causes fréquentes :**
- Image kindest/node non disponible
- Erreur réseau Docker
- Port déjà utilisé (load balancer)

---

#### Kubeconfig inaccessible

**Diagnostic :**
```bash
# Le cluster doit être Provisioned
kubectl get cluster dev-cluster -o jsonpath='{.status.phase}'
# Doit afficher : Provisioned

# Vérifier que le control plane est ready
kubectl get kubeadmcontrolplane
# Doit montrer : INITIALIZED=true, API SERVER=true
```

**Solution :**
```bash
# Attendre que le cluster soit Provisioned
# Puis retry :
clusterctl get kubeconfig dev-cluster > dev-cluster.kubeconfig
```

---

### Pause Pédagogique : Questions de Compréhension

#### Question 1
**Si vous voulez scaler de 2 à 5 workers, quel objet modifiez-vous ?**

<details>
<summary>Voir la réponse</summary>

**Réponse :** `MachineDeployment` - modifier `spec.replicas: 5`

```bash
kubectl scale machinedeployment dev-cluster-md-0 --replicas=5
```
</details>

---

#### Question 2
**Quelle différence entre KubeadmControlPlane et MachineDeployment ?**

<details>
<summary>Voir la réponse</summary>

| Aspect | KubeadmControlPlane | MachineDeployment |
|--------|---------------------|-------------------|
| **Cible** | Nodes control plane | Nodes workers |
| **Criticité** | Critique (cerveau cluster) | Scalable (exécution apps) |
| **HA** | Gestion spéciale (quorum etcd) | Simple réplication |
| **Scaling** | Chiffres impairs (1,3,5) | N'importe quel nombre |
| **Upgrade** | Rolling upgrade prudent | Rolling upgrade standard |

**Pourquoi séparé ?** Le control plane gère l'état du cluster entier. Les workers sont "jetables" et facilement remplaçables.
</details>

---

#### Question 3
**Pourquoi 7 objets au lieu d'un seul gros fichier ?**

<details>
<summary>Voir la réponse</summary>

**Avantages de la séparation :**
1. **Modularité** : Changer la version K8s = modifier 1 objet (KubeadmControlPlane)
2. **Réutilisabilité** : Même template pour plusieurs déploiements
3. **Portabilité** : Changer de provider = remplacer 2 objets sur 7
4. **Scaling** : Modifier replicas sans toucher au reste
5. **Responsabilité unique** : Chaque objet a UN rôle précis

**Exemple :** Pour passer de Docker à AWS :
- Remplacer DockerCluster → AWSCluster
- Remplacer DockerMachineTemplate → AWSMachineTemplate
- Garder : Cluster, KubeadmControlPlane, MachineDeployment, KubeadmConfigTemplate
</details>

---

## 🎓 Ce Que Vous Avez Appris

- ✅ Créer un cluster Kubernetes déclarativement (1 YAML = 7 objets)
- ✅ Observer la progression en temps réel (Pending → Provisioned)
- ✅ Comprendre l'architecture à 7 objets interconnectés
- ✅ Différencier Machines (CRD ClusterAPI) et Nodes (objet K8s)
- ✅ Accéder au workload cluster avec kubeconfig
- ✅ Diagnostiquer pourquoi les nodes sont NotReady (CNI manquant)
- ✅ Scaler les workers avec `kubectl scale`

---

**Module 01 complété ! 🎉**
**Temps écoulé :** 25/90 minutes (10+15)
**Prochaine étape :** Module 02 - Networking avec Calico