# Guide Formateur - Workshop ClusterAPI Express 90min

## Vue d'ensemble

**Workshop ClusterAPI Express** est un atelier **hands-on guidé** de 90 minutes qui enseigne l'orchestration de clusters Kubernetes avec ClusterAPI et k0smotron.

### Format du Workshop
- **Durée totale:** 90 minutes précises
- **Format:** Instructor-led + Hands-on immédiat
- **Pattern:** Voir (Demo) → Faire (Guided) → Comprendre (Explain)
- **Audience:** 15-50 participants, niveau Kubernetes intermédiaire
- **Style:** Démonstration projetée + reproduction immédiate + checkpoints

### Objectifs Pédagogiques
✅ Maîtriser les concepts ClusterAPI (Cluster, Machine, Provider)
✅ Créer des clusters déclarativement (YAML-based)
✅ Automatiser le déploiement CNI avec ClusterResourceSets
✅ Découvrir k0smotron et les control planes virtuels
✅ Déployer des applications multi-clusters avec Helm
✅ Appliquer les opérations de lifecycle (scale, monitor, cleanup)

---

## Préparation (J-1)

### 📋 Checklist Infrastructure

**Infrastructure Management Cluster:**
- [ ] Cluster kind opérationnel avec config ports (30080)
- [ ] ClusterAPI v1.11.1 installé et testé
- [ ] Docker Provider initialisé et fonctionnel
- [ ] k0smotron operator v1.7.0 déployé
- [ ] Helm Addon Provider v0.3.2 installé et testé
- [ ] Tous les pods en status Running
- [ ] Script `setup-infrastructure.sh` testé

**Test Runs Obligatoires:**
- [ ] Run complet des 6 modules (timing: 75 min + 15 min buffer)
- [ ] Tous les scripts `validation.sh` passent ✅
- [ ] Création cluster Docker: < 3 minutes
- [ ] Création cluster k0smotron: < 2 minutes
- [ ] Déploiement Calico CNI: < 1 minute
- [ ] HelmChartProxy nginx: < 2 minutes
- [ ] Cleanup complet: < 1 minute

**Environnement Technique:**
- [ ] Docker 24.0+ avec 8GB+ disponible
- [ ] Internet stable 100Mbps+ (pour pulls images)
- [ ] Ports 30080 libres pour load balancer
- [ ] kubectl, kind, clusterctl, helm, tree dans PATH
- [ ] `watch` command disponible
- [ ] Monitoring scripts testés
- [ ] ⚠️ **LIMITES SYSTÈME CONFIGURÉES** (fs.inotify, ulimit -n, Docker limits)
- [ ] Vérification: `ulimit -n` = 1048576, `sudo sysctl fs.inotify.max_user_watches` = 524288

### 🎤 Matériel de Présentation

**Equipment:**
- [ ] Écran/projecteur testé et calibré
- [ ] Terminal avec police >= 14pt (lisibilité fond de salle)
- [ ] Micro-casque ou micro-cravate testé
- [ ] Backup screen sharing (Teams/Zoom) configuré
- [ ] Pointeur laser/souris de présentation

**Display Setup:**
- [ ] Terminal: Font Consolas/Monaco 16pt, dark theme
- [ ] Deux écrans: Terminal + Slides/Browser
- [ ] Configuration `watch` avec refresh optimal (2sec)
- [ ] Raccourcis clavier testés (Ctrl+C, clear, history)

### 📧 Communication Participants (J-1)

**Email de Préparation:**
```
Objet: Workshop ClusterAPI Express - Préparation (Demain [DATE])

Bonjour,

Demain [HEURE], nous démarrons le Workshop ClusterAPI Express (90 min).

🔧 PRÉREQUIS TECHNIQUES:
- Ordinateur portable avec admin rights
- Docker Desktop installé et démarré
- kubectl, kind, clusterctl, helm, tree installés
- Terminal ou IDE avec bon terminal
- 8GB+ RAM libres, 30GB+ disk, Internet stable
- ⚠️ LIMITES SYSTÈME CONFIGURÉES (CRITIQUE!)

📋 VÉRIFICATION:
- Test Docker: `docker run hello-world`
- Test kubectl: `kubectl version --client`
- Test limites: `ulimit -n` (devrait afficher 1048576)

📥 RESSOURCES:
- Guide installation: [LIEN SETUP.md]
- Repository: [LIEN GITHUB]
- Slides: [LIEN SLIDES]

✋ PROBLÈME SETUP?
- Arrive 15min avant (09:45) pour assistance
- Sinon: [EMAIL/SLACK FORMATEUR]

À demain!
[FORMATEUR]
```

---

## Setup Jour J (30min avant)

### 🏃‍♂️ Early Arrival Protocol (H-30)

**Environnement:**
- [ ] Arriver 30min avant démarrage officiel
- [ ] Tester projecteur, écran, audio complet
- [ ] Vérifier WiFi stabilité (speed test)
- [ ] Configurer terminal presentation mode
- [ ] Tester partage d'écran backup
- [ ] Positionner matériel (pointeur, notes, timer)

**Infrastructure Live:**
- [ ] Relancer `setup-infrastructure.sh` pour fresh start
- [ ] Vérifier ALL validation scripts ✅
- [ ] Créer cluster test et détruire (warm-up)
- [ ] Tester tous les endpoints monitoring
- [ ] Nettoyer Docker: `docker system prune -f`
- [ ] Préparer backup management clusters (2x)

**Monitoring Setup:**
- [ ] Dashboard Docker Desktop visible
- [ ] Terminal secondaire avec `watch 'kubectl get clusters,machines'`
- [ ] Browser tabs: k8s docs, ClusterAPI docs, GitHub repo
- [ ] Timer visible (90min countdown)

### 🔄 Backup Plans

**Plan A (Recommended):** Management cluster local + individual student setups
**Plan B:** Shared cloud cluster avec namespaces isolés
**Plan C:** Demo-only avec participants observant

**Infrastructure Backup:**
- [ ] 2x Management clusters pré-créés (backup1, backup2)
- [ ] Cloud cluster (EKS/AKS) prêt en 5min si total failure
- [ ] VM snapshots avec tout pré-installé
- [ ] USB keys avec offline assets

---

## Déroulé Minute par Minute

### 🕐 00:00-00:10 - Module 00: Introduction (10min)

**⏱️ Timing:** 00:00 → 00:10
**🎯 Objectif:** Présenter ClusterAPI, vérifier environnements, aligner expectations

**📊 Slides:** Slides 1-8 (Architecture ClusterAPI)

**🗣️ Talking Points:**
- Bonjour, workshop express 90min, objectifs ambitieux
- ClusterAPI = Kubernetes pour gérer Kubernetes
- Management cluster + Workload clusters pattern
- Docker Provider (dev) vs Cloud Providers (prod)
- k0smotron = Virtual Control Planes innovation

**💻 Demo Commands (Projeté):**
```bash
# Montrer l'environnement prêt
kubectl get namespaces
kubectl get pods -A | grep -E "(capi|k0s|helm)"
clusterctl version
```

**👥 Action Participants:**
Simultané avec votre demo:
```bash
cd workshop-express/00-introduction
./verification.sh
```

**⚠️ Watch For:**
- Problèmes Docker Desktop
- kubectl context incorrect
- clusterctl non installé
- Erreur verification script

**🚦 Checkpoint:** 90% participants avec ✅ verification avant 00:10

**💡 Pro Tips:**
- Commencer punctual même si quelques retards
- Assistant aide setup pendant introduction
- Montrer urgence: "90min = no time to lose"

---

### 🕐 00:10-00:25 - Module 01: Premier Cluster (15min)

**⏱️ Timing:** 00:10 → 00:25
**🎯 Objectif:** Créer premier cluster DockerProvider fonctionnel

**🗣️ Talking Points:**
- Cluster = ensemble cohérent de 7 objets ClusterAPI
- Pattern déclaratif: `kubectl apply -f` pour tout
- Lifecycle: Pending → Provisioning → Running → Provisioned
- 1 Control Plane + 2 Workers = architecture typique dev

**💻 Demo Commands:**
```bash
cd 01-premier-cluster
cat dev-cluster.yaml | head -20  # Montrer structure
kubectl apply -f dev-cluster.yaml
watch -n 2 'kubectl get clusters,machines'  # Live progression
```

**👥 Action Participants:**
```bash
cd ../01-premier-cluster
cat commands.md  # Lire section par section
kubectl apply -f dev-cluster.yaml
# Suivre progression avec watch
```

**⚠️ Watch For:**
- Docker out of disk space
- Network timeouts image pulls
- Typos dans noms fichiers
- Ctrl+C pour arrêter watch oublié

**🚦 Checkpoint:** 80% participants avec cluster phase "Provisioned" + 3 machines "Running"

**💡 Pro Tips:**
- Expliquer pendant que ça crée (3min création = temps explications)
- Montrer `docker ps` pour containers créés
- Insister: nodes NotReady = normal (CNI manquant)

---

### 🕐 00:25-00:40 - Module 02: Calico CNI (15min)

**⏱️ Timing:** 00:25 → 00:40
**🎯 Objectif:** Installer Calico automatiquement avec ClusterResourceSets

**🗣️ Talking Points:**
- CNI = Container Network Interface obligatoire
- ClusterResourceSets = automation addons par labels
- Label matching: cluster label "cni=calico"
- Calico se déploie automatiquement sur clusters matchants

**💻 Demo Commands:**
```bash
cd ../02-networking-calico
kubectl --kubeconfig ../01-premier-cluster/dev-cluster.kubeconfig get nodes  # NotReady
kubectl get cluster dev-cluster --show-labels  # Pas de label cni
kubectl apply -f calico-crs.yaml  # ClusterResourceSet
kubectl label cluster dev-cluster cni=calico  # Trigger
# Montrer déploiement Calico en live
```

**👥 Action Participants:**
```bash
cd ../02-networking-calico
cat commands.md
kubectl apply -f calico-crs.yaml
kubectl label cluster dev-cluster cni=calico
# Observer pods Calico apparaître
```

**⚠️ Watch For:**
- Label syntax errors
- ClusterResourceSet pas appliqué
- Pods Calico en CrashLoop
- Timeout attente nodes Ready

**🚦 Checkpoint:** 80% participants avec 3 nodes "Ready" + pods Calico "Running"

**💡 Pro Tips:**
- Montrer avant/après: NotReady → Ready
- Expliquer automation: pas de kubectl apply manuel sur workload
- Calico = choix de workshop, pas obligatoire (Flannel, Cilium ok)

---

### 🕐 00:40-00:55 - Module 03: k0smotron (15min)

**⏱️ Timing:** 00:40 → 00:55
**🎯 Objectif:** Créer cluster k0smotron + comparer économies ressources

**🗣️ Talking Points:**
- k0smotron = Control Planes virtuels (pods vs VMs)
- Économies: 55% nodes, 50% memory, 2x plus rapide
- HA simplifié: scheduler Kubernetes natif
- Use cases: dev, CI/CD, multi-tenancy, edge

**💻 Demo Commands:**
```bash
cd ../03-k0smotron
cat k0s-demo-cluster.yaml  # Montrer différences vs Docker
kubectl apply -f k0s-demo-cluster.yaml
watch -n 2 'kubectl get clusters,machines'
./compare-providers.sh  # Comparer ressources
```

**👥 Action Participants:**
```bash
cd ../03-k0smotron
cat commands.md
kubectl apply -f k0s-demo-cluster.yaml
# Observer création plus rapide
./compare-providers.sh
```

**⚠️ Watch For:**
- k0smotron operator not ready
- Confusion control plane pods vs nodes
- Script compare-providers.sh errors
- Mixed contexts kubeconfig

**🚦 Checkpoint:** 80% participants avec 2 clusters fonctionnels + script comparison ok

**💡 Pro Tips:**
- Emphasis sur speed: "k0smotron cluster ready in 90 seconds!"
- Montrer ressources side-by-side: `kubectl top nodes`
- Business case: economics for 100+ clusters

---

### 🕐 00:55-01:15 - Module 04: Automation Helm (20min)

**⏱️ Timing:** 00:55 → 01:15
**🎯 Objectif:** Déployer nginx automatiquement sur multiple clusters avec HelmChartProxy

**🗣️ Talking Points:**
- HelmChartProxy = GitOps pour applications multi-clusters
- ClusterSelector = targeting par labels
- Helm lifecycle: install, upgrade, rollback automatique
- Real-world: déploiement coordonné à l'échelle

**💻 Demo Commands:**
```bash
cd ../04-automation-helm
cat nginx-helmchartproxy.yaml  # Expliquer clusterSelector
kubectl apply -f nginx-helmchartproxy.yaml
kubectl get helmchartproxy,helmreleaseproxy -A  # Observer création
# Tester nginx sur les 2 clusters
```

**👥 Action Participants:**
```bash
cd ../04-automation-helm
cat commands.md
kubectl apply -f nginx-helmchartproxy.yaml
# Observer déploiement sur 2 clusters
curl http://localhost:30080  # Tester nginx
```

**⚠️ Watch For:**
- Helm provider not ready
- Port 30080 conflicts
- ClusterSelector ne match pas
- HelmRelease stuck pending

**🚦 Checkpoint:** 80% participants avec nginx accessible sur port 30080 sur 2 clusters

**💡 Pro Tips:**
- Montrer GitOps workflow: modify YAML → auto update
- Demo scaling: change replicas dans HelmChartProxy
- Emphasize: same app, 2 clusters, 1 manifest

---

### 🕐 01:15-01:30 - Module 05: Operations & Cleanup (15min)

**⏱️ Timing:** 01:15 → 01:30
**🎯 Objectif:** Scaling operations + monitoring + cleanup complet

**🗣️ Talking Points:**
- Production operations: scale, monitor, lifecycle
- Declarative scaling: modify replicas in YAML
- Monitoring: multi-cluster resource tracking
- Cleanup graceful: ordre correct pour éviter dangling resources

**💻 Demo Commands:**
```bash
cd ../05-operations-cleanup
./scale-workers.sh  # Scale workers 2→3
kubectl get machines  # Voir scaling live
./monitor-resources.sh  # Dashboard ressources
./cleanup.sh  # Cleanup complet ordre correct
```

**👥 Action Participants:**
```bash
cd ../05-operations-cleanup
cat commands.md
./scale-workers.sh
./monitor-resources.sh
./cleanup.sh
```

**⚠️ Watch For:**
- Scaling timeout
- Cleanup stuck on finalizers
- Docker containers persisting
- Incomplete cleanup validation

**🚦 Checkpoint:** 100% participants avec cleanup success + `kubectl get clusters` vide

**💡 Pro Tips:**
- Montrer scaling is live: "production-ready scaling"
- Cleanup = crucial skill: avoid resource leaks
- Finale strong: "vous maîtrisez lifecycle complet!"

---

## Gestion du Rythme

### ⚡ Participants Rapides (Fast Track)

**Strategy:** Challenges supplémentaires sans perturber le groupe

**Module 01 Extra:**
```bash
# Explorer les events
kubectl describe cluster dev-cluster
kubectl get events --sort-by='.lastTimestamp'
# Logs des controllers
kubectl logs -n capi-system deployment/capi-controller-manager --tail=50
```

**Module 02 Extra:**
```bash
# Analyser Calico installation
kubectl --kubeconfig dev-cluster.kubeconfig get pods -n calico-system -o wide
kubectl --kubeconfig dev-cluster.kubeconfig describe node <node-name>
```

**Module 03 Extra:**
```bash
# Comparer architectures en détail
kubectl get pods -n k0smotron -o yaml
kubectl exec -n k0smotron <k0s-pod> -- k0s status
```

**Module 04 Extra:**
```bash
# Modifier nginx configuration
# Edit nginx-helmchartproxy.yaml values
# Test rolling update
```

### 🐌 Participants Lents (Catch-up Support)

**Strategy:** Assistance parallèle + shortcuts + checkpoints

**Assistant Protocol (1 assistant / 15 participants):**
- Circulate during hands-on phases
- Fix common issues silently
- Help with terminal/command errors
- Escalate to instructor only if blocking

**Checkpoint Strategy: "80% Rule"**
- Ne jamais attendre 100% ready
- 80% participants ok = continue
- 20% remaining = assistant help en parallèle
- Keep momentum = critical success factor

**Time Buffers:**
- Module 01: 13min content + 2min buffer
- Module 02: 13min content + 2min buffer
- Module 03: 13min content + 2min buffer
- Module 04: 18min content + 2min buffer
- Module 05: 13min content + 2min buffer
- **Total:** 70min + 10min buffers + 10min Q&A

### 🔥 Emergency Time Recovery

**Si retard > 5min:**

**Option 1: Skip Details**
- Montrer résultats sans expliquer chaque commande
- Focus sur concepts clés seulement
- Demo only pour modules 03-04 si nécessaire

**Option 2: Combine Modules**
- 02+03: "CNI et k0smotron ensemble"
- 04+05: "Automation et operations ensemble"

**Option 3: Cut Module 05**
- Essential: Modules 00-04 (core ClusterAPI)
- Module 05 = bonus si temps disponible

---

## Troubleshooting Formateur

### 🔧 Top 5 Issues Participants

**1. Docker Desktop Problèmes**
```bash
# Symptom: Cannot connect to Docker daemon
# Solution:
systemctl start docker        # Linux
# Ou restart Docker Desktop    # Windows/Mac
docker info                   # Test connectivity
```

**2. kubectl Context Incorrect**
```bash
# Symptom: Error from server (NotFound)
# Solution:
kubectl config get-contexts
kubectl config use-context kind-capi-management
```

**3. clusterctl Not Found**
```bash
# Symptom: command not found
# Solution: Installation link + assistant setup
# Quick fix: Use pre-installed VM/container
```

**4. Cluster Creation Stuck**
```bash
# Symptom: Machines stuck Provisioning
# Debug:
kubectl describe machine <machine-name>
docker logs <container-name>
# Common: Docker out of space, network timeout
```

**5. Validation Scripts Fail**
```bash
# Symptom: ❌ tests in validation.sh
# Solution: Check exact error, guide to manual commands
# Most common: timing (wait more), typos (file names)
```

### 🚨 Emergency Procedures

**Infrastructure Failure Totale:**

**Plan A: Backup Management Cluster**
```bash
kind create cluster --name backup-management
# Re-run setup-infrastructure.sh
```

**Plan B: Cloud Cluster Fallback**
```bash
# Pre-provisioned EKS/AKS cluster
# kubeconfig distribution
# Namespace isolation
```

**Plan C: Demo-Only Mode**
```bash
# Instructor demos everything
# Participants observe and take notes
# Provide repo for post-workshop practice
```

**Network/Internet Issues:**
- Pre-pulled Docker images on local registry
- Offline Helm charts and YAML files
- Local mirrors de documentation

### 🎤 Question Management

**Strategy: "Parking Lot"**
- Acknowledge: "Excellente question"
- Defer: "Je note pour la fin"
- Quick answer only if < 30 seconds
- Detailed questions = post-workshop

**Common Questions & Quick Answers:**

**Q: "Production-ready?"**
A: "Workshop = learning environment, production requires: monitoring, backup, security, multi-tenancy"

**Q: "AWS/Azure support?"**
A: "Oui, même concepts, différent provider: CAPA, CAPZ, CAPG"

**Q: "Kubernetes upgrade?"**
A: "clusterctl upgrade, module avancé du workshop complet"

**Q: "Cost comparison?"**
A: "k0smotron: 55% économies, details dans workshop complet"

---

## Post-Workshop

### 📊 Feedback Collection

**Immediate (Last 5min):**
```
Survey Link QR Code:
⭐ Workshop rating 1-5
⭐ Content clarity 1-5
⭐ Pace approprié 1-5
⭐ Hands-on quality 1-5
💬 One thing to improve
💬 Next topic interest
```

**Follow-up Email (J+1):**
```
Merci pour le Workshop ClusterAPI Express!

📚 RESSOURCES:
- Workshop complet (11h): [LINK]
- GitHub repo: [LINK]
- Documentation officielle: [LINKS]
- Community Slack: [LINK]

🎯 NEXT STEPS:
- Testez en environnement dev
- Workshop avancé: [DATE/LIEN]
- ClusterAPI production guide: [LINK]

📝 FEEDBACK:
- Survey complet: [LINK]
- Questions: [EMAIL]

Merci!
```

### 📁 Resource Distribution

**Immediately Available:**
- [x] GitHub repository access
- [x] Workshop complet link (modules/)
- [x] Documentation links
- [x] Community resources

**Follow-up Resources:**
- Workshop slides PDF
- Extended documentation
- Production readiness checklist
- Advanced workshop invitation

### 🧹 Infrastructure Cleanup

**Post-Workshop Tasks:**
```bash
# Cleanup local environment
kind delete cluster --name capi-management
docker system prune -a -f
kubectl config delete-context kind-capi-management

# If cloud infrastructure
terraform destroy
# ou
kubectl delete namespace workshop-participant-*
```

**Infrastructure Tracking:**
- [ ] Management clusters stopped
- [ ] Cloud resources destroyed
- [ ] Costs calculated and logged
- [ ] Participant data cleaned

### 📈 Follow-up Communication

**Week +1: Thank You + Resources**
**Week +2: Feedback Survey**
**Month +1: Advanced Workshop Invitation**
**Month +3: Production Experience Survey**

---

## Checklist Formateur

### 📋 Pre-Workshop (J-1)

**Technical:**
- [ ] Infrastructure setup script tested end-to-end
- [ ] All 6 modules validated individually
- [ ] Backup management clusters ready
- [ ] Monitoring dashboards configured
- [ ] Network/internet connectivity verified
- [ ] Docker images pre-pulled (offline ready)

**Content:**
- [ ] Slides updated and rehearsed
- [ ] Timing validated (75min + 15min buffer)
- [ ] Talking points memorized
- [ ] Q&A preparation done
- [ ] Troubleshooting scenarios practiced

**Logistics:**
- [ ] Venue/room checked
- [ ] AV equipment tested
- [ ] Participant list confirmed
- [ ] Assistants briefed
- [ ] Materials distributed
- [ ] Feedback mechanism ready

### 📋 Day-of-Workshop (H-30)

**Setup:**
- [ ] Arrive 30min early
- [ ] Test complete tech stack
- [ ] Verify internet stability
- [ ] Setup monitoring screens
- [ ] Prepare backup plans
- [ ] Brief assistants on timing

**Go-Live:**
- [ ] Welcome and agenda (00:00)
- [ ] Energy level: high and enthusiastic
- [ ] Timer started (90min countdown)
- [ ] Assistant helping stragglers
- [ ] Checkpoints enforced (80% rule)
- [ ] Emergency plans ready

### 📋 Post-Workshop

**Immediate:**
- [ ] Feedback collection completed
- [ ] Resources distributed
- [ ] Thank you + next steps communicated
- [ ] Infrastructure cleanup initiated
- [ ] Participant questions answered

**Follow-up:**
- [ ] Detailed feedback survey sent
- [ ] Workshop materials archived
- [ ] Lessons learned documented
- [ ] Next workshop iteration planned
- [ ] Community follow-up scheduled

---

## Success Metrics

### 🎯 Workshop Success Criteria

**Completion Rate:**
- ✅ 80%+ participants complete all 5 modules
- ✅ 90%+ participants rate workshop 4+ stars
- ✅ Timeline respected: finish at 90 ± 5 minutes

**Learning Objectives:**
- ✅ 100% participants create functional cluster
- ✅ 90%+ understand ClusterAPI concepts
- ✅ 80%+ understand k0smotron value proposition
- ✅ 70%+ ready to explore production use

**Technical Success:**
- ✅ All validation scripts pass for 80%+ participants
- ✅ Zero infrastructure failures requiring restart
- ✅ All participants access working clusters

### 📈 Quality Indicators

**High Quality Session:**
- Questions show understanding (not confusion)
- Participants helping each other
- Energy maintained throughout
- Few participants stuck/lost
- Strong interest in advanced workshop

**Red Flags:**
- Multiple infrastructure failures
- Significant timing delays (>10min)
- Many participants struggling with basics
- Low energy/engagement
- Complaints about pace/difficulty

---

**Bonne chance pour votre workshop! 🚀**

*Guide formateur v1.0 - Workshop ClusterAPI Express*
*Basé sur ClusterAPI v1.11.1 | k0smotron v1.7.0 | Kubernetes v1.32+*