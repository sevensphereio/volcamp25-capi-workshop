# =============================================================================
# MULTI-ENVIRONMENT EXAMPLE: Dev, Staging, Prod with workspaces
# =============================================================================
# This example demonstrates managing multiple environments using Terraform
# workspaces or by copying this configuration to different directories.
#
# Usage with workspaces:
#   terraform workspace new dev
#   terraform workspace new staging
#   terraform workspace new prod
#
#   terraform workspace select dev
#   terraform apply
#
# Or use separate directories:
#   cp -r multi-env dev/
#   cp -r multi-env staging/
#   cp -r multi-env prod/
# =============================================================================

locals {
  # Environment-specific configurations
  environments = {
    dev = {
      vm_size             = "Standard_B2s"
      vm_count            = 2
      os_disk_size        = 50
      enable_lb           = false
      vnet_address_space  = "10.0.0.0/16"
    }
    staging = {
      vm_size             = "Standard_D2s_v3"
      vm_count            = 3
      os_disk_size        = 75
      enable_lb           = true
      vnet_address_space  = "10.1.0.0/16"
    }
    prod = {
      vm_size             = "Standard_D4s_v3"
      vm_count            = 5
      os_disk_size        = 100
      enable_lb           = true
      vnet_address_space  = "10.2.0.0/16"
    }
  }

  # Select environment (workspace name or variable)
  env = terraform.workspace == "default" ? "dev" : terraform.workspace
  config = local.environments[local.env]

  # Generate VM instances dynamically
  vm_instances = {
    for i in range(local.config.vm_count) : "vm${i + 1}" => {
      name             = "capi-${local.env}-${format("%02d", i + 1)}"
      size             = local.config.vm_size
      enable_public_ip = true
      os_disk_size_gb  = local.config.os_disk_size
      os_disk_type     = local.env == "prod" ? "Premium_LRS" : "StandardSSD_LRS"
    }
  }
}

module "azure_vms" {
  source = "../.."

  # General Configuration
  project_name = "capi-multienv"
  environment  = local.env
  location     = "westeurope"

  # Tags with environment info
  tags = {
    Owner       = "DevOps Team"
    Environment = local.env
    ManagedBy   = "Terraform"
    Workspace   = terraform.workspace
  }

  # Networking - environment-specific
  vnet_address_space      = [local.config.vnet_address_space]
  subnet_address_prefixes = [cidrsubnet(local.config.vnet_address_space, 8, 1)]
  enable_public_ip        = true

  # Security
  allowed_ssh_cidrs = var.allowed_ssh_cidrs

  # VM Configuration - dynamically generated
  vm_instances = local.vm_instances

  # Load Balancer - enabled for staging/prod
  enable_load_balancer = local.config.enable_lb
  load_balancer_sku    = "Standard"

  # Features
  enable_boot_diagnostics = true
}

# Variables
variable "allowed_ssh_cidrs" {
  description = "Allowed CIDR blocks for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Outputs
output "environment" {
  description = "Current environment"
  value       = local.env
}

output "workspace" {
  description = "Current Terraform workspace"
  value       = terraform.workspace
}

output "deployment_summary" {
  description = "Deployment summary"
  value       = module.azure_vms.deployment_summary
}

output "vm_connection_info" {
  description = "SSH connection strings"
  value       = module.azure_vms.ssh_connection_strings
}

output "vm_count" {
  description = "Number of VMs deployed"
  value       = local.config.vm_count
}

output "load_balancer_ip" {
  description = "Load Balancer IP (if enabled)"
  value       = module.azure_vms.load_balancer_public_ip
}