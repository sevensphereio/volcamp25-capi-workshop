# Exemple Basique: 3 VMs pour CAPI Workshop

Déploiement simple de 3 machines virtuelles pour environnement de développement CAPI.

## Configuration

- **VMs:** 3 x Standard_B2s (2 vCPUs, 4 GB RAM)
- **Disks:** 50 GB Standard LRS par VM
- **Network:** VNet 10.0.0.0/16 avec public IPs
- **Security:** NSG avec SSH, HTTP, HTTPS, K8s API
- **Coût:** ~€60/mois

## Déploiement

```bash
# Initialiser
terraform init

# Planifier
terraform plan

# Appliquer
terraform apply

# Récupérer les infos
terraform output ssh_connection_strings
terraform output ssh_private_key > ~/.ssh/azure.pem
chmod 600 ~/.ssh/azure.pem

# Se connecter
ssh -i ~/.ssh/azure.pem azureuser@<PUBLIC_IP>
```

## Architecture

```
┌──────────────────────────────────┐
│   Resource Group: capi-workshop  │
│                                  │
│   ┌──────────────────────────┐   │
│   │  VNet: 10.0.0.0/16       │   │
│   │                          │   │
│   │  ┌────────────────────┐  │   │
│   │  │ capi-mgmt-01       │  │   │
│   │  │ Standard_B2s       │  │   │
│   │  │ Public IP          │  │   │
│   │  └────────────────────┘  │   │
│   │                          │   │
│   │  ┌────────────────────┐  │   │
│   │  │ capi-worker-01     │  │   │
│   │  │ Standard_B2s       │  │   │
│   │  │ Public IP          │  │   │
│   │  └────────────────────┘  │   │
│   │                          │   │
│   │  ┌────────────────────┐  │   │
│   │  │ capi-worker-02     │  │   │
│   │  │ Standard_B2s       │  │   │
│   │  │ Public IP          │  │   │
│   │  └────────────────────┘  │   │
│   └──────────────────────────┘   │
└──────────────────────────────────┘
```

## Personnalisation

Éditez `main.tf` pour ajuster:

```hcl
# Changer la région
location = "northeurope"

# Changer la taille des VMs
size = "Standard_B1s"  # Plus petit

# Ajouter une 4ème VM
vm4 = {
  name = "capi-worker-03"
  size = "Standard_B2s"
}

# Restreindre l'accès SSH
allowed_ssh_cidrs = ["YOUR_IP/32"]
```

## Cleanup

```bash
terraform destroy
```