# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **2-hour hands-on workshop** teaching ClusterAPI and k0smotron for Kubernetes cluster lifecycle management. The workshop is designed for 15-50 participants with intermediate Kubernetes knowledge, using a "See → Do → Understand" pedagogical approach.

### Workshop Structure

The workshop consists of 8 progressive modules (00-07), each with:
- `commands.md` - Step-by-step participant instructions with theory
- `validation.sh` - Automated validation script for checkpoints
- YAML manifests for cluster definitions and resources
- Additional helper scripts where needed

**Total Duration:** 120 minutes (105 min content + 15 min buffers)

## Key Concepts

### Architecture Pattern: Management + Workload Clusters

- **Management Cluster** (kind): Hosts ClusterAPI controllers, creates/manages workload clusters
- **Workload Clusters**: Application clusters created declaratively via YAML manifests
  - `dev-cluster`: Docker Provider (CAPD) - 1 control plane + 2-4 workers
  - `k0s-demo-cluster`: k0smotron provider - 3 control plane pods + 2 workers
  - `multi-01`, `multi-02`, `multi-03`: Multi-cluster deployment via Helm chart

### ClusterAPI Stack

1. **ClusterAPI v1.11.1** - Core controllers for declarative cluster management
2. **Docker Provider (CAPD)** - Local development infrastructure provider
3. **k0smotron v1.7.0** - Virtual control planes (55% resource savings)
4. **Helm Addon Provider v0.3.2** - Multi-cluster application deployment via HelmChartProxy
5. **ClusterResourceSets** - Automatic addon deployment (e.g., Calico CNI)

## Module Progression

```
00-introduction (10min)              → Tool installation verification
00-setup-management (15min)          → Create kind management cluster + install ClusterAPI
01-premier-cluster (15min)           → Create first Docker provider cluster
02-networking-calico (15min)         → Install Calico CNI via ClusterResourceSets
03-k0smotron (15min)                 → Create k0smotron cluster, compare resources
04-multi-cluster-deployment (15min)  → Deploy 3 clusters simultaneously via Helm [NEW]
05-automation-helm (20min)           → Deploy nginx multi-cluster with HelmChartProxy
06-cluster-upgrades (15min)          → Upgrade multiple clusters simultaneously [NEW]
07-operations-cleanup (15min)        → Scale workers, monitor, cleanup
```

## Common Commands

### Workshop Navigation
```bash
# Navigate modules
cd 00-introduction/ && ./verification.sh
cd ../00-setup-management/ && cat commands.md
cd ../01-premier-cluster/ && cat commands.md

# Run module validation
./validation.sh  # In each module directory
```

### Cluster Management
```bash
# Create cluster (declarative)
kubectl apply -f dev-cluster.yaml

# Monitor creation
watch -n 2 'kubectl get clusters,machines'

# Get workload cluster kubeconfig
clusterctl get kubeconfig <cluster-name> > <cluster-name>.kubeconfig

# Access workload cluster
kubectl --kubeconfig <cluster>.kubeconfig get nodes
```

### ClusterResourceSets (Automatic Addons)
```bash
# Create CRS with ConfigMap
kubectl apply -f calico-crs.yaml

# Trigger on cluster via label
kubectl label cluster <cluster-name> cni=calico

# Verify application
kubectl get clusterresourceset
```

### Multi-Cluster Helm Deployment
```bash
# Deploy to multiple clusters via labels
kubectl apply -f nginx-helmchartproxy.yaml

# Monitor deployments
kubectl get helmchartproxy
kubectl get helmreleaseproxy -A
```

### Scaling Operations
```bash
# Scale workers declaratively
kubectl scale machinedeployment <name> --replicas=4

# Monitor scaling
watch -n 2 'kubectl get machines'
```

## File Organization

```
workshop-express/
├── README.md              # Participant guide (architecture, concepts, commands)
├── FORMATEUR.md           # Instructor minute-by-minute guide with troubleshooting
├── SETUP.md              # Infrastructure setup (3 options: local/cloud/pre-provisioned)
├── GLOSSARY.md           # Technical terms dictionary
├── CHEATSHEET.md         # Quick command reference
├── scripts/
│   └── setup-infrastructure.sh  # Automated infrastructure setup
├── 00-introduction/
│   ├── commands.md       # Theory + tool installation steps
│   ├── verification.sh   # Tool verification
│   └── QUICKSTART.md     # Quick reference
├── 00-setup-management/
│   ├── commands.md       # Management cluster setup walkthrough
│   ├── validation.sh     # Management cluster validation
│   └── QUICKSTART.md     # Quick setup reference
├── 01-premier-cluster/
│   ├── commands.md       # Cluster creation walkthrough
│   ├── dev-cluster.yaml  # Docker provider cluster manifest
│   └── validation.sh     # Cluster validation
├── 02-networking-calico/
│   ├── commands.md       # CNI installation walkthrough
│   ├── calico-crs.yaml   # ClusterResourceSet + ConfigMap (7552 lines)
│   └── validation.sh     # CNI validation
├── 03-k0smotron/
│   ├── commands.md       # k0smotron walkthrough
│   ├── k0s-demo-cluster.yaml     # k0smotron cluster manifest
│   ├── compare-providers.sh      # Resource comparison script
│   └── validation.sh             # k0smotron validation
├── 04-multi-cluster-deployment/
│   ├── commands.md       # Multi-cluster deployment walkthrough
│   ├── multi-cluster-chart/      # Helm chart for 3 clusters
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/            # ClusterAPI templates
│   ├── compare-timing.sh         # Parallel vs sequential comparison
│   └── validation.sh             # Multi-cluster validation
├── 05-automation-helm/
│   ├── commands.md       # Helm automation walkthrough
│   ├── nginx-helmchartproxy.yaml # Multi-cluster deployment
│   └── validation.sh     # Helm deployment validation
├── 06-cluster-upgrades/
│   ├── commands.md       # Cluster upgrades walkthrough
│   ├── upgrade-clusters.sh       # Automated upgrade script
│   ├── monitor-upgrades.sh       # Upgrade monitoring dashboard
│   └── validation.sh             # Upgrade validation
└── 07-operations-cleanup/
    ├── commands.md       # Operations + cleanup walkthrough
    ├── scale-workers.sh  # Automated scaling
    ├── monitor-resources.sh  # Resource monitoring dashboard
    ├── cleanup.sh        # Complete cleanup automation
    └── validation.sh     # Final validation
```

## Development Workflow

### Adding New Modules
Each module must include:
1. `commands.md` with See→Do→Understand structure
2. `validation.sh` executable script with comprehensive checks
3. YAML manifests if creating resources
4. Estimated timing matching workshop schedule

### Script Conventions
- All scripts use `#!/bin/bash` with `set -e` for fail-fast
- Validation scripts output ✅/❌ with clear error messages
- Scripts are idempotent where possible
- Include descriptive echo statements for user feedback

### Testing Modules
```bash
# Full workshop dry-run (105 minutes)
cd 00-introduction && ./verification.sh
cd ../01-premier-cluster && kubectl apply -f dev-cluster.yaml && ./validation.sh
cd ../02-networking-calico && kubectl apply -f calico-crs.yaml && kubectl label cluster dev-cluster cni=calico && ./validation.sh
cd ../03-k0smotron && kubectl apply -f k0s-demo-cluster.yaml && kubectl label cluster k0s-demo-cluster cni=calico && ./validation.sh
cd ../04-multi-cluster-deployment && helm install multi-clusters multi-cluster-chart/ && ./validation.sh
cd ../05-automation-helm && kubectl apply -f nginx-helmchartproxy.yaml && ./validation.sh
cd ../06-cluster-upgrades && ./upgrade-clusters.sh && ./validation.sh
cd ../07-operations-cleanup && ./cleanup.sh && ./validation.sh
```

## Troubleshooting

### Common Issues

**Nodes NotReady:**
```bash
# Check CNI installation
kubectl --kubeconfig <cluster>.kubeconfig get pods -n kube-system | grep calico
# Add label if missing
kubectl label cluster <cluster-name> cni=calico
```

**Cluster creation stuck:**
```bash
# Check ClusterAPI logs
kubectl logs -n capi-system deployment/capi-controller-manager -f
# Check machine status
kubectl describe machine <machine-name>
# Verify Docker resources
docker ps && docker stats --no-stream
```

**HelmChartProxy not deploying:**
```bash
# Check HelmReleaseProxy objects
kubectl get helmreleaseproxy -A
# Check Helm provider logs
kubectl logs -n capi-addon-system deployment/capi-addon-helm-controller-manager -f
# Verify cluster labels match selector
kubectl get clusters --show-labels
```

## Key Files to Understand

1. **FORMATEUR.md** - Complete instructor guide with minute-by-minute timing, troubleshooting, and emergency procedures
2. **SETUP.md** - Three infrastructure setup options (local kind, cloud EKS/AKS/GKE, pre-provisioned)
3. **Module commands.md files** - Step-by-step participant instructions with theory integration
4. **Validation scripts** - Automated checkpoint verification for each module

## Important Notes

- Workshop timing is critical: respect 90-minute total (10+15+15+15+20+15)
- Each module has buffers built-in (typically 2 minutes per module)
- 80% rule: Continue when 80% of participants pass validation (don't wait for 100%)
- ClusterAPI reconciliation loops take ~10-30 seconds to reflect changes
- Docker provider nodes are actually containers (docker ps shows them)
- k0smotron control planes run as pods in management cluster, not nodes
- Calico CRS is 7552 lines because it embeds full Calico manifests
- **CRITICAL:** System limits MUST be configured before workshop (see 00-introduction/configure-system-limits.sh)
  - fs.inotify.max_user_watches: 524288 (prevents "watch limit exceeded")
  - fs.file-max: 2097152 (prevents "too many open files")
  - ulimit -n: 1048576 (file descriptors)
  - Docker systemd limits: LimitNOFILE=1048576
  - Requires logout/login or reboot to take effect

## Version Information

- ClusterAPI: v1.11.1
- k0smotron: v1.7.0
- Kubernetes: v1.32.8
- Calico CNI: v3.30.3
- Helm Addon Provider: v0.3.2
- cert-manager: v1.18.2
- kind: v0.30.0
- Helm: v3.19.0
- tree: v1.8.0

## External Resources

- [ClusterAPI Documentation](https://cluster-api.sigs.k8s.io/)
- [k0smotron Documentation](https://docs.k0smotron.io/)
- [Calico Documentation](https://docs.tigera.io/calico/latest/)
- Full 11-hour workshop available in parent repository modules/
