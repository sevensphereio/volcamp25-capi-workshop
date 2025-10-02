# Aide-Mémoire Commandes - Workshop ClusterAPI Express

**Référence rapide de toutes les commandes importantes du workshop**

---

## Navigation Workshop

```bash
# Aller au répertoire principal
cd /home/ubuntu/R_D/CLAUDE_PROJECTS/capi-workshop/workshop-express

# Aller à un module spécifique
cd 00-introduction/     # Module 00
cd 01-premier-cluster/  # Module 01
cd 02-networking-calico # Module 02
cd 03-k0smotron/        # Module 03
cd 04-automation-helm/  # Module 04
cd 05-operations-cleanup/ # Module 05

# Revenir au parent
cd ..
```

---

## Module 00 : Introduction & Vérification

### Vérifier kubectl
```bash
# Afficher la version du client kubectl
kubectl version --client
```

### Vérifier accès au management cluster
```bash
# Obtenir les infos du cluster
kubectl cluster-info --context kind-capi-management

# Lister les nodes du management cluster
kubectl get nodes
```

### Vérifier ClusterAPI installé
```bash
# Lister les deployments ClusterAPI
kubectl get deployments -n capi-system

# Vérifier k0smotron operator
kubectl get pods -n k0smotron

# Vérifier Helm addon provider
kubectl get deployments -n caaph-system
```

### Lancer la validation
```bash
# Exécuter le script de vérification
./verification.sh
```

---

## Module 01 : Premier Cluster

### Créer le cluster
```bash
# Appliquer le manifeste du cluster
kubectl apply -f dev-cluster.yaml
```

### Observer la création
```bash
# Surveiller les clusters et machines (rafraîchissement toutes les 2s)
watch -n 2 'kubectl get clusters,machines'

# Arrêter le watch : Ctrl+C
```

### Voir les containers Docker
```bash
# Lister les containers Docker créés par ClusterAPI
docker ps | grep dev-cluster
```

### Explorer les ressources créées
```bash
# Détails du cluster
kubectl get cluster dev-cluster -o yaml

# Lister les machines
kubectl get machines

# Détails d'une machine
kubectl describe machine <machine-name>

# Status du control plane
kubectl get kubeadmcontrolplane

# Status des workers
kubectl get machinedeployment
```

### Accéder au workload cluster
```bash
# Récupérer le kubeconfig
clusterctl get kubeconfig dev-cluster > dev-cluster.kubeconfig

# Lister les nodes du workload cluster
kubectl --kubeconfig dev-cluster.kubeconfig get nodes

# Lister tous les pods du workload cluster
kubectl --kubeconfig dev-cluster.kubeconfig get pods -A

# Voir les nodes en mode watch
watch -n 2 'kubectl --kubeconfig dev-cluster.kubeconfig get nodes'
```

### Valider le module
```bash
# Lancer le script de validation
./validation.sh
```

---

## Module 02 : Networking avec Calico

### Diagnostiquer le problème CNI
```bash
# Vérifier l'état des nodes (NotReady)
kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig get nodes

# Voir les détails d'un node
kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig describe node <node-name>

# Vérifier les pods système (CoreDNS Pending)
kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig get pods -n kube-system
```

### Créer le ClusterResourceSet
```bash
# Appliquer le manifeste CRS + ConfigMap
kubectl apply -f calico-crs.yaml

# Vérifier le CRS créé
kubectl get clusterresourceset

# Détails du CRS
kubectl describe clusterresourceset calico-cni
```

### Activer le CRS sur le cluster
```bash
# Ajouter le label au cluster
kubectl label cluster dev-cluster cni=calico

# Vérifier le label
kubectl get cluster dev-cluster --show-labels

# Vérifier que le CRS a été appliqué
kubectl get clusterresourceset calico-cni -o yaml | grep -A 10 "status:"
```

### Observer l'installation Calico
```bash
# Surveiller l'apparition des pods Calico
watch -n 2 'kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig get pods -n kube-system'

# Surveiller les nodes devenir Ready
watch -n 2 'kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig get nodes'
```

### Tester le réseau
```bash
# Déployer un pod de test
kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig run test-pod --image=nginx --restart=Never

# Vérifier le pod
kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig get pod test-pod -o wide

# Supprimer le pod de test
kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig delete pod test-pod
```

### Valider le module
```bash
./validation.sh
```

---

## Module 03 : k0smotron

### Créer le cluster k0smotron
```bash
# Appliquer le manifeste k0smotron
kubectl apply -f k0s-demo-cluster.yaml

# Observer la création (plus rapide!)
watch -n 2 'kubectl get clusters,k0smotroncontrolplane,machines'
```

### Observer les control plane pods
```bash
# Voir les pods k0smotron (control planes virtuels)
kubectl get pods -l cluster.x-k8s.io/cluster-name=k0s-demo-cluster

# Détails d'un control plane pod
kubectl describe pod <k0s-demo-cluster-cp-xxx>

# Logs du control plane
kubectl logs <k0s-demo-cluster-cp-xxx> -c kube-apiserver
```

### Accéder au cluster k0smotron
```bash
# Récupérer le kubeconfig
clusterctl get kubeconfig k0s-demo-cluster > k0s-demo-cluster.kubeconfig

# Vérifier les nodes
kubectl --kubeconfig k0s-demo-cluster.kubeconfig get nodes

# Lister les pods
kubectl --kubeconfig k0s-demo-cluster.kubeconfig get pods -A
```

### Labeller pour Calico
```bash
# Ajouter le label pour activer Calico
kubectl label cluster k0s-demo-cluster cni=calico

# Observer les nodes devenir Ready
watch -n 2 'kubectl --kubeconfig k0s-demo-cluster.kubeconfig get nodes'
```

### Comparer les ressources
```bash
# Script de comparaison automatique
./compare-providers.sh

# OU manuellement :
# Lister tous les containers
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Size}}"

# Compter les nodes par cluster
kubectl get machines | grep dev-cluster | wc -l
kubectl get machines | grep k0s-demo-cluster | wc -l
```

### Valider le module
```bash
./validation.sh
```

---

## Module 04 : Automation avec Helm

### Créer le HelmChartProxy
```bash
# Appliquer le manifeste HelmChartProxy
kubectl apply -f nginx-helmchartproxy.yaml

# Vérifier le HelmChartProxy créé
kubectl get helmchartproxy

# Détails du HelmChartProxy
kubectl describe helmchartproxy nginx-demo
```

### Observer le déploiement multi-cluster
```bash
# Lister les HelmReleaseProxy (un par cluster)
kubectl get helmreleaseproxy -A

# Détails d'un HelmReleaseProxy
kubectl describe helmreleaseproxy -n <namespace> <name>

# Surveiller les pods nginx dans dev-cluster
watch -n 2 'kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig get pods'

# Surveiller les pods nginx dans k0s-demo-cluster
watch -n 2 'kubectl --kubeconfig ../03-k0smotron/k0s-demo-cluster.kubeconfig get pods'
```

### Tester l'application nginx
```bash
# Obtenir le port NodePort de nginx (dev-cluster)
kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig get svc nginx-demo -o jsonpath='{.spec.ports[0].nodePort}'

# Tester nginx avec curl
curl http://localhost:<port>

# Pour k0s-demo-cluster
kubectl --kubeconfig ../03-k0smotron/k0s-demo-cluster.kubeconfig get svc nginx-demo -o jsonpath='{.spec.ports[0].nodePort}'
curl http://localhost:<port>
```

### Mettre à jour l'application
```bash
# Éditer le HelmChartProxy pour changer la version ou valeurs
kubectl edit helmchartproxy nginx-demo

# Observer la mise à jour automatique
kubectl get helmreleaseproxy -A -w
```

### Valider le module
```bash
./validation.sh
```

---

## Module 05 : Operations & Cleanup

### Scaler les workers
```bash
# Voir les workers actuels
kubectl get machinedeployment

# Scaler dev-cluster à 4 workers
kubectl scale machinedeployment dev-cluster-md-0 --replicas=4

# Observer le scaling
watch -n 2 'kubectl get machines | grep dev-cluster'

# Vérifier dans le workload cluster
kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig get nodes

# Script de scaling automatique
./scale-workers.sh
```

### Monitorer les ressources
```bash
# Script de monitoring complet
./monitor-resources.sh

# OU manuellement :
# Voir tous les clusters
kubectl get clusters

# Compter les machines
kubectl get machines | wc -l

# Voir les containers Docker
docker ps | wc -l

# Ressources Docker
docker stats --no-stream
```

### Cleanup complet
```bash
# Script de nettoyage automatique
./cleanup.sh

# OU manuellement :
# Supprimer k0s-demo-cluster
kubectl delete cluster k0s-demo-cluster

# Supprimer dev-cluster
kubectl delete cluster dev-cluster

# Attendre la suppression
watch -n 2 'kubectl get clusters,machines'

# Supprimer le CRS et HelmChartProxy
kubectl delete clusterresourceset calico-cni
kubectl delete helmchartproxy nginx-demo

# Vérifier que tout est supprimé
kubectl get clusters
docker ps | grep -E '(dev-cluster|k0s-demo)'
```

### Valider le module
```bash
./validation.sh
```

---

## Commandes Utiles Générales

### Gestion des Clusters
```bash
# Lister tous les clusters
kubectl get clusters

# Détails d'un cluster
kubectl describe cluster <cluster-name>

# Status condensé
kubectl get cluster <cluster-name> -o jsonpath='{.status.phase}'

# Supprimer un cluster
kubectl delete cluster <cluster-name>
```

### Gestion des Machines
```bash
# Lister toutes les machines
kubectl get machines

# Machines d'un cluster spécifique
kubectl get machines | grep <cluster-name>

# Détails d'une machine
kubectl describe machine <machine-name>

# Voir les machines en mode wide
kubectl get machines -o wide
```

### Logs et Debugging
```bash
# Logs du controller ClusterAPI
kubectl logs -n capi-system deployment/capi-controller-manager -f

# Logs du Docker provider
kubectl logs -n capd-system deployment/capd-controller-manager -f

# Logs du k0smotron operator
kubectl logs -n k0smotron deployment/k0smotron-controller-manager -f

# Logs du Helm provider
kubectl logs -n caaph-system deployment/capi-addon-helm-controller-manager -f

# Events d'un cluster
kubectl get events --field-selector involvedObject.name=<cluster-name>
```

### Kubeconfig Management
```bash
# Récupérer un kubeconfig
clusterctl get kubeconfig <cluster-name> > <cluster-name>.kubeconfig

# Utiliser un kubeconfig spécifique
kubectl --kubeconfig <file>.kubeconfig <command>

# Fusionner dans le kubeconfig principal (optionnel)
KUBECONFIG=~/.kube/config:<cluster-name>.kubeconfig kubectl config view --merge --flatten > ~/.kube/config.new
mv ~/.kube/config.new ~/.kube/config
```

### Monitoring en Temps Réel
```bash
# Watch générique (rafraîchissement 2s)
watch -n 2 '<command>'

# Exemples :
watch -n 2 'kubectl get clusters,machines'
watch -n 2 'kubectl get pods -A'
watch -n 2 'docker ps'

# Suivre les events en temps réel
kubectl get events -w

# Suivre les logs en temps réel
kubectl logs -f <pod-name>
```

### Docker
```bash
# Lister les containers ClusterAPI
docker ps | grep -E '(dev-cluster|k0s-demo)'

# Stats des containers
docker stats --no-stream

# Logs d'un container
docker logs <container-name>

# Accéder à un container
docker exec -it <container-name> bash
```

---

## Raccourcis Utiles

### Aliases Bash (optionnel)
```bash
# Ajouter ces alias dans ~/.bashrc pour gagner du temps

# kubectl
alias k='kubectl'
alias kgc='kubectl get clusters'
alias kgm='kubectl get machines'
alias kgp='kubectl get pods -A'

# kubeconfig des workload clusters
alias kdev='kubectl --kubeconfig ~/dev-cluster.kubeconfig'
alias kk0s='kubectl --kubeconfig ~/k0s-demo-cluster.kubeconfig'

# watch
alias wkgc='watch -n 2 "kubectl get clusters,machines"'
alias wdocker='watch -n 2 "docker ps"'
```

### Variables d'Environnement
```bash
# Définir le kubeconfig par défaut
export KUBECONFIG=~/.kube/config

# Définir le contexte par défaut
kubectl config use-context kind-capi-management

# Vérifier le contexte actuel
kubectl config current-context
```

---

## Dépannage Rapide

### Cluster ne démarre pas
```bash
# Vérifier les logs ClusterAPI
kubectl logs -n capi-system deployment/capi-controller-manager --tail=100

# Vérifier la machine
kubectl describe machine <machine-name>

# Vérifier les events
kubectl get events --sort-by='.lastTimestamp' | tail -20
```

### Nodes NotReady
```bash
# Vérifier si le CNI est installé
kubectl --kubeconfig <cluster>.kubeconfig get pods -n kube-system | grep calico

# Vérifier le label du cluster
kubectl get cluster <cluster-name> --show-labels

# Ajouter le label si manquant
kubectl label cluster <cluster-name> cni=calico
```

### HelmChartProxy ne déploie pas
```bash
# Vérifier le HelmChartProxy
kubectl describe helmchartproxy <name>

# Vérifier les HelmReleaseProxy
kubectl get helmreleaseproxy -A

# Logs du Helm provider
kubectl logs -n caaph-system deployment/capi-addon-helm-controller-manager -f
```

---

## Ressources

- **Glossaire** : `GLOSSARY.md` - Tous les termes expliqués
- **README** : `README.md` - Vue d'ensemble du workshop
- **Guide Formateur** : `FORMATEUR.md` - Notes pour le formateur

---

**Conseil :** Imprimez ou gardez cette page ouverte pendant le workshop pour référence rapide !