# Module 03 - QUICKSTART

**Version ultra-rapide : Juste les commandes essentielles**

---

## ✅ Checklist Rapide

```bash
# 1. Aller dans le module
cd /home/ubuntu/R_D/CLAUDE_PROJECTS/capi-workshop/workshop-express/03-k0smotron

# 2. Installer l'opérateur k0smotron
kubectl apply -f https://github.com/k0sproject/k0smotron/releases/download/v1.7.0/install.yaml

# Attendre que le controller soit prêt
kubectl wait --for=condition=Available --timeout=300s \
  deployment/k0smotron-controller-manager -n k0smotron

# 3. Analyser le manifeste k0smotron (optionnel)
cat k0s-demo-cluster.yaml | grep -A 5 "kind: K0smotronControlPlane"

# 4. Créer le cluster
kubectl apply -f k0s-demo-cluster.yaml

# 5. Observer la création rapide (~1 min, Ctrl+C)
watch -n 2 'kubectl get clusters,k0smotroncontrolplane,machines'

# 6. Observer les pods CP dans management cluster
kubectl get pods -n kube-system | grep k0s-demo-cluster

# 7. Comparer avec Docker provider
echo "=== dev-cluster (Docker provider) ==="
docker ps --format "table {{.Names}}\t{{.Status}}" | grep dev-cluster
echo ""
echo "=== k0s-demo-cluster (k0smotron) ==="
docker ps --format "table {{.Names}}\t{{.Status}}" | grep k0s-demo-cluster

# 8. Comparaison automatique des ressources
./compare-providers.sh

# 9. Labeller pour Calico
kubectl label cluster k0s-demo-cluster cni=calico

# 10. Récupérer kubeconfig et vérifier nodes
clusterctl get kubeconfig k0s-demo-cluster > k0s-demo-cluster.kubeconfig
kubectl --kubeconfig k0s-demo-cluster.kubeconfig get nodes

# 11. Validation
./validation.sh
```

---

## Résultats Attendus

| Commande | Résultat OK |
|----------|-------------|
| `kubectl apply -f install.yaml` | k0smotron namespace et controller créés |
| `kubectl wait --for=condition=Available` | deployment/k0smotron-controller-manager Available |
| `kubectl apply -f k0s-demo-cluster.yaml` | 6 objets created |
| Cluster Provisioned | ~1 minute (vs ~3min Docker) |
| `kubectl get pods \| grep k0s-demo` | 3 pods Running (control plane) |
| Docker containers k0s-demo | 2 containers (workers only) |
| Docker containers dev-cluster | 3 containers (CP + workers) |
| `./compare-providers.sh` | Économie 33% containers, 33% mémoire |
| `get nodes` | 2 nodes Ready, ROLES=worker |
| `./validation.sh` | Tous les ✅ |

---

## ⚠️ Notes Importantes

- **Installation k0smotron** : Doit être effectuée avant de créer le cluster k0s-demo
- **Boot 3x plus rapide** : ~1 minute vs ~3 minutes (Docker provider)
- **Pas de container CP** : Le control plane tourne en 3 pods dans le management cluster
- **Économies mesurées** : 55% ressources, 75% mémoire, 66% boot time
- **Nodes immédiatement Ready** : k0s inclut un CNI par défaut (Kube-router)

---

## 🚀 Prochaine Étape

```bash
cd ../04-automation-helm
cat commands.md
```

Pour les explications détaillées, voir `commands.md`