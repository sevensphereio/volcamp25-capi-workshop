# Module 01 - QUICKSTART

**Version ultra-rapide : Juste les commandes essentielles**

---

## ✅ Checklist Rapide

```bash
# 1. Aller dans le module
cd /home/volcampdev/workshop-express/01-premier-cluster

# 2. Générer le manifeste avec clusterctl
clusterctl generate cluster dev-cluster \
  --flavor development \
  --kubernetes-version v1.32.8 \
  --control-plane-machine-count=1 \
  --worker-machine-count=2 \
  > dev-cluster.yaml

# 3. Examiner le manifeste (optionnel)
cat dev-cluster.yaml

# 4. Créer le cluster
kubectl apply -f dev-cluster.yaml

# 5. Observer la création (attendre ~3 min, Ctrl+C pour arrêter)
watch -n 2 'kubectl get clusters,machines'

# 6. Vérifier les containers Docker
docker ps | grep dev-cluster

# 7. Vérifier les ressources ClusterAPI
kubectl get kubeadmcontrolplane
kubectl get machinedeployment
kubectl get machines -o wide

# 8. Récupérer le kubeconfig
clusterctl get kubeconfig dev-cluster > dev-cluster.kubeconfig

# 9. Accéder au workload cluster
kubectl --kubeconfig dev-cluster.kubeconfig get nodes

# 10. Vérifier les pods (CoreDNS sera Pending)
kubectl --kubeconfig dev-cluster.kubeconfig get pods -A

# 11. Validation
./validation.sh
```

---

## Résultats Attendus

| Commande | Résultat OK |
|----------|-------------|
| `clusterctl generate cluster ...` | Fichier dev-cluster.yaml créé (~200 lignes) |
| `kubectl apply -f dev-cluster.yaml` | 7 objets created |
| `kubectl get clusters` | dev-cluster PHASE = Provisioned |
| `kubectl get machines` | 3 machines PHASE = Running, VERSION = v1.32.8 |
| `docker ps \| grep dev-cluster` | 3 containers listés |
| `kubectl get kubeadmcontrolplane` | READY = 1/1, API SERVER = true |
| `kubectl get machinedeployment` | REPLICAS = 2, READY = 2 |
| `kubectl --kubeconfig ... get nodes` | 3 nodes listés (NotReady = normal) |
| `./validation.sh` | Tous les ✅ sauf nodes NotReady |

---

## ⚠️ Notes Importantes

- **Nodes NotReady est NORMAL** - Le CNI n'est pas encore installé
- **CoreDNS Pending est NORMAL** - Il attend le réseau pod
- **Création prend ~3 minutes** - Plus rapide que prod (containers vs VMs)

---

## 🚀 Prochaine Étape

```bash
cd ../02-networking-calico
cat commands.md
```

Pour les explications détaillées, voir `commands.md`