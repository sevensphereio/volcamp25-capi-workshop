# Module 00 - QUICKSTART

**Version ultra-rapide : Juste les commandes essentielles**

---

## ✅ Installation Rapide des Outils

### Installation krew et plugins kubectl

```bash
# Installer krew (gestionnaire de plugins kubectl)
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

# Installer plugins
kubectl krew install ctx ns slice klock
```

### Installation yq

```bash
# Linux
curl -L https://github.com/mikefarah/yq/releases/download/v4.44.6/yq_linux_amd64 -o yq
chmod +x yq
sudo mv yq /usr/local/bin/yq

# macOS (Homebrew)
brew install yq
```

### Augmenter les limites système (IMPORTANT!)

```bash
# Linux - Configuration optimale pour le workshop
echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.conf
echo "fs.inotify.max_user_instances=512" | sudo tee -a /etc/sysctl.conf
echo "fs.file-max=2097152" | sudo tee -a /etc/sysctl.conf
echo "kernel.pid_max=4194304" | sudo tee -a /etc/sysctl.conf
echo "net.core.somaxconn=32768" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Limites utilisateur
cat << EOF | sudo tee -a /etc/security/limits.conf
*    soft    nofile    1048576
*    hard    nofile    1048576
*    soft    nproc     unlimited
*    hard    nproc     unlimited
EOF

# Docker systemd limits
sudo mkdir -p /etc/systemd/system/docker.service.d
cat << EOF | sudo tee /etc/systemd/system/docker.service.d/limits.conf
[Service]
LimitNOFILE=1048576
LimitNPROC=infinity
TasksMax=infinity
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker

# macOS - Configuration limites
sudo launchctl limit maxfiles 1048576 1048576
```

### Validation

```bash
# Aller dans le module
cd 00-introduction

# Validation automatique
./verification.sh
```

---

## Résultats Attendus

| Outil | Résultat OK |
|-------|-------------|
| `docker --version` | Version >= 20.10.0 |
| `kind --version` | Version >= 0.30.0 |
| `kubectl version --client` | Version >= v1.32.0 |
| `kubectl ctx --help` | Affiche l'aide |
| `kubectl ns --help` | Affiche l'aide |
| `kubectl slice --help` | Affiche l'aide |
| `kubectl klock --help` | Affiche l'aide |
| `clusterctl version` | Version >= v1.11.1 |
| `helm version` | Version >= v3.19.0 |
| `jq --version` | Version >= 1.6 |
| `yq --version` | Version >= 4.44.6 |
| `tree --version` | Version >= 1.8.0 |
| `./verification.sh` | Tous les ✅ |

---

## 🚀 Prochaine Étape

```bash
cd ../00-setup-management
cat commands.md
```

Pour les explications détaillées d'installation, voir [commands.md](commands.md)