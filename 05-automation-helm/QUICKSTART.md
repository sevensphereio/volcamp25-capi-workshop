# Module 04 - QUICKSTART

**Version ultra-rapide : Juste les commandes essentielles**

---

## ✅ Checklist Rapide

```bash
# 1. Aller dans le module
cd /home/ubuntu/R_D/CLAUDE_PROJECTS/capi-workshop/workshop-express/05-automation-helm

# 2. Installer le Helm Addon Provider
helm repo add capi-addon-provider https://kubernetes-sigs.github.io/cluster-api-addon-provider-helm
helm repo update

helm install capi-addon-provider capi-addon-provider/cluster-api-addon-provider-helm \
  --namespace capi-addon-system \
  --create-namespace \
  --wait \
  --timeout 300s

# Vérifier l'installation
kubectl get pods -n capi-addon-system

# 3. Analyser le HelmChartProxy (optionnel)
cat nginx-helmchartproxy.yaml

# 4. Labeller les clusters pour sélection
kubectl label cluster dev-cluster environment=demo
kubectl label cluster k0s-demo-cluster environment=demo

# 5. Vérifier les labels
kubectl get clusters --show-labels

# 6. Créer le HelmChartProxy
kubectl apply -f nginx-helmchartproxy.yaml

# 7. Observer la création automatique (attendre ~2 min, Ctrl+C)
watch -n 2 'kubectl get helmchartproxy,helmreleaseproxy'

# 8. Vérifier les détails
kubectl get helmreleaseproxy -o wide

# 9. Vérifier nginx dans dev-cluster
kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig get pods -l app.kubernetes.io/name=nginx

# 10. Vérifier nginx dans k0s-demo-cluster
kubectl --kubeconfig ../03-k0smotron/k0s-demo-cluster.kubeconfig get pods -l app.kubernetes.io/name=nginx

# 11. Vérifier les services
kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig get svc nginx-app
kubectl --kubeconfig ../03-k0smotron/k0s-demo-cluster.kubeconfig get svc nginx-app

# 12. Tester nginx (port-forward)
kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig port-forward svc/nginx-app 8080:80 &
PID=$!
sleep 2
curl -s http://localhost:8080 | grep -o "<title>.*</title>"
kill $PID 2>/dev/null

# 13. Validation
./validation.sh
```

---

## Résultats Attendus

| Commande | Résultat OK |
|----------|-------------|
| `helm install capi-addon-provider...` | Release deployed, STATUS: deployed |
| `kubectl get pods -n capi-addon-system` | capi-addon-helm-controller-manager Running |
| `kubectl label cluster...` | 2 clusters labeled |
| `kubectl apply -f nginx-helmchartproxy.yaml` | helmchartproxy created |
| `kubectl get helmreleaseproxy` | 2 HelmReleaseProxy (un par cluster) |
| Pods nginx after ~2min | 2 pods Running dans chaque cluster |
| `get svc nginx-app` | Service NodePort dans les 2 clusters |
| `curl localhost:8080` | `<title>Welcome to nginx!</title>` |
| `./validation.sh` | Tous les ✅ |

---

## ⚠️ Notes Importantes

- **Installation Helm Addon Provider** : Doit être effectuée avant de créer le HelmChartProxy
- **1 HelmChartProxy → N déploiements** : Un seul manifest déploie sur tous les clusters matchant le label
- **Pattern GitOps** : Label `environment=demo` déclenche le déploiement automatique
- **Self-service** : Nouveau cluster avec label = nginx déployé automatiquement
- **Déploiement prend ~2 minutes** : Helm install + pull image nginx

---

## 🚀 Prochaine Étape

```bash
cd ../05-operations-cleanup
cat commands.md
```

Pour les explications détaillées, voir `commands.md`