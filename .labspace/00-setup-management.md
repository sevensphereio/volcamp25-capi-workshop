# Module 00-setup: Installation du Cluster de Management

**Durée:** 15 minutes
**Objectif:** Créer le cluster de management kind et installer tous les composants ClusterAPI nécessaires

---

## 📑 Table des Matières

- [🎯 Objectifs & Concepts](#-objectifs--concepts)
- [📋 Actions Pas-à-Pas](#-actions-pas-à-pas)
- [💡 Comprendre en Profondeur](#-comprendre-en-profondeur)

---

## 🎯 Objectifs & Concepts

### Ce que vous allez apprendre

✅ Créer un cluster de management kind configuré pour ClusterAPI
✅ Initialiser ClusterAPI avec le provider Docker (CAPD)
✅ Comprendre l'architecture Management vs Workload clusters

### Le Principe : Management Cluster = Usine à Clusters

**Analogie :** Le cluster de management est comme une **usine automobile**. L'usine elle-même ne transporte pas de passagers, mais elle fabrique des voitures (workload clusters) qui le font.

```
Management Cluster (kind)
├── ClusterAPI Controllers     → Chefs d'atelier (orchestrent la fabrication)
└── Docker Provider            → Chaîne d'assemblage Docker

Produit → Workload Clusters
├── dev-cluster (Docker)       → Voiture de développement
├── k0s-demo-cluster           → Voiture électrique (plus économe, provider installé plus tard)
└── multi-clusters             → Flotte de véhicules
```

**Pourquoi séparer Management et Workload ?**
- **Sécurité** : Le control plane de la fabrique est isolé des applications
- **Stabilité** : Un workload cluster crashé n'affecte pas les autres
- **Scalabilité** : 1 management cluster peut gérer 100+ workload clusters
- **Opérations** : Upgrades, backups simplifiés (1 seul point de contrôle)

---

### Les 2 Composants Essentiels

#### 1️⃣ ClusterAPI Core (CAPI)

**Rôle :** Framework central pour la gestion déclarative de clusters Kubernetes

**Composants installés :**
- `capi-controller-manager` : Orchestrateur principal (Cluster, Machine CRDs)
- `capi-kubeadm-bootstrap-controller` : Bootstrap nodes avec kubeadm
- `capi-kubeadm-control-plane-controller` : Gestion control planes HA

**Version :** v1.10.6

---

#### 2️⃣ Docker Provider (CAPD)

**Rôle :** Provider d'infrastructure pour créer des clusters locaux avec Docker

**Pourquoi Docker Provider ?**
- **Vitesse** : Clusters en 2-3 minutes (vs 8-10min avec cloud VMs)
- **Coût zéro** : Pas de facture AWS/Azure
- **Idéal pour** : Développement, CI/CD, formation, testing

**Composant installé :**
- `capd-controller-manager` : Crée containers Docker simulant des VMs

**Version :** v1.10.6 (fixée pour cohérence)

**⚠️ Production :** Remplacer par CAPA (AWS), CAPZ (Azure), CAPG (GCP)

**Note :** Les autres providers (k0smotron, Helm Addon) seront installés plus tard, dans les modules où ils sont utilisés.

---

## 📋 Actions Pas-à-Pas

> **💡 Raccourci :** Pour un setup automatisé complet, utilisez `./setup.sh` qui exécute toutes les étapes ci-dessous. Pour une compréhension détaillée, suivez les étapes manuelles.

### Étape 1 : Vérifier que les outils sont installés

**Objectif :** Confirmer que Docker, kind, kubectl, clusterctl, helm sont disponibles

**Commande :**
```bash
cd /home/volcampdev/workshop-express/00-setup-management
chmod +x verify-tools.sh
./verify-tools.sh
```

**Explication :**
- Script bash qui teste chaque outil requis
- `command -v` : Vérifie si la commande existe dans PATH
- Affiche la version pour confirmation

**Résultat attendu :**
```
🔍 Vérification des outils...
✅ docker: Docker version 27.4.0
✅ kind: kind v0.30.0
✅ kubectl: Client Version: v1.32.0
✅ clusterctl: v1.10.6
✅ helm: v3.19.0

✅ Tous les outils sont prêts!
```

**❌ Si un outil manque :** Retourner au Module 00-introduction pour l'installer

---

### Étape 2 : Créer le cluster de management avec kind

**Objectif :** Créer un cluster Kubernetes local qui hébergera ClusterAPI

**Commande :**
```bash
kind create cluster --config management-cluster-config.yaml
```

**Fichier de configuration :** Le fichier `management-cluster-config.yaml` est disponible dans le répertoire du module.

**Explication de la configuration :**

**1. Nom du cluster :**
```yaml
name: capi-management
```
- Identifie le cluster (contexte kubectl sera `kind-capi-management`)

**2. Montage socket Docker :**
```yaml
extraMounts:
  - hostPath: /var/run/docker.sock
    containerPath: /var/run/docker.sock
```
- **ESSENTIEL** : Monte la socket Docker de l'hôte dans le container kind
- Permet au Docker Provider (CAPD) de créer des containers pour les workload clusters
- Sans cela, CAPD ne peut pas communiquer avec le daemon Docker

**3. Port mapping 30080 :**
```yaml
extraPortMappings:
  - containerPort: 30080
    hostPort: 30080
```
- Expose le port 30080 du container kind vers localhost
- Nécessaire pour tester les applications déployées (nginx, etc.)
- Dans les modules suivants, vous accéderez à http://localhost:30080

**4. Labels du node :**
```yaml
node-labels: "ingress-ready=true"
```
- Marque le node comme prêt pour ingress controllers
- Utilisé par les applications avec LoadBalancer/Ingress

**5. Authorization mode :**
```yaml
authorization-mode: "Webhook"
```
- Active les webhooks d'admission
- Requis par cert-manager et autres controllers avancés

**Résultat attendu :**
```
Creating cluster "capi-management" ...
 ✓ Ensuring node image (kindest/node:v1.32.0)
 ✓ Preparing nodes
 ✓ Writing configuration
 ✓ Starting control-plane
 ✓ Installing CNI
 ✓ Installing StorageClass
Set kubectl context to "kind-capi-management"
You can now use your cluster with:

kubectl cluster-info --context kind-capi-management
```

**✅ Vérification :**
```bash
kubectl cluster-info --context kind-capi-management
kubectl get nodes
```

Vous devriez voir :
```
NAME                            STATUS   ROLES           AGE   VERSION
capi-management-control-plane   Ready    control-plane   1m    v1.32.0
```

---

### Étape 3 : Initialiser ClusterAPI avec le Docker Provider

**Objectif :** Installer les controllers ClusterAPI dans le management cluster

**Commande :**
```bash
export CLUSTER_TOPOLOGY=true
export EXP_CLUSTER_RESOURCE_SET=true
clusterctl init --infrastructure docker:v1.10.6
```

**Explication de la commande :**
- `export CLUSTER_TOPOLOGY=true` : Active la feature gate Cluster Topology (ClusterClass)
- `export EXP_CLUSTER_RESOURCE_SET=true` : Active la feature gate ClusterResourceSet (installation automatique d'addons)
- `clusterctl init` : Commande d'initialisation ClusterAPI
- `--infrastructure docker:v1.10.6` : Spécifie le provider (CAPD) avec version fixe v1.10.6
- Installe automatiquement :
  - ClusterAPI Core v1.10.6
  - Kubeadm Bootstrap Provider v1.10.6
  - Kubeadm Control Plane Provider v1.10.6
  - Docker Infrastructure Provider v1.10.6
  - cert-manager (dépendance requise)

**Résultat attendu :**
```
Fetching providers
Installing cert-manager Version="v1.18.2"
Waiting for cert-manager to be available...
Installing Provider="cluster-api" Version="v1.10.6" TargetNamespace="capi-system"
Installing Provider="bootstrap-kubeadm" Version="v1.10.6" TargetNamespace="capi-kubeadm-bootstrap-system"
Installing Provider="control-plane-kubeadm" Version="v1.10.6" TargetNamespace="capi-kubeadm-control-plane-system"
Installing Provider="infrastructure-docker" Version="v1.10.6" TargetNamespace="capd-system"

Your management cluster has been initialized successfully!

You can now create your first workload cluster by running the following:

  clusterctl generate cluster [name] --infrastructure docker | kubectl apply -f -
```

**⏳ Temps d'installation :** 1-2 minutes

**✅ Vérification :**
```bash
kubectl get pods -A | grep -E "(capi|cert-manager)"
```

**Résultat attendu :**
```
NAMESPACE                          NAME                                                            READY   STATUS
cert-manager                       cert-manager-xxx                                                1/1     Running
cert-manager                       cert-manager-cainjector-xxx                                     1/1     Running
cert-manager                       cert-manager-webhook-xxx                                        1/1     Running
capi-kubeadm-bootstrap-system      capi-kubeadm-bootstrap-controller-manager-xxx                   1/1     Running
capi-kubeadm-control-plane-system  capi-kubeadm-control-plane-controller-manager-xxx               1/1     Running
capi-system                        capi-controller-manager-xxx                                     1/1     Running
capd-system                        capd-controller-manager-xxx                                     1/1     Running
```

**🔍 5 namespaces créés = 5 controllers** :
1. **cert-manager** : Gestion automatique certificats TLS
2. **capi-system** : Controller principal ClusterAPI
3. **capi-kubeadm-bootstrap-system** : Bootstrap nodes avec kubeadm
4. **capi-kubeadm-control-plane-system** : Gestion control planes
5. **capd-system** : Docker infrastructure provider

---

### Étape 4 : Vérifier le montage de la socket Docker

**Objectif :** Confirmer que CAPD peut communiquer avec Docker pour créer des workload clusters

**Commande :**
```bash
./verify-docker-socket.sh
```

**Résultat attendu :**
```
🔍 Vérification du montage de la socket Docker
===============================================

✅ Cluster kind 'capi-management' existe

🔧 Test d'accès à la socket Docker depuis le cluster kind...

✅ Socket Docker est montée et accessible: /var/run/docker.sock
   Permissions: srw-rw---- root docker

🐳 Test de connectivité Docker depuis le cluster kind...

✅ Communication avec Docker Daemon réussie
   Containers visibles: 2

🎛️  Vérification CAPD Controller...

✅ Namespace capd-system existe
✅ CAPD Controller est Running (1/1)

   Vérification des logs CAPD pour erreurs Docker...
   ✅ Aucune erreur Docker dans les logs CAPD

===============================================
🎉 Vérification terminée avec succès!

📊 Résumé:
  ✅ Socket Docker montée: /var/run/docker.sock
  ✅ Communication Docker fonctionnelle
  ✅ CAPD peut créer des containers pour workload clusters

🚀 Le cluster de management est prêt à créer des workload clusters!
```

---

### Étape 5 : Vérification finale complète

**Objectif :** Confirmer que tous les composants sont opérationnels

**Commande :**
```bash
./validation.sh
```

**Résultat attendu :**
```
🔍 Module 00-setup: Validation Cluster de Management
====================================================

✅ Cluster de management kind existe: capi-management
✅ Contexte kubectl correctement configuré: kind-capi-management
✅ ClusterAPI Core installé (capi-system)
✅ Docker Provider installé (capd-system)
✅ cert-manager opérationnel
✅ Tous les pods sont Running

📊 Résumé des Composants:
  ✅ ClusterAPI: v1.10.6
  ✅ Docker Provider: Opérationnel
  ✅ cert-manager: v1.18.2

====================================================
🎉 Module 00-setup terminé avec succès!
🚀 Management cluster prêt à créer des workload clusters
====================================================

Prochaine commande:
  cd ../01-premier-cluster
  cat commands.md
```

**✅ Tous les tests passent :** Votre management cluster est prêt !

---

### Étape 6 : Explorer les ressources installées

**Objectif :** Comprendre ce qui a été installé

**Commandes d'exploration :**

**6.1 - Voir tous les namespaces créés**
```bash
kubectl get namespaces | grep -E "(capi|cert-manager)"
```

**Résultat :**
```
capi-kubeadm-bootstrap-system      Active   10m
capi-kubeadm-control-plane-system  Active   10m
capi-system                        Active   10m
capd-system                        Active   10m
cert-manager                       Active   10m
```

---

**6.2 - Voir les CRDs (Custom Resource Definitions) installées**
```bash
kubectl get crds | grep cluster.x-k8s.io
```

**Résultat :**
```
clusters.cluster.x-k8s.io
dockerclusters.infrastructure.cluster.x-k8s.io
dockermachines.infrastructure.cluster.x-k8s.io
dockermachinetemplates.infrastructure.cluster.x-k8s.io
kubeadmconfigs.bootstrap.cluster.x-k8s.io
kubeadmconfigtemplates.bootstrap.cluster.x-k8s.io
kubeadmcontrolplanes.controlplane.cluster.x-k8s.io
machinedeployments.cluster.x-k8s.io
machines.cluster.x-k8s.io
...
```

**🔍 Ces CRDs sont les "types" que vous utiliserez** dans les modules suivants (Cluster, Machine, etc.)

---

**6.3 - Vérifier les versions installées**
```bash
clusterctl version
kubectl get deployment -n capi-system capi-controller-manager -o jsonpath='{.spec.template.spec.containers[0].image}'
```

**Résultat :**
```
clusterctl version: &version.Info{Major:"1", Minor:"11", GitVersion:"v1.10.6"}
registry.k8s.io/cluster-api/cluster-api-controller:v1.10.6
```

---

**6.4 - Explorer les pods de chaque composant**
```bash
kubectl get pods -n capi-system
kubectl get pods -n capd-system
kubectl get pods -n cert-manager
```

---

**6.5 - Vérifier que la socket Docker est accessible**
```bash
# Tester depuis le container kind
docker exec capi-management-control-plane docker ps

# Devrait afficher tous les containers Docker de l'hôte
```

---

## 🎓 Points Clés à Retenir

✅ **Management Cluster** : Usine à clusters, héberge les controllers ClusterAPI
✅ **ClusterAPI Core** : Framework déclaratif (Cluster, Machine CRDs)
✅ **Docker Provider** : Infrastructure locale rapide (dev/test)
✅ **cert-manager** : Gestion automatique certificats (dépendance CAPI)
✅ **Autres providers** : k0smotron et Helm Addon seront installés dans les modules suivants

### Architecture Récapitulative

```
Management Cluster (kind)
│
├── ClusterAPI Core (capi-system)
│   ├── cluster-controller      → Gère objets Cluster
│   ├── machine-controller      → Gère objets Machine
│   └── machinedeployment-controller → Gère scaling workers
│
├── Bootstrap Provider (capi-kubeadm-bootstrap-system)
│   └── kubeadm-bootstrap-controller → Configure nodes avec kubeadm
│
├── Control Plane Provider (capi-kubeadm-control-plane-system)
│   └── kubeadmcontrolplane-controller → Gère control planes HA
│
├── Infrastructure Provider
│   └── Docker Provider (capd-system) → Crée containers
│
└── Dependencies
    └── cert-manager → Certificats TLS automatiques
```

---

## ⏭️ Prochaine Étape

Management cluster ✅ prêt, passez au **Module 01** :

```bash
cd ../01-premier-cluster
cat commands.md
```

**Module 01 :** Créer votre premier workload cluster avec Docker Provider

---

## 💡 Comprendre en Profondeur

> **Note :** Cette section approfondit les concepts techniques. Vous pouvez la sauter et y revenir plus tard.

### Pourquoi kind pour le Management Cluster ?

**kind (Kubernetes IN Docker)** est le choix idéal pour workshops/dev car :

**Avantages :**
- **Setup rapide** : < 1 minute vs 10-15min cloud clusters
- **Coût zéro** : Pas de facture AWS/Azure
- **Reproductible** : Configuration identique sur tous les laptops
- **Cleanup facile** : `kind delete cluster` = tout supprimé
- **CI/CD friendly** : Parfait pour pipelines automatisés

**Limitations (production) :**
- Pas de persistance réelle (tout en RAM/disk local)
- Pas de HA multi-nodes physiques
- Pas de load balancing cloud
- Limité par ressources de la machine hôte

**Production Management Cluster :**
```
Environment          Recommendation
────────────────────────────────────
Dev/Test            → kind
CI/CD               → kind ou EKS/GKE
Staging             → EKS, AKS, GKE (HA)
Production          → EKS, AKS, GKE (HA + backup)
```

---

### Anatomie d'un Cluster kind

**Quand vous exécutez `kind create cluster` :**

```bash
docker ps
```

Vous voyez :
```
CONTAINER ID   IMAGE                  NAMES
abc123def456   kindest/node:v1.32.0   capi-management-control-plane
```

**Ce container contient un Kubernetes COMPLET :**
- **Control Plane** : API server, etcd, scheduler, controller-manager
- **Kubelet** : Agent node
- **Container Runtime** : containerd
- **CNI** : kindnet (réseau pod)

**Structure interne :**
```
Container kind (Docker)
├── systemd (init system)
├── containerd (runtime pour pods)
├── kubelet (agent Kubernetes)
└── Static Pods (dans /etc/kubernetes/manifests/)
    ├── kube-apiserver
    ├── kube-controller-manager
    ├── kube-scheduler
    └── etcd
```

**Socket Docker Montée - Architecture Critique :**
```yaml
extraMounts:
  - hostPath: /var/run/docker.sock
    containerPath: /var/run/docker.sock
```

**Pourquoi c'est ESSENTIEL :**
```
Host Machine
├── Docker Daemon (dockerd)
│   └── Socket: /var/run/docker.sock
│
├── Container kind (management cluster)
│   ├── Socket montée: /var/run/docker.sock → (partagée avec host)
│   └── Pod CAPD Controller
│       └── Utilise la socket pour créer containers (workload cluster nodes)
│
└── Containers créés par CAPD (workload clusters)
    ├── dev-cluster-control-plane-xxx
    ├── dev-cluster-worker-xxx
    └── k0s-demo-cluster-worker-xxx
```

**Flow de création d'un workload cluster :**
```
1. User: kubectl apply -f dev-cluster.yaml
   ↓
2. CAPI Controller (dans kind): Détecte nouveau Cluster
   ↓
3. CAPD Controller (dans kind): Reçoit DockerMachine à créer
   ↓
4. CAPD utilise /var/run/docker.sock pour communiquer avec Docker host
   ↓
5. Docker Daemon (host): Crée containers (nodes du workload cluster)
   ↓
6. Containers créés: Apparaissent dans `docker ps` sur le host
```

**Sans le montage de la socket :**
- CAPD ne peut pas créer de containers
- Les machines restent en "Provisioning" indéfiniment
- Erreur: "Cannot connect to Docker daemon"

---

**Port Mapping Expliqué :**
```yaml
extraPortMappings:
  - containerPort: 30080
    hostPort: 30080
```

**Flow de trafic :**
```
Browser (localhost:30080)
    ↓
Docker Host (port 30080)
    ↓
kind Container (port 30080)
    ↓
Service NodePort (port 30080)
    ↓
Pod Application (port 80)
```

---

### ClusterAPI Init : Que se passe-t-il ?

**Commande :**
```bash
clusterctl init --infrastructure docker
```

**Workflow détaillé :**

**1. Vérification prérequis (T+0s)**
```
clusterctl vérifie:
✓ kubectl accessible
✓ Cluster Kubernetes détecté (management cluster)
✓ Permissions suffisantes (cluster-admin)
```

**2. Installation cert-manager (T+5s)**
```
Why cert-manager first?
→ ClusterAPI utilise webhooks (admission, conversion)
→ Webhooks nécessitent certificats TLS
→ cert-manager génère/renouvelle automatiquement les certs

Installation:
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.18.2/cert-manager.yaml
```

**3. Installation ClusterAPI Core (T+30s)**
```
Namespace: capi-system
Deployment: capi-controller-manager

Controllers inclus:
- Cluster controller (gère Cluster CRD)
- Machine controller (gère Machine CRD)
- MachineSet controller (gère réplication)
- MachineDeployment controller (gère scaling/updates)
- ClusterResourceSet controller (gère addons)
```

**4. Installation Bootstrap Provider (T+45s)**
```
Namespace: capi-kubeadm-bootstrap-system
Deployment: capi-kubeadm-bootstrap-controller-manager

Rôle:
- Génère cloud-init scripts pour nodes
- Configure kubeadm init/join automatiquement
- Injecte certificats et tokens
```

**5. Installation Control Plane Provider (T+60s)**
```
Namespace: capi-kubeadm-control-plane-system
Deployment: capi-kubeadm-control-plane-controller-manager

Rôle:
- Gère KubeadmControlPlane CRD
- Automatise HA control planes
- Rolling upgrades control planes
- Gestion quorum etcd
```

**6. Installation Docker Provider (T+75s)**
```
Namespace: capd-system
Deployment: capd-controller-manager

Rôle:
- Crée containers Docker pour simuler VMs
- Configure réseau Docker entre containers
- Gère DockerCluster, DockerMachine CRDs
```

**Vérification finale :**
```bash
kubectl get pods -A | grep -E "(capi|cert)"
```

**Tous les pods doivent être Running (STATUS) et READY (1/1 ou 2/2)**

---


### cert-manager : Pourquoi Indispensable ?

**ClusterAPI utilise des Webhooks Kubernetes :**

**1. Validating Webhooks** : Valident les objets avant création
```yaml
Exemple: Création d'un Cluster
User: kubectl apply -f cluster.yaml
    ↓
API Server: Appelle Validating Webhook
    ↓
ClusterAPI Controller: Vérifie
  ✓ clusterNetwork.pods.cidrBlocks valide
  ✓ controlPlaneRef existe
  ✓ infrastructureRef existe
    ↓
API Server: Accepte ou rejette
```

**2. Mutating Webhooks** : Modifient les objets automatiquement
```yaml
Exemple: Création d'une Machine
User: kubectl apply -f machine.yaml (sans spec.version)
    ↓
API Server: Appelle Mutating Webhook
    ↓
ClusterAPI Controller: Injecte automatiquement
  spec.version: v1.32.8 (depuis Cluster parent)
    ↓
Objet modifié sauvegardé
```

**3. Conversion Webhooks** : Convertissent entre versions API
```yaml
Manifest ancien: apiVersion: cluster.x-k8s.io/v1alpha3
    ↓
Conversion Webhook: Convertit v1alpha3 → v1beta1
    ↓
Stored version: v1beta1
```

**Webhooks NÉCESSITENT TLS :**
- API server communique avec webhooks via HTTPS
- Sans certificats valides = erreur webhook call failed

**cert-manager automatise :**
```
1. Génère CA (Certificate Authority) privée
2. Crée certificats pour chaque webhook
3. Injecte caBundle dans webhook configurations
4. Renouvelle automatiquement avant expiration (90 jours)
```

**Sans cert-manager :**
```bash
# Génération manuelle (complexe, erreur-prone)
openssl genrsa -out ca.key 2048
openssl req -x509 -new -nodes -key ca.key -subj "/CN=webhook-ca" -days 3650 -out ca.crt
openssl genrsa -out webhook.key 2048
openssl req -new -key webhook.key -subj "/CN=webhook.capi-system.svc" -out webhook.csr
openssl x509 -req -in webhook.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out webhook.crt -days 365
kubectl create secret tls webhook-cert --cert=webhook.crt --key=webhook.key -n capi-system
# ... répéter pour chaque webhook
# ... renouvellement manuel tous les ans
```

**Avec cert-manager :**
```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: capi-webhook-cert
spec:
  secretName: capi-webhook-cert
  duration: 8760h  # 1 an
  renewBefore: 720h  # Renouveler 30 jours avant
  issuerRef:
    name: capi-selfsigned-issuer
    kind: Issuer
  dnsNames:
    - webhook.capi-system.svc
    - webhook.capi-system.svc.cluster.local
```

**Résultat :** Automatisé, sécurisé, sans intervention humaine.

---

## 🔧 Dépannage

### Socket Docker Non Montée

**Symptôme :** Dans les modules suivants, les workload clusters ne se créent pas (machines restent en Provisioning)

**Cause :** Socket Docker (`/var/run/docker.sock`) non montée dans le cluster kind

**Diagnostic :**
```bash
# Vérifier si la socket est accessible depuis le cluster kind
docker exec capi-management-control-plane ls -la /var/run/docker.sock

# Vérifier que les pods CAPD peuvent communiquer avec Docker
kubectl logs -n capd-system deployment/capd-controller-manager | grep -i "docker"
```

**Solution :**
```bash
# Recréer le cluster avec la socket Docker montée
kind delete cluster --name capi-management

# Le fichier management-cluster-config.yaml est dans le répertoire du module
kind create cluster --config management-cluster-config.yaml
export CLUSTER_TOPOLOGY=true
export EXP_CLUSTER_RESOURCE_SET=true
clusterctl init --infrastructure docker:v1.10.6
```

**Vérification :**
```bash
# Tester l'accès Docker depuis le cluster
kubectl run -it --rm debug --image=docker:latest --restart=Never -- docker ps

# Vous devriez voir les containers Docker de l'hôte
```

---

### ClusterAPI Init Échoue

**Symptôme :** `clusterctl init` timeout ou erreur

**Diagnostic :**
```bash
# Vérifier permissions kubectl
kubectl auth can-i create namespaces
kubectl auth can-i create crds

# Vérifier connexion internet (téléchargement manifests)
curl -I https://github.com

# Logs de clusterctl
clusterctl init --infrastructure docker -v 5  # Verbosity max
```

**Solutions :**
```bash
# Permissions insuffisantes
kubectl config view --minify  # Vérifier le contexte actuel
# Utiliser admin kubeconfig ou accorder cluster-admin

# Network issues
# Utiliser --config pour spécifier mirrors locaux
clusterctl init --infrastructure docker --config clusterctl.yaml

# Retry avec cleanup
clusterctl delete --infrastructure docker --include-crd
export CLUSTER_TOPOLOGY=true
export EXP_CLUSTER_RESOURCE_SET=true
clusterctl init --infrastructure docker:v1.10.6
```

---


## 📊 Validation Complète

### Checklist Finale

**Management Cluster :**
- [ ] Cluster kind "capi-management" existe
- [ ] Contexte kubectl configuré: `kind-capi-management`
- [ ] Node status: Ready

**ClusterAPI Core :**
- [ ] Namespace `capi-system` existe
- [ ] Deployment `capi-controller-manager` : Running
- [ ] CRDs installées : `kubectl get crd | grep cluster.x-k8s.io` montre 20+ CRDs

**Providers :**
- [ ] Docker Provider (capd-system) : Running

**Dependencies :**
- [ ] cert-manager pods : Running (3/3)

**Commande Unique de Validation :**
```bash
# Le script full-check.sh est disponible dans le répertoire du module
chmod +x full-check.sh
./full-check.sh
```

---

## 🎓 Ce Que Vous Avez Appris

✅ Créer un cluster kind configuré pour ClusterAPI
✅ Initialiser ClusterAPI avec le Docker Provider
✅ Comprendre l'architecture Management vs Workload
✅ Valider l'installation complète des composants

**Architecture Finale :**
```
Management Cluster (kind) ✅
├── ClusterAPI v1.10.6 ✅
├── Docker Provider ✅
└── cert-manager v1.18.2 ✅

Prêt à créer → Workload Clusters!
(k0smotron et Helm Addon seront installés dans les modules suivants)
```

---

**Module 00-setup complété ! 🎉**
**Temps écoulé :** 15 minutes
**Prochaine étape :** Module 01 - Premier Cluster avec Docker Provider
