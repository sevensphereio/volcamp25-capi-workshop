# Module 04: Automation avec Helm - Commandes

**Durée:** 20 minutes
**Objectif:** Déployer automatiquement des applications sur plusieurs clusters avec HelmChartProxy

---

## 📖 Partie 1: Introduction au Helm Addon Provider (4 minutes)

### Qu'est-ce que le Helm Addon Provider?

Le **Helm Addon Provider** automatise le déploiement d'applications Helm sur plusieurs clusters ClusterAPI simultanément.

```bash
cd /home/ubuntu/R_D/CLAUDE_PROJECTS/capi-workshop/workshop-express/04-automation-helm
```

### Architecture GitOps

```
Management Cluster
├── HelmChartProxy (template global)
│   └── clusterSelector: environment=demo
├── HelmReleaseProxy (par cluster)
│   ├── dev-cluster → nginx-app release
│   └── k0s-demo-cluster → nginx-app release
└── Auto-sync vers workload clusters
```

### Avantages vs Déploiement Manuel

| Méthode | Multi-cluster | Consistance | GitOps | Maintenance |
|---------|---------------|-------------|--------|-------------|
| **Manuel** | `helm install` x N | ❌ Dérive | ❌ Manuelle | 🔴 **Complexe** |
| **HelmChartProxy** | 1 manifest | ✅ Identique | ✅ Déclaratif | 🟢 **Simple** |

### Concepts Clés

✅ **HelmChartProxy:** Template global pour déployer sur plusieurs clusters
✅ **clusterSelector:** Sélectionne les clusters cibles via labels
✅ **HelmReleaseProxy:** Instance par cluster (créée automatiquement)
✅ **valuesTemplate:** Configuration Helm centralisée
✅ **Auto-sync:** Déploiement automatique sur nouveaux clusters

---

## 📋 Partie 2: Analyser nginx-helmchartproxy.yaml (3 minutes)

### Explorer le manifeste

```bash
cat nginx-helmchartproxy.yaml
```

### Décortique du HelmChartProxy

#### 1. Sélecteur de Clusters (L7-9)
```yaml
clusterSelector:
  matchLabels:
    environment: demo  # ← Cible tous les clusters avec ce label
```

**🎯 Tous les clusters avec `environment=demo` recevront nginx!**

#### 2. Configuration du Chart Helm (L10-13)
```yaml
repoURL: https://charts.bitnami.com/bitnami  # ← Repository Helm
chartName: nginx                             # ← Chart officiel nginx
version: 15.1.0                             # ← Version spécifique
releaseName: nginx-app                       # ← Nom du release
```

#### 3. Namespace Cible (L14)
```yaml
namespace: default  # ← Déploiement dans namespace default
```

#### 4. Valeurs Helm Centralisées (L15-18)
```yaml
valuesTemplate: |
  replicaCount: 2      # ← 2 pods nginx par cluster
  service:
    type: NodePort     # ← Service accessible depuis l'extérieur
```

### Flux de Déploiement

```
1. HelmChartProxy créé
2. Helm Addon Provider détecte les clusters matchLabels
3. HelmReleaseProxy créé pour chaque cluster
4. Helm chart déployé dans chaque workload cluster
5. Monitoring continu des nouveaux clusters
```

---

## 🏷️ Partie 3: Labeller les Clusters (2 minutes)

### Ajouter le label aux clusters existants

```bash
kubectl label cluster dev-cluster environment=demo
kubectl label cluster k0s-demo-cluster environment=demo
```

**Vérification:**
```bash
kubectl get clusters --show-labels
```

**Résultat attendu:**
```
NAME                 PHASE         AGE   LABELS
dev-cluster          Provisioned   20m   environment=demo
k0s-demo-cluster     Provisioned   15m   cni=calico,environment=demo
```

### Pourquoi labeller d'abord?

⚡ **Ordre important:** Les labels doivent exister AVANT la création du HelmChartProxy
⚡ **Auto-détection:** Le provider scanne les clusters existants immédiatement
⚡ **Évite race conditions:** Garantit que tous les clusters sont ciblés

---

## 🚀 Partie 4: Créer le HelmChartProxy (2 minutes)

### Appliquer le manifeste

```bash
kubectl apply -f nginx-helmchartproxy.yaml
```

**Résultat attendu:**
```
helmchartproxy.addons.cluster.x-k8s.io/nginx-app created
```

### Observer la création automatique des HelmReleaseProxy

```bash
watch -n 2 'kubectl get helmchartproxy,helmreleaseproxy'
```

**Progression attendue:**

**~10 secondes:**
```
NAME                                          CLUSTER   READY   STATUS
helmchartproxy.addons.cluster.x-k8s.io/nginx-app         False   Reconciling

NAME                                                                         CLUSTER           READY   STATUS
helmreleaseproxy.addons.cluster.x-k8s.io/dev-cluster-nginx-app               dev-cluster       False   Installing
helmreleaseproxy.addons.cluster.x-k8s.io/k0s-demo-cluster-nginx-app          k0s-demo-cluster  False   Installing
```

**~30 secondes:**
```
NAME                                          CLUSTER   READY   STATUS
helmchartproxy.addons.cluster.x-k8s.io/nginx-app         True    Ready

NAME                                                                         CLUSTER           READY   STATUS
helmreleaseproxy.addons.cluster.x-k8s.io/dev-cluster-nginx-app               dev-cluster       True    Deployed
helmreleaseproxy.addons.cluster.x-k8s.io/k0s-demo-cluster-nginx-app          k0s-demo-cluster  True    Deployed
```

**Appuyez sur Ctrl+C.**

**🎉 2 HelmReleaseProxy créés automatiquement!**

---

## 👀 Partie 5: Observer les Déploiements (4 minutes)

### Vérifier les HelmReleaseProxy en détail

```bash
kubectl get helmreleaseproxy -o wide
```

**Résultat:**
```
NAME                             CLUSTER           READY   STATUS     REVISION   CHART        VERSION
dev-cluster-nginx-app            dev-cluster       True    Deployed   1          nginx        15.1.0
k0s-demo-cluster-nginx-app       k0s-demo-cluster  True    Deployed   1          nginx        15.1.0
```

### Vérifier nginx dans dev-cluster

```bash
echo "=== dev-cluster nginx pods ==="
kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig get pods -l app.kubernetes.io/name=nginx
```

**Résultat attendu:**
```
NAME                         READY   STATUS    RESTARTS   AGE
nginx-app-xxx                1/1     Running   0          2m
nginx-app-yyy                1/1     Running   0          2m
```

### Vérifier nginx dans k0s-demo-cluster

```bash
echo "=== k0s-demo-cluster nginx pods ==="
kubectl --kubeconfig ../03-k0smotron/k0s-demo-cluster.kubeconfig get pods -l app.kubernetes.io/name=nginx
```

**Résultat attendu:**
```
NAME                         READY   STATUS    RESTARTS   AGE
nginx-app-xxx                1/1     Running   0          2m
nginx-app-yyy                1/1     Running   0          2m
```

### Vérifier les services

```bash
echo "=== dev-cluster nginx service ==="
kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig get svc nginx-app

echo ""
echo "=== k0s-demo-cluster nginx service ==="
kubectl --kubeconfig ../03-k0smotron/k0s-demo-cluster.kubeconfig get svc nginx-app
```

**Résultat pour chaque cluster:**
```
NAME        TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
nginx-app   NodePort   10.96.xxx.xxx  <none>        80:xxxxx/TCP   3m
```

---

## 🌐 Partie 6: Tester nginx avec Port-Forward (3 minutes)

### Test dev-cluster

```bash
echo "🧪 Test nginx sur dev-cluster..."
kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig port-forward svc/nginx-app 8080:80 &
PID1=$!
sleep 2

curl -s http://localhost:8080 | grep -o "<title>.*</title>" || echo "Page nginx détectée"
kill $PID1 2>/dev/null || true
wait $PID1 2>/dev/null || true
```

### Test k0s-demo-cluster

```bash
echo "🧪 Test nginx sur k0s-demo-cluster..."
kubectl --kubeconfig ../03-k0smotron/k0s-demo-cluster.kubeconfig port-forward svc/nginx-app 8081:80 &
PID2=$!
sleep 2

curl -s http://localhost:8081 | grep -o "<title>.*</title>" || echo "Page nginx détectée"
kill $PID2 2>/dev/null || true
wait $PID2 2>/dev/null || true
```

**Résultat attendu pour chaque test:**
```
🧪 Test nginx sur dev-cluster...
Forwarding from 127.0.0.1:8080 -> 80
<title>Welcome to nginx!</title>

🧪 Test nginx sur k0s-demo-cluster...
Forwarding from 127.0.0.1:8081 -> 80
<title>Welcome to nginx!</title>
```

### Statistiques de déploiement

```bash
echo "📊 Résumé du déploiement automatique:"
echo "   ✅ 1 HelmChartProxy → 2 HelmReleaseProxy"
echo "   ✅ 2 clusters → 4 pods nginx (2 par cluster)"
echo "   ✅ 2 services NodePort configurés"
echo "   ✅ Déploiement en ~30 secondes"
echo "   ✅ Configuration identique sur tous les clusters"
```

---

## 🎯 Partie 7: Test Nouveau Cluster (2 minutes)

### Simuler l'ajout d'un nouveau cluster

Si un nouveau cluster était créé avec le label `environment=demo`, nginx serait automatiquement déployé!

```bash
echo "💡 Test automatique:"
echo "   1. Nouveau cluster avec label environment=demo"
echo "   2. HelmReleaseProxy créé automatiquement"
echo "   3. nginx déployé sans intervention"
echo ""
echo "Commande théorique:"
echo "   kubectl label cluster nouveau-cluster environment=demo"
echo "   # nginx déployé automatiquement en <30s!"
```

### Voir la magie GitOps

```bash
kubectl describe helmchartproxy nginx-app | grep -A 10 "Status:"
```

**Points clés dans la sortie:**
- `Ready: True`
- `Status: Ready`
- `Conditions: Ready`
- Clusters matchés dans la liste

---

## ✅ Validation du Module

### Exécuter le script de validation

```bash
./validation.sh
```

**Résultat attendu:**
```
🔍 Module 04: Validation Automation Helm
=======================================

✅ HelmChartProxy nginx-app existe
✅ Cluster dev-cluster a le label environment=demo
✅ Cluster k0s-demo-cluster a le label environment=demo
✅ 2 HelmReleaseProxy créés automatiquement
✅ HelmReleaseProxy dev-cluster-nginx-app Ready
✅ HelmReleaseProxy k0s-demo-cluster-nginx-app Ready
✅ 2 pods nginx Running dans dev-cluster
✅ 2 pods nginx Running dans k0s-demo-cluster
✅ Service nginx-app existe dans dev-cluster
✅ Service nginx-app existe dans k0s-demo-cluster
✅ nginx accessible sur dev-cluster (port-forward test)
✅ nginx accessible sur k0s-demo-cluster (port-forward test)

📊 Résumé déploiement automatique:
   🎯 1 HelmChartProxy → 2 clusters ciblés
   🚀 2 HelmReleaseProxy → 4 pods nginx (2x2)
   ⚡ Déploiement en ~30 secondes
   🔄 GitOps: ajout cluster = déploiement auto

=======================================
🎉 Module 04 terminé avec succès!
🚀 Prêt pour Module 05: Operations & Cleanup
=======================================
```

---

## 📚 Résumé des Concepts

| Concept | Description | Avantage |
|---------|-------------|----------|
| **HelmChartProxy** | Template global multi-cluster | 1 manifest → N clusters |
| **clusterSelector** | Sélection via labels | Ciblage flexible |
| **HelmReleaseProxy** | Instance par cluster (auto) | Gestion granulaire |
| **valuesTemplate** | Configuration centralisée | Consistance garantie |
| **GitOps** | Déclaratif et idempotent | Automatisation complète |

---

## 🔍 Troubleshooting

### HelmChartProxy reste False
```bash
# Vérifier le controller
kubectl logs -n capi-system deployment/capi-addon-helm-controller-manager -f

# Vérifier les events
kubectl describe helmchartproxy nginx-app
```

### HelmReleaseProxy échoue
```bash
# Détails de l'erreur
kubectl describe helmreleaseproxy dev-cluster-nginx-app

# Logs de déploiement
kubectl logs -n capi-system -l cluster.x-k8s.io/provider=addon-helm
```

### nginx pods ne démarrent pas
```bash
# Dans le workload cluster
kubectl --kubeconfig dev-cluster.kubeconfig describe pods -l app.kubernetes.io/name=nginx

# Events du namespace
kubectl --kubeconfig dev-cluster.kubeconfig get events --sort-by=.lastTimestamp
```

### Repository Helm inaccessible
```bash
# Test de connectivité
helm repo add bitnami https://charts.bitnami.com/bitnami
helm search repo bitnami/nginx

# Vérifier la version
helm show chart bitnami/nginx --version 15.1.0
```

---

## 🎓 Ce Que Vous Avez Appris

✅ Automatiser le déploiement multi-cluster avec Helm
✅ Utiliser clusterSelector pour cibler des clusters
✅ Comprendre HelmChartProxy → HelmReleaseProxy
✅ Centraliser la configuration avec valuesTemplate
✅ Implémenter GitOps pour les applications
✅ Tester la connectivité des applications déployées

---

## ⏭️ Prochaine Étape

**Module 05 (15 min):** Operations & Cleanup
- Scaling des workers
- Monitoring des ressources
- Cleanup complet

```bash
cd ../05-operations-cleanup
cat commands.md
```

---

**Module 04 complété! 🎉**
**Temps écoulé:** 75/90 minutes (10+15+15+15+20)
**Prochaine étape:** Module 05 - Operations & Cleanup