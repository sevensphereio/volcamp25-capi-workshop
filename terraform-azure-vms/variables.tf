# =============================================================================
# GENERAL CONFIGURATION
# =============================================================================

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string

  validation {
    condition     = length(var.project_name) > 0 && length(var.project_name) <= 20
    error_message = "Project name must be between 1 and 20 characters"
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod"
  }
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "westeurope"
}

variable "resource_group_name" {
  description = "Name of the resource group (if empty, will be auto-generated)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# =============================================================================
# NETWORKING CONFIGURATION
# =============================================================================

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefixes" {
  description = "Address prefixes for the subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "enable_public_ip" {
  description = "Enable public IP addresses for VMs"
  type        = bool
  default     = true
}

variable "public_ip_allocation_method" {
  description = "Allocation method for public IPs (Static or Dynamic)"
  type        = string
  default     = "Dynamic"

  validation {
    condition     = contains(["Static", "Dynamic"], var.public_ip_allocation_method)
    error_message = "Public IP allocation method must be Static or Dynamic"
  }
}

# =============================================================================
# SECURITY CONFIGURATION
# =============================================================================

variable "ssh_public_key" {
  description = "SSH public key for VM access (if empty, will be auto-generated)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "allowed_ssh_cidrs" {
  description = "List of CIDR blocks allowed to SSH to VMs"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_http_cidrs" {
  description = "List of CIDR blocks allowed HTTP/HTTPS access to VMs"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "additional_nsg_rules" {
  description = "Additional NSG rules to apply"
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  default = []
}

# =============================================================================
# COMPUTE CONFIGURATION
# =============================================================================

variable "vm_count" {
  description = "Number of identical VMs to create (simple mode, mutually exclusive with vm_instances)"
  type        = number
  default     = 0

  validation {
    condition     = var.vm_count >= 0 && var.vm_count <= 100
    error_message = "VM count must be between 0 and 100"
  }
}

variable "vm_name_prefix" {
  description = "Prefix for VM names when using vm_count (will be suffixed with -01, -02, etc.)"
  type        = string
  default     = "vm"
}

variable "vm_instances" {
  description = "Map of VM instances to create (advanced mode, mutually exclusive with vm_count)"
  type = map(object({
    name               = string
    size               = string
    zone               = optional(string)
    admin_username     = optional(string)
    enable_public_ip   = optional(bool)
    os_disk_size_gb    = optional(number)
    os_disk_type       = optional(string)
    data_disks         = optional(list(object({
      name    = string
      size_gb = number
      lun     = number
      caching = optional(string)
    })))
    custom_data        = optional(string)
    tags               = optional(map(string))
  }))
  default = {}

  validation {
    condition     = length(var.vm_instances) >= 0 && length(var.vm_instances) <= 100
    error_message = "Must define between 0 and 100 VM instances"
  }
}

variable "default_vm_size" {
  description = "Default VM size if not specified in vm_instances"
  type        = string
  default     = "Standard_B2s"
}

variable "default_admin_username" {
  description = "Default admin username for VMs"
  type        = string
  default     = "azureuser"
}

variable "default_os_disk_size_gb" {
  description = "Default OS disk size in GB"
  type        = number
  default     = 30

  validation {
    condition     = var.default_os_disk_size_gb >= 30 && var.default_os_disk_size_gb <= 4095
    error_message = "OS disk size must be between 30 and 4095 GB"
  }
}

variable "default_os_disk_type" {
  description = "Default OS disk type (Standard_LRS, StandardSSD_LRS, Premium_LRS)"
  type        = string
  default     = "Standard_LRS"

  validation {
    condition     = contains(["Standard_LRS", "StandardSSD_LRS", "Premium_LRS"], var.default_os_disk_type)
    error_message = "OS disk type must be Standard_LRS, StandardSSD_LRS, or Premium_LRS"
  }
}

variable "vm_image" {
  description = "VM image configuration"
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

variable "enable_boot_diagnostics" {
  description = "Enable boot diagnostics for VMs"
  type        = bool
  default     = true
}

variable "enable_accelerated_networking" {
  description = "Enable accelerated networking for VMs"
  type        = bool
  default     = false
}

# =============================================================================
# HIGH AVAILABILITY CONFIGURATION
# =============================================================================

variable "enable_availability_zones" {
  description = "Enable availability zones for VMs"
  type        = bool
  default     = false
}

variable "enable_load_balancer" {
  description = "Create and configure an Azure Load Balancer"
  type        = bool
  default     = false
}

variable "load_balancer_sku" {
  description = "SKU for the Load Balancer (Basic or Standard)"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard"], var.load_balancer_sku)
    error_message = "Load Balancer SKU must be Basic or Standard"
  }
}