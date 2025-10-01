# =============================================================================
# BASIC EXAMPLE: Simple 3-VM deployment
# =============================================================================
# This example demonstrates a minimal configuration for deploying 3 VMs
# suitable for development or testing environments.
#
# Usage:
#   terraform init
#   terraform plan
#   terraform apply
# =============================================================================

module "azure_vms" {
  source = "../.."

  # General Configuration
  project_name = "capi-workshop"
  environment  = "dev"
  location     = "westeurope"

  # Tags
  tags = {
    Owner   = "DevOps Team"
    Purpose = "ClusterAPI Workshop"
    CostCenter = "Engineering"
  }

  # Networking
  vnet_address_space      = ["10.0.0.0/16"]
  subnet_address_prefixes = ["10.0.1.0/24"]
  enable_public_ip        = true

  # Security - restrict SSH to your IP (recommended)
  allowed_ssh_cidrs = [
    "0.0.0.0/0"  # CHANGE THIS: Replace with your IP/CIDR
  ]

  # VM Configuration: 3 VMs for CAPI management + workers
  vm_instances = {
    vm1 = {
      name               = "capi-mgmt-01"
      size               = "Standard_B2s"  # 2 vCPUs, 4 GB RAM
      enable_public_ip   = true
      os_disk_size_gb    = 50
    }

    vm2 = {
      name               = "capi-worker-01"
      size               = "Standard_B2s"
      enable_public_ip   = true
      os_disk_size_gb    = 50
    }

    vm3 = {
      name               = "capi-worker-02"
      size               = "Standard_B2s"
      enable_public_ip   = true
      os_disk_size_gb    = 50
    }
  }

  # Boot diagnostics enabled
  enable_boot_diagnostics = true
}

# Output connection information
output "vm_connection_info" {
  description = "SSH connection strings for all VMs"
  value       = module.azure_vms.ssh_connection_strings
}

output "vm_public_ips" {
  description = "Public IP addresses of all VMs"
  value       = module.azure_vms.vm_public_ips
}

output "ssh_private_key" {
  description = "Generated SSH private key (save to file and chmod 600)"
  value       = module.azure_vms.ssh_private_key
  sensitive   = true
}