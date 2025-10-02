# Setup Infrastructure - Workshop ClusterAPI Express

## Vue d'ensemble

Ce guide détaille l'installation et la configuration de l'infrastructure nécessaire pour le **Workshop ClusterAPI Express**. Trois options sont disponibles selon votre contexte d'utilisation.

### Infrastructure Requirements Summary

| Composant | Version | Rôle |
|-----------|---------|------|
| **Docker** | 24.0+ | Runtime pour nodes Kubernetes (kind containers) |
| **kubectl** | 1.32.8+ | Interface avec clusters Kubernetes |
| **kind** | 0.30+ | Création management cluster local |
| **clusterctl** | 1.11+ | CLI ClusterAPI pour lifecycle clusters |
| **helm** | 3.19+ | Package manager pour Helm Addon Provider |
| **tree** | 1.8+ | Visualisation arborescente de répertoires |

### Setup Options Overview

| Option | Contexte | Durée Setup | Recommandé Pour |
|--------|----------|-------------|-----------------|
| **Option 1** | Local Development | 20 minutes | Tests, développement individuel |
| **Option 2** | Cloud Production | 45 minutes | Workshops 20+ participants |
| **Option 3** | Pre-provisioned | 5 minutes | Conférences, formations |

---

## Option 1: Local Setup (Dev/Test)

**Contexte:** Développement individual, tests, formation personnelle
**Durée:** 20 minutes
**Resources:** 8GB RAM, 4 CPU cores, 30GB disk

### System Limits Configuration (CRITICAL)

**⚠️ IMPORTANT:** Avant d'installer les outils, configurez les limites système pour éviter les erreurs.

#### Automated Configuration (Recommended)

```bash
cd workshop-express/00-introduction
./configure-system-limits.sh
```

#### Manual Configuration

**Linux:**
```bash
# Kernel limits
echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.conf
echo "fs.inotify.max_user_instances=512" | sudo tee -a /etc/sysctl.conf
echo "fs.file-max=2097152" | sudo tee -a /etc/sysctl.conf
echo "kernel.pid_max=4194304" | sudo tee -a /etc/sysctl.conf
echo "kernel.threads-max=4194304" | sudo tee -a /etc/sysctl.conf
echo "net.core.somaxconn=32768" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# User limits
cat << EOF | sudo tee -a /etc/security/limits.conf
*    soft    nofile     1048576
*    hard    nofile     1048576
*    soft    nproc      unlimited
*    hard    nproc      unlimited
*    soft    memlock    unlimited
*    hard    memlock    unlimited
EOF

# Docker systemd limits
sudo mkdir -p /etc/systemd/system/docker.service.d
cat << EOF | sudo tee /etc/systemd/system/docker.service.d/limits.conf
[Service]
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
EOF
```

**macOS:**
```bash
# Session limits
sudo launchctl limit maxfiles 1048576 1048576

# Permanent configuration
cat << 'EOF' | sudo tee /Library/LaunchDaemons/limit.maxfiles.plist
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
  </dict>
</plist>
EOF
sudo launchctl load -w /Library/LaunchDaemons/limit.maxfiles.plist
```

**Verification:**
```bash
# Linux
ulimit -n          # Should show: 1048576
sudo sysctl fs.inotify.max_user_watches  # Should show: 524288

# macOS
launchctl limit maxfiles  # Should show: 1048576
```

**⚠️ REBOOT or LOGOUT/LOGIN required for limits to take effect!**

---

### Prerequisites Installation

#### 1. Docker Desktop Installation

**Linux (Ubuntu/Debian):**
```bash
# Update package index
sudo apt-get update

# Install dependencies
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Setup repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker
sudo systemctl enable docker
sudo systemctl start docker

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Verify installation
docker run hello-world
```

**macOS:**
```bash
# Install using Homebrew
brew install --cask docker

# Or download from https://www.docker.com/products/docker-desktop/
# Launch Docker Desktop and wait for initialization
```

**Windows:**
```powershell
# Download Docker Desktop from https://www.docker.com/products/docker-desktop/
# Install and restart
# Enable WSL2 if prompted
```

**Verification:**
```bash
docker --version
# Output: Docker version 24.0.x, build xxxxx

docker info
# Should show: Server version, no errors
```

#### 2. kubectl Installation

**Linux:**
```bash
# Download latest stable version
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Validate binary (optional)
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check

# Install kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verify
kubectl version --client
```

**macOS:**
```bash
# Using Homebrew (recommended)
brew install kubectl

# Or download directly
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
```

**Windows:**
```powershell
# Using Chocolatey
choco install kubernetes-cli

# Or using winget
winget install Kubernetes.kubectl

# Or manual download from https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
```

#### 3. kind Installation

**Linux:**
```bash
# Download latest version
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.30.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Verify
kind version
```

**macOS:**
```bash
# Using Homebrew
brew install kind

# Or manual download
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.30.0/kind-darwin-amd64
[ $(uname -m) = arm64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.30.0/kind-darwin-arm64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

**Windows:**
```powershell
# Using Chocolatey
choco install kind

# Or download manually
curl.exe -Lo kind-windows-amd64.exe https://kind.sigs.k8s.io/dl/v0.30.0/kind-windows-amd64
Move-Item .\kind-windows-amd64.exe c:\some-dir-in-your-PATH\kind.exe
```

#### 4. clusterctl Installation

**Linux:**
```bash
curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v1.10.6/clusterctl-linux-amd64 -o clusterctl
chmod +x ./clusterctl
sudo mv ./clusterctl /usr/local/bin/clusterctl

# Verify
clusterctl version
```

**macOS:**
```bash
# Intel Mac
curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v1.10.6/clusterctl-darwin-amd64 -o clusterctl
# Apple Silicon Mac
curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v1.10.6/clusterctl-darwin-arm64 -o clusterctl

chmod +x ./clusterctl
sudo mv ./clusterctl /usr/local/bin/clusterctl
```

**Windows:**
```powershell
curl.exe -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v1.10.6/clusterctl-windows-amd64.exe -o clusterctl.exe
# Move to PATH directory
```

#### 5. helm Installation

**Linux:**
```bash
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

# Verify
helm version
```

**macOS:**
```bash
# Using Homebrew
brew install helm

# Verify
helm version
```

**Windows:**
```powershell
# Using Chocolatey
choco install kubernetes-helm

# Using winget
winget install Helm.Helm
```

### Step-by-Step Infrastructure Setup

#### 1. Create Management Cluster

```bash
# Create cluster configuration
cat > management-cluster-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: capi-management
nodes:
  - role: control-plane
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

# Create the cluster
kind create cluster --config management-cluster-config.yaml

# Verify cluster is ready
kubectl cluster-info --context kind-capi-management
```

**Expected Output:**
```
Creating cluster "capi-management" ...
 ✓ Ensuring node image (kindest/node:v1.32.9) 🖼
 ✓ Preparing nodes 📦
 ✓ Writing configuration 📜
 ✓ Starting control-plane 🕹️
 ✓ Installing CNI 🔌
 ✓ Installing StorageClass 💾
Set kubectl context to "kind-capi-management"

Kubernetes control plane is running at https://127.0.0.1:xxxxx
CoreDNS is running at https://127.0.0.1:xxxxx/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

#### 2. Initialize ClusterAPI

```bash
# Initialize ClusterAPI with Docker provider
clusterctl init --infrastructure docker

# Wait for controllers to be ready
kubectl wait --for=condition=Available --timeout=300s \
  deployment/capi-controller-manager -n capi-system

kubectl wait --for=condition=Available --timeout=300s \
  deployment/capd-controller-manager -n capd-system

# Verify installation
kubectl get pods -A | grep -E "(capi|capd)"
```

**Expected Output:**
```
Fetching providers
Installing cert-manager Version="v1.18.2"
Waiting for cert-manager to be available...
Installing Provider="cluster-api" Version="v1.10.6" TargetNamespace="capi-system"
Installing Provider="bootstrap-kubeadm" Version="v1.10.6" TargetNamespace="capi-kubeadm-bootstrap-system"
Installing Provider="control-plane-kubeadm" Version="v1.10.6" TargetNamespace="capi-kubeadm-control-plane-system"
Installing Provider="infrastructure-docker" Version="v1.10.6" TargetNamespace="capd-system"

Your management cluster has been initialized successfully!
```

#### 3. Install k0smotron Operator

```bash
# Install k0smotron v1.7.0
kubectl apply -f https://github.com/k0sproject/k0smotron/releases/download/v1.7.0/install.yaml

# Wait for operator to be ready
kubectl wait --for=condition=Available --timeout=300s \
  deployment/k0smotron-controller-manager -n k0smotron

# Verify installation
kubectl get pods -n k0smotron
```

**Expected Output:**
```
namespace/k0smotron created
customresourcedefinition.apiextensions.k8s.io/clusters.k0smotron.io created
customresourcedefinition.apiextensions.k8s.io/jointoken.k0smotron.io created
...
deployment.apps/k0smotron-controller-manager created

NAME                                        READY   STATUS    RESTARTS   AGE
k0smotron-controller-manager-xxxxx-xxxxx    2/2     Running   0          30s
```

#### 4. Install Helm Addon Provider

```bash
# Add helm repository
helm repo add capi-addon-provider https://kubernetes-sigs.github.io/cluster-api-addon-provider-helm
helm repo update

# Install Helm Addon Provider
helm install capi-addon-provider capi-addon-provider/cluster-api-addon-provider-helm \
  --namespace caaph-system \
  --create-namespace \
  --wait \
  --timeout 300s

# Verify installation
kubectl get pods -n caaph-system
```

**Expected Output:**
```
NAME                                               READY   STATUS    RESTARTS   AGE
capi-addon-helm-controller-manager-xxxxx-xxxxx    2/2     Running   0          45s
```

#### 5. Complete Verification

```bash
# Navigate to workshop directory
cd workshop-express/00-introduction

# Run verification script
./verification.sh
```

**Expected Output:**
```
🔍 Module 00: Vérification Environnement
======================================

✅ kubectl accessible
✅ Management cluster accessible
✅ ClusterAPI installé (v1.10.6)
✅ Docker provider ready
✅ k0smotron operator running (v1.7.0)
✅ Helm provider ready

======================================
🎉 Environnement prêt pour le workshop!
======================================

Prochaine commande:
  cd ../01-premier-cluster
  cat commands.md
```

### Resource Requirements Validation

```bash
# Check available resources
echo "=== System Resources ==="
echo "CPU cores: $(nproc)"
echo "Memory: $(free -h | grep '^Mem:' | awk '{print $2}')"
echo "Disk space: $(df -h / | tail -1 | awk '{print $4}') available"

echo "=== Docker Resources ==="
docker system df

echo "=== kind clusters ==="
kind get clusters
```

**Minimum Requirements Check:**
- CPU: 4+ cores
- Memory: 8GB+ total
- Disk: 30GB+ available
- Docker: Running without errors

---

## Option 2: Cloud Setup (Production Workshop)

**Contexte:** Workshops avec 20+ participants, formations entreprise
**Durée:** 45 minutes setup
**Avantages:** Stabilité, isolation, performance, scalabilité

### Why Cloud for Large Workshops

**Challenges with Local Setup at Scale:**
- Network limitations (image pulls × N participants)
- Hardware heterogeneity (different OSs, versions)
- Support complexity (troubleshooting × N environments)
- Resource constraints (laptop limitations)

**Cloud Benefits:**
- Consistent environment for all participants
- Reliable network and resources
- Centralized monitoring and support
- Professional workshop experience

### Infrastructure Options

#### Option 2A: Amazon EKS

**Prerequisites:**
- AWS Account with appropriate permissions
- aws-cli configured
- eksctl installed
- Terraform (optional, for IaC)

**Step 1: Create EKS Cluster**
```bash
# Using eksctl (simple)
eksctl create cluster \
  --name capi-workshop-mgmt \
  --version 1.28 \
  --region us-west-2 \
  --nodegroup-name standard-workers \
  --node-type m5.large \
  --nodes 3 \
  --nodes-min 1 \
  --nodes-max 4 \
  --managed

# Verify cluster access
kubectl get nodes
```

**Step 2: Install ClusterAPI**
```bash
# Install cluster-api controllers
clusterctl init --infrastructure aws

# Install k0smotron
kubectl apply -f https://github.com/k0sproject/k0smotron/releases/download/v1.7.0/install.yaml

# Install Helm provider
helm repo add capi-addon-provider https://kubernetes-sigs.github.io/cluster-api-addon-provider-helm
helm install capi-addon-provider capi-addon-provider/cluster-api-addon-provider-helm \
  --namespace caaph-system --create-namespace --wait
```

**Step 3: Participant Isolation**
```bash
# Create namespaces for participants
for i in {1..30}; do
  kubectl create namespace workshop-participant-$i
  kubectl create rolebinding participant-$i \
    --clusterrole=edit \
    --user=participant-$i \
    --namespace=workshop-participant-$i
done
```

#### Option 2B: Azure AKS

**Prerequisites:**
- Azure subscription
- az-cli installed and configured
- Terraform (optional)

**Step 1: Create AKS Cluster**
```bash
# Create resource group
az group create --name capi-workshop-rg --location westus2

# Create AKS cluster
az aks create \
  --resource-group capi-workshop-rg \
  --name capi-workshop-mgmt \
  --node-count 3 \
  --node-vm-size Standard_D2s_v3 \
  --enable-addons monitoring \
  --kubernetes-version 1.28.3

# Get credentials
az aks get-credentials --resource-group capi-workshop-rg --name capi-workshop-mgmt
```

**Step 2: Install ClusterAPI**
```bash
# Install with Azure provider
clusterctl init --infrastructure azure

# Continue with k0smotron and Helm provider as above
```

#### Option 2C: Google GKE

**Prerequisites:**
- Google Cloud account
- gcloud-cli configured
- Project with GKE API enabled

**Step 1: Create GKE Cluster**
```bash
# Set project and zone
gcloud config set project YOUR-PROJECT-ID
gcloud config set compute/zone us-central1-a

# Create cluster
gcloud container clusters create capi-workshop-mgmt \
  --num-nodes=3 \
  --machine-type=e2-standard-2 \
  --kubernetes-version=1.28

# Get credentials
gcloud container clusters get-credentials capi-workshop-mgmt
```

### Multi-Participant Isolation Strategies

#### Strategy 1: Namespace Isolation (Recommended)

```bash
# Create participant namespaces with resource quotas
for i in {1..50}; do
  # Create namespace
  kubectl create namespace participant-$i

  # Apply resource quota
  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: participant-quota
  namespace: participant-$i
spec:
  hard:
    requests.cpu: "2"
    requests.memory: 4Gi
    limits.cpu: "4"
    limits.memory: 8Gi
    persistentvolumeclaims: "0"
    services: "5"
    secrets: "10"
    configmaps: "10"
EOF

  # Create role binding
  kubectl create rolebinding participant-$i-admin \
    --clusterrole=admin \
    --user=participant-$i \
    --namespace=participant-$i
done
```

#### Strategy 2: Service Account Based Access

```bash
# Create service accounts with limited permissions
for i in {1..50}; do
  kubectl create serviceaccount participant-$i -n participant-$i

  # Create kubeconfig for service account
  SECRET_NAME=$(kubectl get serviceaccount participant-$i -n participant-$i -o jsonpath='{.secrets[0].name}')
  TOKEN=$(kubectl get secret $SECRET_NAME -n participant-$i -o jsonpath='{.data.token}' | base64 --decode)

  # Generate kubeconfig
  kubectl config set-cluster workshop-cluster \
    --server=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}') \
    --certificate-authority-data=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[0].cluster.certificate-authority-data}') \
    --kubeconfig=participant-$i.kubeconfig

  kubectl config set-credentials participant-$i \
    --token=$TOKEN \
    --kubeconfig=participant-$i.kubeconfig

  kubectl config set-context participant-$i \
    --cluster=workshop-cluster \
    --user=participant-$i \
    --namespace=participant-$i \
    --kubeconfig=participant-$i.kubeconfig

  kubectl config use-context participant-$i --kubeconfig=participant-$i.kubeconfig
done
```

### Cost Estimation

**AWS EKS (30 participants, 4 hours workshop):**
- EKS cluster: $0.10/hour × 4h = $0.40
- EC2 instances (3 × m5.large): $0.096/hour × 3 × 4h = $1.15
- **Total: ~$1.55 + data transfer**

**Azure AKS (30 participants, 4 hours workshop):**
- AKS cluster: Free (managed service)
- VM instances (3 × Standard_D2s_v3): $0.096/hour × 3 × 4h = $1.15
- **Total: ~$1.15 + storage/network**

**GKE (30 participants, 4 hours workshop):**
- GKE cluster: $0.10/hour × 4h = $0.40
- Compute instances (3 × e2-standard-2): $0.067/hour × 3 × 4h = $0.80
- **Total: ~$1.20 + network**

---

## Option 3: Pre-provisioned Environment (Recommended for Conferences)

**Contexte:** Conférences, formations en salle, événements
**Durée:** 5 minutes par participant
**Avantages:** Expérience fluide, support minimal, timing prévisible

### Infrastructure Pre-Setup

**Management Cluster:**
- Kubernetes cluster déjà configuré
- ClusterAPI pré-installé et testé
- k0smotron operator opérationnel
- Helm Addon Provider configuré
- Namespaces participants pré-créés

**Participant Onboarding:**
1. Distribution de kubeconfig individuels
2. Accès à namespace dédié
3. Validation environnement immédiate
4. Workshop prêt à démarrer

### Kubeconfig Distribution Methods

#### Method 1: Email Distribution (Pre-Workshop)

```bash
# Generate participant kubeconfigs
./scripts/generate-participant-configs.sh

# Email template
for i in {1..30}; do
  echo "Participant $i kubeconfig:" > participant-$i-email.txt
  echo "Save as ~/.kube/config or use --kubeconfig flag" >> participant-$i-email.txt
  echo "" >> participant-$i-email.txt
  cat participant-$i.kubeconfig >> participant-$i-email.txt
done
```

#### Method 2: QR Code Distribution (On-Site)

```bash
# Install qrencode
sudo apt-get install qrencode

# Generate QR codes for kubeconfig URLs
for i in {1..30}; do
  # Upload kubeconfig to secure temporary storage
  CONFIG_URL="https://workshop-configs.example.com/participant-$i.kubeconfig"
  qrencode -t PNG -o participant-$i-qr.png "$CONFIG_URL"
done
```

#### Method 3: Shared Storage Access

```bash
# Setup shared directory
mkdir -p /shared/workshop-configs

# Generate configs in shared location
for i in {1..30}; do
  cp participant-$i.kubeconfig /shared/workshop-configs/
done

# Participant instructions
echo "Download your kubeconfig:"
echo "http://workshop-server.local/configs/participant-N.kubeconfig"
```

### Verification Script for Pre-provisioned

```bash
#!/bin/bash
# verify-preprovisioned.sh

echo "🔍 Vérification Environnement Pre-provisionné"
echo "============================================="

# Check kubeconfig access
if kubectl get nodes &>/dev/null; then
    echo "✅ Kubernetes cluster accessible"
else
    echo "❌ Cannot access Kubernetes cluster"
    echo "   Vérifiez votre kubeconfig"
    exit 1
fi

# Check namespace access
NAMESPACE=$(kubectl config view --minify -o jsonpath='{..namespace}')
if [ -z "$NAMESPACE" ]; then
    echo "❌ Namespace not configured in kubeconfig"
    exit 1
else
    echo "✅ Namespace: $NAMESPACE"
fi

# Check ClusterAPI access
if kubectl get clusters -n $NAMESPACE &>/dev/null; then
    echo "✅ ClusterAPI accessible"
else
    echo "❌ ClusterAPI not accessible"
    exit 1
fi

# Check permissions
if kubectl auth can-i create clusters -n $NAMESPACE &>/dev/null; then
    echo "✅ Permissions suffisantes"
else
    echo "❌ Permissions insuffisantes"
    exit 1
fi

echo "============================================="
echo "🎉 Environnement prêt! Démarrez le workshop:"
echo "  cd workshop-express/01-premier-cluster"
echo "  cat commands.md"
```

---

## Troubleshooting Setup

### Common Issues and Solutions

#### Docker Installation Issues

**Issue: Docker daemon not starting**
```bash
# Linux: Check service status
sudo systemctl status docker
sudo systemctl start docker

# Check logs
sudo journalctl -fu docker.service

# Common fix: Clean restart
sudo systemctl stop docker
sudo rm -rf /var/lib/docker/tmp/*
sudo systemctl start docker
```

**Issue: Permission denied (Docker Desktop)**
```bash
# Linux: Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Test access
docker run hello-world
```

#### kind Cluster Creation Fails

**Issue: Port conflicts**
```bash
# Check port usage
sudo netstat -tulpn | grep :30080

# Kill conflicting processes
sudo fuser -k 30080/tcp

# Or use different port
kind create cluster --config <(sed 's/30080/30081/g' management-cluster-config.yaml)
```

**Issue: Network issues**
```bash
# Reset kind cluster
kind delete cluster --name capi-management
docker system prune -f

# Recreate with fresh config
kind create cluster --config management-cluster-config.yaml
```

#### ClusterAPI Initialization Fails

**Issue: Network timeouts**
```bash
# Check internet connectivity
curl -I https://github.com/kubernetes-sigs/cluster-api/releases

# Use specific version if latest fails
clusterctl init --infrastructure docker --core cluster-api:v1.10.6

# Check controller logs
kubectl logs -n capi-system deployment/capi-controller-manager
```

**Issue: Missing prerequisites**
```bash
# Verify cert-manager
kubectl get pods -n cert-manager

# Manual cert-manager install if needed
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.18.2/cert-manager.yaml
```

#### k0smotron Operator Issues

**Issue: CrashLoopBackOff**
```bash
# Check logs
kubectl logs -n k0smotron deployment/k0smotron-controller-manager

# Common issue: insufficient resources
kubectl describe nodes

# Fix: Increase Docker memory limit or use smaller setup
```

**Issue: Webhook not ready**
```bash
# Wait longer for webhook
kubectl wait --for=condition=Available --timeout=600s \
  deployment/k0smotron-controller-manager -n k0smotron

# Check webhook endpoint
kubectl get validatingwebhookconfigurations
```

#### Helm Provider Installation Issues

**Issue: Helm repo not accessible**
```bash
# Update repo manually
helm repo add capi-addon-provider https://kubernetes-sigs.github.io/cluster-api-addon-provider-helm
helm repo update

# Check repo status
helm repo list
```

**Issue: Timeout during installation**
```bash
# Increase timeout
helm install capi-addon-provider capi-addon-provider/cluster-api-addon-provider-helm \
  --namespace caaph-system \
  --create-namespace \
  --wait \
  --timeout 600s

# Check pod status
kubectl get pods -n caaph-system
kubectl describe pod -n caaph-system <pod-name>
```

### Performance Tuning

#### Docker Configuration

```bash
# Increase Docker resources (Docker Desktop)
# Settings → Resources → Advanced:
# - CPUs: 4+
# - Memory: 8GB+
# - Disk: 50GB+

# Linux: Edit daemon.json
sudo tee /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

sudo systemctl restart docker
```

#### Kubernetes Resource Optimization

```bash
# Increase kubelet resources in kind config
cat > optimized-management-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: capi-management
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 30080
        hostPort: 30080
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
            max-pods: "200"
            kube-reserved: "cpu=500m,memory=1Gi"
            system-reserved: "cpu=500m,memory=1Gi"
EOF
```

---

## Cleanup Instructions

### Complete Environment Cleanup

```bash
#!/bin/bash
# cleanup-infrastructure.sh

echo "🧹 Cleanup Infrastructure Workshop"
echo "=================================="

# Delete kind cluster
if kind get clusters | grep -q capi-management; then
    echo "Suppression cluster kind..."
    kind delete cluster --name capi-management
    echo "✅ Cluster kind supprimé"
fi

# Clean Docker system
echo "Nettoyage Docker..."
docker system prune -a -f
echo "✅ Docker nettoyé"

# Remove kubectl contexts
echo "Nettoyage contextes kubectl..."
kubectl config delete-context kind-capi-management 2>/dev/null || true
kubectl config delete-cluster kind-capi-management 2>/dev/null || true
kubectl config delete-user kind-capi-management 2>/dev/null || true
echo "✅ Contextes kubectl nettoyés"

# Clean temporary files
rm -f management-cluster-config.yaml
rm -f *.kubeconfig
echo "✅ Fichiers temporaires supprimés"

echo "=================================="
echo "🎉 Cleanup terminé!"
echo "=================================="
```

### Cloud Cleanup (if used)

**AWS EKS:**
```bash
# Delete EKS cluster
eksctl delete cluster --name capi-workshop-mgmt --region us-west-2

# Or using AWS CLI
aws eks delete-cluster --name capi-workshop-mgmt --region us-west-2
```

**Azure AKS:**
```bash
# Delete resource group (includes cluster)
az group delete --name capi-workshop-rg --yes --no-wait
```

**Google GKE:**
```bash
# Delete cluster
gcloud container clusters delete capi-workshop-mgmt --zone us-central1-a --quiet
```

---

## Resource Requirements Detail

### Minimum Requirements (Single User)

| Component | Requirement | Explanation |
|-----------|-------------|-------------|
| **CPU** | 4 cores | kind cluster + ClusterAPI controllers + workload clusters |
| **Memory** | 8GB | Management cluster (2GB) + Workload clusters (4GB) + OS (2GB) |
| **Disk** | 30GB | Docker images (10GB) + Containers (15GB) + OS (5GB) |
| **Network** | 10Mbps | Container image pulls, reasonably fast |

### Recommended Requirements (Workshop Instructor)

| Component | Requirement | Explanation |
|-----------|-------------|-------------|
| **CPU** | 8 cores | Smooth demo experience, multiple concurrent operations |
| **Memory** | 16GB | Multiple clusters, monitoring, recording setup |
| **Disk** | 50GB | Extra space for logs, recordings, backup clusters |
| **Network** | 50Mbps | Fast demo setup, reliable streaming if recorded |

### Cloud Requirements (30 Participants)

| Component | Requirement | Cost (4h workshop) |
|-----------|-------------|-------------------|
| **Management Cluster** | 3×Standard_D2s_v3 (Azure) | ~$1.15 |
| **Network** | Standard egress | ~$0.50 |
| **Storage** | 100GB persistent | ~$0.40 |
| **Total** | Per workshop | **~$2.05** |

---

## Security Considerations

### Local Setup Security

```bash
# Secure Docker daemon (if needed)
sudo usermod -aG docker $USER
# Note: This gives Docker root access - only for development

# Secure kubeconfig
chmod 600 ~/.kube/config

# Regular cleanup of containers and images
docker system prune -a --volumes
```

### Cloud Setup Security

```bash
# Use IAM roles with minimal permissions
# Example for AWS:
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "eks:DescribeCluster",
        "eks:ListClusters"
      ],
      "Resource": "arn:aws:eks:region:account:cluster/capi-workshop-mgmt"
    }
  ]
}

# Network security
# - Private subnets for worker nodes
# - Security groups limiting access
# - VPC endpoints for AWS services
```

### Workshop Participant Isolation

```bash
# Network policies for namespace isolation
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: participant-1
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  egress:
  - to: []
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
```

---

## Monitoring and Observability

### Basic Monitoring Setup

```bash
# Install metrics-server (if not present)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Basic monitoring commands
kubectl top nodes
kubectl top pods -A

# Watch cluster resources
watch 'kubectl get clusters,machines,kubeadmcontrolplane,machinedeployment'
```

### Workshop Dashboard

```bash
# Simple dashboard script
#!/bin/bash
# workshop-dashboard.sh

while true; do
  clear
  echo "🎯 Workshop ClusterAPI Dashboard"
  echo "================================"
  echo "⏰ $(date)"
  echo ""

  echo "📊 Management Cluster:"
  kubectl get nodes -o wide
  echo ""

  echo "🏗️ Workload Clusters:"
  kubectl get clusters
  echo ""

  echo "🖥️ Machines:"
  kubectl get machines
  echo ""

  echo "🔧 Controllers:"
  kubectl get pods -A | grep -E "(capi|k0s|helm)" | grep -v Completed
  echo ""

  sleep 10
done
```

---

**Setup Guide complet! Ready for Workshop ClusterAPI Express! 🚀**

*Guide Setup v1.0 - Compatible avec ClusterAPI v1.10.6 | k0smotron v1.7.0 | Kubernetes v1.32.9 | Helm v3.19.0*