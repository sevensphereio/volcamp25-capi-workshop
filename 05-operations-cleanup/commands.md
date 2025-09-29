# Module 05: Operations & Cleanup - Commandes

**Durée:** 15 minutes
**Objectif:** Gérer les opérations cluster (scaling, monitoring) et nettoyer l'environnement

---

## ⚖️ Partie 1: Scaling des Workers (4 minutes)

### Comprendre le Scaling ClusterAPI

Le scaling dans ClusterAPI se fait via les **MachineDeployments** (équivalent des Deployments pour les pods).

```bash
cd /home/ubuntu/R_D/CLAUDE_PROJECTS/capi-workshop/workshop-express/05-operations-cleanup
```

### État actuel des clusters

```bash
kubectl get machinedeployment -o wide
```

**Résultat attendu:**
```
NAME                   CLUSTER            REPLICAS   READY   UPDATED   AGE
dev-cluster-md-0       dev-cluster        2          2       2         25m
k0s-demo-cluster-md-0  k0s-demo-cluster   2          2       2         20m
```

**Actuellement:** 2 workers par cluster

### Scaling manuel avec kubectl

```bash
kubectl scale machinedeployment dev-cluster-md-0 --replicas=4
```

**Résultat:**
```
machinedeployment.cluster.x-k8s.io/dev-cluster-md-0 scaled
```

### Observer le scaling en temps réel

```bash
watch -n 2 'kubectl get machines -l cluster.x-k8s.io/cluster-name=dev-cluster'
```

**Progression attendue:**

**~30 secondes:**
```
NAME                                    CLUSTER       PHASE         AGE
dev-cluster-control-plane-xxxx          dev-cluster   Running       25m
dev-cluster-md-0-yyyyy-zzzzz            dev-cluster   Running       25m
dev-cluster-md-0-yyyyy-aaaaa            dev-cluster   Running       25m
dev-cluster-md-0-bbbbbb-ccccc           dev-cluster   Provisioning  30s  # ← Nouveau
dev-cluster-md-0-bbbbbb-ddddd           dev-cluster   Provisioning  30s  # ← Nouveau
```

**~2 minutes:**
```
NAME                                    CLUSTER       PHASE     AGE
dev-cluster-control-plane-xxxx          dev-cluster   Running   27m
dev-cluster-md-0-yyyyy-zzzzz            dev-cluster   Running   27m
dev-cluster-md-0-yyyyy-aaaaa            dev-cluster   Running   27m
dev-cluster-md-0-bbbbbb-ccccc           dev-cluster   Running   2m    # ✅ Ready
dev-cluster-md-0-bbbbbb-ddddd           dev-cluster   Running   2m    # ✅ Ready
```

**Appuyez sur Ctrl+C.**

### Utiliser le script de scaling automatisé

```bash
./scale-workers.sh k0s-demo-cluster 3
```

**Résultat attendu:**
```
🔧 Scaling workers pour cluster: k0s-demo-cluster
   Nouvelle taille: 3 replicas

📋 MachineDeployment trouvé: k0s-demo-cluster-md-0
   Replicas actuelles: 2

🚀 Scaling MachineDeployment...
machinedeployment.cluster.x-k8s.io/k0s-demo-cluster-md-0 scaled
✅ Commande de scaling envoyée

👀 Monitoring du scaling...
⏱️  01:30 - Machines: 3/3 Running

🎉 Scaling terminé avec succès!

📊 État final:
NAME                                      CLUSTER            PHASE     VERSION   AGE
k0s-demo-cluster-md-0-xxxx-yyyy           k0s-demo-cluster   Running   v1.28.3   20m
k0s-demo-cluster-md-0-xxxx-zzzz           k0s-demo-cluster   Running   v1.28.3   20m
k0s-demo-cluster-md-0-aaaa-bbbb           k0s-demo-cluster   Running   v1.28.3   1m

🔍 Vérification dans le workload cluster:
   Nodes dans le cluster: 3/3 Ready

✅ Scaling de k0s-demo-cluster terminé: 2 → 3 replicas
```

---

## 📊 Partie 2: Monitoring des Ressources (4 minutes)

### Lancer le monitoring en temps réel

```bash
./monitor-resources.sh
```

**Dashboard attendu:**
```
📊 ClusterAPI Resource Monitor - 14:25:30
=============================

Cluster              Nodes  Pods     Containers CPU%     Memory
-------------------- ------ -------- -------- -------- ----------
management              1       45       1     15.2%      380MB
dev-cluster             5       12       5     25.1%      650MB
k0s-demo-cluster        3       10       3     18.5%      420MB

📈 Statistiques additionnelles:
   Clusters: 2 | Machines: 8
   k0smotron Control Plane Pods: 3
   HelmReleaseProxy: 2

🔄 Mise à jour toutes les 5 secondes...
   Ctrl+C pour arrêter le monitoring
```

**Laissez tourner 30 secondes pour observer les variations.**

### Observer l'impact du scaling

Le monitoring montre:
- **dev-cluster:** 5 containers (1 CP + 4 workers)
- **k0s-demo-cluster:** 3 containers (0 CP + 3 workers) ← Control plane virtualisé!
- **Économie:** k0smotron utilise 40% moins de containers

### Comparer la consommation

```bash
# Appuyez sur Ctrl+C pour arrêter le monitoring
```

**Observations clés:**
- **Management cluster:** Stable (~380MB)
- **dev-cluster:** Proportionnel au nombre de workers
- **k0s-demo-cluster:** Plus efficace (control plane partagé)

---

## 📚 Partie 3: Résumé des Concepts Appris (2 minutes)

### Récapitulatif des 5 Modules

| Module | Concept | Temps | Acquis |
|--------|---------|-------|--------|
| **00** | Introduction | 10min | Setup et vue d'ensemble |
| **01** | Premier cluster | 15min | Objets ClusterAPI de base |
| **02** | Networking | 15min | CNI automatisé avec ClusterResourceSets |
| **03** | k0smotron | 15min | Control plane virtualisé (55% économie) |
| **04** | Automation Helm | 20min | Déploiement multi-cluster GitOps |
| **05** | Operations | 15min | Scaling et monitoring |

### Technologies Maîtrisées

✅ **ClusterAPI Core:** Cluster, Machine, MachineDeployment, KubeadmControlPlane
✅ **Providers:** Docker (standard) et k0smotron (optimisé)
✅ **Automation:** ClusterResourceSets pour CNI, HelmChartProxy pour apps
✅ **Operations:** Scaling déclaratif, monitoring multi-cluster
✅ **GitOps:** Configuration centralisée et déploiement automatique

### Architectures Comparées

```
Docker Provider:          k0smotron:
┌─────────────────┐       ┌─────────────────┐
│ Management      │       │ Management      │
│ ┌─────────────┐ │       │ ┌─────────────┐ │
│ │ Controllers │ │       │ │ Controllers │ │
│ └─────────────┘ │       │ │ + CP Pods   │ │ ← Économie!
└─────────────────┘       │ └─────────────┘ │
┌─────────────────┐       └─────────────────┘
│ Workload Cluster│       ┌─────────────────┐
│ ┌─────────────┐ │       │ Workload Cluster│
│ │ CP Nodes    │ │       │ ┌─────────────┐ │
│ │ + Workers   │ │       │ │ Workers Only│ │ ← 55% économie
│ └─────────────┘ │       │ └─────────────┘ │
└─────────────────┘       └─────────────────┘
```

---

## 🧹 Partie 4: Cleanup Complet (3 minutes)

### Sauvegarder l'état final

```bash
echo "📊 État final avant cleanup:"
kubectl get clusters,machines,helmreleaseproxy
echo ""
echo "Docker containers:"
docker ps | grep -E "(dev-cluster|k0s-demo|capi-management)"
```

### Exécuter le cleanup automatisé

```bash
./cleanup.sh
```

**Progression attendue:**
```
🧹 ClusterAPI Workshop Cleanup
==============================

🔍 Workload clusters trouvés:
   - dev-cluster
   - k0s-demo-cluster

⚠️  ATTENTION: Cette opération va supprimer TOUS les workload clusters!

Clusters qui seront supprimés:
dev-cluster
k0s-demo-cluster

Êtes-vous sûr de vouloir continuer? (y/N): y

🗑️  Suppression des HelmChartProxy...
   Suppression HelmChartProxy: nginx-app
   ✅ HelmChartProxy supprimés

🗑️  Suppression des workload clusters...
   Suppression cluster: dev-cluster
   Suppression cluster: k0s-demo-cluster
   ✅ Commandes de suppression envoyées

👀 Monitoring de la suppression...
⏱️  02:15 - Clusters restants: 0 | Machines restantes: 0

🎉 Suppression terminée avec succès!

📊 État final:
   Clusters workload: 0
   Machines: 0
   HelmReleaseProxy: 0
   Docker containers:
     Management cluster: 1
     dev-cluster: 0
     k0s-demo-cluster: 0

🔍 Vérification du management cluster...
   ✅ Management cluster opérationnel (1/1 nodes Ready)

🎉 Cleanup terminé avec succès!

🎓 Workshop Express ClusterAPI terminé! 🎉
```

### Vérification finale

```bash
kubectl get clusters,machines,helmreleaseproxy
```

**Résultat attendu:**
```
No resources found
```

```bash
docker ps | grep kind
```

**Résultat attendu:**
```
CONTAINER ID   IMAGE                  NAMES
xxxxxxxxxxxx   kindest/node:v1.28.3   capi-management-control-plane  # ← Seul le management cluster reste
```

---

## 📈 Partie 5: Ressources pour Aller Plus Loin (2 minutes)

### Workshop Complet (3-4 heures)

Pour approfondir ClusterAPI:

```bash
echo "🎓 Ressources d'apprentissage:"
echo ""
echo "Workshop complet ClusterAPI:"
echo "   - URL: https://github.com/kubernetes-sigs/cluster-api/tree/main/docs/workshop"
echo "   - Durée: 3-4 heures"
echo "   - Contenu: 10 modules détaillés"
echo ""
echo "Modules avancés:"
echo "   - Providers cloud (AWS, Azure, GCP)"
echo "   - Cluster autoscaling"
echo "   - Disaster recovery"
echo "   - Observability et monitoring"
echo "   - Security et policy management"
echo ""
echo "Documentation officielle:"
echo "   - https://cluster-api.sigs.k8s.io/"
echo "   - https://k0smotron.io/"
echo ""
echo "Communauté:"
echo "   - Slack: #cluster-api sur Kubernetes Slack"
echo "   - GitHub: https://github.com/kubernetes-sigs/cluster-api"
```

### Prochaines Étapes Recommandées

1. **Production:** Tester avec un provider cloud (AWS/Azure/GCP)
2. **Automation:** Intégrer dans CI/CD GitOps
3. **Monitoring:** Déployer Prometheus + Grafana
4. **Security:** Implémenter OPA Gatekeeper
5. **Backup:** Configurer Velero pour disaster recovery

---

## ✅ Validation du Module

### Exécuter le script de validation

```bash
./validation.sh
```

**Résultat attendu:**
```
🔍 Module 05: Validation Operations & Cleanup
=============================================

✅ dev-cluster scalé à 4 workers
✅ k0s-demo-cluster scalé à 3 workers
✅ Script de monitoring existe et est exécutable
✅ Script de scaling existe et est exécutable
✅ Script de cleanup existe et est exécutable
✅ Cleanup exécuté (0 workload clusters)
✅ Cleanup exécuté (0 machines)
✅ Management cluster opérationnel

📊 Résumé workshop express:
   ⏱️  Durée totale: 90 minutes
   📖 5 modules complétés
   🎯 2 providers testés (Docker + k0smotron)
   🚀 Déploiement automatisé (Helm)
   📊 55% économie ressources (k0smotron)

=============================================
🎉 Workshop Express complété! 🎉
Félicitations! Vous maîtrisez ClusterAPI 🎓
=============================================
```

---

## 📚 Résumé des Opérations

| Opération | Commande | Résultat |
|-----------|----------|----------|
| **Scale Up** | `kubectl scale machinedeployment <name> --replicas=N` | Plus de workers |
| **Scale Down** | `kubectl scale machinedeployment <name> --replicas=N` | Moins de workers |
| **Monitor** | `./monitor-resources.sh` | Dashboard temps réel |
| **Cleanup** | `./cleanup.sh` | Suppression complète |

---

## 🔍 Troubleshooting

### Scaling bloqué
```bash
# Vérifier les events du MachineDeployment
kubectl describe machinedeployment <name>

# Logs du controller
kubectl logs -n capi-system deployment/capi-controller-manager -f
```

### Machines ne démarrent pas
```bash
# État des machines
kubectl get machines -o wide

# Events des machines
kubectl describe machine <machine-name>
```

### Cleanup incomplet
```bash
# Forcer la suppression
kubectl delete clusters --all --ignore-not-found=true
kubectl delete machines --all --ignore-not-found=true

# Retirer les finalizers si bloqué
kubectl patch cluster <name> -p '{"metadata":{"finalizers":[]}}' --type=merge
```

---

## 🎓 Ce Que Vous Avez Appris

✅ Scaler des clusters déclarativement (MachineDeployment)
✅ Monitorer les ressources multi-cluster en temps réel
✅ Comparer l'efficacité Docker vs k0smotron (55% économie)
✅ Automatiser les opérations avec scripts bash
✅ Nettoyer proprement un environnement ClusterAPI
✅ Comprendre l'écosystème complet ClusterAPI

---

**Module 05 complété! 🎉**
**Workshop Express terminé! 🎓**
**Temps total:** 90/90 minutes
**Prochaine étape:** Workshop complet 3-4h pour production!