# =============================================================================
# LOCAL VARIABLES AND COMPUTED VALUES
# =============================================================================

locals {
  # Resource naming
  resource_group_name = var.resource_group_name != "" ? var.resource_group_name : "${var.project_name}-${var.environment}-rg"
  vnet_name          = "${var.project_name}-${var.environment}-vnet"
  subnet_name        = "${var.project_name}-${var.environment}-subnet"
  nsg_name           = "${var.project_name}-${var.environment}-nsg"
  lb_name            = "${var.project_name}-${var.environment}-lb"

  # Common tags applied to all resources
  common_tags = merge(
    {
      Environment  = var.environment
      Project      = var.project_name
      ManagedBy    = "Terraform"
      CreatedDate  = timestamp()
    },
    var.tags
  )

  # SSH key management
  generate_ssh_key = var.ssh_public_key == ""
  ssh_public_key   = local.generate_ssh_key ? tls_private_key.vm_ssh[0].public_key_openssh : var.ssh_public_key

  # VM instance processing
  vm_instances_normalized = {
    for key, vm in var.vm_instances : key => {
      name                       = vm.name
      size                       = coalesce(vm.size, var.default_vm_size)
      zone                       = vm.zone
      admin_username             = coalesce(vm.admin_username, var.default_admin_username)
      enable_public_ip           = coalesce(vm.enable_public_ip, var.enable_public_ip)
      os_disk_size_gb           = coalesce(vm.os_disk_size_gb, var.default_os_disk_size_gb)
      os_disk_type              = coalesce(vm.os_disk_type, var.default_os_disk_type)
      data_disks                = coalesce(vm.data_disks, [])
      custom_data               = vm.custom_data
      tags                      = merge(local.common_tags, coalesce(vm.tags, {}))
    }
  }

  # Flatten data disks for easier iteration
  data_disks_flat = flatten([
    for vm_key, vm in local.vm_instances_normalized : [
      for disk in vm.data_disks : {
        vm_key   = vm_key
        disk_key = "${vm_key}-${disk.name}"
        name     = disk.name
        size_gb  = disk.size_gb
        lun      = disk.lun
        caching  = coalesce(disk.caching, "ReadWrite")
      }
    ]
  ])

  # Load balancer backend pool VMs
  lb_backend_vms = var.enable_load_balancer ? {
    for key, vm in local.vm_instances_normalized : key => vm
  } : {}
}