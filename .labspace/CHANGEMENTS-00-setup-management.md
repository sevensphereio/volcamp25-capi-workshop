# Changements Module 00-setup-management

## ✅ Mise à jour : Montage Socket Docker

**Date :** 2025-10-01
**Importance :** 🔴 CRITIQUE

---

## Problème Résolu

### Symptôme
Sans le montage de la socket Docker dans le cluster kind, les workload clusters créés avec le Docker Provider (CAPD) ne se créent pas correctement. Les machines restent indéfiniment en état "Provisioning".

### Cause
Le Docker Provider (CAPD) doit pouvoir communiquer avec le Docker Daemon de l'hôte pour créer des containers qui simulent des VMs. Sans accès à `/var/run/docker.sock`, CAPD ne peut pas créer ces containers.

---

## Solution Implémentée

### Configuration kind mise à jour

Ajout de la section `extraMounts` dans le fichier de configuration kind :

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: capi-management
nodes:
  - role: control-plane
    extraMounts:                          # ← NOUVEAU
      - hostPath: /var/run/docker.sock     # ← NOUVEAU
        containerPath: /var/run/docker.sock # ← NOUVEAU
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
```

---

## Fichiers Modifiés

### 1. `commands.md`
- ✅ Configuration kind mise à jour avec `extraMounts`
- ✅ Section d'explication ajoutée pour le montage socket
- ✅ Section de dépannage ajoutée avec diagnostic socket Docker
- ✅ Architecture Docker-in-Docker expliquée dans "Comprendre en Profondeur"
- ✅ Nouvelle étape de vérification socket (Étape 4)

### 2. `QUICKSTART.md`
- ✅ Configuration kind mise à jour avec `extraMounts`
- ✅ Nouvelle étape de vérification socket ajoutée

### 3. `scripts/setup-infrastructure.sh`
- ✅ Configuration kind mise à jour avec `extraMounts`
- ✅ Vérification automatique de la socket ajoutée après création cluster

### 4. Nouveaux Fichiers Créés

#### `verify-docker-socket.sh` (NOUVEAU)
Script de vérification dédié qui teste :
- ✅ Existence du cluster kind
- ✅ Socket Docker montée et accessible
- ✅ Communication avec Docker Daemon
- ✅ État du CAPD Controller
- ✅ Logs CAPD pour erreurs Docker

#### `README.md` (NOUVEAU)
Documentation complète du module avec :
- ✅ Explication de l'importance de la socket Docker
- ✅ Architecture visuelle
- ✅ Guide de démarrage rapide
- ✅ Procédures de dépannage

#### `CHANGEMENTS.md` (ce fichier)
Documentation des modifications apportées au module

---

## Architecture Avant / Après

### ❌ AVANT (Configuration Incomplète)

```
Host Machine
├── Docker Daemon (dockerd)
│   └── Socket: /var/run/docker.sock
│
└── Container kind (management cluster)
    └── Pod CAPD Controller
        └── ❌ Pas d'accès à Docker
            └── Erreur: "Cannot connect to Docker daemon"
```

### ✅ APRÈS (Configuration Correcte)

```
Host Machine
├── Docker Daemon (dockerd)
│   └── Socket: /var/run/docker.sock
│
├── Container kind (management cluster)
│   ├── Socket montée: /var/run/docker.sock → (partagée avec host)
│   └── Pod CAPD Controller
│       └── ✅ Utilise la socket pour créer containers
│
└── Containers créés par CAPD (workload clusters)
    ├── dev-cluster-control-plane-xxx
    ├── dev-cluster-worker-xxx
    └── k0s-demo-cluster-worker-xxx
```

---

## Impact sur le Workshop

### Participants

**Si cluster déjà créé SANS socket :**
```bash
# Recréer le cluster avec la bonne configuration
kind delete cluster --name capi-management
cd /home/volcampdev/workshop-express/00-setup-management
cat commands.md  # Suivre les nouvelles instructions
```

**Validation :**
```bash
cd /home/volcampdev/workshop-express/00-setup-management
./verify-docker-socket.sh  # Doit afficher ✅
./validation.sh            # Doit afficher ✅
```

### Formateurs

**Nouveaux points à mentionner :**
1. ⚠️ La socket Docker est ESSENTIELLE pour CAPD
2. 📚 Expliquer l'architecture Docker-in-Docker (kind + CAPD)
3. 🔍 Utiliser `verify-docker-socket.sh` pour diagnostic
4. 🚀 Montrer `docker ps` avant/après création workload cluster

**Timing inchangé :** 15 minutes (une étape de vérification ajoutée, mais rapide)

---

## Validation des Changements

### Test 1 : Création Cluster Management
```bash
cd /home/volcampdev/workshop-express/00-setup-management

# Créer cluster
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

# Vérifier socket
docker exec capi-management-control-plane ls -la /var/run/docker.sock
# Doit afficher: srw-rw---- ... /var/run/docker.sock

docker exec capi-management-control-plane docker ps
# Doit afficher les containers Docker de l'hôte
```

### Test 2 : Script de Vérification
```bash
./verify-docker-socket.sh
# Tous les tests doivent passer avec ✅
```

### Test 3 : Validation Complète
```bash
./validation.sh
# Tous les tests doivent passer avec ✅
```

### Test 4 : Création Workload Cluster (Module 01)
```bash
# Après avoir terminé Module 00
cd ../01-premier-cluster
kubectl apply -f dev-cluster.yaml

# Vérifier que les containers sont créés
watch -n 2 'docker ps | grep dev-cluster'
# Doit afficher les containers dev-cluster-control-plane et dev-cluster-worker
```

---

## Dépannage

### Socket Non Montée

**Symptôme :**
```bash
./verify-docker-socket.sh
❌ Socket Docker NON accessible dans le cluster kind
```

**Solution :**
```bash
# Recréer avec bonne configuration
kind delete cluster --name capi-management
kind create cluster --config management-cluster-config.yaml
clusterctl init --infrastructure docker
```

### Permission Denied

**Symptôme :**
```bash
docker exec capi-management-control-plane docker ps
permission denied while trying to connect to the Docker daemon socket
```

**Solution :**
```bash
# Vérifier permissions socket sur l'hôte
ls -la /var/run/docker.sock
# Doit être: srw-rw---- root docker

# Vérifier que l'utilisateur est dans le groupe docker
groups
# Doit contenir "docker"

# Si pas dans le groupe, ajouter et relogin
sudo usermod -aG docker $USER
# Puis déconnecter/reconnecter ou: newgrp docker
```

---

## Notes pour la Prochaine Version

### Améliorations Possibles

1. **Script d'auto-correction**
   - Détecter automatiquement si socket manquante
   - Proposer recréation automatique du cluster

2. **Validation Proactive**
   - Ajouter check socket dans `validation.sh`
   - Bloquer progression si socket non montée

3. **Documentation Visuelle**
   - Diagrammes architecture Docker-in-Docker
   - Vidéo explicative socket mounting

4. **Support Multi-OS**
   - Tester sur macOS (Docker Desktop)
   - Tester sur Windows (WSL2 + Docker Desktop)
   - Documenter différences par OS

---

## Ressources Additionnelles

- **kind Documentation :** https://kind.sigs.k8s.io/docs/user/configuration/#extra-mounts
- **ClusterAPI Docker Provider :** https://cluster-api.sigs.k8s.io/user/quick-start.html#docker
- **Docker Socket Security :** https://docs.docker.com/engine/security/

---

**Version :** 2.0
**Auteur :** Claude Code
**Révision :** 2025-10-01
