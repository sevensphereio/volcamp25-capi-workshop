# =============================================================================
# PRODUCTION EXAMPLE: High-availability multi-zone deployment
# =============================================================================
# This example demonstrates a production-ready configuration with:
# - Multiple availability zones
# - Azure Load Balancer
# - Custom data disks
# - Enhanced security
# - Custom cloud-init scripts
#
# Usage:
#   terraform init
#   terraform plan
#   terraform apply
# =============================================================================

module "azure_vms" {
  source = "../.."

  # General Configuration
  project_name = "capi-prod"
  environment  = "prod"
  location     = "westeurope"

  # Tags
  tags = {
    Owner       = "Platform Team"
    Environment = "Production"
    Compliance  = "SOC2"
    CostCenter  = "Infrastructure"
    Backup      = "Daily"
  }

  # Networking
  vnet_address_space      = ["10.10.0.0/16"]
  subnet_address_prefixes = ["10.10.1.0/24"]
  enable_public_ip        = true

  # Security - restricted access
  allowed_ssh_cidrs = [
    "203.0.113.0/24"  # Corporate VPN
  ]
  allowed_http_cidrs = [
    "0.0.0.0/0"  # Public access for application
  ]

  # High Availability
  enable_availability_zones = true
  enable_load_balancer     = true
  load_balancer_sku        = "Standard"

  # VM Configuration: 6 VMs across 3 zones
  vm_instances = {
    mgmt1 = {
      name             = "capi-mgmt-01"
      size             = "Standard_D4s_v3"  # 4 vCPUs, 16 GB RAM
      zone             = "1"
      enable_public_ip = true
      os_disk_size_gb  = 100
      os_disk_type     = "Premium_LRS"

      # Additional data disk for etcd
      data_disks = [
        {
          name    = "etcd-data"
          size_gb = 50
          lun     = 0
          caching = "ReadWrite"
        }
      ]

      custom_data = file("${path.module}/cloud-init-mgmt.yaml")
    }

    worker1 = {
      name             = "capi-worker-01"
      size             = "Standard_D2s_v3"  # 2 vCPUs, 8 GB RAM
      zone             = "1"
      enable_public_ip = true
      os_disk_size_gb  = 100
      os_disk_type     = "StandardSSD_LRS"

      data_disks = [
        {
          name    = "container-storage"
          size_gb = 100
          lun     = 0
          caching = "ReadWrite"
        }
      ]

      custom_data = file("${path.module}/cloud-init-worker.yaml")
    }

    worker2 = {
      name             = "capi-worker-02"
      size             = "Standard_D2s_v3"
      zone             = "2"
      enable_public_ip = true
      os_disk_size_gb  = 100
      os_disk_type     = "StandardSSD_LRS"

      data_disks = [
        {
          name    = "container-storage"
          size_gb = 100
          lun     = 0
        }
      ]

      custom_data = file("${path.module}/cloud-init-worker.yaml")
    }

    worker3 = {
      name             = "capi-worker-03"
      size             = "Standard_D2s_v3"
      zone             = "3"
      enable_public_ip = true
      os_disk_size_gb  = 100
      os_disk_type     = "StandardSSD_LRS"

      data_disks = [
        {
          name    = "container-storage"
          size_gb = 100
          lun     = 0
        }
      ]

      custom_data = file("${path.module}/cloud-init-worker.yaml")
    }

    worker4 = {
      name             = "capi-worker-04"
      size             = "Standard_D2s_v3"
      zone             = "1"
      enable_public_ip = false  # Private worker
      os_disk_size_gb  = 100
      os_disk_type     = "StandardSSD_LRS"

      data_disks = [
        {
          name    = "container-storage"
          size_gb = 100
          lun     = 0
        }
      ]

      custom_data = file("${path.module}/cloud-init-worker.yaml")
    }

    worker5 = {
      name             = "capi-worker-05"
      size             = "Standard_D2s_v3"
      zone             = "2"
      enable_public_ip = false
      os_disk_size_gb  = 100
      os_disk_type     = "StandardSSD_LRS"

      data_disks = [
        {
          name    = "container-storage"
          size_gb = 100
          lun     = 0
        }
      ]

      custom_data = file("${path.module}/cloud-init-worker.yaml")
    }
  }

  # Enhanced features
  enable_boot_diagnostics      = true
  enable_accelerated_networking = true

  # VM Image: Ubuntu 22.04 LTS
  vm_image = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Additional NSG rules for monitoring
  additional_nsg_rules = [
    {
      name                       = "AllowPrometheus"
      priority                   = 200
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "9090"
      source_address_prefix      = "10.10.0.0/16"
      destination_address_prefix = "*"
    },
    {
      name                       = "AllowGrafana"
      priority                   = 210
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3000"
      source_address_prefix      = "10.10.0.0/16"
      destination_address_prefix = "*"
    }
  ]
}

# Outputs
output "deployment_summary" {
  description = "Production deployment summary"
  value       = module.azure_vms.deployment_summary
}

output "load_balancer_ip" {
  description = "Load Balancer public IP"
  value       = module.azure_vms.load_balancer_public_ip
}

output "vm_connection_info" {
  description = "SSH connection strings"
  value       = module.azure_vms.ssh_connection_strings
}

output "vm_public_ips" {
  description = "VM public IPs"
  value       = module.azure_vms.vm_public_ips
}

output "vm_private_ips" {
  description = "VM private IPs"
  value       = module.azure_vms.vm_private_ips
}