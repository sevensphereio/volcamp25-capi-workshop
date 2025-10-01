# Module 06: Mise à Jour Simultanée de Multiples Clusters

**Durée:** 15 minutes
**Objectif:** Mettre à jour simultanément la version Kubernetes de plusieurs clusters

---

## 📑 Table des Matières

- [🎯 Objectifs & Concepts](#-objectifs--concepts)
- [📋 Actions Pas-à-Pas](#-actions-pas-à-pas)
- [💡 Comprendre en Profondeur](#-comprendre-en-profondeur)

---

## 🎯 Objectifs & Concepts

### Ce que vous allez apprendre

✅ Mettre à jour simultanément la version Kubernetes de 3+ clusters
✅ Observer le rolling upgrade des control planes et workers
✅ Comprendre le processus zero-downtime de ClusterAPI
✅ Vérifier la santé des clusters après upgrade

### Le Principe : Rolling Upgrade Automatisé

**Analogie :** Imaginez une **flotte de navires** qui doivent passer en révision. Au lieu de les ramener au port un par un (séquentiel), vous envoyez des équipes de maintenance sur chaque navire simultanément (parallèle), et chaque équipe fait la révision membre par membre sans arrêter le navire.

**Ce que ClusterAPI fait automatiquement :**
```
Pour chaque cluster (en parallèle):
  1. Upgrade Control Plane
     - Drain node 1 → Upgrade → Rejoin
     - (Si HA) Drain node 2 → Upgrade → Rejoin
     - (Si HA) Drain node 3 → Upgrade → Rejoin

  2. Upgrade Workers (rolling)
     - Drain worker 1 → Upgrade → Rejoin
     - Drain worker 2 → Upgrade → Rejoin
     - ...

Résultat: Tous les clusters upgradés sans downtime
```

**Pourquoi c'est sûr ?**
- **Validation automatique** : ClusterAPI vérifie la santé après chaque node
- **Rollback possible** : Si échec, les anciens nodes restent disponibles
- **Zero-downtime** : Les pods sont déplacés avant drain (si HA)

---

## 📋 Actions Pas-à-Pas

### Étape 1 : Aller dans le répertoire du module

**Objectif :** Se positionner dans le dossier de travail

**Commande :**
```bash
cd /home/ubuntu/R_D/CLAUDE_PROJECTS/capi-workshop/workshop-express/06-cluster-upgrades
```

---

### Étape 2 : Vérifier les versions actuelles des clusters

**Objectif :** Identifier quels clusters ont besoin d'upgrade

**Commande :**
```bash
kubectl get clusters -o custom-columns="NAME:.metadata.name,CP_VERSION:.spec.controlPlaneRef.name,PHASE:.status.phase"
```

**Résultat attendu :**
```
NAME         CP_VERSION                     PHASE
dev-cluster  dev-cluster-control-plane      Provisioned
multi-01     multi-01-control-plane         Provisioned
multi-02     multi-02-control-plane         Provisioned
multi-03     multi-03-control-plane         Provisioned
```

---

### Étape 3 : Voir les versions Kubernetes actuelles

**Objectif :** Confirmer les versions avant upgrade

**Commande :**
```bash
kubectl get kubeadmcontrolplane,machinedeployment -o custom-columns="NAME:.metadata.name,TYPE:.kind,VERSION:.spec.version,REPLICAS:.spec.replicas,READY:.status.readyReplicas"
```

**Résultat attendu :**
```
NAME                           TYPE                   VERSION    REPLICAS  READY
dev-cluster-control-plane      KubeadmControlPlane    v1.32.8    1         1
dev-cluster-md-0               MachineDeployment      v1.32.8    2         2
multi-01-control-plane         KubeadmControlPlane    v1.32.8    1         1
multi-01-md-0                  MachineDeployment      v1.32.8    2         2
multi-02-control-plane         KubeadmControlPlane    v1.32.8    1         1
multi-02-md-0                  MachineDeployment      v1.32.8    2         2
multi-03-control-plane         KubeadmControlPlane    v1.32.8    1         1
multi-03-md-0                  MachineDeployment      v1.32.8    2         2
```

**🔍 Points clés :**
- Tous les clusters sont sur v1.32.8
- Nous allons upgrader vers v1.33.0 (exemple)
- CP et workers doivent être upgradés séparément

---

### Étape 4 : Examiner le script d'upgrade automatisé

**Objectif :** Comprendre le workflow d'upgrade

**Commande :**
```bash
cat upgrade-clusters.sh
```

**Résultat attendu :**
```bash
#!/bin/bash
# Upgrade multiple clusters to a new Kubernetes version

NEW_VERSION="v1.33.0"  # Target version
CLUSTERS=("dev-cluster" "multi-01" "multi-02" "multi-03")

for cluster in "${CLUSTERS[@]}"; do
  echo "🔄 Upgrading cluster: $cluster to $NEW_VERSION"

  # Upgrade Control Plane
  kubectl patch kubeadmcontrolplane ${cluster}-control-plane \
    --type=merge \
    -p "{\"spec\":{\"version\":\"${NEW_VERSION}\"}}"

  # Upgrade Workers
  kubectl patch machinedeployment ${cluster}-md-0 \
    --type=merge \
    -p "{\"spec\":{\"template\":{\"spec\":{\"version\":\"${NEW_VERSION}\"}}}}"
done
```

**🔍 Explication :**
- Boucle sur tous les clusters
- Patch le KubeadmControlPlane (CP upgrade)
- Patch le MachineDeployment (workers upgrade)
- Les upgrades démarrent EN PARALLÈLE pour tous les clusters

---

### Étape 5 : Lancer l'upgrade simultané

**Objectif :** Upgrader tous les clusters en une seule commande

**⚠️ IMPORTANT :** Pour ce workshop, nous allons faire un upgrade "fictif" en changeant juste un label, car v1.33.0 n'existe pas encore. En production, vous changeriez réellement la version.

**Commande (simulation d'upgrade) :**
```bash
# Simulation: On va juste ajouter un label upgrade-test pour voir le rolling update
for cluster in dev-cluster multi-01 multi-02 multi-03; do
  echo "🔄 Simulating upgrade for cluster: $cluster"
  kubectl patch kubeadmcontrolplane ${cluster}-control-plane \
    --type=merge \
    -p '{"metadata":{"labels":{"upgrade-test":"simulated"}}}'
done
```

**Résultat attendu :**
```
🔄 Simulating upgrade for cluster: dev-cluster
kubeadmcontrolplane.controlplane.cluster.x-k8s.io/dev-cluster-control-plane patched

🔄 Simulating upgrade for cluster: multi-01
kubeadmcontrolplane.controlplane.cluster.x-k8s.io/multi-01-control-plane patched

🔄 Simulating upgrade for cluster: multi-02
kubeadmcontrolplane.controlplane.cluster.x-k8s.io/multi-02-control-plane patched

🔄 Simulating upgrade for cluster: multi-03
kubeadmcontrolplane.controlplane.cluster.x-k8s.io/multi-03-control-plane patched
```

**🔍 Ce qui se passerait avec un vrai upgrade :**
1. ClusterAPI détecte le changement de version
2. Pour chaque cluster (en parallèle):
   - Crée une nouvelle Machine avec la nouvelle version
   - Drain l'ancienne Machine (déplace les pods)
   - Supprime l'ancienne Machine
   - Répète pour chaque worker

---

### Étape 6 : Observer un vrai upgrade (demo avec version patch)

**Objectif :** Voir le rolling upgrade en action

**⚠️ Cette étape est optionnelle et dépend des versions disponibles.**

**Commande (upgrade patch version) :**
```bash
# Example: upgrade de v1.32.8 vers v1.32.9 (si disponible)
NEW_VERSION="v1.32.9"

# Upgrade un seul cluster pour observer
kubectl patch kubeadmcontrolplane multi-01-control-plane \
  --type=merge \
  -p "{\"spec\":{\"version\":\"${NEW_VERSION}\"}}"
```

**Observer le rolling upgrade :**
```bash
watch -n 2 'kubectl get machines -l cluster.x-k8s.io/cluster-name=multi-01'
```

**Résultat attendu (progression) :**

**T+0s - Upgrade démarre :**
```
NAME                              CLUSTER    PHASE     VERSION
multi-01-control-plane-xxx        multi-01   Running   v1.32.8
multi-01-md-0-yyy-zzz             multi-01   Running   v1.32.8
multi-01-md-0-yyy-aaa             multi-01   Running   v1.32.8
```

**T+30s - Nouvelle Machine CP créée :**
```
NAME                              CLUSTER    PHASE         VERSION
multi-01-control-plane-xxx        multi-01   Running       v1.32.8
multi-01-control-plane-new        multi-01   Provisioning  v1.32.9  ← Nouveau!
multi-01-md-0-yyy-zzz             multi-01   Running       v1.32.8
multi-01-md-0-yyy-aaa             multi-01   Running       v1.32.8
```

**T+2min - CP upgradé, workers en cours :**
```
NAME                              CLUSTER    PHASE         VERSION
multi-01-control-plane-new        multi-01   Running       v1.32.9  ← Upgradé!
multi-01-md-0-yyy-zzz             multi-01   Running       v1.32.8
multi-01-md-0-yyy-aaa             multi-01   Running       v1.32.8
multi-01-md-0-new1                multi-01   Provisioning  v1.32.9  ← Nouveau!
```

**T+5min - Upgrade complet :**
```
NAME                              CLUSTER    PHASE     VERSION
multi-01-control-plane-new        multi-01   Running   v1.32.9
multi-01-md-0-new1                multi-01   Running   v1.32.9
multi-01-md-0-new2                multi-01   Running   v1.32.9
```

**Appuyez sur Ctrl+C pour arrêter le watch**

---

### Étape 7 : Utiliser le script de monitoring

**Objectif :** Surveiller l'upgrade de tous les clusters en parallèle

**Commande :**
```bash
./monitor-upgrades.sh
```

**Résultat attendu :**
```
🔍 Monitoring Cluster Upgrades
================================

Cluster: dev-cluster
  Control Plane: v1.32.8 (1/1 ready)
  Workers: v1.32.8 (2/2 ready)
  Status: ✅ Stable

Cluster: multi-01
  Control Plane: v1.32.9 (1/1 ready)  ← Upgradé!
  Workers: v1.32.9 (2/2 ready)
  Status: ✅ Upgraded

Cluster: multi-02
  Control Plane: v1.32.8 → v1.32.9 (0/1 ready)  ← En cours
  Workers: v1.32.8 (2/2 ready)
  Status: 🔄 Upgrading

Cluster: multi-03
  Control Plane: v1.32.8 (1/1 ready)
  Workers: v1.32.8 (2/2 ready)
  Status: ⏳ Pending

Press Ctrl+C to exit
```

---

### Étape 8 : Vérifier les versions après upgrade

**Objectif :** Confirmer que les upgrades ont réussi

**Commande :**
```bash
kubectl get kubeadmcontrolplane,machinedeployment \
  -o custom-columns="NAME:.metadata.name,VERSION:.spec.version,READY:.status.readyReplicas,UPDATED:.status.updatedReplicas"
```

**Résultat attendu (si upgrade réel) :**
```
NAME                           VERSION    READY  UPDATED
dev-cluster-control-plane      v1.33.0    1      1
dev-cluster-md-0               v1.33.0    2      2
multi-01-control-plane         v1.33.0    1      1
multi-01-md-0                  v1.33.0    2      2
multi-02-control-plane         v1.33.0    1      1
multi-02-md-0                  v1.33.0    2      2
multi-03-control-plane         v1.33.0    1      1
multi-03-md-0                  v1.33.0    2      2
```

**✅ Vérification :**
- VERSION = nouvelle version
- READY = UPDATED (toutes les machines upgradées)

---

### Étape 9 : Vérifier la santé des workload clusters

**Objectif :** Confirmer que les applications tournent toujours

**Commandes :**
```bash
# Vérifier les nodes de chaque cluster
for cluster in dev-cluster multi-01 multi-02 multi-03; do
  echo "=== Cluster: $cluster ==="
  kubectl --kubeconfig ${cluster}.kubeconfig get nodes
  echo ""
done
```

**Résultat attendu (pour chaque cluster) :**
```
=== Cluster: multi-01 ===
NAME                          STATUS   ROLES           AGE   VERSION
multi-01-control-plane-new    Ready    control-plane   5m    v1.33.0
multi-01-md-0-new1            Ready    <none>          3m    v1.33.0
multi-01-md-0-new2            Ready    <none>          3m    v1.33.0
```

**✅ Vérification :**
- STATUS = Ready
- VERSION = nouvelle version
- Aucun node en NotReady

---

### Étape 10 : Tester les applications (si deployées)

**Objectif :** Confirmer que les apps survivent à l'upgrade

**Si nginx déployé (Module 05) :**
```bash
# Vérifier que nginx tourne toujours
for cluster in multi-01 multi-02 multi-03; do
  echo "=== Cluster: $cluster ==="
  kubectl --kubeconfig ${cluster}.kubeconfig get pods -n nginx
done
```

**Résultat attendu :**
```
=== Cluster: multi-01 ===
NAME                     READY   STATUS    RESTARTS   AGE
nginx-xxxxx-yyyyy        1/1     Running   0          15m
nginx-xxxxx-zzzzz        1/1     Running   0          15m
```

**✅ Vérification :**
- Pods en Running
- RESTARTS = 0 (pas de crash pendant l'upgrade)
- AGE plus ancien que l'upgrade (pods pas recréés)

---

### Étape 11 : Analyser les événements d'upgrade

**Objectif :** Comprendre ce qui s'est passé en détail

**Commande :**
```bash
kubectl get events --sort-by='.lastTimestamp' | grep -E 'Machine|upgrade' | tail -20
```

**Résultat attendu :**
```
5m  Normal  SuccessfulCreate  Machine  Created new machine multi-01-control-plane-new
4m  Normal  Draining          Machine  Draining node multi-01-control-plane-xxx
3m  Normal  Deleted           Machine  Deleted machine multi-01-control-plane-xxx
2m  Normal  SuccessfulCreate  Machine  Created new machine multi-01-md-0-new1
...
```

**🔍 Étapes visibles :**
1. Create new machine (nouvelle version)
2. Drain old machine (déplace les pods)
3. Delete old machine
4. Repeat pour chaque node

---

### Étape 12 : Calculer le temps d'upgrade

**Objectif :** Mesurer la durée totale

**Commande :**
```bash
# Comparer timestamp de début et fin
CLUSTER="multi-01"
START_TIME=$(kubectl get kubeadmcontrolplane ${CLUSTER}-control-plane -o jsonpath='{.metadata.annotations.upgrade-start-time}' 2>/dev/null || echo "N/A")
echo "Upgrade start time: $START_TIME"

# Si pas d'annotation, utiliser les events
kubectl get events --sort-by='.firstTimestamp' | grep "multi-01" | grep "SuccessfulCreate" | head -1
kubectl get events --sort-by='.lastTimestamp' | grep "multi-01" | grep "Running" | tail -1
```

**Temps d'upgrade typiques :**
```
Single cluster (1 CP + 2 workers):
  - Control Plane: 2-3 minutes
  - Workers (séquentiel): 2x2 minutes = 4 minutes
  - Total: ~7 minutes

Multiple clusters (parallel):
  - 4 clusters x 7 minutes each = 7 minutes (pas 28!)
  - Économie de temps: 75% vs séquentiel
```

---

### Étape 13 : Rollback d'un upgrade (demo)

**Objectif :** Savoir annuler un upgrade problématique

**⚠️ Cette section est théorique (ne pas exécuter si upgrade réussi)**

**Commande de rollback :**
```bash
# Rollback vers l'ancienne version
OLD_VERSION="v1.32.8"
CLUSTER="multi-01"

kubectl patch kubeadmcontrolplane ${CLUSTER}-control-plane \
  --type=merge \
  -p "{\"spec\":{\"version\":\"${OLD_VERSION}\"}}"

kubectl patch machinedeployment ${CLUSTER}-md-0 \
  --type=merge \
  -p "{\"spec\":{\"template\":{\"spec\":{\"version\":\"${OLD_VERSION}\"}}}}"
```

**🔍 Ce qui se passe :**
- ClusterAPI détecte la version downgrade
- Crée de nouvelles machines avec l'ancienne version
- Rolling update vers l'ancienne version
- Les données/apps sont préservées

---

### Étape 14 : Cleanup des anciennes machines

**Objectif :** Vérifier que les anciennes machines sont supprimées

**Commande :**
```bash
# Lister toutes les machines
kubectl get machines -A

# Vérifier qu'il n'y a pas de machines "Deleting" coincées
kubectl get machines -o json | jq '.items[] | select(.status.phase=="Deleting") | .metadata.name'
```

**Résultat attendu :**
- Pas de machines en phase "Deleting"
- Seulement les nouvelles machines en "Running"

**Si machines coincées :**
```bash
# Forcer la suppression (cas rare)
kubectl delete machine <stuck-machine-name> --force --grace-period=0
```

---

### Étape 15 : Valider le module

**Objectif :** Exécuter le script de validation automatique

**Commande :**
```bash
./validation.sh
```

**Résultat attendu :**
```
🔍 Module 06: Validation Cluster Upgrades
==========================================

✅ 4 Clusters existent
✅ Tous les clusters sont Provisioned
✅ Tous les control planes sont ready
✅ Toutes les machines sont Running
✅ Aucune machine en phase Deleting
✅ Workload clusters accessibles
✅ Nodes Ready dans tous les clusters

==========================================
🎉 Module 06 terminé avec succès!
🚀 Prêt pour Module 07: Operations & Cleanup
==========================================
```

---

## 🎓 Points Clés à Retenir

✅ **Rolling upgrade automatisé** : ClusterAPI gère le drain/upgrade/rejoin
✅ **Zero-downtime** : Pods déplacés avant upgrade (si HA)
✅ **Parallel upgrades** : Plusieurs clusters upgradés simultanément
✅ **Rollback possible** : Retour à l'ancienne version si problème
✅ **Validation automatique** : ClusterAPI vérifie la santé après chaque étape
✅ **Production-ready** : Pattern utilisé pour 100+ clusters en prod

### Workflow d'Upgrade Détaillé

```
                     ┌─────────────────┐
                     │  User: Patch    │
                     │  version field  │
                     └────────┬────────┘
                              │
                              ▼
                     ┌─────────────────┐
                     │  ClusterAPI     │
                     │  Reconcile Loop │
                     └────────┬────────┘
                              │
                ┌─────────────┴─────────────┐
                │                           │
                ▼                           ▼
       ┌────────────────┐         ┌────────────────┐
       │ Control Plane  │         │    Workers     │
       │    Upgrade     │         │    Upgrade     │
       └────────┬───────┘         └────────┬───────┘
                │                           │
    ┌───────────┴───────────┐   ┌───────────┴───────────┐
    ▼                       ▼   ▼                       ▼
[Create New]           [Drain]  [Create New]       [Drain]
[Wait Ready]           [Delete] [Wait Ready]       [Delete]
[Delete Old]                    [Next Worker]
```

---

## ⏭️ Prochaine Étape

**Module 07 (15 min) :** Operations & Cleanup
- Scaler les workers dynamiquement
- Monitorer les ressources
- Cleanup complet de l'environnement

```bash
cd ../07-operations-cleanup
cat commands.md
```

---

## 💡 Comprendre en Profondeur

> **Note :** Cette section approfondit les concepts techniques.

### Stratégies d'Upgrade

#### Rolling Update (défaut)

**Configuration :**
```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # 1 nouveau node avant supprimer ancien
      maxUnavailable: 0  # 0 node down autorisé
```

**Workflow :**
```
3 workers total, maxSurge=1, maxUnavailable=0:

T+0:  [Old1] [Old2] [Old3]           (3 running)
T+1:  [Old1] [Old2] [Old3] [New1]    (4 running - surge)
T+2:  [Old2] [Old3] [New1]           (Old1 drained & deleted)
T+3:  [Old2] [Old3] [New1] [New2]    (4 running - surge)
T+4:  [Old3] [New1] [New2]           (Old2 drained & deleted)
T+5:  [Old3] [New1] [New2] [New3]    (4 running - surge)
T+6:  [New1] [New2] [New3]           (Old3 drained & deleted)

Result: Always 3+ nodes running → Zero downtime
```

---

#### In-Place Update (expérimental)

**Avantages :**
- Pas de création de nouvelles machines
- Upgrade plus rapide
- Conserve les IP

**Désavantages :**
- Downtime possible (reboot requis)
- Moins safe (pas de rollback facile)
- Non recommandé pour prod

---

### Upgrade Control Plane HA

**Pour control plane avec replicas=3 :**

```yaml
spec:
  replicas: 3
  rolloutStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
```

**Workflow :**
```
T+0:  [CP1] [CP2] [CP3]              (Quorum 3/3)
T+1:  [CP1] [CP2] [CP3] [CP4-new]    (4 running)
T+2:  [CP2] [CP3] [CP4-new]          (Quorum 3/3 - CP1 supprimé)
T+3:  [CP2] [CP3] [CP4] [CP5-new]    (4 running)
T+4:  [CP3] [CP4] [CP5-new]          (Quorum 3/3 - CP2 supprimé)
T+5:  [CP3] [CP4] [CP5] [CP6-new]    (4 running)
T+6:  [CP4] [CP5] [CP6]              (Quorum 3/3 - CP3 supprimé)

Result: Quorum etcd maintenu → API server toujours disponible
```

**Points critiques :**
- Toujours maintenir le quorum etcd (n/2 + 1)
- Ne jamais upgrader 2 CP en même temps
- Vérifier santé après chaque CP

---

### Gestion des Pods Pendant l'Upgrade

**Pod Eviction Process :**

1. **Node marked unschedulable** : Nouveaux pods ne peuvent pas être créés
2. **Pods avec PDB vérifié** : Respect des PodDisruptionBudgets
3. **Graceful termination** : SIGTERM envoyé, grace period (30s par défaut)
4. **Force kill** : Si timeout, SIGKILL envoyé
5. **Pods recréés** : Sur d'autres nodes par les controllers (ReplicaSet, etc.)

**Best practices :**
```yaml
# Dans vos Deployments
apiVersion: apps/v1
kind: Deployment
spec:
  replicas: 3  # ≥2 pour survivre à l'upgrade
  template:
    spec:
      containers:
      - name: app
        lifecycle:
          preStop:  # Hook pour cleanup graceful
            exec:
              command: ["/bin/sh", "-c", "sleep 15"]
        terminationGracePeriodSeconds: 30
```

---

### Versionning Kubernetes

**Semantic Versioning :**
```
v1.32.8
│ │  └─ Patch (bugfixes, backports sécurité)
│ └──── Minor (features, API changes)
└────── Major (breaking changes - rare)
```

**Règles d'upgrade :**
- ✅ Patch upgrade : Toujours safe (v1.32.8 → v1.32.9)
- ✅ Minor upgrade : 1 version à la fois (v1.32 → v1.33)
- ❌ Skip versions : Non supporté (v1.32 → v1.34)
- ❌ Downgrade major : Non supporté (v1.33 → v1.32)

**Compatibilité components :**
```
Control Plane v1.33.0
  ├─ Workers: v1.32.x ou v1.33.x (N-1 supporté)
  ├─ kubectl: v1.32.x à v1.34.x (N-1 à N+1)
  └─ CNI: Compatible toutes versions (Calico, Cilium, etc.)
```

---

### Rollback Scenarios

#### Scenario 1: Upgrade échoue au milieu

**Symptômes :**
- Nouvelles machines ne démarrent pas
- Old machines toujours Running

**Action :**
```bash
# ClusterAPI rollback automatique après timeout (10 min)
# Ou manuel :
kubectl patch kubeadmcontrolplane <name> --type=merge -p '{"spec":{"version":"<old-version>"}}'
```

**Résultat :**
- Anciennes machines conservées
- Nouvelles machines supprimées
- Cluster revient à l'état stable

---

#### Scenario 2: Upgrade réussit mais app casse

**Symptômes :**
- Nodes en Ready
- Pods crashent ou comportement anormal

**Actions :**
1. Vérifier logs des pods
2. Rollback app (pas K8s)
3. Si API incompatibilité, rollback K8s

```bash
# Rollback K8s version
kubectl patch kubeadmcontrolplane <name> --type=merge -p '{"spec":{"version":"<old-version>"}}'
```

---

### Monitoring d'Upgrade

**Métriques clés à surveiller :**

```bash
# 1. Machine lifecycle
kubectl get machines -w

# 2. Node status
kubectl --kubeconfig workload.kubeconfig get nodes -w

# 3. Pod evictions
kubectl --kubeconfig workload.kubeconfig get events | grep Evicted

# 4. API availability (si HA)
while true; do
  kubectl --kubeconfig workload.kubeconfig get nodes &>/dev/null && echo "✅ API OK" || echo "❌ API DOWN"
  sleep 2
done
```

**Alerting production :**
- Prometheus: `kube_node_status_condition{condition="Ready",status="false"}`
- Alert si upgrade prend > 15 minutes
- Alert si pods evicted > threshold

---

### Troubleshooting

#### Upgrade stuck / ne démarre pas

**Diagnostic :**
```bash
# Check KubeadmControlPlane status
kubectl describe kubeadmcontrolplane <name>

# Events
kubectl get events --sort-by='.lastTimestamp' | grep <cluster>

# Machine controller logs
kubectl logs -n capi-system deployment/capi-controller-manager -f
```

**Causes fréquentes :**
1. Image Docker non disponible pour nouvelle version
2. Ressources insuffisantes
3. Version incompatible (skip de version)
4. Erreur de syntaxe dans le patch

**Solution :**
```bash
# Rollback
kubectl patch kubeadmcontrolplane <name> --type=merge -p '{"spec":{"version":"<old-version>"}}'
```

---

#### Machine reste en Deleting

**Diagnostic :**
```bash
kubectl describe machine <stuck-machine>
```

**Causes :**
- Finalizer bloqué
- Provider infrastructure erreur

**Solution :**
```bash
# Remove finalizer
kubectl patch machine <name> -p '{"metadata":{"finalizers":[]}}' --type=merge

# Force delete
kubectl delete machine <name> --force --grace-period=0
```

---

## 🎓 Ce Que Vous Avez Appris

✅ Upgrader simultanément plusieurs clusters Kubernetes
✅ Comprendre le rolling upgrade zero-downtime
✅ Observer le drain/upgrade/rejoin automatisé
✅ Rollback en cas de problème
✅ Monitorer l'upgrade en temps réel
✅ Vérifier la santé post-upgrade
✅ Patterns production pour 100+ clusters

---

**Module 06 complété ! 🎉**
**Temps écoulé :** 105/120 minutes (10+15+15+15+20+15+15)
**Prochaine étape :** Module 07 - Operations & Cleanup
