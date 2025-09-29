# Module 02: Networking avec Calico - Commandes

**Durée:** 15 minutes
**Objectif:** Installer Calico CNI automatiquement avec ClusterResourceSets et passer les nodes à Ready

---

## 📖 Partie 1: Diagnostic du Problème (3 minutes)

### Vérifier l'état des nodes

```bash
cd /home/ubuntu/R_D/CLAUDE_PROJECTS/capi-workshop/workshop-express/02-networking-calico
kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig get nodes
```

**Résultat actuel:**
```
NAME                              STATUS     ROLES           AGE   VERSION
dev-cluster-control-plane-xxxx    NotReady   control-plane   5m    v1.28.3
dev-cluster-md-0-yyyyy-zzzzz      NotReady   <none>          4m    v1.28.3
dev-cluster-md-0-yyyyy-aaaaa      NotReady   <none>          4m    v1.28.3
```

**❌ STATUS: NotReady**

### Diagnostiquer la cause

```bash
kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig describe node dev-cluster-control-plane-* | grep -A 5 "Conditions:"
```

**Résultat clé:**
```
Conditions:
  Type             Status
  Ready            False
  ...
  Message: network plugin is not ready: cni config uninitialized
```

**🔍 Problème identifié:** Pas de CNI installé!

### Vérifier les pods kube-system

```bash
kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig get pods -n kube-system
```

**Résultat:**
```
NAME                                            READY   STATUS
coredns-xxx                                     0/1     Pending
coredns-yyy                                     0/1     Pending
etcd-dev-cluster-control-plane-xxxx             1/1     Running
kube-apiserver-dev-cluster-control-plane-xxxx   1/1     Running
...
```

**CoreDNS est Pending** car il attend le réseau pod.

---

## 📚 Partie 2: Comprendre ClusterResourceSet (3 minutes)

### Qu'est-ce qu'un ClusterResourceSet?

**ClusterResourceSet (CRS)** est un mécanisme ClusterAPI pour déployer automatiquement des ressources (addons) sur les workload clusters.

### Architecture CRS

```
Management Cluster
├── ClusterResourceSet (définit QUOI et QUAND)
│   ├── clusterSelector: cni: calico  ← Sélection par label
│   └── resources: ConfigMap calico-addon
│
├── ConfigMap (contient les manifestes)
│   └── data:
│       └── calico.yaml: |
│           <manifestes Calico complets>
│
└── Clusters avec label cni: calico
    ↓
    Calico appliqué automatiquement!
```

### Avantages CRS

✅ **Automatique:** Dès qu'un cluster a le bon label, les ressources sont appliquées
✅ **Déclaratif:** Tout en YAML, versionné dans Git
✅ **Réutilisable:** Un CRS pour tous les clusters avec le même label
✅ **Standard:** Pattern ClusterAPI officiel

### Explorer le manifeste

```bash
cat calico-crs.yaml | head -20
```

**Résultat:**
```yaml
apiVersion: addons.cluster.x-k8s.io/v1beta1
kind: ClusterResourceSet
metadata:
  name: calico-cni
spec:
  clusterSelector:
    matchLabels:
      cni: calico          ← Cherche les clusters avec ce label
  resources:
  - name: calico-addon     ← Référence au ConfigMap
    kind: ConfigMap
  strategy: ApplyOnce      ← Appliqué une seule fois
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: calico-addon
data:
  calico.yaml: |           ← Manifeste Calico complet (7000+ lignes)
    ...
```

---

## 🚀 Partie 3: Créer le ClusterResourceSet (3 minutes)

### Appliquer le CRS

```bash
kubectl apply -f calico-crs.yaml
```

**Résultat attendu:**
```
clusterresourceset.addons.cluster.x-k8s.io/calico-cni created
configmap/calico-addon created
```

**2 objets créés:**
1. **ClusterResourceSet:** Définit la règle d'application
2. **ConfigMap:** Contient le manifeste Calico v3.26.3

### Vérifier le CRS créé

```bash
kubectl get clusterresourceset
```

**Résultat:**
```
NAME         AGE
calico-cni   10s
```

### Détails du CRS

```bash
kubectl describe clusterresourceset calico-cni
```

**Points clés:**
- Cluster Selector: `cni=calico`
- Resources: ConfigMap/calico-addon
- Strategy: ApplyOnce

---

## 🏷️ Partie 4: Activer le CRS sur le Cluster (2 minutes)

### Labeller le cluster dev-cluster

Pour que le CRS s'applique, le cluster doit avoir le label `cni: calico`:

```bash
kubectl label cluster dev-cluster cni=calico
```

**Résultat:**
```
cluster.cluster.x-k8s.io/dev-cluster labeled
```

**🎯 Déclencheur:** Dès que le label est appliqué, ClusterAPI détecte le match et applique le CRS!

### Vérifier le label

```bash
kubectl get cluster dev-cluster --show-labels
```

**Résultat:**
```
NAME          PHASE        AGE   LABELS
dev-cluster   Provisioned  10m   cni=calico,environment=demo
```

### Vérifier l'application du CRS

```bash
kubectl get clusterresourceset calico-cni -o yaml | grep -A 10 "status:"
```

**Résultat attendu:**
```yaml
status:
  conditions:
  - lastTransitionTime: "2025-XX-XXT..."
    status: "True"
    type: ResourcesApplied
```

---

## 👀 Partie 5: Observer l'Installation Calico (3 minutes)

### Observer les pods Calico apparaître

```bash
watch -n 2 'kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig get pods -n kube-system'
```

**Progression attendue:**

**Minute 1:**
```
NAME                                    READY   STATUS              RESTARTS
calico-kube-controllers-xxx             0/1     ContainerCreating   0
calico-node-aaaa                        0/1     Init:0/3            0
calico-node-bbbb                        0/1     Init:0/3            0
calico-node-cccc                        0/1     Init:0/3            0
coredns-xxx                             0/1     Pending             0
coredns-yyy                             0/1     Pending             0
```

**Minute 2:**
```
NAME                                    READY   STATUS    RESTARTS
calico-kube-controllers-xxx             1/1     Running   0
calico-node-aaaa                        1/1     Running   0
calico-node-bbbb                        1/1     Running   0
calico-node-cccc                        1/1     Running   0
coredns-xxx                             1/1     Running   0
coredns-yyy                             1/1     Running   0
```

**✅ Tous les pods Running!**

**Appuyez sur Ctrl+C pour arrêter.**

### Pods Calico Déployés

| Pod | Rôle | Déploiement |
|-----|------|-------------|
| **calico-node** | CNI agent sur chaque node | DaemonSet (1 pod/node) |
| **calico-kube-controllers** | Controller pour les policies | Deployment (1 replica) |

### Observer les nodes passer à Ready

```bash
watch -n 2 'kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig get nodes'
```

**Progression:**

**Avant:**
```
NAME                              STATUS     ROLES           AGE
dev-cluster-control-plane-xxxx    NotReady   control-plane   10m
dev-cluster-md-0-yyyyy-zzzzz      NotReady   <none>          9m
dev-cluster-md-0-yyyyy-aaaaa      NotReady   <none>          9m
```

**Après (~1 minute):**
```
NAME                              STATUS   ROLES           AGE
dev-cluster-control-plane-xxxx    Ready    control-plane   11m
dev-cluster-md-0-yyyyy-zzzzz      Ready    <none>          10m
dev-cluster-md-0-yyyyy-aaaaa      Ready    <none>          10m
```

**✅ 3/3 nodes Ready!**

---

## ✅ Partie 6: Validation Finale (1 minute)

### Tester la communication réseau

Déployer un pod de test:

```bash
kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig run test-pod --image=nginx --restart=Never
```

Attendre que le pod soit Running:

```bash
kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig get pod test-pod
```

**Résultat:**
```
NAME       READY   STATUS    RESTARTS   AGE
test-pod   1/1     Running   0          10s
```

Vérifier l'IP du pod (assignée par Calico):

```bash
kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig get pod test-pod -o wide
```

**Résultat:**
```
NAME       READY   STATUS    RESTARTS   AGE   IP              NODE
test-pod   1/1     Running   0          20s   192.168.X.Y     dev-cluster-md-0-...
```

**✅ Pod a une IP du range 192.168.0.0/16 (configuré dans dev-cluster.yaml)!**

### Cleanup du pod de test

```bash
kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig delete pod test-pod
```

### Exécuter le script de validation

```bash
./validation.sh
```

**Résultat attendu:**
```
🔍 Module 02: Validation Networking Calico
===========================================

✅ ClusterResourceSet calico-cni existe
✅ ConfigMap calico-addon existe
✅ Cluster dev-cluster a le label cni=calico
✅ CRS appliqué sur le cluster
✅ Calico pods Running (4/4)
   - calico-kube-controllers: 1/1
   - calico-node DaemonSet: 3/3
✅ 3/3 nodes Ready
✅ CoreDNS pods Running (2/2)
✅ Communication réseau fonctionnelle

===========================================
🎉 Module 02 terminé avec succès!
🚀 Prêt pour Module 03: k0smotron Control Planes
===========================================
```

---

## 📚 Résumé des Concepts

| Concept | Description | Exemple |
|---------|-------------|---------|
| **CNI** | Container Network Interface - plugin réseau pod | Calico, Flannel, Cilium |
| **ClusterResourceSet** | Déploiement automatique d'addons | CRS pour Calico, CSI, etc. |
| **clusterSelector** | Sélection de clusters par labels | `cni: calico` |
| **ConfigMap** | Stockage des manifestes à déployer | calico-addon |
| **DaemonSet** | Pod sur chaque node | calico-node |

---

## 🔍 Troubleshooting

### Calico pods ne démarrent pas
```bash
# Vérifier les events
kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig get events -n kube-system --sort-by='.lastTimestamp'

# Logs d'un pod Calico
kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig logs -n kube-system calico-node-xxx
```

### CRS ne s'applique pas
```bash
# Vérifier le label du cluster
kubectl get cluster dev-cluster --show-labels

# Si label manquant
kubectl label cluster dev-cluster cni=calico

# Logs du CRS controller
kubectl logs -n capi-system deployment/capi-controller-manager | grep clusterresourceset
```

### Nodes restent NotReady
```bash
# Attendre 1-2 minutes après installation Calico

# Vérifier que tous les pods Calico sont Running
kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig get pods -n kube-system -l k8s-app=calico-node

# Si problème persiste, restart kubelet (automatique dans Docker provider)
```

---

## 🎓 Ce Que Vous Avez Appris

✅ Diagnostiquer un problème de CNI manquant
✅ Comprendre ClusterResourceSets pour automation
✅ Déployer Calico automatiquement sur un cluster
✅ Utiliser les labels pour déclencher des actions
✅ Valider que le réseau pod fonctionne

---

## ⏭️ Prochaine Étape

**Module 03 (15 min):** k0smotron Control Planes Virtuels
- Comprendre les économies de ressources (55%)
- Créer un cluster k0smotron équivalent
- Comparer les métriques avec Docker provider

```bash
cd ../03-k0smotron
cat commands.md
```

---

**Module 02 complété! 🎉**
**Temps écoulé:** 40/90 minutes (10+15+15)
**Prochaine étape:** Module 03 - k0smotron Control Planes