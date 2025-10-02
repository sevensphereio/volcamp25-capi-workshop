# Module 05 - QUICKSTART

**Version ultra-rapide : Juste les commandes essentielles**

---

## ✅ Checklist Rapide

```bash
# 1. Aller dans le module
cd /home/ubuntu/R_D/CLAUDE_PROJECTS/capi-workshop/workshop-express/05-operations-cleanup

# 2. Vérifier l'état actuel
kubectl get machinedeployment -o wide

# 3. Scaler dev-cluster à 4 workers
kubectl scale machinedeployment dev-cluster-md-0 --replicas=4

# 4. Observer le scaling (attendre ~2 min, Ctrl+C)
watch -n 2 'kubectl get machines -l cluster.x-k8s.io/cluster-name=dev-cluster'

# 5. Scaler k0s-demo-cluster à 3 workers (script)
./scale-workers.sh k0s-demo-cluster 3

# 6. Lancer le monitoring (observer 30s, Ctrl+C)
./monitor-resources.sh

# 7. Récapitulatif du workshop (afficher résumé)
cat << 'EOF'
🎓 Workshop ClusterAPI Express - 90 Minutes:
✅ Module 00: Fondations ClusterAPI (10min)
✅ Module 01: Premier cluster - 7 objets (15min)
✅ Module 02: Networking - CNI + CRS (15min)
✅ Module 03: k0smotron - Économies 55% (15min)
✅ Module 04: Helm multi-cluster (20min)
✅ Module 05: Operations & cleanup (15min)

📊 Réalisations:
- 2 clusters créés (Docker + k0smotron)
- 2 applications nginx déployées
- Économies mesurées: 55% ressources
EOF

# 8. Sauvegarder l'état final
kubectl get clusters,machines
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "(dev-cluster|k0s-demo)"

# 9. Exécuter le cleanup (répondre 'y')
./cleanup.sh

# 10. Vérifier le cleanup complet
kubectl get clusters,machines
docker ps | grep -E "(dev-cluster|k0s-demo)" || echo "✅ Tous les clusters nettoyés"

# 11. Validation finale
./validation.sh
```

---

## Résultats Attendus

| Commande | Résultat OK |
|----------|-------------|
| `kubectl scale... --replicas=4` | machinedeployment scaled |
| `get machines` (dev-cluster) | 5 machines (1 CP + 4 workers) |
| `./scale-workers.sh...` | k0s-demo-cluster scaled to 3 |
| `./monitor-resources.sh` | Stats affichées (clusters, machines, containers) |
| `./cleanup.sh` | Clusters supprimés après confirmation |
| `get clusters` (après cleanup) | No resources found |
| `docker ps \| grep cluster` | Aucun container (ou seulement management) |
| `./validation.sh` | Cleanup confirmé ✅ |

---

## ⚠️ Notes Importantes

- **Scaling prend ~2 minutes** : Création de nouvelles machines + bootstrap
- **Cleanup est irréversible** : Toutes les données des workload clusters seront perdues
- **Management cluster préservé** : kind-capi-management reste actif pour d'autres workshops
- **Économie finale mesurée** : 8 containers (5+3) vs 6 containers (2+3+1) avec k0smotron

---

## 🎉 FÉLICITATIONS !

Vous avez complété le **Workshop ClusterAPI Express** en 90 minutes !

### Ce que vous maîtrisez maintenant :

✅ Créer des clusters Kubernetes déclarativement (ClusterAPI)
✅ Automatiser le déploiement CNI (ClusterResourceSets)
✅ Optimiser les ressources (k0smotron - 55% économie)
✅ Déployer des applications multi-cluster (HelmChartProxy)
✅ Scaler et monitorer vos clusters

### Prochaines étapes :

📚 **Workshop complet (11h)** : `cd ../../modules/` pour aller plus loin
🌐 **Documentation** : [ClusterAPI](https://cluster-api.sigs.k8s.io/) | [k0smotron](https://docs.k0smotron.io/)
💬 **Communauté** : Rejoignez le Slack ClusterAPI

---

**🚀 Prêt pour la production !**

Pour les explications détaillées, voir `commands.md`