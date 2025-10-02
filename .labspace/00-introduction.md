# Module 00: Installation des Outils du Workshop

**Durée:** 10 minutes
**Objectif:** Installer et valider tous les outils nécessaires au workshop

---

## 📑 Table des Matières

- [🎯 Objectifs](#-objectifs).
- [📋 Outils à Installer](#-outils-à-installer). 
- [🔧 Installation Pas-à-Pas](#-installation-pas-à-pas). 
- [✅ Validation Finale](#-validation-finale). 

---

## 🎯 Objectifs

À la fin de ce module, vous aurez installé et validé :

- ✅ **Docker Engine** - Runtime pour les containers. 
- ✅ **kind** - Kubernetes IN Docker (management cluster). 
- ✅ **kubectl** - CLI Kubernetes
- ✅ **kubectl plugins** - kubens, kubectx, kubectl-slice, kubectl-klock
- ✅ **clusterctl** - CLI ClusterAPI
- ✅ **Helm** - Gestionnaire de packages Kubernetes
- ✅ **jq** - Parser JSON en ligne de commande
- ✅ **yq** - Parser YAML en ligne de commande
- ✅ **tree** - Visualisation arborescente de répertoires

---

## 📋 Outils mis en jeu

### Récapitulatif des Composants

| Outil | Version Minimale | Utilité Workshop |
|-------|------------------|------------------|
| **Docker Engine** | 20.10+ | Runtime pour kind et clusters CAPD |
| **kind** | 0.30.0+ | Management cluster local |
| **kubectl** | 1.32.0+ | outils de gestion en CLI pour clusters k8s |
| **kubens** | - | Changer de namespace rapidement |
| **kubectx** | - | Changer de contexte Kubernetes |
| **kubectl-slice** | - | permet de découper un manifests YAML multi-documents |
| **kubectl-klock** | - | kubectl -w mais en mieux |
| **clusterctl** | 1.10.6 | CLI ClusterAPI (init, create, upgrade) |
| **Helm** | 3.19.0+ | Gestionnaire de packages Kubernetes |
| **jq** | 1.6+ | Manipuler JSON (kubeconfig, manifests) |
| **yq** | 4.0+ | Manipuler YAML (manifests, values) |
| **tree** | 1.8+ | Visualiser structure de répertoires |

## 🔧 Installation Pas-à-Pas

> **💡 Note pour les Formateurs :** Si vous avez déjà préparé des machines avec tous les outils installés, les participants peuvent passer directement à la [section Validation](#-validation-finale).

**FASTRACK**:
```bash
cd 00-introduction
chmod +x setup.sh
./setup.sh
```

/!\ attention si les limites se s'appliquent pas, les appliquer à la main ci-dessous Etape 11 Option B /!\

### Étape 1 : Déterminer votre système d'exploitation

**Commande :**
```bash
uname -s -m
```

**Résultats possibles :**
- `Linux x86_64` → Instructions Linux AMD64
- `Linux aarch64` → Instructions Linux ARM64
- `Darwin x86_64` → Instructions macOS Intel
- `Darwin arm64` → Instructions macOS Apple Silicon

---

### Étape 2 : Installer Docker Engine

#### Linux (Ubuntu/Debian)

```bash
# Mise à jour des paquets
sudo apt-get update

# Installation des dépendances
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# Ajout de la clé GPG officielle Docker
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Ajout du repository Docker
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Installation Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Ajouter votre utilisateur au groupe docker (évite sudo)
sudo usermod -aG docker $USER
newgrp docker

# Vérification
docker --version
```

#### macOS [ /!\ NON TESTE /!\ ]

```bash
# Installer Docker Desktop via Homebrew
brew install --cask docker

# OU télécharger Docker Desktop manuellement :
# https://www.docker.com/products/docker-desktop/

# Lancer Docker Desktop depuis Applications
# Vérification
docker --version
```

**✅ Vérification :** Vous devez voir `Docker version 20.10.0` ou supérieur

---

### Étape 3 : Installer kind

#### Linux

```bash
# Télécharger kind v0.30.0
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.30.0/kind-linux-amd64

# Rendre exécutable
chmod +x ./kind

# Déplacer dans PATH
sudo mv ./kind /usr/local/bin/kind

# Vérification
kind --version
```

#### macOS [ /!\ NON TESTE /!\ ]

```bash
# Via Homebrew
brew install kind

# OU manuellement (Intel)
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.30.0/kind-darwin-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# OU manuellement (Apple Silicon)
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.30.0/kind-darwin-arm64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Vérification
kind --version
```

**✅ Vérification :** `kind version 0.30.0` ou supérieur

---

### Étape 4 : Installer kubectl

#### Linux

```bash
# Télécharger la dernière version stable
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Rendre exécutable
chmod +x kubectl

# Déplacer dans PATH
sudo mv kubectl /usr/local/bin/

# Vérification
kubectl version --client
```

#### macOS [ /!\ NON TESTE /!\ ]

```bash
# Via Homebrew
brew install kubectl

# OU manuellement (Intel)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# OU manuellement (Apple Silicon)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/arm64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Vérification
kubectl version --client
```

**✅ Vérification :** `Client Version: v1.32.0` ou supérieur

---

### Étape 5 : Installer kubectl plugins (kubens, kubectx, kubectl-slice)

#### Installer krew (gestionnaire de plugins kubectl)

**Linux/macOS :**
```bash
(
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  KREW="krew-${OS}_${ARCH}" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
  tar zxvf "${KREW}.tar.gz" &&
  ./"${KREW}" install krew
)

# Ajouter krew au PATH
echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# OU pour zsh
echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Vérification
kubectl krew version
```

#### Installer les plugins

```bash
# kubectx : changer de contexte Kubernetes rapidement
kubectl krew install ctx

# kubens : changer de namespace rapidement
kubectl krew install ns

# kubectl-slice : découper des manifests YAML multi-documents
kubectl krew install slice

# kubectl-klock : verrouiller ressources pour éviter modifications accidentelles
kubectl krew install klock

# Vérification
kubectl ctx --help
kubectl ns --help
kubectl slice --help
kubectl klock --help
```

**✅ Vérification :** Les 4 commandes affichent leur aide

---

### Étape 6 : Installer clusterctl

#### Linux

```bash
# Télécharger clusterctl v1.10.6
curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v1.10.6/clusterctl-linux-amd64 -o clusterctl

# Rendre exécutable
chmod +x ./clusterctl

# Déplacer dans PATH
sudo mv ./clusterctl /usr/local/bin/clusterctl

# Vérification
clusterctl version
```

#### macOS [ /!\ NON TESTE /!\ ]

```bash
# Intel
curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v1.10.6/clusterctl-darwin-amd64 -o clusterctl
chmod +x ./clusterctl
sudo mv ./clusterctl /usr/local/bin/clusterctl

# Apple Silicon
curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v1.10.6/clusterctl-darwin-arm64 -o clusterctl
chmod +x ./clusterctl
sudo mv ./clusterctl /usr/local/bin/clusterctl

# Vérification
clusterctl version
```

**✅ Vérification :** `clusterctl version: &version.Info{Major:"1", Minor:"10", GitVersion:"v1.10.6"...}`

---

### Étape 7 : Installer Helm

#### Linux

```bash
# Télécharger Helm v3.19.0
curl -fsSL https://get.helm.sh/helm-v3.19.0-linux-amd64.tar.gz -o helm.tar.gz

# Extraire l'archive
tar -zxvf helm.tar.gz

# Déplacer dans PATH
sudo mv linux-amd64/helm /usr/local/bin/helm

# Nettoyer
rm -rf linux-amd64 helm.tar.gz

# Vérification
helm version
```

#### macOS [ /!\ NON TESTE /!\ ]

```bash
# Via Homebrew
brew install helm

# OU manuellement (Intel)
curl -fsSL https://get.helm.sh/helm-v3.19.0-darwin-amd64.tar.gz -o helm.tar.gz
tar -zxvf helm.tar.gz
sudo mv darwin-amd64/helm /usr/local/bin/helm
rm -rf darwin-amd64 helm.tar.gz

# OU manuellement (Apple Silicon)
curl -fsSL https://get.helm.sh/helm-v3.19.0-darwin-arm64.tar.gz -o helm.tar.gz
tar -zxvf helm.tar.gz
sudo mv darwin-arm64/helm /usr/local/bin/helm
rm -rf darwin-arm64 helm.tar.gz

# Vérification
helm version
```

**✅ Vérification :** `version.BuildInfo{Version:"v3.19.0"...}`

---

### Étape 8 : Installer jq

#### Linux (Ubuntu/Debian)

```bash
sudo apt-get update
sudo apt-get install -y jq

# Vérification
jq --version
```

#### macOS [ /!\ NON TESTE /!\ ]

```bash
# Via Homebrew
brew install jq

# Vérification
jq --version
```

**✅ Vérification :** `jq-1.6` ou supérieur

---

### Étape 9 : Installer yq

#### Linux

```bash
# Télécharger yq v4.44.6
curl -L https://github.com/mikefarah/yq/releases/download/v4.44.6/yq_linux_amd64 -o yq

# Rendre exécutable
chmod +x yq

# Déplacer dans PATH
sudo mv yq /usr/local/bin/yq

# Vérification
yq --version
```

#### macOS [ /!\ NON TESTE /!\ ]

```bash
# Via Homebrew
brew install yq

# OU manuellement (Intel)
curl -L https://github.com/mikefarah/yq/releases/download/v4.44.6/yq_darwin_amd64 -o yq
chmod +x yq
sudo mv yq /usr/local/bin/yq

# OU manuellement (Apple Silicon)
curl -L https://github.com/mikefarah/yq/releases/download/v4.44.6/yq_darwin_arm64 -o yq
chmod +x yq
sudo mv yq /usr/local/bin/yq

# Vérification
yq --version
```

**✅ Vérification :** `yq (https://github.com/mikefarah/yq/) version v4.44.6`

---

### Étape 10 : Installer tree

#### Linux (Ubuntu/Debian)

```bash
sudo apt-get update
sudo apt-get install -y tree

# Vérification
tree --version
```

#### macOS [ /!\ NON TESTE /!\ ]

```bash
# Via Homebrew
brew install tree

# Vérification
tree --version
```

**✅ Vérification :** `tree v1.8.0` ou supérieur

---

### Étape 11 : Augmenter les limites système (Kernel et Filesystem)

**Objectif :** Optimiser le système pour supporter de nombreux clusters et containers

#### Pourquoi augmenter les limites ?

Le workshop crée plusieurs clusters Kubernetes avec de nombreux containers. Les limites par défaut du système peuvent causer :
- ❌ Erreur "too many open files"
- ❌ Erreur "inotify watch limit exceeded"
- ❌ Performance dégradée avec beaucoup de containers
- ❌ Échecs de création de pods/containers

#### Option A : Script Automatique (RECOMMANDÉ)

**Commande :**
```bash
# Lancer le script de configuration automatique
./configure-system-limits.sh
```

Ce script interactif va :
1. Détecter votre système d'exploitation (Linux/macOS)
2. Configurer automatiquement toutes les limites nécessaires
3. Créer des backups de vos fichiers de configuration
4. Vérifier que tout est bien configuré

**Note :** Vous devrez vous reconnecter après l'exécution du script pour que les changements prennent effet.

---

#### Option B : Configuration Manuelle

Si vous préférez configurer manuellement ou si le script automatique échoue :

##### Linux (Ubuntu/Debian)

**Configuration des limites :**

```bash
# 1. Augmenter les limites d'inotify (surveillance fichiers)
echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.conf
echo "fs.inotify.max_user_instances=512" | sudo tee -a /etc/sysctl.conf

# 2. Augmenter les limites de fichiers ouverts
echo "fs.file-max=2097152" | sudo tee -a /etc/sysctl.conf

# 3. Augmenter les limites de processus/threads
echo "kernel.pid_max=4194304" | sudo tee -a /etc/sysctl.conf
echo "kernel.threads-max=4194304" | sudo tee -a /etc/sysctl.conf

# 4. Augmenter les limites réseau (connexions)
echo "net.core.somaxconn=32768" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.ip_local_port_range=1024 65535" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_max_syn_backlog=8192" | sudo tee -a /etc/sysctl.conf

# 5. Appliquer immédiatement les changements
sudo sysctl -p

# Vérification
sudo sysctl fs.inotify.max_user_watches
sudo sysctl fs.file-max
sudo sysctl kernel.pid_max
```

**Configuration des limites utilisateur (/etc/security/limits.conf) :**

```bash
# Ajouter les limites pour l'utilisateur courant
cat << EOF | sudo tee -a /etc/security/limits.conf
# Workshop ClusterAPI - Limites augmentées
*               soft    nofile          1048576
*               hard    nofile          1048576
*               soft    nproc           unlimited
*               hard    nproc           unlimited
*               soft    memlock         unlimited
*               hard    memlock         unlimited
root            soft    nofile          1048576
root            hard    nofile          1048576
root            soft    nproc           unlimited
root            hard    nproc           unlimited
EOF

# Vérifier les limites actuelles
ulimit -n   # Fichiers ouverts
ulimit -u   # Processus
```

**Configuration systemd pour Docker :**

```bash
# Créer le répertoire de configuration
sudo mkdir -p /etc/systemd/system/docker.service.d

# Créer le fichier de limites pour Docker
cat << EOF | sudo tee /etc/systemd/system/docker.service.d/limits.conf
[Service]
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
EOF

# Recharger systemd et redémarrer Docker
sudo systemctl daemon-reload
sudo systemctl restart docker

# Vérification
docker info | grep -i "Default Runtime"
```

#### macOS

**Configuration macOS :**

```bash
# 1. Augmenter les limites de fichiers ouverts (session)
sudo launchctl limit maxfiles 1048576 1048576

# 2. Créer un fichier de configuration permanent
cat << EOF | sudo tee /Library/LaunchDaemons/limit.maxfiles.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>limit.maxfiles</string>
    <key>ProgramArguments</key>
    <array>
      <string>launchctl</string>
      <string>limit</string>
      <string>maxfiles</string>
      <string>1048576</string>
      <string>1048576</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>ServiceIPC</key>
    <false/>
  </dict>
</plist>
EOF

# 3. Charger la configuration
sudo launchctl load -w /Library/LaunchDaemons/limit.maxfiles.plist

# 4. Configurer Docker Desktop
# Ouvrir Docker Desktop → Settings → Resources
# - CPUs: 4+ cores
# - Memory: 8+ GB
# - Swap: 2+ GB
# - Disk: 50+ GB

# Vérification
launchctl limit maxfiles
ulimit -n
```

#### Vérification finale des limites

**Commandes de vérification :**

```bash
# Linux
echo "=== Limites Kernel ==="
sudo sysctl fs.inotify.max_user_watches
sudo sysctl fs.inotify.max_user_instances
sudo sysctl fs.file-max
sudo sysctl kernel.pid_max
sudo sysctl net.core.somaxconn

echo -e "\n=== Limites Utilisateur ==="
ulimit -n    # Hard limit: 1048576
ulimit -u    # Hard limit: unlimited
ulimit -l    # Memlock: unlimited

echo -e "\n=== Docker Info ==="
docker info 2>/dev/null | grep -E "(CPUs|Total Memory|Server Version)"

# macOS
launchctl limit maxfiles
ulimit -n
```

**Résultat attendu Linux :**
```
=== Limites Kernel ===
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 512
fs.file-max = 2097152
kernel.pid_max = 4194304
net.core.somaxconn = 32768

=== Limites Utilisateur ===
1048576
unlimited
unlimited

=== Docker Info ===
 CPUs: 8
 Total Memory: 15.5 GiB
 Server Version: 27.4.0
```

**Résultat attendu macOS :**
```
maxfiles    1048576        1048576
1048576
```

**✅ Si tous les tests passent :** Votre système est optimisé pour le workshop !

**❌ Si erreur de permissions :** Vous devez avoir les droits sudo pour modifier ces paramètres

---

## ✅ Validation Finale

### Lancer le script de validation automatique

**Commande :**
```bash
cd 00-introduction
./verification.sh
```

**Résultat attendu :**
```
🔍 Module 00: Validation Installation Outils
=============================================

✅ Docker installé (version 27.4.0)
✅ kind installé (version 0.30.0)
✅ kubectl installé (version 1.32.0)
✅ kubectl plugin: ctx installé
✅ kubectl plugin: ns installé
✅ kubectl plugin: slice installé
✅ kubectl plugin: klock installé
✅ clusterctl installé (version 1.10.6)
✅ Helm installé (version 3.19.0)
✅ jq installé (version 1.6)
✅ yq installé (version 4.44.6)
✅ tree installé (version 1.8.0)

=============================================
🔍 Vérification des limites système
=============================================

✅ fs.inotify.max_user_watches: 524288 (>= 524288)
✅ fs.inotify.max_user_instances: 512 (>= 512)
✅ fs.file-max: 2097152 (>= 2097152)
✅ kernel.pid_max: 4194304 (>= 4194304)
✅ net.core.somaxconn: 32768 (>= 32768)
✅ ulimit -n (open files): 1048576 (>= 1048576)
✅ Docker daemon accessible et en cours d'exécution

=============================================
🎉 Module 00 terminé avec succès!
🚀 Tous les outils et limites système sont prêts
=============================================

Prochaine commande:
  cd ~/00-setup-management
  cat commands.md
```

**✅ Si tous les tests passent :** Vous êtes prêt pour le workshop !

**❌ Si un test échoue :** Revenez aux étapes d'installation correspondantes

---

## 🎓 Points Clés à Retenir

✅ **Docker Engine** : Nécessaire pour kind et CAPD
✅ **kind** : Créera votre management cluster local
✅ **kubectl** : Interface universelle avec tous les clusters
✅ **Plugins kubectl** : Productivité maximale (ctx, ns, slice, klock)
✅ **clusterctl** : CLI officielle ClusterAPI
✅ **Helm** : Déploiements multi-clusters et automatisation
✅ **jq** : Manipulation JSON (kubeconfig, manifests)
✅ **yq** : Manipulation YAML (manifests, values)
✅ **tree** : Visualisation arborescente de répertoires

---

## ⏭️ Prochaine Étape

Une fois tous les outils ✅, passez au **Module 00-setup-management**

---

## 🔧 Dépannage

### Docker installation échoue

**Symptôme Linux :** `Permission denied` lors de `docker ps`

**Solution :**
```bash
# Vérifier que vous êtes dans le groupe docker
groups | grep docker

# Si non présent, ajouter et recharger
sudo usermod -aG docker $USER
newgrp docker

# OU redémarrer votre session
```

**Symptôme macOS :** `Cannot connect to Docker daemon`

**Solution :** Lancer Docker Desktop depuis Applications et attendre que l'icône soit verte

---

### kubectl plugin non trouvé après installation

**Symptôme :** `kubectl: 'ctx' is not a kubectl command`

**Solution :**
```bash
# Vérifier que krew est dans le PATH
echo $PATH | grep krew

# Si absent, ajouter manuellement
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# Rendre permanent
echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

---

### clusterctl version affiche une erreur

**Symptôme :** `clusterctl version` affiche des warnings

**Cause :** C'est normal ! clusterctl essaie de se connecter au management cluster

**Vérification :** Tant que le numéro de version s'affiche (`v1.10.6`), l'outil est bien installé

---

### Erreur "certificate signed by unknown authority"

**Symptôme :** Erreur lors du téléchargement (curl/wget)

**Solution :**
```bash
# Mettre à jour les certificats CA (Linux)
sudo apt-get update
sudo apt-get install -y ca-certificates

# macOS : réinstaller certificates
brew reinstall ca-certificates
```

---

## 💡 Astuces Productivité

### Alias utiles à ajouter

```bash
# Ajouter à ~/.bashrc ou ~/.zshrc
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgn='kubectl get nodes'
alias kdp='kubectl describe pod'
alias kl='kubectl logs'
alias kex='kubectl exec -it'

# Recharger
source ~/.bashrc  # ou ~/.zshrc
```

### Autocomplétion kubectl

**Bash :**
```bash
echo 'source <(kubectl completion bash)' >> ~/.bashrc
source ~/.bashrc
```

**Zsh :**
```bash
echo 'source <(kubectl completion zsh)' >> ~/.zshrc
source ~/.zshrc
```

**Bénéfice :** Tab pour autocompléter les commandes kubectl !

---

**Module 00 terminé ! 🎉 Tous les outils sont installés.**
