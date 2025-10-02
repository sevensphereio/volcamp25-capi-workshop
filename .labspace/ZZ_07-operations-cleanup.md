# Module 07: Operations & Cleanup

**Durée:** 15 minutes

---

## 🎯 Objectifs & Concepts

### Ce que vous allez apprendre
- Scaler des clusters déclarativement (MachineDeployment)
- Monitorer les ressources multi-cluster
- Nettoyer proprement un environnement ClusterAPI
- Récapituler les compétences acquises en 2 heures (120 minutes)

### Concepts clés
**MachineDeployment:** Équivalent des Deployments Kubernetes pour l'infrastructure. Permet de scaler les workers de manière déclarative (kubectl scale), avec les mêmes patterns que les pods.

**Scaling ClusterAPI:**
```
kubectl scale machinedeployment <name> --replicas=N
```
Fonctionne exactement comme `kubectl scale deployment` pour les pods!

**Cleanup Graceful:**
Ordre correct pour éviter les ressources orphelines :
1. Applications (HelmChartProxy)
2. Clusters (workload clusters)
3. Management cluster préservé

**Monitoring Multi-Cluster:**
Vue d'ensemble centralisée de tous les clusters depuis le management cluster pour détecter les anomalies et comparer les performances.

---

## 📋 Actions Pas-à-Pas

### Action 1: Vérifier l'état actuel des workers

**Objectif:** Connaître le nombre de workers avant scaling

**Commande:**
```bash
cd /home/ubuntu/R_D/CLAUDE_PROJECTS/capi-workshop/workshop-express/07-operations-cleanup
kubectl get machinedeployment -o wide
```

**Explication de la commande:**
- `get machinedeployment`: liste tous les MachineDeployments (gestion des workers)
- `-o wide`: affiche des colonnes supplémentaires (replicas, ready, updated)

**Résultat attendu:**
```
NAME                   CLUSTER            REPLICAS   READY   UPDATED   AGE
dev-cluster-md-0       dev-cluster        2          2       2         25m
k0s-demo-cluster-md-0  k0s-demo-cluster   2          2       2         20m
```

**✅ Vérification:** Actuellement 2 workers (replicas) par cluster.

---

### Action 2: Scaler dev-cluster à 4 workers

**Objectif:** Augmenter le nombre de workers déclarativement

**Commande:**
```bash
kubectl scale machinedeployment dev-cluster-md-0 --replicas=4
```

**Explication de la commande:**
- `scale machinedeployment`: commande de scaling (comme pour Deployments)
- `dev-cluster-md-0`: nom du MachineDeployment à scaler
- `--replicas=4`: nouvelle taille cible (2 → 4 workers)

**Résultat attendu:**
```
machinedeployment.cluster.x-k8s.io/dev-cluster-md-0 scaled
```

**✅ Vérification:** La commande de scaling est acceptée. Les nouvelles machines vont se provisionner.

---

### Action 3: Observer le scaling en temps réel

**Objectif:** Voir les nouvelles machines apparaître et passer à Running

**Commande:**
```bash
watch -n 2 'kubectl get machines -l cluster.x-k8s.io/cluster-name=dev-cluster'
```

**Explication de la commande:**
- `watch -n 2`: rafraîchit l'affichage toutes les 2 secondes
- `-l cluster.x-k8s.io/cluster-name=dev-cluster`: filtre pour n'afficher que les machines de dev-cluster

**Résultat attendu (progression):**

**~30 secondes:**
```
NAME                                    CLUSTER       PHASE         AGE
dev-cluster-control-plane-xxxx          dev-cluster   Running       25m
dev-cluster-md-0-yyyyy-zzzzz            dev-cluster   Running       25m
dev-cluster-md-0-yyyyy-aaaaa            dev-cluster   Running       25m
dev-cluster-md-0-bbbbbb-ccccc           dev-cluster   Provisioning  30s  # Nouveau
dev-cluster-md-0-bbbbbb-ddddd           dev-cluster   Provisioning  30s  # Nouveau
```

**~2 minutes:**
```
NAME                                    CLUSTER       PHASE     AGE
dev-cluster-control-plane-xxxx          dev-cluster   Running   27m
dev-cluster-md-0-yyyyy-zzzzz            dev-cluster   Running   27m
dev-cluster-md-0-yyyyy-aaaaa            dev-cluster   Running   27m
dev-cluster-md-0-bbbbbb-ccccc           dev-cluster   Running   2m    # Ready!
dev-cluster-md-0-bbbbbb-ddddd           dev-cluster   Running   2m    # Ready!
```

**✅ Vérification:** 5 machines au total (1 CP + 4 workers). Appuyez sur Ctrl+C.

---

### Action 4: Scaler k0s-demo-cluster avec le script

**Objectif:** Utiliser le script automatisé pour scaler avec monitoring intégré

**Commande:**
```bash
./scale-workers.sh k0s-demo-cluster 3
```

**Explication de la commande:**
- `./scale-workers.sh`: script qui scale et monitore automatiquement
- `k0s-demo-cluster`: nom du cluster cible
- `3`: nouvelle taille cible (2 → 3 workers)

**Résultat attendu:**
```
🔧 Scaling workers pour cluster: k0s-demo-cluster
   Nouvelle taille: 3 replicas

📋 MachineDeployment trouvé: k0s-demo-cluster-md-0
   Replicas actuelles: 2

🚀 Scaling MachineDeployment...
✅ Commande de scaling envoyée

👀 Monitoring du scaling...
⏱️  01:30 - Machines: 3/3 Running

🎉 Scaling terminé avec succès!

📊 État final:
NAME                                      CLUSTER            PHASE     AGE
k0s-demo-cluster-md-0-xxxx-yyyy           k0s-demo-cluster   Running   20m
k0s-demo-cluster-md-0-xxxx-zzzz           k0s-demo-cluster   Running   20m
k0s-demo-cluster-md-0-aaaa-bbbb           k0s-demo-cluster   Running   1m

✅ Scaling de k0s-demo-cluster terminé: 2 → 3 replicas
```

**✅ Vérification:** k0s-demo-cluster a maintenant 3 workers. Le script a monitoré automatiquement.

---

### Action 5: Lancer le monitoring des ressources

**Objectif:** Observer la consommation des clusters en temps réel

**Commande:**
```bash
./monitor-resources.sh
```

**Explication de la commande:**
- Script qui affiche un dashboard temps réel des ressources (nodes, pods, containers, mémoire)
- Rafraîchissement automatique toutes les 5 secondes

**Résultat attendu:**
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

**✅ Vérification:** Le dashboard affiche tous les clusters. Notez la différence : dev-cluster (5 containers) vs k0s-demo-cluster (3 containers) car k0smotron n'a pas de control plane node. Laissez tourner 30 secondes puis Ctrl+C.

---

### Action 6: Comparer l'impact du scaling

**Objectif:** Comprendre l'effet du scaling sur les ressources

**Commande:**
```bash
echo "📊 Comparaison post-scaling:"
echo "dev-cluster: 1 CP + 4 workers = 5 containers"
echo "k0s-demo-cluster: 0 CP + 3 workers = 3 containers"
echo ""
echo "Économie k0smotron: 40% moins de containers (3 vs 5)"
```

**Explication de la commande:**
- Simple affichage pour visualiser l'économie même après scaling

**Résultat attendu:**
```
📊 Comparaison post-scaling:
dev-cluster: 1 CP + 4 workers = 5 containers
k0s-demo-cluster: 0 CP + 3 workers = 3 containers

Économie k0smotron: 40% moins de containers (3 vs 5)
```

**✅ Vérification:** k0smotron reste plus efficient même avec différentes tailles de clusters.

---

### Action 7: Récapitulatif du workshop (2 heures)

**Objectif:** Visualiser le parcours d'apprentissage complet

**Commande:**
```bash
cat << 'EOF'
🎓 Parcours d'Apprentissage - 90 Minutes de Maîtrise

Module 00 (10min): Fondations
├─ ClusterAPI = "Kubernetes pour gérer Kubernetes"
├─ Management vs Workload clusters
└─ Controllers et boucles de réconciliation

Module 01 (15min): Premier Cluster
├─ 7 objets pour 1 cluster (séparation responsabilités)
├─ Cluster lifecycle: Pending → Provisioning → Provisioned
└─ Machine ≠ Node (CRD vs objet K8s)

Module 02 (15min): Networking
├─ CNI = système postal des pods
├─ ClusterResourceSets = automation addons
└─ Pattern label-based (GitOps)

Module 03 (15min): k0smotron
├─ Control plane virtualisé (pods vs nodes)
├─ 55% économie ressources, 66% temps boot
└─ Cas d'usage: dev, CI/CD, multi-tenancy

Module 04 (20min): Helm Automation
├─ HelmChartProxy = template multi-cluster
├─ 1 manifest → N instances automatiques
└─ GitOps (1 commit = N déploiements)

Module 07 (15min): Operations
├─ Scaling déclaratif (MachineDeployment)
├─ Monitoring multi-cluster
└─ Cleanup graceful

✅ Architecture Créée:
├─ 2 workload clusters fonctionnels
├─ 7 nodes (1 CP + 4 workers + 3 workers k0s)
├─ 3 CP pods k0smotron
├─ 2 applications déployées (nginx x2)
└─ Automation complète (CRS + Helm)

🏆 Compétences Acquises:
✅ ClusterAPI Core (Maîtrise)
✅ Multi-Provider (Docker + k0smotron)
✅ Automation (CRS label-based)
✅ GitOps Multi-Cluster (HelmChartProxy)
✅ Optimisation (économies 37-90%)
✅ Operations (scaling, monitoring)
EOF
```

**✅ Vérification:** Récapitulatif complet de tout ce qui a été appris et construit.

---

### Action 8: Sauvegarder l'état final

**Objectif:** Capturer l'état avant le cleanup pour référence

**Commande:**
```bash
echo "📊 État final avant cleanup:"
kubectl get clusters,machines,helmreleaseproxy
echo ""
echo "Docker containers:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "(dev-cluster|k0s-demo|capi-management)"
```

**Explication de la commande:**
- `get clusters,machines,helmreleaseproxy`: affiche tous les objets ClusterAPI créés
- `docker ps`: affiche les containers Docker correspondants

**Résultat attendu:**
```
📊 État final avant cleanup:
NAME                                        PHASE         AGE
cluster.cluster.x-k8s.io/dev-cluster          Provisioned   30m
cluster.cluster.x-k8s.io/k0s-demo-cluster     Provisioned   25m

NAME                                                PHASE     AGE
machine.cluster.x-k8s.io/dev-cluster-cp-xxxx        Running   30m
machine.cluster.x-k8s.io/dev-cluster-md-0-...       Running   30m
[... total 8 machines ...]

NAME                                                                         READY
helmreleaseproxy.addons.cluster.x-k8s.io/dev-cluster-nginx-app               True
helmreleaseproxy.addons.cluster.x-k8s.io/k0s-demo-cluster-nginx-app          True

Docker containers:
capi-management-control-plane     Up 35 minutes
dev-cluster-control-plane-xxxx    Up 30 minutes
dev-cluster-md-0-... [4 workers]
k0s-demo-cluster-md-0-... [3 workers]
```

**✅ Vérification:** État complet capturé : 2 clusters, 8 machines, 2 apps déployées.

---

### Action 9: Exécuter le cleanup automatisé

**Objectif:** Nettoyer proprement tous les workload clusters

**Commande:**
```bash
./cleanup.sh
```

**Explication de la commande:**
- Script interactif qui supprime : HelmChartProxy → Clusters → Machines
- Ordre correct pour éviter les ressources orphelines
- Management cluster préservé

**Résultat attendu:**
```
🧹 ClusterAPI Workshop Cleanup
==============================

🔍 Workload clusters trouvés:
   - dev-cluster
   - k0s-demo-cluster

⚠️  ATTENTION: Cette opération va supprimer TOUS les workload clusters!

Êtes-vous sûr de vouloir continuer? (y/N): y

🗑️  Suppression des HelmChartProxy...
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
   Management cluster: ✅ Opérationnel

🎓 Workshop Express ClusterAPI terminé! 🎉
```

**✅ Vérification:** Tous les workload clusters et ressources supprimés. Management cluster intact.

---

### Action 10: Vérifier le cleanup complet

**Objectif:** Confirmer qu'il ne reste aucune ressource workload

**Commande:**
```bash
kubectl get clusters,machines,helmreleaseproxy
```

**Explication de la commande:**
- Même commande qu'avant le cleanup pour vérifier la suppression

**Résultat attendu:**
```
No resources found
```

**✅ Vérification:** Aucune ressource ClusterAPI restante. Cleanup complet!

---

### Action 11: Vérifier que le management cluster est intact

**Objectif:** Confirmer que seul le management cluster subsiste

**Commande:**
```bash
docker ps --format "table {{.Names}}\t{{.Status}}" | grep kind
```

**Explication de la commande:**
- `docker ps`: liste les containers
- `grep kind`: filtre pour n'afficher que le management cluster (kind)

**Résultat attendu:**
```
NAMES                              STATUS
capi-management-control-plane      Up 40 minutes
```

**✅ Vérification:** Seul le management cluster kind reste. Workload clusters supprimés.

---

### Action 12: Validation finale du module

**Objectif:** Vérifier que toutes les opérations sont complétées

**Commande:**
```bash
./validation.sh
```

**Explication de la commande:**
- Script qui vérifie : scaling effectué, monitoring exécuté, cleanup complété, management cluster opérationnel

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
   ⏱️  Durée totale: 120 minutes (2 heures)
   📖 5 modules complétés
   🎯 2 providers testés (Docker + k0smotron)
   🚀 Déploiement automatisé (Helm)
   📊 55% économie ressources (k0smotron)

=============================================
🎉 Workshop Express complété! 🎉
Félicitations! Vous maîtrisez ClusterAPI 🎓
=============================================
```

**✅ Vérification:** Workshop complété avec succès! Tous les objectifs atteints.

---

## 💡 Comprendre en Profondeur

### Scaling Déclaratif : MachineDeployment = Deployment

ClusterAPI réutilise les patterns Kubernetes pour l'infrastructure :

```bash
# Scaling pods (standard Kubernetes)
kubectl scale deployment nginx --replicas=5

# Scaling workers (ClusterAPI - EXACTEMENT pareil!)
kubectl scale machinedeployment dev-cluster-md-0 --replicas=5
```

**Mêmes concepts :**
- Déclaratif (état désiré vs impératif)
- Reconciliation automatique
- Rollout progressif
- Self-healing (remplace machines défaillantes)

---

### Ordre de Cleanup : Pourquoi c'est Important

**Ordre correct (script):**
```
1. HelmChartProxy (applications)
2. Clusters (workload clusters)
3. Machines (supprimées automatiquement avec clusters)
```

**Pourquoi pas l'inverse ?**
- Supprimer cluster AVANT apps = apps orphelines dans workload cluster mourant
- Supprimer machines AVANT cluster = cluster controller confus
- Script gère les finalizers et dépendances

---

### Monitoring Multi-Cluster : Vue Centralisée

**Avantage management cluster :**
```
1 point de contrôle → N clusters observés
```

En production, ajouter :
- Prometheus pour métriques détaillées
- Grafana pour dashboards visuels
- Alertmanager pour notifications
- Export vers SIEM pour audit

---

### Ce Que Vous Avez Construit en 90 Minutes

**Infrastructure complète :**
- 1 management cluster (kind)
- 2 workload clusters (Docker + k0smotron)
- 7 nodes (1 CP + 6 workers)
- 3 pods control plane virtualisés
- 2 applications automatisées (nginx)
- GitOps complet (CRS + HelmChartProxy)

**Valeur production :**
Cette architecture peut gérer 100+ clusters avec même effort!

---

## 🔍 Troubleshooting

**Scaling bloqué:**
```bash
# Events du MachineDeployment
kubectl describe machinedeployment dev-cluster-md-0

# Logs du controller
kubectl logs -n capi-system deployment/capi-controller-manager -f
```

**Machines ne démarrent pas:**
```bash
# État des machines
kubectl get machines -o wide

# Events des machines
kubectl describe machine dev-cluster-md-0-xxxx-yyyy
```

**Cleanup incomplet:**
```bash
# Forcer la suppression
kubectl delete clusters --all --ignore-not-found=true

# Retirer les finalizers si bloqué
kubectl patch cluster dev-cluster -p '{"metadata":{"finalizers":[]}}' --type=merge
```

---

## 🎉 FÉLICITATIONS !

### Vous avez complété le Workshop ClusterAPI Express!

**En 2 heures, vous avez :**
- ✅ Maîtrisé ClusterAPI de zéro à l'automation avancée
- ✅ Créé 2 clusters avec 2 providers différents
- ✅ Implémenté GitOps multi-cluster (CRS + Helm)
- ✅ Optimisé les coûts avec k0smotron (55-90% économies)
- ✅ Acquis des compétences production-ready

### 🏆 Vous êtes maintenant capable de:
- Gérer des flottes de clusters Kubernetes déclarativement
- Implémenter GitOps pour infrastructure ET applications
- Optimiser les coûts cloud significativement
- Automatiser le lifecycle complet des clusters
- Architecturer des solutions multi-cloud

### 🚀 Prochaines étapes recommandées:

**Semaine 1-2: Expérimentation**
- Refaire ce workshop localement
- Tester avec différents providers
- Créer vos propres ClusterResourceSets

**Semaine 3-4: POC Cloud**
- Setup management cluster sur AWS/Azure/GCP
- Créer 2-3 clusters de test
- Implémenter GitOps avec ArgoCD/Flux

**Mois 2: Production Pilot**
- Migrer 1 application non-critique
- Setup monitoring complet
- Documenter runbooks

**Mois 3+: Rollout Complet**
- Migration progressive des workloads
- Automation CI/CD complète
- Self-service pour équipes dev

### 📚 Ressources pour aller plus loin:

**Documentation officielle:**
- ClusterAPI: https://cluster-api.sigs.k8s.io/
- k0smotron: https://k0smotron.io/

**Communauté:**
- Slack: #cluster-api sur Kubernetes Slack
- GitHub: https://github.com/kubernetes-sigs/cluster-api

**Workshop complet (3-4h):**
- 10 modules avancés
- Cloud providers (AWS, Azure, GCP)
- Production features (observability, DR, security)

---

**🎊 Workshop Express TERMINÉ avec SUCCÈS! 🎊**

**Merci d'avoir participé et bon voyage dans le monde ClusterAPI! 🌟**