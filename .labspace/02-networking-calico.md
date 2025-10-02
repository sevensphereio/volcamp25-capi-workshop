# Module 02: Networking avec Calico

**Durée:** 15 minutes

---

## 🎯 Objectifs & Concepts

### Ce que vous allez apprendre
- ✅ Pourquoi les nodes sont NotReady sans CNI (Container Network Interface)
- ✅ Comment ClusterResourceSet automatise le déploiement d'addons
- ✅ Déployer Calico automatiquement avec le pattern label-based
- ✅ Passer les nodes de NotReady à Ready

### Concepts clés
**CNI (Container Network Interface):** Plugin réseau qui permet la communication pod-to-pod. Sans CNI, kubelet déclare les nodes NotReady car il ne peut pas garantir la connectivité réseau.

**ClusterResourceSet (CRS):** Mécanisme ClusterAPI pour déployer automatiquement des ressources (addons) sur les workload clusters via sélection par labels. Équivalent d'un "système d'installation automatique" : un label sur le cluster déclenche le déploiement.

**Workflow CRS:**
```
1. Créer ClusterResourceSet + ConfigMap (contient manifest)
2. labeliser le cluster cible
3. CRS controller détecte le match et applique automatiquement
```

**Avantages vs installation manuelle:**
- Automatique une fois le labelling fait (pas de kubectl apply manuel)
- Déclaratif et versionnable Git (GitOps ready)
- Réutilisable pour N clusters (même label = même addon)
- Self-service (nouveau cluster avec le bon label = addon auto-installé)

---

## 📋 Actions Pas-à-Pas

### Action 1: Diagnostiquer le problème réseau

**Objectif:** Comprendre pourquoi les nodes sont NotReady

**Commande:**
```bash
cd ~/02-networking-calico
kubectl --kubeconfig ~/01-premier-cluster/dev-cluster.kubeconfig get nodes
```

**Explication de la commande:**
- `--kubeconfig`: pointe vers le kubeconfig du workload cluster dev-cluster
- `get nodes`: affiche l'état des nodes du cluster

**Résultat attendu:**
```
NAME                              STATUS     ROLES           AGE   VERSION
dev-cluster-control-plane-xxxx    NotReady   control-plane   5m    v1.32.8
dev-cluster-md-0-yyyyy-zzzzz      NotReady   <none>          4m    v1.32.8
dev-cluster-md-0-yyyyy-aaaaa      NotReady   <none>          4m    v1.32.8
```

**✅ Vérification:** Tous les nodes sont en STATUS NotReady. C'est normal à ce stade : aucun CNI n'est installé.

---

### Action 2: Identifier la cause (CNI manquant)

**Objectif:** Confirmer que le problème vient de l'absence de CNI

**Commande:**
```bash
kubectl --kubeconfig ~/01-premier-cluster/dev-cluster.kubeconfig describe node dev-cluster-control-plane-* | grep -A 5 "Conditions:"
```

**Explication de la commande:**
- `describe node`: affiche les détails d'un node
- `dev-cluster-control-plane-*`: wildcard pour matcher le nom du node control plane
- `grep -A 5 "Conditions:"`: filtre pour afficher les conditions du node (5 lignes après)

**Résultat attendu:**
```
Conditions:
  Type             Status
  Ready            False
  ...
  Message: network plugin is not ready: cni config uninitialized
```

**✅ Vérification:** Le message confirme "network plugin is not ready". Le CNI n'est pas configuré.

---

### Action 3: Analyser le manifeste ClusterResourceSet

**Objectif:** Comprendre la structure du CRS avant de l'appliquer

**Commande:**
```bash
cat calico-crs.yaml | head -30
```

**Explication de la commande:**
- `cat`: affiche le contenu du fichier
- `head -30`: limite l'affichage aux 30 premières lignes pour voir la structure

**Résultat attendu:**
```yaml
apiVersion: addons.cluster.x-k8s.io/v1beta1
kind: ClusterResourceSet
metadata:
  name: calico-cni
spec:
  clusterSelector:
    matchLabels:
      cni: calico          # Cible les clusters avec ce label
  resources:
  - name: calico-addon     # Référence au ConfigMap
    kind: ConfigMap
  strategy: ApplyOnce      # Appliqué une seule fois
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: calico-addon
data:
  calico.yaml: |           # Manifeste Calico complet (7000+ lignes)
    ...
```

**✅ Vérification:** Le CRS contient 2 objets : ClusterResourceSet (règle) + ConfigMap (manifeste Calico)

---

### Action 4: Créer le ClusterResourceSet

**Objectif:** Déployer la règle CRS dans le management cluster

**Commande:**
```bash
kubectl apply -f calico-crs.yaml -f calico-cm-crs.yaml
```

**Explication de la commande:**
- `apply -f`: crée ou met à jour les ressources définies dans le fichier YAML
- `calico-crs.yaml`: fichier contenant ClusterResourceSet + ConfigMap

**Résultat attendu:**
```
clusterresourceset.addons.cluster.x-k8s.io/calico-cni created
configmap/calico-addon created
```

**✅ Vérification:** 2 objets créés : le CRS (règle) et le ConfigMap (données Calico)

---

### Action 5: Vérifier le CRS créé

**Objectif:** Confirmer que le CRS existe et est actif

**Commande:**
```bash
kubectl get clusterresourceset
```

**Explication de la commande:**
- `get clusterresourceset`: liste tous les ClusterResourceSets du management cluster

**Résultat attendu:**
```
NAME         AGE
calico-cni   10s
```

**✅ Vérification:** Le CRS calico-cni apparaît dans la liste

---

### Action 6: Activer le CRS en labellant le cluster

**Objectif:** Déclencher le déploiement automatique de Calico

**Commande:**
```bash
kubectl label cluster dev-cluster cni=calico
```

**Explication de la commande:**
- `label cluster dev-cluster`: ajoute un label au cluster dev-cluster
- `cni=calico`: label qui matche le clusterSelector du CRS

**Résultat attendu:**
```
cluster.cluster.x-k8s.io/dev-cluster labeled
```

**✅ Vérification:** Le label est ajouté. Le CRS controller va détecter le match et appliquer Calico automatiquement dans les secondes qui suivent.

---

### Action 7: Vérifier le label appliqué

**Objectif:** Confirmer que le label est bien présent sur le cluster

**Commande:**
```bash
kubectl get cluster dev-cluster --show-labels
```

**Explication de la commande:**
- `--show-labels`: affiche tous les labels du cluster dans la sortie

**Résultat attendu:**
```
NAME          PHASE        AGE   LABELS
dev-cluster   Provisioned  10m   cni=calico,environment=demo
```

**✅ Vérification:** Le label `cni=calico` est présent dans LABELS

---

### Action 8: Observer l'installation automatique de Calico

**Objectif:** Voir en temps réel l'apparition des pods Calico dans le workload cluster

**Commande:**
```bash
watch -n 2 'kubectl --kubeconfig ~/01-premier-cluster/dev-cluster.kubeconfig get pods -n kube-system'
```

**Explication de la commande:**
- `watch -n 2`: exécute la commande toutes les 2 secondes et affiche le résultat
- `-n kube-system`: limite l'affichage au namespace système où Calico se déploie

**Résultat attendu (progression):**

**Minute 1:**
```
NAME                                    READY   STATUS              RESTARTS
calico-kube-controllers-xxx             0/1     ContainerCreating   0
calico-node-aaaa                        0/1     Init:0/3            0
calico-node-bbbb                        0/1     Init:0/3            0
coredns-xxx                             0/1     Pending             0
```

**Minute 2:**
```
NAME                                    READY   STATUS    RESTARTS
calico-kube-controllers-xxx             1/1     Running   0
calico-node-aaaa                        1/1     Running   0
calico-node-bbbb                        1/1     Running   0
coredns-xxx                             1/1     Running   0
```

**✅ Vérification:** Tous les pods Calico (calico-node DaemonSet + calico-kube-controllers) sont Running. CoreDNS passe aussi à Running car il peut maintenant obtenir une IP réseau. Appuyez sur Ctrl+C pour arrêter.

---

### Action 9: Observer les nodes passer à Ready

**Objectif:** Confirmer que les nodes détectent le CNI et passent à Ready

**Commande:**
```bash
watch -n 2 'kubectl --kubeconfig ~/01-premier-cluster/dev-cluster.kubeconfig get nodes'
```

**Explication de la commande:**
- `watch -n 2`: rafraîchit l'affichage toutes les 2 secondes
- `get nodes`: affiche l'état des nodes

**Résultat attendu (progression):**

**Avant (~1 minute):**
```
NAME                              STATUS   ROLES           AGE
dev-cluster-control-plane-xxxx    Ready    control-plane   11m
dev-cluster-md-0-yyyyy-zzzzz      Ready    <none>          10m
dev-cluster-md-0-yyyyy-aaaaa      Ready    <none>          10m
```

**✅ Vérification:** 3/3 nodes sont Ready. Le CNI est fonctionnel. Appuyez sur Ctrl+C.

---

### Action 10: Tester la communication réseau

**Objectif:** Valider que les pods peuvent obtenir des IPs et communiquer

**Commande:**
```bash
kubectl --kubeconfig ~/01-premier-cluster/dev-cluster.kubeconfig run test-pod --image=nginx --restart=Never
kubectl --kubeconfig ~/01-premier-cluster/dev-cluster.kubeconfig get pod test-pod -o wide
```

**Explication de la commande:**
- `run test-pod`: crée un pod simple avec nginx
- `--restart=Never`: crée un pod simple (pas un Deployment)
- `get pod -o wide`: affiche les détails incluant l'IP assignée

**Résultat attendu:**
```
NAME       READY   STATUS    RESTARTS   AGE   IP              NODE
test-pod   1/1     Running   0          20s   192.168.X.Y     dev-cluster-md-0-...
```

**✅ Vérification:** Le pod a une IP du range 192.168.0.0/16 (défini dans dev-cluster.yaml). Le réseau fonctionne.

**Cleanup:**
```bash
kubectl --kubeconfig ~/01-premier-cluster/dev-cluster.kubeconfig delete pod test-pod
```

---

### Action 11: Validation automatique du module

**Objectif:** Vérifier que toutes les étapes sont réussies

**Commande:**
```bash
./validation.sh
```

**Explication de la commande:**
- Script qui vérifie : CRS existe, label appliqué, pods Calico Running, nodes Ready

**Résultat attendu:**
```
🔍 Module 02: Validation Networking Calico
===========================================

✅ ClusterResourceSet calico-cni existe
✅ ConfigMap calico-addon existe
✅ Cluster dev-cluster a le label cni=calico
✅ CRS appliqué sur le cluster
✅ Calico pods Running (4/4)
✅ 3/3 nodes Ready
✅ CoreDNS pods Running (2/2)

===========================================
🎉 Module 02 terminé avec succès!
🚀 Prêt pour Module 03: k0smotron Control Planes
===========================================
```

**✅ Vérification:** Tous les checks passent. Le réseau est fonctionnel.

---

## 💡 Comprendre en Profondeur

### Pourquoi CoreDNS était Pending avant Calico ?

CoreDNS est un pod qui nécessite une IP réseau pour fonctionner. Sans CNI :
- Le scheduler ne peut pas assigner d'IP au pod
- Les routes réseau n'existent pas
- Le pod reste en Pending

Dès que Calico est installé :
- Le CNI assigne une IP du range configuré
- Les routes sont créées automatiquement
- CoreDNS peut démarrer et fournir le DNS au cluster

**Ordre critique:** CNI AVANT tout autre addon réseau.

---

### ClusterResourceSet : ApplyOnce vs Reconcile

Deux stratégies d'application :

**ApplyOnce (utilisé ici):**
- Appliqué une seule fois au moment du match
- Modifications ultérieures du CRS ne sont pas propagées
- Convient pour addons gérés indépendamment après installation

**Reconcile:**
- Réappliqué régulièrement pour forcer la configuration
- Modifications du CRS propagées automatiquement
- Convient pour garantir la conformité continue

---

### Pattern Label-Based : Flexibilité GitOps

Le sélecteur par labels permet des stratégies flexibles :

```yaml
# Exemple : tous les clusters production ET Europe
clusterSelector:
  matchLabels:
    environment: production
    region: europe
```

**Avantages :**
- Self-service : équipes dev ajoutent un label = addon déployé
- Gouvernance : équipes platform contrôlent les CRS
- Évolutivité : 1 CRS pour 100+ clusters

---

### Calico : Plus qu'un CNI

Calico offre également :
- **Network Policies :** Firewall pod-to-pod (sécurité)
- **BGP routing :** Routage avancé pour on-premise
- **Observability :** Métriques réseau détaillées

---

## 🔍 Troubleshooting

**Pods Calico ne démarrent pas :**
```bash
kubectl --kubeconfig ~/01-premier-cluster/dev-cluster.kubeconfig get events -n kube-system --sort-by='.lastTimestamp'
kubectl --kubeconfig ~/01-premier-cluster/dev-cluster.kubeconfig logs -n kube-system calico-node-xxx
```

**CRS ne s'applique pas :**
```bash
# Vérifier le label
kubectl get cluster dev-cluster --show-labels

# Logs du CRS controller
kubectl logs -n capi-system deployment/capi-controller-manager | grep clusterresourceset
```

**Nodes restent NotReady :**
```bash
# Attendre 1-2 minutes après installation Calico
# Vérifier que tous les pods Calico sont Running
kubectl --kubeconfig ~/01-premier-cluster/dev-cluster.kubeconfig get pods -n kube-system -l k8s-app=calico-node
```

---

## ⏭️ Prochaine Étape

**Module 03 (15 min):** k0smotron Control Planes Virtuels
- Comprendre les économies de ressources (55%)
- Créer un cluster k0smotron
- Comparer avec Docker provider

```bash
cd ~/03-k0smotron
cat commands.md
```
