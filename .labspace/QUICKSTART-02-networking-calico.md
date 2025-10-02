# Module 02 - QUICKSTART

**Version ultra-rapide : Juste les commandes essentielles**

---

## ✅ Checklist Rapide

```bash
# 1. Aller dans le module
cd /home/ubuntu/R_D/CLAUDE_PROJECTS/capi-workshop/workshop-express/02-networking-calico

# 2. Diagnostiquer (nodes NotReady)
kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig get nodes

# 3. Confirmer le problème CNI
kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig describe node dev-cluster-control-plane-* | grep -A 5 "Conditions:"

# 4. Examiner le manifeste CRS (optionnel)
cat calico-crs.yaml | head -30

# 5. Créer le ClusterResourceSet
kubectl apply -f calico-crs.yaml

# 6. Vérifier le CRS créé
kubectl get clusterresourceset

# 7. Activer en labellant le cluster
kubectl label cluster dev-cluster cni=calico

# 8. Vérifier le label
kubectl get cluster dev-cluster --show-labels

# 9. Observer l'installation Calico (attendre ~1-2 min, Ctrl+C)
watch -n 2 'kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig get pods -n kube-system'

# 10. Observer les nodes devenir Ready (Ctrl+C)
watch -n 2 'kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig get nodes'

# 11. Tester le réseau
kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig run test-pod --image=nginx --restart=Never
kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig get pod test-pod -o wide
kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig delete pod test-pod

# 12. Validation
./validation.sh
```

---

## Résultats Attendus

| Commande | Résultat OK |
|----------|-------------|
| `get nodes` (début) | 3 nodes STATUS = NotReady |
| `kubectl apply -f calico-crs.yaml` | 2 objets created |
| `kubectl get clusterresourceset` | calico-cni listé |
| `kubectl label cluster...` | cluster labeled |
| Pods Calico after ~1min | calico-node (3) + calico-kube-controllers (1) Running |
| `get nodes` (fin) | 3 nodes STATUS = Ready |
| `get pod test-pod -o wide` | IP dans range 192.168.X.Y |
| `./validation.sh` | Tous les ✅ |

---

## ⚠️ Notes Importantes

- **Installation Calico prend ~1-2 minutes** après labelling
- **CoreDNS passe aussi à Running** une fois Calico installé
- **Le label `cni=calico` déclenche tout** automatiquement (pattern GitOps)

---

## 🚀 Prochaine Étape

```bash
cd ../03-k0smotron
cat commands.md
```

Pour les explications détaillées, voir `commands.md`