# Module 00-setup: Installation du Cluster de Management

**Durée:** 15 minutes | **Objectif:** Créer le cluster de management kind et installer ClusterAPI

---

## ⚡ Quick Start

```bash
cd /home/volcampdev/workshop-express/00-setup-management
./setup.sh
```

Le script `setup.sh` configure automatiquement les **feature gates ClusterAPI** nécessaires :
- `CLUSTER_TOPOLOGY=true` (support ClusterClass)
- `EXP_CLUSTER_RESOURCE_SET=true` (installation automatique d'addons)

---

## 📁 Fichiers du Module

- **[commands.md](commands.md)** - Instructions détaillées avec théorie et pratique
- **[QUICKSTART.md](QUICKSTART.md)** - Guide rapide (commandes uniquement)
- **[setup.sh](setup.sh)** - 🆕 Script d'installation automatique complet (avec exports)
- **[validation.sh](validation.sh)** - Script de validation de tous les composants
- **[verify-docker-socket.sh](verify-docker-socket.sh)** - Vérification spécifique de la socket Docker
- **management-cluster-config.yaml** - Configuration kind (créé durant le module)

---

## 🎯 Ce que ce module installe

1. **Cluster kind** `capi-management` avec:
   - Socket Docker montée (CRITIQUE pour CAPD)
   - Port 30080 exposé (pour tester les applications)
   - Labels et patches pour ingress et webhooks

2. **ClusterAPI Core v1.11.1**
   - Controllers principaux (Cluster, Machine, MachineDeployment)
   - Bootstrap Provider (kubeadm)
   - Control Plane Provider (kubeadm)

3. **Docker Provider (CAPD)**
   - Crée des containers Docker simulant des VMs
   - Utilise la socket Docker pour communiquer avec le daemon

4. **cert-manager v1.18.2**
   - Gestion automatique des certificats TLS
   - Requis pour les webhooks ClusterAPI

---

## ⚠️ Configuration CRITIQUE : Socket Docker

### Pourquoi c'est ESSENTIEL ?

Le montage de la socket Docker (`/var/run/docker.sock`) est **ABSOLUMENT NÉCESSAIRE** pour que le Docker Provider (CAPD) puisse créer des containers pour les workload clusters.

```yaml
extraMounts:
  - hostPath: /var/run/docker.sock
    containerPath: /var/run/docker.sock
```

### Architecture

```
Host Machine
├── Docker Daemon (dockerd)
│   └── Socket: /var/run/docker.sock
│
├── Container kind (management cluster)
│   ├── Socket montée: /var/run/docker.sock → (partagée avec host)
│   └── Pod CAPD Controller
│       └── Utilise la socket pour créer containers workload
│
└── Containers créés par CAPD (workload clusters)
    ├── dev-cluster-control-plane-xxx
    ├── dev-cluster-worker-xxx
    └── k0s-demo-cluster-worker-xxx
```

### Sans cette configuration

❌ Les workload clusters ne se créent pas
❌ Les machines restent en "Provisioning" indéfiniment
❌ Erreur CAPD: "Cannot connect to Docker daemon"

---

## 🚀 Démarrage Rapide

### Option 1 : Guide Complet
```bash
cd /home/volcampdev/workshop-express/00-setup-management
cat commands.md
# Suivre les instructions pas-à-pas
```

### Option 2 : Commandes Rapides
```bash
cd /home/volcampdev/workshop-express/00-setup-management

# 1. Créer cluster kind avec socket Docker
cat > management-cluster-config.yaml << 'EOF'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: capi-management
nodes:
  - role: control-plane
    extraMounts:
      - hostPath: /var/run/docker.sock
        containerPath: /var/run/docker.sock
    extraPortMappings:
      - containerPort: 30080
        hostPort: 30080
        protocol: TCP
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
            authorization-mode: "Webhook"
EOF

kind create cluster --config management-cluster-config.yaml

# 2. Initialiser ClusterAPI + Docker Provider (avec feature gates)
export CLUSTER_TOPOLOGY=true
export EXP_CLUSTER_RESOURCE_SET=true
clusterctl init --infrastructure docker

# 3. Vérifier socket Docker
./verify-docker-socket.sh

# 4. Validation finale
./validation.sh
```

---

## ✅ Validation

### 1. Vérifier la Socket Docker
```bash
./verify-docker-socket.sh
```

**Doit afficher :**
```
✅ Socket Docker est montée et accessible: /var/run/docker.sock
✅ Communication avec Docker Daemon réussie
✅ CAPD peut créer des containers pour workload clusters
```

### 2. Validation Complète
```bash
./validation.sh
```

**Doit afficher :**
```
✅ Cluster de management kind existe: capi-management
✅ ClusterAPI Core installé (capi-system)
✅ Docker Provider installé (capd-system)
✅ cert-manager opérationnel
✅ Tous les pods sont Running
```

---

## 🔧 Dépannage

### Socket Docker Non Accessible

**Symptôme :**
```bash
./verify-docker-socket.sh
❌ Socket Docker NON accessible dans le cluster kind
```

**Solution :**
```bash
# Recréer le cluster avec la bonne configuration
kind delete cluster --name capi-management
kind create cluster --config management-cluster-config.yaml
clusterctl init --infrastructure docker
./verify-docker-socket.sh
```

### Pods pas Ready

**Vérifier :**
```bash
kubectl get pods -A | grep -v Running
kubectl logs -n capd-system deployment/capd-controller-manager
```

**Solution :**
```bash
# Attendre que tous les pods soient Running (peut prendre 1-2 minutes)
watch -n 2 'kubectl get pods -A'
```

### clusterctl init échoue

**Vérifier connexion internet :**
```bash
curl -I https://github.com
```

**Retry avec verbosité :**
```bash
clusterctl init --infrastructure docker -v 5
```

---

## 📚 Ressources

- **Commandes détaillées :** [commands.md](commands.md)
- **Guide rapide :** [QUICKSTART.md](QUICKSTART.md)
- **ClusterAPI Docs :** https://cluster-api.sigs.k8s.io/
- **kind Docs :** https://kind.sigs.k8s.io/

---

## ⏭️ Prochaine Étape

Une fois la validation réussie :

```bash
cd ../01-premier-cluster
cat commands.md
```

**Module 01 :** Créer votre premier workload cluster avec Docker Provider

---

**Temps total :** ~15 minutes | **Difficulté :** ⭐⭐☆☆☆
