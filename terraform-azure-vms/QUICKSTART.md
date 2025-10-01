# 🚀 Quickstart - Terraform Azure VMs

Déployez plusieurs VMs Azure en **moins de 5 minutes**.

## Prérequis Rapides

```bash
# 1. Vérifier Terraform
terraform version  # >= 1.5.0

# 2. Se connecter à Azure
az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

## Déploiement en 4 Étapes

### Étape 1: Créer terraform.tfvars

```bash
cat > terraform.tfvars <<'EOF'
project_name = "workshop"
environment  = "dev"
location     = "westeurope"

vm_instances = {
  vm1 = {
    name             = "node-01"
    size             = "Standard_B2s"
    enable_public_ip = true
  }
  vm2 = {
    name             = "node-02"
    size             = "Standard_B2s"
    enable_public_ip = true
  }
}

# ⚠️ SÉCURITÉ: Remplacez par votre IP
allowed_ssh_cidrs = ["0.0.0.0/0"]
EOF
```

### Étape 2: Initialiser et Déployer

```bash
terraform init
terraform apply -auto-approve
```

**Temps de déploiement:** 2-4 minutes

### Étape 3: Récupérer les Accès

```bash
# IPs publiques
terraform output vm_public_ips

# Clé SSH
terraform output -raw ssh_private_key > ~/.ssh/azure.pem
chmod 600 ~/.ssh/azure.pem

# Commandes SSH
terraform output ssh_connection_strings
```

### Étape 4: Se Connecter

```bash
# Obtenir l'IP
VM_IP=$(terraform output -json vm_public_ips | jq -r '.["node-01"]')

# SSH
ssh -i ~/.ssh/azure.pem azureuser@$VM_IP
```

## Exemples Prêts à l'Emploi

### Exemple Basic (3 VMs)

```bash
cd examples/basic
terraform init && terraform apply
```

### Exemple Production (6 VMs + Load Balancer)

```bash
cd examples/production
terraform init && terraform apply
```

### Multi-Environnements (Workspaces)

```bash
cd examples/multi-env
terraform workspace new dev
terraform apply
```

## Configuration Minimale

```hcl
module "azure_vms" {
  source = "./terraform-azure-vms"

  project_name = "myproject"
  environment  = "dev"

  vm_instances = {
    vm1 = { name = "app-01", size = "Standard_B2s" }
  }
}
```

## Cleanup

```bash
terraform destroy -auto-approve
```

## Troubleshooting Rapide

### VM pas accessible?

```bash
# Vérifier l'état
az vm list -g $(terraform output -raw resource_group_name) --output table

# Vérifier les NSG rules
az network nsg rule list \
  -g $(terraform output -raw resource_group_name) \
  --nsg-name $(terraform output -raw nsg_id | awk -F/ '{print $NF}') \
  --output table
```

### Quota dépassé?

```bash
# Vérifier quotas
az vm list-usage --location westeurope --output table

# Utiliser une VM plus petite
size = "Standard_B1s"  # Au lieu de B2s
```

## Commandes Utiles

```bash
# Lister toutes les ressources
terraform state list

# Voir les outputs
terraform output

# Valider la configuration
terraform validate

# Formater le code
terraform fmt -recursive

# Afficher le plan
terraform plan
```

## Support

Documentation complète: [README.md](README.md)

---

**Happy Deploying! 🎉**