# Module 00: Introduction & Setup - Commandes

**Durée:** 10 minutes
**Objectif:** Comprendre ClusterAPI et valider l'environnement

---

## 📖 Partie 1: Présentation ClusterAPI (5 minutes)

### Architecture ClusterAPI

ClusterAPI permet de gérer le lifecycle complet de clusters Kubernetes de façon **déclarative** et **Kubernetes-native**.

```
┌─────────────────────────────────────────┐
│     Management Cluster                  │
│  ┌──────────────────────────────────┐   │
│  │   ClusterAPI Controllers         │   │
│  │   - Cluster Controller           │   │
│  │   - Machine Controller           │   │
│  │   - Provider Controllers         │   │
│  └──────────────────────────────────┘   │
│                  ↓                       │
│     Manages Workload Clusters           │
└─────────────────────────────────────────┘
            ↓           ↓
┌─────────────────┐  ┌─────────────────┐
│ Workload Cluster│  │ Workload Cluster│
│  dev-cluster    │  │  prod-cluster   │
│  (Apps)         │  │  (Apps)         │
└─────────────────┘  └─────────────────┘
```

### Concepts Clés

1. **Management Cluster:** Cluster Kubernetes qui héberge ClusterAPI
2. **Workload Cluster:** Clusters Kubernetes gérés par ClusterAPI (vos apps)
3. **Cluster:** CRD représentant un cluster Kubernetes complet
4. **Machine:** CRD représentant une machine (node) dans un cluster
5. **Provider:** Implementation pour une infrastructure (Docker, AWS, Azure, etc.)

### Pourquoi ClusterAPI?

✅ **Déclaratif:** Clusters définis en YAML comme tout objet Kubernetes
✅ **Multi-cloud:** Même API pour AWS, Azure, GCP, on-premise
✅ **Lifecycle management:** Create, scale, upgrade, delete automatisés
✅ **Kubernetes-native:** Utilise les patterns Kubernetes (CRDs, controllers)

---

## 🔧 Partie 2: Validation Environnement (3 minutes)

### Étape 1: Vérifier kubectl

```bash
kubectl version --client
```

**Résultat attendu:**
```
Client Version: v1.28.0 or higher
```

### Étape 2: Vérifier accès au Management Cluster

```bash
kubectl cluster-info --context kind-capi-management
```

**Résultat attendu:**
```
Kubernetes control plane is running at https://127.0.0.1:XXXXX
CoreDNS is running at https://127.0.0.1:XXXXX/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

### Étape 3: Vérifier ClusterAPI installé

```bash
kubectl get deployments -n capi-system
```

**Résultat attendu:**
```
NAME                            READY   UP-TO-DATE   AVAILABLE   AGE
capi-controller-manager         1/1     1            1           Xm
capd-controller-manager         1/1     1            1           Xm
```

### Étape 4: Vérifier k0smotron operator

```bash
kubectl get pods -n k0smotron
```

**Résultat attendu:**
```
NAME                                  READY   STATUS    RESTARTS   AGE
k0smotron-controller-manager-xxx      2/2     Running   0          Xm
```

### Étape 5: Vérifier Helm Addon Provider

```bash
kubectl get deployments -n capi-addon-system
```

**Résultat attendu:**
```
NAME                                    READY   UP-TO-DATE   AVAILABLE   AGE
capi-addon-helm-controller-manager      1/1     1            1           Xm
```

### Étape 6: Vérifier aucun workload cluster existant

```bash
kubectl get clusters
```

**Résultat attendu:**
```
No resources found in default namespace.
```

**👉 C'est normal! Vous allez créer vos premiers clusters dans les modules suivants.**

---

## ✅ Partie 3: Validation Automatique (2 minutes)

### Exécuter le script de validation

```bash
cd /home/ubuntu/R_D/CLAUDE_PROJECTS/capi-workshop/workshop-express/00-introduction
./verification.sh
```

**Résultat attendu:**
```
🔍 Module 00: Validation Environnement
========================================

✅ kubectl accessible
✅ Management cluster accessible
✅ ClusterAPI installé (v1.5.3)
✅ Docker provider ready
✅ k0smotron operator running
✅ Helm provider ready
✅ No existing workload clusters (clean slate)

========================================
🎉 Module 00 terminé avec succès!
🚀 Prêt pour Module 01: Premier Cluster ClusterAPI
========================================
```

---

## 📚 Résumé des Concepts

| Concept | Description | Exemple |
|---------|-------------|---------|
| **Management Cluster** | Cluster qui héberge ClusterAPI | kind-capi-management |
| **Workload Cluster** | Cluster géré par ClusterAPI | dev-cluster, prod-cluster |
| **Provider** | Implémentation infrastructure | Docker, AWS, Azure |
| **Cluster CRD** | Définition déclarative d'un cluster | `kind: Cluster` |
| **Machine CRD** | Définition déclarative d'un node | `kind: Machine` |

---

## 🎯 Ce que Vous Allez Faire Ensuite

**Module 01 (15 min):** Créer votre premier cluster avec ClusterAPI
- Définir un cluster en YAML
- Observer la création en temps réel
- Explorer les objets créés (Cluster, Machines, Nodes)

---

## 🔍 Troubleshooting

### kubectl not found
```bash
# Installer kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

### Management cluster not accessible
```bash
# Vérifier que le cluster kind existe
kind get clusters

# Doit afficher: capi-management

# Vérifier le contexte
kubectl config get-contexts
```

### ClusterAPI not installed
```bash
# Ce workshop nécessite une infrastructure pré-provisionnée
# Contactez le formateur si ClusterAPI n'est pas installé
```

---

## ⏭️ Prochaine Étape

Une fois la validation réussie:

```bash
cd ../01-premier-cluster
cat commands.md
```

---

**Module 00 complété! 🎉**
**Temps écoulé:** 10/90 minutes
**Prochaine étape:** Module 01 - Premier Cluster ClusterAPI