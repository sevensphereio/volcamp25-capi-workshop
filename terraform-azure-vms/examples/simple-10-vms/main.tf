# =============================================================================
# SIMPLE 10 VMS DEPLOYMENT EXAMPLE
# =============================================================================
# This example demonstrates deploying 10 identical VMs using the simple
# vm_count parameter instead of defining each VM individually.
#
# Perfect for:
# - Workshop environments with identical participant VMs
# - Testing/development environments
# - Quick cluster deployments
# =============================================================================

module "workshop_vms" {
  source = "../.."

  # Project configuration
  project_name = "workshop"
  environment  = "dev"
  location     = "westeurope"

  # Simple mode: Just specify the count!
  vm_count        = 10
  vm_name_prefix  = "workshop-vm"

  # VM specifications (applied to all VMs)
  default_vm_size         = "Standard_B2s"
  default_admin_username  = "azureuser"
  default_os_disk_size_gb = 50
  default_os_disk_type    = "Standard_LRS"

  # Networking
  vnet_address_space      = ["10.0.0.0/16"]
  subnet_address_prefixes = ["10.0.1.0/24"]
  enable_public_ip        = true

  # Security
  allowed_ssh_cidrs = ["0.0.0.0/0"]  # Restrict in production!

  # Optional: Custom tags
  tags = {
    Workshop    = "ClusterAPI-k0smotron"
    Instructor  = "DevOps-Team"
    Duration    = "2-hours"
    Participants = "10"
  }
}

# =============================================================================
# OUTPUTS
# =============================================================================

output "deployment_info" {
  description = "Deployment summary"
  value       = module.workshop_vms.deployment_summary
}

output "vm_ssh_connections" {
  description = "SSH connection strings for all VMs"
  value       = module.workshop_vms.ssh_connection_strings
}

output "vm_public_ips" {
  description = "Public IP addresses of all VMs"
  value       = module.workshop_vms.vm_public_ips
}

output "ssh_private_key" {
  description = "SSH private key to connect to VMs"
  value       = module.workshop_vms.ssh_private_key
  sensitive   = true
}

# =============================================================================
# USAGE INSTRUCTIONS
# =============================================================================
#
# 1. Initialize Terraform:
#    terraform init
#
# 2. Review the plan:
#    terraform plan
#
# 3. Deploy the VMs:
#    terraform apply
#
# 4. Get SSH connection info:
#    terraform output vm_ssh_connections
#
# 5. Save SSH private key:
#    terraform output -raw ssh_private_key > workshop_key.pem
#    chmod 600 workshop_key.pem
#
# 6. Connect to a VM:
#    ssh -i workshop_key.pem azureuser@<public-ip>
#
# 7. Destroy when done:
#    terraform destroy
#
