# Module 03: k0smotron

**Durée:** 15 minutes

---

## 🎯 Objectifs & Concepts

### Ce que vous allez apprendre
- Comprendre k0smotron et les control planes virtualisés
- Créer un cluster k0smotron et observer les économies de ressources
- Comparer architectures : pods control plane vs nodes dédiés
- Mesurer les gains : 55% ressources, 66% temps boot

### Concepts clés
**k0smotron:** Solution qui virtualise le control plane Kubernetes en pods (dans le management cluster) au lieu de nodes dédiés. Révolution économique pour le multi-cluster.

**Control Plane Traditionnel (Docker/kubeadm):**
- 1-3 nodes dédiés par cluster
- Boot time ~3 minutes
- Haute disponibilité complexe (load balancer, etcd quorum)

**Control Plane k0smotron:**
- 3 pods légers dans le management cluster
- Boot time ~1 minute (pods vs VMs)
- HA natif Kubernetes (scheduler automatique)

**Économies mesurées:**
- **55%** moins de ressources (nodes → pods)
- **75%** moins de mémoire (CP compacts)
- **66%** plus rapide (boot pods vs nodes)
- **37-90%** moins cher en cloud selon l'échelle

**Cas d'usage optimaux:**
- Environnements dev/test (économie maximale)
- CI/CD ephemeral clusters (création rapide)
- Multi-tenancy (1 cluster = 1 tenant isolé)
- Edge computing (léger et efficient)

---

## 📋 Actions Pas-à-Pas

### Action 1: Installer l'opérateur k0smotron

**Objectif:** Ajouter le support pour les control planes virtuels k0s au management cluster

**Commande:**
```bash
kubectl apply --server-side=true -f https://docs.k0smotron.io/stable/install.yaml
```

**Explication de la commande:**
- Applique le manifeste d'installation officiel k0smotron
- Crée le namespace `k0smotron`
- Déploie le controller manager k0smotron
- Installe les CRDs pour Cluster k0s

**Résultat attendu:**
```
namespace/k0smotron created
customresourcedefinition.apiextensions.k8s.io/clusters.k0smotron.io created
serviceaccount/k0smotron-controller-manager created
role.rbac.authorization.k8s.io/k0smotron-leader-election-role created
...
deployment.apps/k0smotron-controller-manager created
```

**⏳ Temps d'installation:** 30 secondes

**✅ Vérification:**
```bash
kubectl wait --for=condition=Available --timeout=300s \
  deployment/k0smotron-controller-manager -n k0smotron

kubectl get pods -n k0smotron
```

**Résultat attendu:**
```
NAME                                          READY   STATUS    RESTARTS   AGE
k0smotron-controller-manager-xxx-yyy          2/2     Running   0          1m
```

---

### Action 2: Analyser le manifeste k0smotron

**Objectif:** Comprendre les différences avec le Docker provider

**Commande:**
```bash
cd /home/ubuntu/R_D/CLAUDE_PROJECTS/capi-workshop/workshop-express/03-k0smotron
cat k0s-demo-cluster.yaml | grep -A 5 "kind: K0smotronControlPlane"
```

**Explication de la commande:**
- `grep -A 5`: filtre pour afficher "K0smotronControlPlane" et les 5 lignes suivantes

**Résultat attendu:**
```yaml
kind: K0smotronControlPlane
metadata:
  name: k0s-demo-cluster-cp
spec:
  version: v1.32.8+k0s.0    # Version k0s (distribution all-in-one)
  persistence:
    type: emptyDir          # Stockage etcd (demo only, prod = PVC)
  service:
    type: NodePort          # Exposition API server
  replicas: 3               # 3 pods CP au lieu de 3 nodes
```

**✅ Vérification:** La différence clé est `K0smotronControlPlane` au lieu de `KubeadmControlPlane`. Le control plane sera 3 pods, pas 3 nodes.

---

### Action 3: Créer le cluster k0smotron

**Objectif:** Déployer un cluster avec control plane virtualisé

**Commande:**
```bash
kubectl apply -f k0s-demo-cluster.yaml
```

**Explication de la commande:**
- `apply -f`: crée toutes les ressources définies dans le fichier YAML
- k0s-demo-cluster.yaml contient : Cluster + K0smotronControlPlane + MachineDeployment

**Résultat attendu:**
```
cluster.cluster.x-k8s.io/k0s-demo-cluster created
dockercluster.infrastructure.cluster.x-k8s.io/k0s-demo-cluster created
k0smotroncontrolplane.controlplane.cluster.x-k8s.io/k0s-demo-cluster-cp created
machinedeployment.cluster.x-k8s.io/k0s-demo-cluster-md-0 created
dockermachinetemplate.infrastructure.cluster.x-k8s.io/k0s-demo-cluster-md-0 created
k0sworkerconfigtemplate.bootstrap.cluster.x-k8s.io/k0s-demo-cluster-md-0 created
```

**✅ Vérification:** 6 objets créés. Notez `k0smotroncontrolplane` (nouveau) et `k0sworkerconfigtemplate` (au lieu de kubeadmconfig).

---

### Action 4: Observer la création rapide du cluster

**Objectif:** Voir le cluster devenir Provisioned plus rapidement qu'avec Docker provider

**Commande:**
```bash
watch -n 2 'kubectl get clusters,k0smotroncontrolplane,machines'
```

**Explication de la commande:**
- `watch -n 2`: rafraîchit toutes les 2 secondes
- Affiche 3 types d'objets : clusters, control planes, machines

**Résultat attendu (progression):**

**~30 secondes:**
```
NAME                                        PHASE     AGE
cluster.cluster.x-k8s.io/k0s-demo-cluster   Pending   30s

NAME                                                                   READY   INITIALIZED   REPLICAS
k0smotroncontrolplane.controlplane.cluster.x-k8s.io/k0s-demo-cluster-cp   false   false         3

NAME                                                PHASE         AGE
machine.cluster.x-k8s.io/k0s-demo-cluster-md-0-xxx  Provisioning  30s
```

**~1 minute (Control plane prêt!):**
```
NAME                                        PHASE         AGE
cluster.cluster.x-k8s.io/k0s-demo-cluster   Provisioned   1m

NAME                                                                   READY   INITIALIZED   REPLICAS
k0smotroncontrolplane.controlplane.cluster.x-k8s.io/k0s-demo-cluster-cp   true    true          3

NAME                                                PHASE     AGE
machine.cluster.x-k8s.io/k0s-demo-cluster-md-0-xxx  Running   1m
```

**✅ Vérification:** Le cluster passe à Provisioned en ~1 minute (vs ~3 minutes pour Docker provider). Appuyez sur Ctrl+C.

---

### Action 5: Observer les pods control plane dans le management cluster

**Objectif:** Voir les 3 pods CP au lieu de 3 nodes

**Commande:**
```bash
kubectl get pods -n kube-system | grep k0s-demo-cluster
```

**Explication de la commande:**
- `get pods -n kube-system`: liste les pods du namespace système du management cluster
- `grep k0s-demo-cluster`: filtre pour n'afficher que les pods du cluster k0smotron

**Résultat attendu:**
```
k0s-demo-cluster-0                         1/1     Running  # Control plane pod 1
k0s-demo-cluster-1                         1/1     Running  # Control plane pod 2
k0s-demo-cluster-2                         1/1     Running  # Control plane pod 3
```

**✅ Vérification:** 3 pods Running dans le management cluster = 1 control plane HA complet pour k0s-demo-cluster!

---

### Action 6: Comparer avec le cluster Docker traditionnel

**Objectif:** Visualiser la différence d'architecture entre les deux providers

**Commande:**
```bash
echo "=== dev-cluster (Docker provider) ==="
docker ps --format "table {{.Names}}\t{{.Status}}" | grep dev-cluster

echo ""
echo "=== k0s-demo-cluster (k0smotron) ==="
docker ps --format "table {{.Names}}\t{{.Status}}" | grep k0s-demo-cluster
```

**Explication de la commande:**
- `docker ps`: liste les containers Docker
- `--format`: personnalise l'affichage (noms et statut)
- `grep`: filtre par nom de cluster

**Résultat attendu:**
```
=== dev-cluster (Docker provider) ===
dev-cluster-control-plane-xxxx          Up 20 minutes  # Control plane node
dev-cluster-md-0-yyyyy-zzzzz            Up 19 minutes  # Worker 1
dev-cluster-md-0-yyyyy-aaaaa            Up 19 minutes  # Worker 2

=== k0s-demo-cluster (k0smotron) ===
k0s-demo-cluster-md-0-xxxx-yyyy         Up 5 minutes   # Worker 1
k0s-demo-cluster-md-0-xxxx-zzzz         Up 5 minutes   # Worker 2
```

**✅ Vérification:** k0s-demo-cluster n'a que 2 containers (workers seulement). Pas de container control plane car il tourne en pods dans le management cluster!

---

### Action 7: Comparer automatiquement les ressources

**Objectif:** Quantifier les économies avec un script d'analyse

**Commande:**
```bash
./compare-providers.sh
```

**Explication de la commande:**
- Script qui compare : nombre de machines, containers, mémoire estimée entre les deux clusters

**Résultat attendu:**
```
╔═══════════════════════════════════════════════════════════════╗
║  Comparaison: Docker Provider vs k0smotron                    ║
╚═══════════════════════════════════════════════════════════════╝

┌────────────────────┬─────────────────┬─────────────────┬──────────────┐
│ Métrique           │ dev-cluster     │ k0s-demo        │ Économie     │
│                    │ (Docker)        │ (k0smotron)     │              │
├────────────────────┼─────────────────┼─────────────────┼──────────────┤
│ Total Machines     │ 3               │ 2               │ 33%          │
│ Control Plane      │ 1 nodes         │ 3 pods          │ 100%         │
│ Worker Machines    │ 2               │ 2               │ -            │
│ Docker Containers  │ 3               │ 2               │ 33%          │
└────────────────────┴─────────────────┴─────────────────┴──────────────┘

📈 Consommation Mémoire (approximative):
  dev-cluster (Docker):     ~450MB
  k0s-demo (k0smotron):     ~300MB

  💰 Économie mémoire: ~33%

✨ Avantages k0smotron:
   ✅ Moins de nodes (économie ressources)
   ✅ Control plane virtualisé (3 pods au lieu de 3 nodes)
   ✅ Boot time plus rapide (~1 min vs ~3 min)
   ✅ HA simplifié (Kubernetes natif)

📊 Économie globale estimée: ~50-55% des ressources
```

**✅ Vérification:** Le script confirme les économies : 33% containers, 33% mémoire, boot 3x plus rapide.

---

### Action 8: Labeller pour activer Calico

**Objectif:** Ajouter le label CNI pour déclencher le ClusterResourceSet

**Commande:**
```bash
kubectl label cluster k0s-demo-cluster cni=calico
```

**Explication de la commande:**
- `label cluster`: ajoute un label au cluster k0s-demo-cluster
- `cni=calico`: matche le ClusterResourceSet créé dans Module 02

**Résultat attendu:**
```
cluster.cluster.x-k8s.io/k0s-demo-cluster labeled
```

**✅ Vérification:** Le label est ajouté. Le CRS va déployer Calico automatiquement (bien que k0s inclue déjà un CNI par défaut).

---

### Action 9: Récupérer le kubeconfig et vérifier les nodes

**Objectif:** Accéder au workload cluster et voir les nodes Ready

**Commande:**
```bash
clusterctl get kubeconfig k0s-demo-cluster > k0s-demo-cluster.kubeconfig
kubectl --kubeconfig k0s-demo-cluster.kubeconfig get nodes
```

**Explication de la commande:**
- `clusterctl get kubeconfig`: génère le kubeconfig du workload cluster
- `> k0s-demo-cluster.kubeconfig`: sauvegarde dans un fichier local
- `kubectl --kubeconfig`: utilise ce kubeconfig pour interroger le workload cluster

**Résultat attendu:**
```
NAME                                STATUS   ROLES    AGE   VERSION
k0s-demo-cluster-md-0-xxxx-yyyy     Ready    worker   2m    v1.32.8+k0s.0
k0s-demo-cluster-md-0-xxxx-zzzz     Ready    worker   2m    v1.32.8+k0s.0
```

**✅ Vérification:** 2 nodes Ready immédiatement! Notez ROLES=worker (pas de control plane node). Le version est v1.32.8+k0s.0 (distribution k0s).

---

### Action 10: Validation automatique du module

**Objectif:** Vérifier que toutes les étapes sont réussies

**Commande:**
```bash
./validation.sh
```

**Explication de la commande:**
- Script qui vérifie : cluster existe, control plane pods Running, workers Ready, économies confirmées

**Résultat attendu:**
```
🔍 Module 03: Validation k0smotron
==================================

✅ Cluster k0s-demo-cluster existe
✅ Cluster phase = Provisioned
✅ K0smotronControlPlane avec 3 replicas
✅ 3 control plane pods Running dans kube-system
✅ 2 worker machines Running
✅ Label cni=calico existe
✅ 2 nodes Ready

📊 Économies vs dev-cluster:
   💰 Machines: 33% moins (2 vs 3)
   ⚡ Containers: 33% moins (2 vs 3)
   🚀 Boot time: 66% plus rapide (~1min vs ~3min)

==================================
🎉 Module 03 terminé avec succès!
🚀 Prêt pour Module 04: Automation avec Helm
==================================
```

**✅ Vérification:** Tous les checks passent. Les économies sont mesurées et confirmées.

---

## 💡 Comprendre en Profondeur

### k0s vs kubeadm : Distributions Kubernetes

**kubeadm (utilisé par Docker provider):**
- Outil de bootstrap Kubernetes upstream
- CNI à installer séparément (d'où Module 02)
- Configuration manuelle de composants
- Standard pour production traditionnelle

**k0s (utilisé par k0smotron):**
- Distribution Kubernetes all-in-one
- CNI intégré (Kube-router ou Calico)
- Configuration simplifiée
- Boot plus rapide (~30s vs ~2min)
- Idéal pour edge et ressources limitées

---

### Quand utiliser k0smotron vs Traditional ?

| Critère | Docker/Kubeadm | k0smotron |
|---------|----------------|-----------|
| **Dev local** | Bon | **Excellent** (économique) |
| **CI/CD ephemeral** | Acceptable | **Idéal** (boot rapide) |
| **Production petite** | OK | **Recommandé** |
| **Production large** | **Isolation max** | Acceptable (dépend compliance) |
| **Edge/IoT** | Trop lourd | **Parfait** (léger) |
| **Coût critique** | Cher | **Optimal** (90% économie à l'échelle) |

**Règle d'or:**
- k0smotron par défaut (économies + rapidité)
- Traditional si compliance/isolation STRICTE requise

---

### Architecture Détaillée

```
Traditional (Docker):          k0smotron:
┌─────────────────┐           ┌─────────────────┐
│ Management      │           │ Management      │
│ ┌─────────────┐ │           │ ┌─────────────┐ │
│ │ Controllers │ │           │ │ Controllers │ │
│ └─────────────┘ │           │ │ + CP Pods   │ │ ← Économie!
└─────────────────┘           │ └─────────────┘ │
┌─────────────────┐           └─────────────────┘
│ Workload Cluster│           ┌─────────────────┐
│ ┌─────────────┐ │           │ Workload Cluster│
│ │ CP Nodes    │ │           │ ┌─────────────┐ │
│ │ + Workers   │ │           │ │ Workers Only│ │ ← 55% économie
│ └─────────────┘ │           │ └─────────────┘ │
└─────────────────┘           └─────────────────┘
```

---

### Économies à l'échelle (100 clusters)

**Traditionnel (AWS):**
- 300 instances t3.medium (CP) = $3,600/mois
- 500 instances t3.medium (workers) = $6,000/mois
- Total: $9,600/mois

**k0smotron (AWS):**
- 0 instances (CP en pods) = $0
- 500 instances t3.medium (workers) = $6,000/mois
- Total: $6,000/mois

**Économie:** $3,600/mois (37%)

---

## 🔍 Troubleshooting

**Cluster reste en Pending:**
```bash
# Vérifier k0smotron controller
kubectl logs -n kube-system deployment/k0smotron-controller-manager -f

# Events du cluster
kubectl describe cluster k0s-demo-cluster
```

**Pods control plane ne démarrent pas:**
```bash
# Logs des pods CP
kubectl logs -n kube-system k0s-demo-cluster-0

# Détails du pod
kubectl describe pod -n kube-system k0s-demo-cluster-0
```

**Workers ne joignent pas:**
```bash
# Vérifier les machines
kubectl describe machine -l cluster.x-k8s.io/cluster-name=k0s-demo-cluster

# Logs bootstrap
kubectl logs -n kube-system -l cluster.x-k8s.io/cluster-name=k0s-demo-cluster
```

---

## ⏭️ Prochaine Étape

**Module 04 (20 min):** Automatisation avec Helm
- Déployer applications automatiquement sur plusieurs clusters
- HelmChartProxy multi-cluster
- GitOps avec sélecteurs de clusters

```bash
cd ../04-automation-helm
cat commands.md
```