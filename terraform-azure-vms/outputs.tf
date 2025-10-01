# =============================================================================
# OUTPUTS
# =============================================================================

# Resource Group
output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}

# Networking
output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "subnet_id" {
  description = "ID of the subnet"
  value       = azurerm_subnet.main.id
}

output "nsg_id" {
  description = "ID of the network security group"
  value       = azurerm_network_security_group.main.id
}

# Virtual Machines
output "vm_ids" {
  description = "Map of VM names to their resource IDs"
  value = {
    for key, vm in azurerm_linux_virtual_machine.vm : key => vm.id
  }
}

output "vm_names" {
  description = "List of VM names"
  value       = [for vm in azurerm_linux_virtual_machine.vm : vm.name]
}

output "vm_private_ips" {
  description = "Map of VM names to their private IP addresses"
  value = {
    for key, vm in azurerm_linux_virtual_machine.vm : vm.name => vm.private_ip_address
  }
}

output "vm_public_ips" {
  description = "Map of VM names to their public IP addresses (if enabled)"
  value = {
    for key, vm in local.vm_instances_normalized : vm.name => (
      vm.enable_public_ip ? azurerm_public_ip.vm[key].ip_address : null
    )
  }
}

output "vm_principal_ids" {
  description = "Map of VM names to their managed identity principal IDs"
  value = {
    for key, vm in azurerm_linux_virtual_machine.vm : vm.name => vm.identity[0].principal_id
  }
}

# SSH Configuration
output "ssh_private_key" {
  description = "Generated SSH private key (if auto-generated)"
  value       = local.generate_ssh_key ? tls_private_key.vm_ssh[0].private_key_openssh : "User provided SSH key"
  sensitive   = true
}

output "ssh_public_key" {
  description = "SSH public key used for VMs"
  value       = local.ssh_public_key
  sensitive   = true
}

# Connection Strings
output "ssh_connection_strings" {
  description = "SSH connection strings for each VM"
  value = {
    for key, vm in local.vm_instances_normalized : vm.name => (
      vm.enable_public_ip ?
      "ssh ${vm.admin_username}@${azurerm_public_ip.vm[key].ip_address}" :
      "ssh ${vm.admin_username}@${azurerm_linux_virtual_machine.vm[key].private_ip_address}"
    )
  }
}

# Load Balancer (if enabled)
output "load_balancer_public_ip" {
  description = "Public IP address of the load balancer (if enabled)"
  value       = var.enable_load_balancer ? azurerm_public_ip.lb[0].ip_address : null
}

output "load_balancer_id" {
  description = "ID of the load balancer (if enabled)"
  value       = var.enable_load_balancer ? azurerm_lb.main[0].id : null
}

# Summary
output "deployment_summary" {
  description = "Summary of the deployment"
  value = {
    project_name        = var.project_name
    environment         = var.environment
    location            = var.location
    resource_group      = azurerm_resource_group.main.name
    vm_count            = length(azurerm_linux_virtual_machine.vm)
    vnet_address_space  = var.vnet_address_space[0]
    load_balancer_enabled = var.enable_load_balancer
  }
}