# Module 00-setup: QUICKSTART

**Durée:** 15 minutes | **Objectif:** Créer le cluster de management et installer ClusterAPI

---

## 🚀 Commandes Rapides

### 1. Vérifier les Outils
```bash
cd /home/volcampdev/workshop-express/00-setup-management
docker --version
kind --version
kubectl version --client
clusterctl version
helm version
```

### 2. Créer le Cluster kind
```bash
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
```

### 3. Initialiser ClusterAPI
```bash
export CLUSTER_TOPOLOGY=true
export EXP_CLUSTER_RESOURCE_SET=true
clusterctl init --infrastructure docker:v1.10.6
```

### 4. Vérifier Socket Docker
```bash
./verify-docker-socket.sh
```

### 5. Valider l'Installation
```bash
./validation.sh
```

---

## ✅ Résultat Attendu

```
🔍 Module 00-setup: Validation Cluster de Management
====================================================

✅ Cluster de management kind existe: capi-management
✅ Contexte kubectl correctement configuré
✅ ClusterAPI Core installé (capi-system)
✅ Docker Provider installé (capd-system)
✅ cert-manager opérationnel

====================================================
🎉 Module 00-setup terminé avec succès!
🚀 Management cluster prêt à créer des workload clusters
====================================================
```

---

## ⏭️ Prochaine Étape

```bash
cd ../01-premier-cluster
cat commands.md
```

---

## 🔧 Dépannage Express

### Cluster kind échoue
```bash
kind delete cluster --name capi-management
kind create cluster --config management-cluster-config.yaml
```

### clusterctl init timeout
```bash
# Vérifier internet
curl -I https://github.com

# Retry
export CLUSTER_TOPOLOGY=true
export EXP_CLUSTER_RESOURCE_SET=true
clusterctl init --infrastructure docker:v1.10.6 -v 5
```

### Pods pas Ready
```bash
# Vérifier l'état
kubectl get pods -A | grep -v Running

# Logs d'un pod problématique
kubectl logs -n <namespace> <pod-name>
```

---

**Temps total:** ~15 minutes | **Next:** Module 01 - Premier Cluster
