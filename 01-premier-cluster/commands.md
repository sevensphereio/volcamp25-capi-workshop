# Module 01: Premier Cluster ClusterAPI - Commandes

**Durée:** 15 minutes
**Objectif:** Créer votre premier cluster Kubernetes avec ClusterAPI Docker provider

---

## 📖 Partie 1: Explication du Manifeste (3 minutes)

### Explorer le manifeste dev-cluster.yaml

```bash
cd /home/ubuntu/R_D/CLAUDE_PROJECTS/capi-workshop/workshop-express/01-premier-cluster
cat dev-cluster.yaml
```

Le manifeste contient **7 objets ClusterAPI:**

### 1. Cluster (L1-18)
```yaml
apiVersion: cluster.x-k8s.io/v1beta1
kind: Cluster
metadata:
  name: dev-cluster
spec:
  clusterNetwork:
    pods:
      cidrBlocks: ["192.168.0.0/16"]  # Network pour les pods
  controlPlaneRef:
    kind: KubeadmControlPlane          # Référence au control plane
  infrastructureRef:
    kind: DockerCluster                 # Provider infrastructure
```

**Rôle:** Définit le cluster de haut niveau

### 2. DockerCluster (L19-24)
```yaml
kind: DockerCluster
metadata:
  name: dev-cluster
spec: {}
```

**Rôle:** Configuration infrastructure spécifique Docker (load balancer, réseau)

### 3. KubeadmControlPlane (L25-52)
```yaml
kind: KubeadmControlPlane
metadata:
  name: dev-cluster-control-plane
spec:
  replicas: 1           # 1 node control plane
  version: v1.28.3      # Version Kubernetes
  machineTemplate:
    infrastructureRef:
      kind: DockerMachineTemplate
```

**Rôle:** Définit le control plane (combien de replicas, quelle version)

### 4. DockerMachineTemplate (CP) (L53-62)
```yaml
kind: DockerMachineTemplate
metadata:
  name: dev-cluster-control-plane
spec:
  template:
    spec:
      extraMounts:
        - containerPath: /var/run/docker.sock
```

**Rôle:** Template pour créer les machines control plane

### 5. MachineDeployment (L63-79)
```yaml
kind: MachineDeployment
metadata:
  name: dev-cluster-md-0
spec:
  clusterName: dev-cluster
  replicas: 2                  # 2 worker nodes
  version: v1.28.3
```

**Rôle:** Définit les workers (comme un Deployment pour les pods)

### 6. DockerMachineTemplate (Workers) (L80-89)
**Rôle:** Template pour créer les machines workers

### 7. KubeadmConfigTemplate (L90-101)
**Rôle:** Configuration Kubeadm pour bootstrapper les workers

---

## 🚀 Partie 2: Créer le Cluster (2 minutes)

### Appliquer le manifeste

```bash
kubectl apply -f dev-cluster.yaml
```

**Résultat attendu:**
```
cluster.cluster.x-k8s.io/dev-cluster created
dockercluster.infrastructure.cluster.x-k8s.io/dev-cluster created
kubeadmcontrolplane.controlplane.cluster.x-k8s.io/dev-cluster-control-plane created
dockermachinetemplate.infrastructure.cluster.x-k8s.io/dev-cluster-control-plane created
machinedeployment.cluster.x-k8s.io/dev-cluster-md-0 created
dockermachinetemplate.infrastructure.cluster.x-k8s.io/dev-cluster-md-0 created
kubeadmconfigtemplate.bootstrap.cluster.x-k8s.io/dev-cluster-md-0 created
```

**7 objets créés!** ClusterAPI va maintenant orchestrer la création du cluster.

---

## 👀 Partie 3: Observer la Création (5 minutes)

### Observer le Cluster et les Machines

```bash
watch -n 2 'kubectl get clusters,machines'
```

**Progression attendue:**

**Minute 1:**
```
NAME                                    PHASE         AGE
cluster.cluster.x-k8s.io/dev-cluster    Pending       30s

NAME                                                           CLUSTER       PHASE         AGE
machine.cluster.x-k8s.io/dev-cluster-control-plane-xxxx       dev-cluster   Provisioning  30s
machine.cluster.x-k8s.io/dev-cluster-md-0-yyyyy-zzzzz         dev-cluster   Pending       30s
machine.cluster.x-k8s.io/dev-cluster-md-0-yyyyy-aaaaa         dev-cluster   Pending       30s
```

**Minute 2:**
```
NAME                                    PHASE           AGE
cluster.cluster.x-k8s.io/dev-cluster    Provisioning    2m

NAME                                                           CLUSTER       PHASE         AGE
machine.cluster.x-k8s.io/dev-cluster-control-plane-xxxx       dev-cluster   Running       2m
machine.cluster.x-k8s.io/dev-cluster-md-0-yyyyy-zzzzz         dev-cluster   Provisioning  2m
machine.cluster.x-k8s.io/dev-cluster-md-0-yyyyy-aaaaa         dev-cluster   Provisioning  2m
```

**Minute 3:**
```
NAME                                    PHASE         AGE
cluster.cluster.x-k8s.io/dev-cluster    Provisioned   3m

NAME                                                           CLUSTER       PHASE     AGE
machine.cluster.x-k8s.io/dev-cluster-control-plane-xxxx       dev-cluster   Running   3m
machine.cluster.x-k8s.io/dev-cluster-md-0-yyyyy-zzzzz         dev-cluster   Running   3m
machine.cluster.x-k8s.io/dev-cluster-md-0-yyyyy-aaaaa         dev-cluster   Running   3m
```

**Appuyez sur Ctrl+C pour arrêter le watch.**

### Phases du Cycle de Vie

| Phase | Signification |
|-------|---------------|
| **Pending** | Objet créé, en attente de provisioning |
| **Provisioning** | Infrastructure en cours de création |
| **Running** | Machine opérationnelle |
| **Provisioned** | Cluster complet et opérationnel |

### Voir les containers Docker créés

```bash
docker ps | grep dev-cluster
```

**Résultat attendu:**
```
CONTAINER ID   IMAGE                  NAMES
xxxxxxxxxxxx   kindest/node:v1.28.3   dev-cluster-control-plane-xxxx
yyyyyyyyyyyy   kindest/node:v1.28.3   dev-cluster-md-0-yyyyy-zzzzz
zzzzzzzzzzzz   kindest/node:v1.28.3   dev-cluster-md-0-yyyyy-aaaaa
```

**3 containers Docker = 3 nodes Kubernetes!**

---

## 🔍 Partie 4: Explorer les Ressources (3 minutes)

### Détails du Cluster

```bash
kubectl get cluster dev-cluster -o yaml | grep -A 10 "^status:"
```

**Points clés:**
- `phase: Provisioned`
- `controlPlaneReady: true`
- `infrastructureReady: true`

### KubeadmControlPlane

```bash
kubectl get kubeadmcontrolplane
```

**Résultat:**
```
NAME                         CLUSTER       INITIALIZED   API SERVER   REPLICAS   READY   UPDATED
dev-cluster-control-plane    dev-cluster   true          true         1          1       1
```

### MachineDeployment

```bash
kubectl get machinedeployment
```

**Résultat:**
```
NAME                 CLUSTER       REPLICAS   READY   UPDATED   UNAVAILABLE   PHASE     AGE
dev-cluster-md-0     dev-cluster   2          2       2         0             Running   3m
```

### Machines Détaillées

```bash
kubectl get machines -o wide
```

**Résultat:**
```
NAME                                    CLUSTER       PHASE     VERSION   NODENAME
dev-cluster-control-plane-xxxx          dev-cluster   Running   v1.28.3   dev-cluster-control-plane-xxxx
dev-cluster-md-0-yyyyy-zzzzz            dev-cluster   Running   v1.28.3   dev-cluster-md-0-yyyyy-zzzzz
dev-cluster-md-0-yyyyy-aaaaa            dev-cluster   Running   v1.28.3   dev-cluster-md-0-yyyyy-aaaaa
```

---

## 🎯 Partie 5: Accéder au Cluster (2 minutes)

### Récupérer le kubeconfig

```bash
clusterctl get kubeconfig dev-cluster > dev-cluster.kubeconfig
```

**Vérification:**
```bash
ls -lh dev-cluster.kubeconfig
```

### Lister les nodes dans le workload cluster

```bash
kubectl --kubeconfig dev-cluster.kubeconfig get nodes
```

**Résultat attendu:**
```
NAME                              STATUS     ROLES           AGE   VERSION
dev-cluster-control-plane-xxxx    NotReady   control-plane   3m    v1.28.3
dev-cluster-md-0-yyyyy-zzzzz      NotReady   <none>          2m    v1.28.3
dev-cluster-md-0-yyyyy-aaaaa      NotReady   <none>          2m    v1.28.3
```

### ⚠️ Pourquoi NotReady?

Les nodes sont **NotReady** car il manque le **CNI (Container Network Interface)**.

```bash
kubectl --kubeconfig dev-cluster.kubeconfig get pods -A
```

**Résultat:**
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

**CoreDNS est Pending** car il attend le réseau pod (CNI).

**👉 Module 02 résoudra ce problème en installant Calico CNI!**

---

## ✅ Validation du Module

### Exécuter le script de validation

```bash
./validation.sh
```

**Résultat attendu:**
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

---

## 📚 Résumé des Concepts

| Concept | Description | Commande |
|---------|-------------|----------|
| **Cluster** | Objet de haut niveau représentant le cluster | `kubectl get clusters` |
| **Machine** | Représente un node Kubernetes | `kubectl get machines` |
| **KubeadmControlPlane** | Définit le control plane | `kubectl get kubeadmcontrolplane` |
| **MachineDeployment** | Définit les workers (comme Deployment) | `kubectl get machinedeployment` |
| **Phase** | État du lifecycle (Pending → Provisioned) | Visible dans `kubectl get` |

---

## 🔍 Troubleshooting

### Cluster reste en Pending
```bash
# Vérifier les logs du controller
kubectl logs -n capi-system deployment/capi-controller-manager -f

# Vérifier les events du cluster
kubectl describe cluster dev-cluster
```

### Machine ne démarre pas
```bash
# Détails de la machine
kubectl describe machine <machine-name>

# Logs Docker
docker logs <container-name>
```

### Pas de kubeconfig
```bash
# Le cluster doit être Provisioned
kubectl get cluster dev-cluster

# Si Provisioned, retry
clusterctl get kubeconfig dev-cluster > dev-cluster.kubeconfig
```

---

## 🎓 Ce Que Vous Avez Appris

✅ Créer un cluster ClusterAPI déclarativement (YAML)
✅ Observer la progression de création en temps réel
✅ Comprendre les objets ClusterAPI (Cluster, Machine, etc.)
✅ Accéder au workload cluster avec kubeconfig
✅ Diagnostiquer pourquoi les nodes sont NotReady

---

## ⏭️ Prochaine Étape

**Module 02 (15 min):** Installer Calico CNI automatiquement
- Comprendre ClusterResourceSets
- Automatiser le déploiement de Calico
- Passer les nodes à Ready

```bash
cd ../02-networking-calico
cat commands.md
```

---

**Module 01 complété! 🎉**
**Temps écoulé:** 25/90 minutes (10+15)
**Prochaine étape:** Module 02 - Networking avec Calico