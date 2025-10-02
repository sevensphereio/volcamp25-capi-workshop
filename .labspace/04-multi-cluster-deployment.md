# Module 04: Déploiement Simultané de Multiples Clusters

**Durée:** 15 minutes
**Objectif:** Déployer simultanément 3 clusters Kubernetes avec un Helm chart

---

## 📑 Table des Matières

- [🎯 Objectifs & Concepts](#-objectifs--concepts)
- [📋 Actions Pas-à-Pas](#-actions-pas-à-pas)
- [💡 Comprendre en Profondeur](#-comprendre-en-profondeur)

---

## 🎯 Objectifs & Concepts

### Ce que vous allez apprendre

- ✅ Créer 3 clusters Kubernetes simultanément avec un seul Helm chart
- ✅ Observer la création parallèle vs séquentielle
- ✅ Comprendre comment Helm peut templatiser les ressources ClusterAPI
- ✅ Mesurer les gains de temps du déploiement parallèle

### Le Principe : Infrastructure as Code avec Helm

**Analogie :** Imaginez une **usine de robots**. Au lieu de construire chaque robot à la main (séquentiel), vous programmez une ligne d'assemblage (Helm chart) qui fabrique tous les robots en parallèle.

**Problème résolu :**
```
Méthode séquentielle:
  Cluster 1 (3 min) → Cluster 2 (3 min) → Cluster 3 (3 min) = 9 minutes

Méthode parallèle (ce module):
  Cluster 1 \
  Cluster 2  } Tous en même temps = 3 minutes
  Cluster 3 /
```

**Pourquoi Helm ?**
- **Templating** : Un seul template pour N clusters
- **Values** : Configuration centralisée
- **Atomicité** : Rollback de tous les clusters si erreur
- **Traçabilité** : Versioning via Helm releases

---

## 📋 Actions Pas-à-Pas

### Étape 1 : Aller dans le répertoire du module

**Objectif :** Se positionner dans le dossier de travail

**Commande :**
```bash
cd ~/04-multi-cluster-deployment
```

---

### Étape 2 : Examiner la structure du Helm chart

**Objectif :** Comprendre comment le chart est organisé

**Commande :**
```bash
tree multi-cluster-chart/
```

**Résultat attendu :**
```
multi-cluster-chart/
├── Chart.yaml          # Métadonnées du chart
├── values.yaml         # Configuration des 3 clusters
└── templates/
    ├── cluster.yaml                    # Template Cluster
    ├── dockercluster.yaml              # Template DockerCluster
    ├── kubeadmcontrolplane.yaml        # Template KubeadmControlPlane
    ├── dockermachinetemplate-cp.yaml   # Template CP machines
    ├── machinedeployment.yaml          # Template MachineDeployment
    ├── dockermachinetemplate-workers.yaml  # Template workers
    └── kubeadmconfigtemplate.yaml      # Template KubeadmConfig
```

---

### Étape 3 : Analyser le fichier values.yaml

**Objectif :** Voir comment définir plusieurs clusters

**Commande :**
```bash
cat multi-cluster-chart/values.yaml
```

 /!\ **reduire à 2 clusters si les ressources sont limités** /!\

**Explication :**
```yaml
clusters:
  - name: multi-01
    controlPlaneReplicas: 1
    workerReplicas: 2
    kubernetesVersion: v1.32.8
  - name: multi-02
    controlPlaneReplicas: 1
    workerReplicas: 2
    kubernetesVersion: v1.32.8
  - name: multi-03
    controlPlaneReplicas: 1
    workerReplicas: 2
    kubernetesVersion: v1.32.8
```

**🔍 Points clés :**
- 3 clusters définis dans une liste
- Configuration identique (dev/staging/prod auraient des configs différentes)
- Helm va boucler sur cette liste pour créer 3x7 objets = 21 objets

---

### Étape 4 : Examiner un template Helm

**Objectif :** Comprendre comment Helm génère les objets ClusterAPI

**Commande :**
```bash
cat multi-cluster-chart/templates/cluster.yaml
```

**Résultat attendu :**
```yaml
{{- range .Values.clusters }}
---
apiVersion: cluster.x-k8s.io/v1beta1
kind: Cluster
metadata:
  name: {{ .name }}
  labels:
    environment: demo
spec:
  clusterNetwork:
    pods:
      cidrBlocks: ["192.168.0.0/16"]
  controlPlaneRef:
    kind: KubeadmControlPlane
    name: {{ .name }}-control-plane
  infrastructureRef:
    kind: DockerCluster
    name: {{ .name }}
{{- end }}
```

**🔍 Explication :**
- `{{- range .Values.clusters }}` : Boucle sur chaque cluster
- `{{ .name }}` : Injecte le nom du cluster
- Génère 3 objets Cluster (multi-01, multi-02, multi-03)

---

### Étape 5 : Tester le rendu du template (dry-run)

**Objectif :** Voir les manifestes générés sans les appliquer

**Commande :**
```bash
helm template multi-cluster-chart/ | head -50
```

**Explication de la commande :**
- `helm template` : Génère les manifestes sans installation
- `multi-cluster-chart/` : Chemin du chart
- `| head -50` : Affiche les 50 premières lignes

**✅ Vérification :**
Vous devriez voir 3 objets Cluster successifs avec les noms :
- `multi-01`
- `multi-02`
- `multi-03`

---

### Étape 6 : Compter les objets générés

**Objectif :** Confirmer que 3 clusters = 21 objets

**Commande :**
```bash
helm template multi-cluster-chart/ | grep "^kind:" | sort | uniq -c
```

**Résultat attendu :**
```
   3 kind: Cluster
   3 kind: DockerCluster
   3 kind: DockerMachineTemplate
   3 kind: DockerMachineTemplate
   3 kind: KubeadmConfigTemplate
   3 kind: KubeadmControlPlane
   3 kind: MachineDeployment
```

**✅ Vérification :** 7 types x 3 instances = 21 objets

---

### Étape 7 : Déployer les 3 clusters simultanément

**Objectif :** Lancer la création parallèle

**Commande :**
```bash
helm install multi-clusters multi-cluster-chart/
```

**Explication de la commande :**
- `helm install` : Installe un chart Helm
- `multi-clusters` : Nom de la release Helm
- `multi-cluster-chart/` : Chemin du chart

**Résultat attendu :**
```
NAME: multi-clusters
LAST DEPLOYED: [timestamp]
NAMESPACE: default
STATUS: deployed
REVISION: 1
```

**🔍 Ce qui se passe :**
1. Helm envoie les 21 objets à l'API Kubernetes en une seule transaction
2. ClusterAPI détecte 3 nouveaux Clusters
3. Les 3 clusters démarrent leur création EN PARALLÈLE
4. Chaque cluster crée indépendamment son infrastructure

---

### Étape 8 : Observer la création parallèle

**Objectif :** Voir les 3 clusters se créer simultanément

**Commande :**
```bash
watch -n 2 'kubectl get clusters,machines'
```

**Résultat attendu (progression sur 3 minutes) :**

**T+30s - Démarrage parallèle :**
```
NAME                                    PHASE       AGE
cluster.cluster.x-k8s.io/multi-01       Pending     30s
cluster.cluster.x-k8s.io/multi-02       Pending     30s
cluster.cluster.x-k8s.io/multi-03       Pending     30s

NAME                                                  CLUSTER     PHASE         AGE
machine.cluster.x-k8s.io/multi-01-control-plane-xxx  multi-01    Provisioning  30s
machine.cluster.x-k8s.io/multi-02-control-plane-yyy  multi-02    Provisioning  30s
machine.cluster.x-k8s.io/multi-03-control-plane-zzz  multi-03    Provisioning  30s
machine.cluster.x-k8s.io/multi-01-md-0-aaa-bbb       multi-01    Pending       30s
machine.cluster.x-k8s.io/multi-01-md-0-aaa-ccc       multi-01    Pending       30s
machine.cluster.x-k8s.io/multi-02-md-0-ddd-eee       multi-02    Pending       30s
... (9 machines au total)
```

**T+3min - Clusters provisionnés :**
```
NAME                                    PHASE         AGE
cluster.cluster.x-k8s.io/multi-01       Provisioned   3m
cluster.cluster.x-k8s.io/multi-02       Provisioned   3m
cluster.cluster.x-k8s.io/multi-03       Provisioned   3m

NAME                                                  CLUSTER     PHASE     AGE
machine.cluster.x-k8s.io/multi-01-control-plane-xxx  multi-01    Running   3m
machine.cluster.x-k8s.io/multi-02-control-plane-yyy  multi-02    Running   3m
machine.cluster.x-k8s.io/multi-03-control-plane-zzz  multi-03    Running   3m
... (9 machines en Running)
```

**✅ Vérification :** Les 3 clusters atteignent Provisioned en ~3 minutes (pas 9!)

**Appuyez sur Ctrl+C pour arrêter le watch**

---

### Étape 9 : Vérifier les containers Docker

**Objectif :** Confirmer que 9 containers = 9 nodes (3 clusters x 3 nodes)

**Commande :**
```bash
docker ps | grep multi-
```

**Résultat attendu :**
```
CONTAINER ID   IMAGE                  NAMES
xxxxxxxxxxxx   kindest/node:v1.32.8   multi-01-control-plane-xxx
yyyyyyyyyyyy   kindest/node:v1.32.8   multi-01-md-0-aaa-bbb
zzzzzzzzzzzz   kindest/node:v1.32.8   multi-01-md-0-aaa-ccc
aaaaaaaaaaaa   kindest/node:v1.32.8   multi-02-control-plane-yyy
bbbbbbbbbbbb   kindest/node:v1.32.8   multi-02-md-0-ddd-eee
cccccccccccc   kindest/node:v1.32.8   multi-02-md-0-ddd-fff
dddddddddddd   kindest/node:v1.32.8   multi-03-control-plane-zzz
eeeeeeeeeeee   kindest/node:v1.32.8   multi-03-md-0-ggg-hhh
ffffffffffff   kindest/node:v1.32.8   multi-03-md-0-ggg-iii
```

**✅ Vérification :** 9 containers (3 CP + 6 workers)

---

### Étape 10 : Comparer avec l'approche séquentielle

**Objectif :** Mesurer le gain de temps

**Commande :**
```bash
./compare-timing.sh
```

**Résultat attendu :**
```
🔍 Comparaison Déploiement Séquentiel vs Parallèle
====================================================

📊 Résultats:
-------------
Approche Séquentielle:
  - Temps théorique: 9 minutes (3 clusters x 3 min)
  - CPU idle time: 67% (2 cores inactifs pendant 6 min)

Approche Parallèle (ce module):
  - Temps réel: 3 minutes
  - Gain de temps: 6 minutes (67% plus rapide)
  - CPU utilization: 100% (tous les cores utilisés)

💰 Économies en Production:
  10 clusters: 30 min → 3 min (27 min économisées)
  100 clusters: 5 heures → 3 min (297 min économisées)

✅ Le déploiement parallèle est optimal!
```

---

### Étape 11 : Explorer les releases Helm

**Objectif :** Comprendre la traçabilité Helm

**Commande :**
```bash
helm list
```

**Résultat attendu :**
```
NAME            NAMESPACE  REVISION  STATUS    CHART              APP VERSION
multi-clusters  default    1         deployed  multi-cluster-0.1.0  1.32.8
```

**✅ Vérification :** 1 release Helm qui gère 3 clusters

---

### Étape 12 : Voir les ressources gérées par Helm

**Objectif :** Comprendre la relation Helm ↔ ClusterAPI

**Commande :**
```bash
helm get manifest multi-clusters | grep "^kind:" | sort | uniq -c
```

**Résultat attendu :**
```
   3 kind: Cluster
   3 kind: DockerCluster
   6 kind: DockerMachineTemplate
   3 kind: KubeadmConfigTemplate
   3 kind: KubeadmControlPlane
   3 kind: MachineDeployment
```

**🔍 Explication :**
- Helm stocke le manifeste complet (21 objets)
- Rollback possible avec `helm rollback`
- Versioning automatique des déploiements

---

### Étape 13 : Appliquer le label CNI automatiquement (bonus)

**Objectif :** Préparer les clusters pour Calico (Module 02)

**Commande :**
```bash
kubectl label cluster multi-01 multi-02 multi-03 cni=calico
```

**Résultat attendu :**
```
cluster.cluster.x-k8s.io/multi-01 labeled
cluster.cluster.x-k8s.io/multi-02 labeled
cluster.cluster.x-k8s.io/multi-03 labeled
```

**🔍 Explication :**
Si vous avez déjà créé le ClusterResourceSet Calico (Module 02), il va automatiquement installer Calico sur ces 3 nouveaux clusters.

**Vérifier l'installation automatique :**
```bash
kubectl get clusterresourceset
kubectl get clusterresourcesetbinding -A
```

---

### Étape 14 : Accéder aux clusters créés

**Objectif :** Confirmer que les 3 clusters sont fonctionnels

**Commandes :**
```bash
clusterctl get kubeconfig multi-01 > multi-01.kubeconfig
clusterctl get kubeconfig multi-02 > multi-02.kubeconfig
clusterctl get kubeconfig multi-03 > multi-03.kubeconfig
```

**Tester l'accès :**
```bash
kubectl --kubeconfig multi-01.kubeconfig get nodes
kubectl --kubeconfig multi-02.kubeconfig get nodes
kubectl --kubeconfig multi-03.kubeconfig get nodes
```

**Résultat attendu (pour chaque cluster) :**
```
NAME                          STATUS     ROLES           AGE   VERSION
multi-XX-control-plane-xxx    NotReady   control-plane   3m    v1.32.8
multi-XX-md-0-yyy-zzz         NotReady   <none>          2m    v1.32.8
multi-XX-md-0-yyy-aaa         NotReady   <none>          2m    v1.32.8
```

**⚠️ NotReady est normal** si le label CNI n'a pas été appliqué ou si le ClusterResourceSet Calico n'existe pas encore.

---

### Étape 15 : Valider le module

**Objectif :** Exécuter le script de validation automatique

**Commande :**
```bash
./validation.sh
```

**Résultat attendu :**
```
🔍 Module 04: Validation Multi-Cluster Deployment
==================================================

✅ Helm release 'multi-clusters' déployé
✅ 3 Clusters créés (multi-01, multi-02, multi-03)
✅ 3 Clusters en phase Provisioned
✅ 3 Control planes ready
✅ 9 Machines en phase Running
✅ 9 containers Docker actifs
✅ Kubeconfigs accessibles

==================================================
🎉 Module 04 terminé avec succès!
🚀 Prêt pour Module 05: Automation Helm
==================================================
```

---

## 🎓 Points Clés à Retenir

- ✅ **Helm + ClusterAPI = Infrastructure as Code puissante**
- ✅ **Déploiement parallèle vs séquentiel** : 67% plus rapide (3 min vs 9 min)
- ✅ **Templating** : 1 template → N clusters avec configurations variables
- ✅ **Traçabilité** : Helm releases, versioning, rollback
- ✅ **Scaling** : Déployer 100 clusters aussi facilement que 3
- ✅ **Patterns production** : Multi-region, multi-env, multi-tenant

### Cas d'Usage Réels

**Multi-Region Deployment:**
```yaml
clusters:
  - name: prod-us-east-1
    region: us-east-1
  - name: prod-eu-west-1
    region: eu-west-1
  - name: prod-ap-southeast-1
    region: ap-southeast-1
```

**Multi-Environment:**
```yaml
clusters:
  - name: dev-cluster
    size: small
    workerReplicas: 2
  - name: staging-cluster
    size: medium
    workerReplicas: 4
  - name: prod-cluster
    size: large
    workerReplicas: 10
```

---

## ⏭️ Prochaine Étape

**Module 05-automation-helm (20 min) :** Automation avec Helm
- HelmChartProxy pour déployer apps multi-clusters
- ClusterSelector pour ciblage intelligent
- GitOps workflows


---

## 💡 Comprendre en Profondeur

> **Note :** Cette section approfondit les concepts techniques.

### Architecture du Déploiement Parallèle

**Workflow complet :**

```
T+0s   : helm install → Envoie 21 objets à l'API Kubernetes
T+1s   : ClusterAPI détecte 3 nouveaux Clusters
T+1s   : 3 reconciliation loops démarrent EN PARALLÈLE

Cluster multi-01         Cluster multi-02         Cluster multi-03
    ↓                        ↓                        ↓
Create CP machine       Create CP machine       Create CP machine
    ↓ (30s)                 ↓ (30s)                 ↓ (30s)
CP provisioning         CP provisioning         CP provisioning
    ↓ (60s)                 ↓ (60s)                 ↓ (60s)
CP Running              CP Running              CP Running
    ↓                        ↓                        ↓
Create 2 workers        Create 2 workers        Create 2 workers
    ↓ (60s)                 ↓ (60s)                 ↓ (60s)
Workers Running         Workers Running         Workers Running
    ↓                        ↓                        ↓
T+180s: PROVISIONED     T+180s: PROVISIONED     T+180s: PROVISIONED
```

**Pourquoi c'est parallèle ?**
- Chaque Cluster a son propre controller reconciliation loop
- Pas de dépendances entre les 3 clusters
- Docker peut créer plusieurs containers simultanément
- CPU/RAM suffisants pour supporter 9 nodes

---

### Helm Templates Avancés

**Boucles avec conditions :**

```yaml
{{- range .Values.clusters }}
---
apiVersion: cluster.x-k8s.io/v1beta1
kind: Cluster
metadata:
  name: {{ .name }}
  labels:
    environment: {{ .environment | default "dev" }}
    {{- if .production }}
    backup: enabled
    monitoring: prometheus
    {{- end }}
spec:
  # ...
{{- end }}
```

**Variables calculées :**

```yaml
{{- range .Values.clusters }}
---
apiVersion: cluster.x-k8s.io/v1beta1
kind: MachineDeployment
metadata:
  name: {{ .name }}-md-0
spec:
  replicas: {{ .workerReplicas | default 2 }}
  template:
    spec:
      version: {{ .kubernetesVersion | default $.Values.defaultK8sVersion }}
{{- end }}
```

---

### Helm vs Templating Natif (Kustomize, ytt)

**Comparaison :**

| Aspect | Helm | Kustomize | ytt |
|--------|------|-----------|-----|
| **Templating** | Go templates | Patches (limité) | Starlark (très puissant) |
| **Release management** | Oui (helm list, rollback) | Non | Non |
| **Dependencies** | Oui (sub-charts) | Non | Non |
| **Learning curve** | Moyenne | Faible | Élevée |
| **Adoption** | 85% (industrie standard) | 50% (K8s natif) | 10% (Carvel) |

**Pourquoi Helm pour ce use-case ?**
- Templating loops (`range`) simplifie 3 clusters → 1 template
- Release management = traçabilité + rollback
- Adoption massive = patterns connus

---

### Patterns Production

#### Pattern 1: Multi-Region Deployment

**values-prod.yaml :**
```yaml
clusters:
  - name: prod-us-east
    region: us-east-1
    provider: aws
    instanceType: m5.xlarge
    workerReplicas: 10
  - name: prod-eu-west
    region: eu-west-1
    provider: aws
    instanceType: m5.xlarge
    workerReplicas: 10
  - name: prod-ap-southeast
    region: ap-southeast-1
    provider: aws
    instanceType: m5.xlarge
    workerReplicas: 10
```

**Déploiement :**
```bash
helm install prod-fleet multi-cluster-chart/ -f values-prod.yaml
```

---

#### Pattern 2: Environment Promotion

**values-environments.yaml :**
```yaml
environments:
  dev:
    clusterCount: 1
    size: small
    workerReplicas: 2
  staging:
    clusterCount: 2
    size: medium
    workerReplicas: 4
  prod:
    clusterCount: 5
    size: large
    workerReplicas: 10
```

**Pipeline CI/CD :**
```bash
# Deploy dev
helm upgrade --install dev-env chart/ --set env=dev

# Promote to staging (after tests)
helm upgrade --install staging-env chart/ --set env=staging

# Promote to prod (after approval)
helm upgrade --install prod-env chart/ --set env=prod
```

---

#### Pattern 3: Disaster Recovery

**Helm permet le rollback instantané :**

```bash
# Déploiement qui casse
helm upgrade multi-clusters chart/ --set clusters[0].workerReplicas=100
# Erreur: Pas assez de ressources

# Rollback instantané à la version précédente
helm rollback multi-clusters
# Les 3 clusters reviennent à leur état précédent
```

---

### Scaling Limits

**Combien de clusters peut-on déployer simultanément ?**

**Facteurs limitants :**
1. **CPU/RAM du management cluster** : Contrôleurs ClusterAPI
2. **Capacité de l'infrastructure provider** : Docker, AWS, etc.
3. **Rate limits API** : Cloud providers ont des quotas

**Benchmarks (Docker provider) :**
```
Management cluster (4 CPU, 16GB RAM):
- 10 clusters: 3 minutes ✅
- 50 clusters: 5 minutes ✅
- 100 clusters: 10 minutes ⚠️ (CPU throttling)
- 500 clusters: Non recommandé ❌
```

**Production (AWS) :**
```
Management cluster (8 CPU, 32GB RAM):
- 100 clusters: 5-8 minutes ✅
- 500 clusters: 15-20 minutes ✅
- 1000+ clusters: Sharding requis (multiple management clusters)
```

---

### Troubleshooting

#### Helm release failed

**Diagnostic :**
```bash
helm status multi-clusters
helm get manifest multi-clusters
kubectl describe cluster multi-01
```

**Causes fréquentes :**
- Erreur de syntaxe dans le template
- Valeurs manquantes dans values.yaml
- Références incorrectes (controlPlaneRef, etc.)

**Solution :**
```bash
# Test le rendering sans déployer
helm template multi-cluster-chart/ | kubectl apply --dry-run=client -f -

# Si erreur, corriger le chart et réinstaller
helm uninstall multi-clusters
helm install multi-clusters multi-cluster-chart/
```

---

#### Un cluster reste en Pending

**Diagnostic :**
```bash
# Identifier le cluster bloqué
kubectl get clusters

# Détails
kubectl describe cluster multi-02

# Machines associées
kubectl get machines -l cluster.x-k8s.io/cluster-name=multi-02
```

**Causes fréquentes :**
- Ressources Docker insuffisantes (RAM/CPU)
- Port collision (load balancer)
- Erreur de configuration spécifique à ce cluster

**Solution :**
```bash
# Supprimer uniquement le cluster problématique
kubectl delete cluster multi-02

# Redéployer avec un chart corrigé
helm upgrade multi-clusters multi-cluster-chart/
```

---

## 🎓 Ce Que Vous Avez Appris

- ✅ Déployer simultanément 3 clusters avec un seul Helm chart
- ✅ Comprendre le templating Helm pour ClusterAPI
- ✅ Mesurer les gains de performance (67% plus rapide)
- ✅ Gérer les clusters avec Helm releases (traçabilité, rollback)
- ✅ Patterns production (multi-region, multi-env, DR)
- ✅ Troubleshooting des déploiements multi-clusters

---

**Module 04 complété ! 🎉**
**Temps écoulé :** 55/120 minutes (10+15+15+15)
**Prochaine étape :** Module 05 - Automation avec Helm
