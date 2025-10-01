# Glossaire ClusterAPI - Workshop Express

**Guide de référence rapide pour tous les termes techniques du workshop**

---

## A

### API Server
**Définition :** Composant central du control plane Kubernetes qui expose l'API REST.
**Analogie :** C'est la réception d'un hôtel - toutes les demandes passent par là.
**Dans le workshop :** L'API server permet à kubectl de communiquer avec le cluster.

### Addon
**Définition :** Composant optionnel ajouté à Kubernetes pour étendre ses fonctionnalités.
**Exemples :** CNI (Calico), CSI (drivers storage), DNS, Monitoring.
**Dans le workshop :** Nous installons Calico CNI et nginx comme addons.

---

## C

### CNI (Container Network Interface)
**Définition :** Plugin qui gère le réseau des pods (attribution IP, routage).
**Pourquoi c'est critique :** Sans CNI, les pods ne peuvent pas communiquer → nodes NotReady.
**Exemples :** Calico, Flannel, Cilium, Weave.
**Dans le workshop :** Nous installons Calico pour permettre la communication réseau.

### Cluster
**Définition :** Ensemble de machines (nodes) qui exécutent des applications conteneurisées.
**Composants :** Control plane (cerveau) + Nodes workers (muscles).
**Dans le workshop :** Nous créons 2 clusters : dev-cluster et k0s-demo-cluster.

### ClusterAPI (CAPI)
**Définition :** Projet Kubernetes pour gérer le lifecycle de clusters de façon déclarative.
**Principe :** "Kubernetes pour gérer Kubernetes" - créer des clusters avec des fichiers YAML.
**Dans le workshop :** C'est l'outil principal que nous utilisons pour créer et gérer nos clusters.

### ClusterResourceSet (CRS)
**Définition :** Mécanisme ClusterAPI pour déployer automatiquement des ressources sur les workload clusters.
**Analogie :** Système d'installation automatique d'apps (comme iCloud pour iPhone).
**Dans le workshop :** Nous l'utilisons pour installer automatiquement Calico sur nos clusters.

### clusterctl
**Définition :** Outil CLI pour gérer ClusterAPI (installation, upgrade, récupération kubeconfig).
**Commandes clés :** `clusterctl init`, `clusterctl get kubeconfig`.
**Dans le workshop :** Nous l'utilisons pour récupérer les kubeconfigs des clusters créés.

### ConfigMap
**Définition :** Objet Kubernetes pour stocker des données de configuration non sensibles.
**Format :** Paires clé-valeur ou fichiers entiers.
**Dans le workshop :** Nous stockons le manifeste Calico dans un ConfigMap pour le CRS.

### Control Plane
**Définition :** Ensemble des composants qui gèrent le cluster (API server, etcd, scheduler, controller-manager).
**Analogie :** Le cerveau du cluster - prend toutes les décisions.
**Dans le workshop :** Nous créons des control planes traditionnels (nodes) et virtuels (pods k0smotron).

### CRD (Custom Resource Definition)
**Définition :** Extension de l'API Kubernetes pour créer de nouveaux types d'objets.
**Dans le workshop :** Cluster, Machine, ClusterResourceSet sont des CRDs créés par ClusterAPI.

---

## D

### DaemonSet
**Définition :** Contrôleur Kubernetes qui garantit qu'un pod tourne sur chaque node.
**Cas d'usage :** Monitoring, logging, CNI agents.
**Dans le workshop :** calico-node est déployé comme DaemonSet (1 pod par node).

### Declarative (Déclaratif)
**Définition :** Approche où vous déclarez l'état désiré, et le système s'en occupe.
**Opposé :** Impératif (vous donnez des commandes séquentielles).
**Dans le workshop :** Nous déclarons nos clusters en YAML, ClusterAPI les crée automatiquement.

### Deployment
**Définition :** Contrôleur Kubernetes pour gérer des pods (scaling, rolling updates, self-healing).
**Dans le workshop :** calico-kube-controllers est un Deployment avec 1 replica.

---

## E

### etcd
**Définition :** Base de données clé-valeur distribuée qui stocke l'état du cluster.
**Importance :** Perte d'etcd = perte du cluster entier.
**Dans le workshop :** etcd tourne dans le control plane (node ou pod k0smotron).

---

## G

### GitOps
**Définition :** Pratique de gérer l'infrastructure et les applications via Git (source de vérité).
**Workflow :** Git commit → Outil détecte → Applique automatiquement.
**Dans le workshop :** ClusterResourceSet et HelmChartProxy suivent ce pattern.

---

## H

### HA (High Availability / Haute Disponibilité)
**Définition :** Architecture qui tolère les pannes sans interruption de service.
**Pour K8s :** 3 ou 5 control plane nodes (quorum etcd).
**Dans le workshop :** dev-cluster a 1 CP (pas HA), k0s-demo-cluster a 3 CP pods (HA).

### Helm
**Définition :** Gestionnaire de packages pour Kubernetes (comme apt/yum).
**Concepts :** Chart (package), Release (déploiement d'un chart).
**Dans le workshop :** Nous utilisons HelmChartProxy pour déployer nginx automatiquement.

### HelmChartProxy
**Définition :** CRD du Helm Addon Provider pour déployer un chart Helm sur plusieurs clusters.
**Avantage :** 1 manifest → déploiement multi-cluster automatique via labels.
**Dans le workshop :** Nous déployons nginx sur tous les clusters avec label `environment=demo`.

---

## I

### Infrastructure Provider
**Définition :** Plugin ClusterAPI qui traduit les actions vers un provider spécifique (AWS, Azure, Docker, etc.).
**Dans le workshop :** Nous utilisons Docker Provider (CAPD) pour créer des clusters localement.

---

## K

### kind (Kubernetes IN Docker)
**Définition :** Outil pour exécuter des clusters Kubernetes dans des containers Docker.
**Usage :** Dev local, CI/CD, testing.
**Dans le workshop :** Notre management cluster tourne sur kind.

### k0s
**Définition :** Distribution Kubernetes légère avec tout embarqué dans un seul binaire.
**Avantages :** Simple, rapide, minimal.
**Dans le workshop :** k0smotron utilise k0s pour les control planes virtuels.

### k0smotron
**Définition :** Extension ClusterAPI qui virtualise les control planes (pods au lieu de nodes).
**Innovation :** Économie de 55% de ressources, boot 3x plus rapide.
**Dans le workshop :** Nous créons k0s-demo-cluster avec des CP virtuels.

### kubeadm
**Définition :** Outil officiel pour bootstrapper des clusters Kubernetes.
**Commandes :** `kubeadm init` (créer CP), `kubeadm join` (joindre nodes).
**Dans le workshop :** ClusterAPI utilise kubeadm en arrière-plan pour dev-cluster.

### kubeconfig
**Définition :** Fichier de configuration avec les credentials pour accéder à un cluster.
**Contenu :** API server URL, certificats, contextes.
**Dans le workshop :** Nous récupérons les kubeconfigs avec `clusterctl get kubeconfig`.

### kubectl
**Définition :** Outil CLI pour interagir avec les clusters Kubernetes.
**Fonction :** Envoie des requêtes HTTP REST à l'API server.
**Dans le workshop :** Nous l'utilisons pour toutes les opérations sur les clusters.

### KubeadmControlPlane
**Définition :** CRD ClusterAPI pour définir le control plane avec kubeadm.
**Paramètres :** replicas, version, configuration kubeadm.
**Dans le workshop :** Utilisé pour dev-cluster (Docker provider).

### Kubelet
**Définition :** Agent qui tourne sur chaque node et gère les pods.
**Rôle :** Exécuter les pods, surveiller leur santé, reporter à l'API server.
**Dans le workshop :** Kubelet déclare les nodes NotReady si le CNI manque.

---

## M

### Machine
**Définition :** CRD ClusterAPI représentant un node Kubernetes.
**Lifecycle :** Pending → Provisioning → Running → Deleting.
**Dans le workshop :** Chaque Machine devient un container Docker (node du cluster).

### MachineDeployment
**Définition :** CRD ClusterAPI pour gérer les worker nodes (comme un Deployment pour pods).
**Fonctionnalités :** Scaling, rolling updates, self-healing.
**Dans le workshop :** Nous l'utilisons pour créer 2 workers, puis scaler à 4.

### Management Cluster
**Définition :** Cluster Kubernetes qui héberge ClusterAPI et gère les workload clusters.
**Analogie :** Le chef d'orchestre qui dirige mais ne joue pas d'instrument.
**Dans le workshop :** Notre cluster kind qui crée dev-cluster et k0s-demo-cluster.

---

## N

### Namespace
**Définition :** Isolation logique dans Kubernetes (comme des dossiers).
**Exemples :** default, kube-system, capi-system.
**Dans le workshop :** Les controllers ClusterAPI tournent dans capi-system.

### Node
**Définition :** Machine (physique ou virtuelle) qui exécute des pods.
**Types :** Control plane nodes (gestion), Worker nodes (apps).
**Dans le workshop :** Chaque container Docker devient un node dans nos clusters.

---

## P

### Pod
**Définition :** Plus petite unité déployable dans Kubernetes (1+ containers).
**Caractéristiques :** IP unique, stockage partagé, lifecycle éphémère.
**Dans le workshop :** Calico, CoreDNS, nginx tournent dans des pods.

### Provider
**Définition :** Composant qui adapte ClusterAPI à une infrastructure spécifique.
**Catégories :** Infrastructure (AWS, Azure, Docker), Bootstrap (kubeadm, k0s), Control Plane.
**Dans le workshop :** Nous utilisons Docker Provider + k0smotron.

---

## R

### Reconciliation Loop
**Définition :** Boucle continue qui compare l'état actuel à l'état désiré et corrige les différences.
**Fréquence :** Toutes les ~10 secondes pour les controllers K8s.
**Dans le workshop :** ClusterAPI controllers surveillent et créent les clusters automatiquement.

### Replica
**Définition :** Copie identique d'un pod ou node pour HA et scaling.
**Exemples :** 3 control plane replicas, 2 worker replicas.
**Dans le workshop :** MachineDeployment avec replicas: 2 crée 2 workers.

---

## S

### Scheduler
**Définition :** Composant du control plane qui décide sur quel node placer les pods.
**Critères :** Ressources disponibles, affinités, contraintes.
**Dans le workshop :** kube-scheduler tourne dans le control plane.

### Service
**Définition :** Objet Kubernetes qui expose des pods via une IP stable.
**Types :** ClusterIP, NodePort, LoadBalancer.
**Dans le workshop :** k0smotron expose l'API server via un Service NodePort.

---

## W

### Workload Cluster
**Définition :** Cluster Kubernetes créé et géré par ClusterAPI pour exécuter vos applications.
**Analogie :** Les avions qui transportent les passagers (vs aéroport = management).
**Dans le workshop :** dev-cluster et k0s-demo-cluster sont des workload clusters.

### Worker Node
**Définition :** Node qui exécute les applications (pods) mais pas le control plane.
**Rôle :** Fournir CPU/RAM/storage aux pods.
**Dans le workshop :** Nous créons 2 workers, puis les scalons à 4.

---

## Y

### YAML
**Définition :** Format de fichier pour décrire des objets Kubernetes de façon lisible.
**Structure :** Hiérarchique avec indentation (espaces, pas tabs).
**Dans le workshop :** Tous nos clusters et addons sont définis en YAML.

---

## Symboles et Acronymes Courants

| Acronyme | Signification | Définition |
|----------|---------------|------------|
| **CAPI** | Cluster API | ClusterAPI |
| **CAPD** | Cluster API Provider Docker | Provider Docker pour ClusterAPI |
| **CAPA** | Cluster API Provider AWS | Provider AWS pour ClusterAPI |
| **CNI** | Container Network Interface | Plugin réseau pour les pods |
| **CP** | Control Plane | Composants de gestion du cluster |
| **CRD** | Custom Resource Definition | Extension de l'API Kubernetes |
| **CRS** | ClusterResourceSet | Déploiement automatique d'addons |
| **HA** | High Availability | Haute disponibilité |
| **k8s** | Kubernetes | (8 lettres entre k et s) |
| **LB** | Load Balancer | Répartiteur de charge |

---

## Conventions de Nommage dans le Workshop

| Nom | Signification |
|-----|---------------|
| **dev-cluster** | Cluster de démonstration avec Docker Provider |
| **k0s-demo-cluster** | Cluster de démonstration avec k0smotron |
| **capi-management** | Notre management cluster (kind) |
| **calico-cni** | ClusterResourceSet pour installer Calico |
| **nginx-demo** | HelmChartProxy pour déployer nginx |

---

## Ressources Externes

- [ClusterAPI Documentation](https://cluster-api.sigs.k8s.io/)
- [k0smotron Documentation](https://docs.k0smotron.io/)
- [Kubernetes Glossary](https://kubernetes.io/docs/reference/glossary/)
- [Calico Documentation](https://docs.tigera.io/calico/latest/)

---

**Conseil :** Gardez ce glossaire ouvert pendant le workshop pour référence rapide !