# Module 05: Automation avec Helm

**Durée:** 20 minutes

---

## 🎯 Objectifs & Concepts

### Ce que vous allez apprendre
- Automatiser le déploiement d'applications sur plusieurs clusters
- Utiliser HelmChartProxy pour GitOps multi-cluster
- Sélection de clusters par labels
- Pattern self-service pour équipes développement

### Concepts clés
**Helm Addon Provider:** Extension ClusterAPI qui permet de déployer des Helm charts automatiquement sur plusieurs workload clusters via un système de proxy.

**HelmChartProxy:** Template global (dans management cluster) qui définit QUEL chart déployer et sur QUELS clusters (via clusterSelector). Un HelmChartProxy crée automatiquement des HelmReleaseProxy pour chaque cluster matchant.

**HelmReleaseProxy:** Instance concrète par cluster (créée automatiquement), représente un déploiement Helm spécifique. Ne pas modifier manuellement.

**Workflow GitOps:**
```
1. HelmChartProxy créé (template + sélecteur)
2. Provider détecte clusters avec labels matchants
3. HelmReleaseProxy créé automatiquement par cluster
4. Helm chart déployé dans chaque workload cluster
5. Nouveaux clusters avec label = déploiement automatique
```

**Avantages vs déploiement manuel:**
- 1 manifest → N clusters (scalabilité)
- Consistance garantie (même version partout)
- Self-service (équipes dev ajoutent label = app déployée)
- GitOps natif (1 commit = propagation automatique)

---

## 📋 Actions Pas-à-Pas

### Action 1: Installer le Helm Addon Provider

**Objectif:** Ajouter le support pour le déploiement automatique d'applications Helm multi-clusters

**Commande:**
```bash
clusterctl init \
  --core cluster-api:v1.10.6 \
  --bootstrap kubeadm:v1.10.6 \
  --control-plane kubeadm:v1.10.6 \
  --infrastructure docker:v1.10.6 \
  --addon helm:v0.3.2
```

**Explication de la commande:**
- `clusterctl init` : Commande d'initialisation ClusterAPI
- `--addon helm:v0.3.2` : Installe le Helm Addon Provider version 0.3.2
- Installation automatique dans le namespace `caaph-system` (CAPI Addon Provider Helm)
- Doit être exécuté avec tous les providers pour ajouter l'addon

**Résultat attendu:**
```
Fetching providers
Skipping installing cert-manager as it is already installed
Installing Provider="addon-helm" Version="v0.3.2" TargetNamespace="caaph-system"

Your management cluster has been configured with the addon provider!

You can now use HelmChartProxy to deploy Helm charts across multiple clusters.
```

**✅ Vérification:**
```bash
kubectl get pods -n caaph-system
```

**Résultat attendu:**
```
NAME                                        READY   STATUS    RESTARTS   AGE
caaph-controller-manager-xxx                1/1     Running   0          1m
```

---

### Action 2: Analyser le manifeste HelmChartProxy

**Objectif:** Comprendre la structure du proxy avant déploiement

**Commande:**
```bash
cd ~/05-automation-helm
cat nginx-helmchartproxy.yaml
```

**Explication de la commande:**
- `cat`: affiche le contenu complet du fichier HelmChartProxy

**Résultat attendu:**
```yaml
apiVersion: addons.cluster.x-k8s.io/v1alpha1
kind: HelmChartProxy
metadata:
  name: nginx-app
spec:
  clusterSelector:
    matchLabels:
      environment: demo      # Cible tous clusters avec ce label
  repoURL: https://charts.bitnami.com/bitnami
  chartName: nginx
  version: 15.1.0
  releaseName: nginx-app
  namespace: default
  valuesTemplate: |
    replicaCount: 2          # 2 pods nginx par cluster
    service:
      type: NodePort         # Service accessible depuis extérieur
```

**✅ Vérification:** Le HelmChartProxy cible `environment: demo` et déploiera nginx avec 2 replicas sur tous les clusters matchants.

**hint: y'a aussi openbao à tester :)**
---

### Action 3: Labeller les clusters pour le ciblage

**Objectif:** Ajouter le label avant de créer le HelmChartProxy pour éviter race conditions

**Commande:**
```bash
kubectl label cluster dev-cluster environment=demo
```

**Explication de la commande:**
- `label cluster`: ajoute le label `environment=demo` aux deux clusters
- Ordre important : labels AVANT HelmChartProxy pour détection immédiate

**Résultat attendu:**
```
cluster.cluster.x-k8s.io/dev-cluster labeled
```

**✅ Vérification:** Les deux clusters ont maintenant le label qui matche le clusterSelector.

---

### Action 4: Vérifier les labels appliqués

**Objectif:** Confirmer que les clusters sont correctement étiquetés

**Commande:**
```bash
kubectl get clusters --show-labels
```

**Explication de la commande:**
- `--show-labels`: affiche tous les labels de chaque cluster

**Résultat attendu:**
```
NAME                 PHASE         AGE   LABELS
dev-cluster          Provisioned   25m   cni=calico,environment=demo
```

**✅ Vérification:** Les deux clusters ont `environment=demo` dans leurs labels.

---

### Action 5: Créer le HelmChartProxy

**Objectif:** Déployer le template global qui déclenchera les déploiements

**Commande:**
```bash
kubectl apply -f nginx-helmchartproxy.yaml
```

**Explication de la commande:**
- `apply -f`: crée le HelmChartProxy dans le management cluster
- Le provider détectera immédiatement les clusters matchants

**Résultat attendu:**
```
helmchartproxy.addons.cluster.x-k8s.io/nginx-app created
```

**✅ Vérification:** Le HelmChartProxy est créé. Le provider va maintenant créer des HelmReleaseProxy automatiquement.

---

### Action 6: Observer la création automatique des HelmReleaseProxy

**Objectif:** Voir la magie GitOps en action - création automatique des instances

**Commande:**
```bash
watch -n 2 'kubectl get helmchartproxy,helmreleaseproxy'
```

**Explication de la commande:**
- `watch -n 2`: rafraîchit l'affichage toutes les 2 secondes
- Affiche à la fois le proxy (template) et les releases (instances)

**Résultat attendu (progression):**

**~10 secondes:**
```
NAME                                          READY   STATUS
helmchartproxy.addons.cluster.x-k8s.io/nginx-app         False   Reconciling

NAME                                                                         READY   STATUS
helmreleaseproxy.addons.cluster.x-k8s.io/dev-cluster-nginx-app               False   Installing
```

**~30 secondes:**
```
NAME                                          READY   STATUS
helmchartproxy.addons.cluster.x-k8s.io/nginx-app         True    Ready

NAME                                                                         READY   STATUS
helmreleaseproxy.addons.cluster.x-k8s.io/dev-cluster-nginx-app               True    Deployed
```

**✅ Vérification:** 2 HelmReleaseProxy créés automatiquement (1 par cluster) et STATUS=Deployed. Appuyez sur Ctrl+C.

---

### Action 7: Vérifier les détails des HelmReleaseProxy

**Objectif:** Voir les informations de chaque déploiement

**Commande:**
```bash
kubectl get helmreleaseproxy -o wide
```

**Explication de la commande:**
- `-o wide`: affiche des colonnes supplémentaires (revision, chart, version)

**Résultat attendu:**
```
NAME                             CLUSTER           READY   STATUS     REVISION   CHART        VERSION
dev-cluster-nginx-app            dev-cluster       True    Deployed   1          nginx        15.1.0
```

**✅ Vérification:** Même chart, même version sur les deux clusters = consistance garantie!

---

### Action 8: Vérifier nginx dans dev-cluster

**Objectif:** Confirmer que les pods nginx tournent dans le premier workload cluster

**Commande:**
```bash
kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig get pods -l app.kubernetes.io/name=nginx
```

**Explication de la commande:**
- `--kubeconfig`: utilise le kubeconfig du workload cluster dev-cluster
- `-l app.kubernetes.io/name=nginx`: filtre pour afficher seulement les pods nginx

**Résultat attendu:**
```
NAME                         READY   STATUS    RESTARTS   AGE
nginx-app-xxx                1/1     Running   0          2m
nginx-app-yyy                1/1     Running   0          2m
```

**✅ Vérification:** 2 pods nginx Running dans dev-cluster (replicaCount: 2 dans valuesTemplate).

---

### Action 9: Vérifier nginx dans k0s-demo-cluster

**Objectif:** Confirmer que les pods nginx tournent dans le second workload cluster

**Commande:**
```bash
kubectl --kubeconfig ~/03-k0smotron/k0s-demo-cluster.kubeconfig get pods -l app.kubernetes.io/name=nginx
```

**Explication de la commande:**
- `--kubeconfig`: utilise le kubeconfig du workload cluster k0s-demo-cluster
- Même filtre pour nginx

**Résultat attendu:**
```
NAME                         READY   STATUS    RESTARTS   AGE
nginx-app-xxx                1/1     Running   0          2m
nginx-app-yyy                1/1     Running   0          2m
```

**✅ Vérification:** 2 pods nginx Running dans k0s-demo-cluster également. Configuration identique!

---

### Action 10: Vérifier les services créés

**Objectif:** Confirmer que les services NodePort sont déployés

**Commande:**
```bash
kubectl --kubeconfig ~/01-premier-cluster/dev-cluster.kubeconfig get svc nginx-app

```

**Explication de la commande:**
- `get svc nginx-app`: affiche le service nginx-app créé par le chart Helm
- Deux commandes pour comparer les deux clusters

**Résultat attendu (pour chaque cluster):**
```
NAME        TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
nginx-app   NodePort   10.96.xxx.xxx  <none>        80:xxxxx/TCP   3m
```

**✅ Vérification:** Service de type NodePort créé dans les deux clusters avec un port aléatoire (30000-32767).

---

### Action 11: Tester nginx avec port-forward

**Objectif:** Valider que nginx est accessible et fonctionnel

**Commande:**
```bash
# Test dev-cluster
kubectl --kubeconfig ~/01-premier-cluster/dev-cluster.kubeconfig port-forward svc/nginx-app 8080:80 &
PID1=$!
sleep 2
curl -s http://localhost:8080 | grep -o "<title>.*</title>"
kill $PID1 2>/dev/null
```

**Explication de la commande:**
- `port-forward svc/nginx-app 8080:80`: forward le port 80 du service vers localhost:8080
- `&`: exécute en arrière-plan
- `PID=$!`: sauvegarde le PID du processus pour le tuer ensuite
- `curl`: teste l'accès HTTP
- `grep -o "<title>.*</title>"`: extrait le titre de la page nginx

**Résultat attendu:**
```
<title>Welcome to nginx!</title>
<title>Welcome to nginx!</title>
```

**✅ Vérification:** Nginx répond correctement sur les deux clusters!

---

### Action 12: Validation automatique du module

**Objectif:** Vérifier que toutes les étapes sont réussies

**Commande:**
```bash
./validation.sh
```

**Explication de la commande:**
- Script qui vérifie : HelmChartProxy existe, labels appliqués, HelmReleaseProxy créés, pods Running, services accessibles

**Résultat attendu:**
```
🔍 Module 05: Validation Automation Helm
=======================================

- ✅ HelmChartProxy nginx-app existe
- ✅ Cluster dev-cluster a le label environment=demo
- ✅ Cluster k0s-demo-cluster a le label environment=demo
- ✅ 2 HelmReleaseProxy créés automatiquement
- ✅ HelmReleaseProxy dev-cluster-nginx-app Ready
- ✅ HelmReleaseProxy k0s-demo-cluster-nginx-app Ready
- ✅ 2 pods nginx Running dans dev-cluster
- ✅ Service nginx-app existe dans dev-cluster
- ✅ Service nginx-app existe dans k0s-demo-cluster


=======================================
🎉 Module 05 terminé avec succès!
🚀 Prêt pour Module 06: Cluster Upgrades
=======================================
```

**✅ Vérification:** Tous les checks passent. GitOps multi-cluster fonctionnel!

---

## 💡 Comprendre en Profondeur

### HelmChartProxy vs HelmReleaseProxy

| Aspect | HelmChartProxy | HelmReleaseProxy |
|--------|----------------|------------------|
| **Scope** | Global (management) | Par cluster (management) |
| **Création** | Manuelle (vous) | Automatique (provider) |
| **Nombre** | 1 pour N clusters | N (1 par cluster matchant) |
| **Contenu** | Template + sélection | Instance concrète |
| **Modification** | Modifiable (propage) | Généré (ne pas toucher) |

**Analogie:** HelmChartProxy = recette de cuisine (template réutilisable), HelmReleaseProxy = plat préparé dans chaque restaurant (instance).

---

### Pattern Self-Service pour Platform Engineering

Les équipes platform créent des HelmChartProxy pour les services communs :

```yaml
kind: HelmChartProxy
metadata:
  name: monitoring-stack
spec:
  clusterSelector:
    matchLabels:
      monitoring: enabled  # Opt-in
  resources:
    - prometheus
    - grafana
```

Les équipes dev activent les services en ajoutant un label :
```bash
kubectl label cluster my-app-cluster monitoring=enabled
# Stack monitoring déployé automatiquement!
```

**Avantages:**
- Gouvernance centralisée (platform contrôle les HelmChartProxy)
- Self-service décentralisé (dev ajoutent labels)
- Consistance garantie (même version partout)

---

### Sélecteurs Avancés : Logique AND

Le `matchLabels` utilise une logique AND pour plus de précision :

```yaml
clusterSelector:
  matchLabels:
    environment: production   # ET
    region: eu-west-1         # ET
    tier: frontend            # = Clusters prod EU frontend uniquement
```

Permet un ciblage très granulaire pour des stratégies complexes.

---

### valuesTemplate : Configuration Centralisée

Le valuesTemplate permet d'éviter la duplication (DRY principle) :

```yaml
valuesTemplate: |
  replicaCount: {{ if eq .Cluster.metadata.labels.size "large" }}5{{ else }}2{{ end }}
  resources:
    limits:
      memory: {{ .Cluster.metadata.labels.memory | default "256Mi" }}
```

Supporte le templating Go pour adapter la config par cluster!

---

## 🔍 Troubleshooting

**HelmChartProxy reste False:**
```bash
# Vérifier le controller
kubectl logs -n capi-system deployment/capi-addon-helm-controller-manager -f

# Events du proxy
kubectl describe helmchartproxy nginx-app
```

**HelmReleaseProxy échoue:**
```bash
# Détails de l'erreur
kubectl describe helmreleaseproxy dev-cluster-nginx-app

# Logs du provider
kubectl logs -n capi-system -l cluster.x-k8s.io/provider=addon-helm
```

**Pods nginx ne démarrent pas:**
```bash
# Dans le workload cluster
kubectl --kubeconfig dev-cluster.kubeconfig describe pods -l app.kubernetes.io/name=nginx

# Events
kubectl --kubeconfig dev-cluster.kubeconfig get events --sort-by=.lastTimestamp
```

**Repository Helm inaccessible:**
```bash
# Test manuel
helm repo add bitnami https://charts.bitnami.com/bitnami
helm search repo bitnami/nginx
helm show chart bitnami/nginx --version 15.1.0
```