# =============================================================================
# COMPUTE RESOURCES
# =============================================================================

# Virtual Machines
resource "azurerm_linux_virtual_machine" "vm" {
  for_each = local.vm_instances_normalized

  name                            = each.value.name
  location                        = azurerm_resource_group.main.location
  resource_group_name             = azurerm_resource_group.main.name
  size                            = each.value.size
  zone                            = each.value.zone
  admin_username                  = each.value.admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.vm[each.key].id]
  custom_data                     = each.value.custom_data != null ? base64encode(each.value.custom_data) : null

  # SSH Configuration
  admin_ssh_key {
    username   = each.value.admin_username
    public_key = local.ssh_public_key
  }

  # OS Disk Configuration
  os_disk {
    name                 = "${each.value.name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = each.value.os_disk_type
    disk_size_gb         = each.value.os_disk_size_gb
  }

  # Source Image
  source_image_reference {
    publisher = var.vm_image.publisher
    offer     = var.vm_image.offer
    sku       = var.vm_image.sku
    version   = var.vm_image.version
  }

  # Boot Diagnostics
  dynamic "boot_diagnostics" {
    for_each = var.enable_boot_diagnostics ? [1] : []
    content {
      storage_account_uri = null  # Uses managed storage account
    }
  }

  # Identity (for managed identities if needed)
  identity {
    type = "SystemAssigned"
  }

  tags = each.value.tags

  lifecycle {
    ignore_changes = [
      custom_data,  # Prevent recreation on cloud-init changes
    ]
  }
}

# Data Disks
resource "azurerm_managed_disk" "data" {
  for_each = {
    for disk in local.data_disks_flat : disk.disk_key => disk
  }

  name                 = "${local.vm_instances_normalized[each.value.vm_key].name}-${each.value.name}"
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  storage_account_type = local.vm_instances_normalized[each.value.vm_key].os_disk_type
  create_option        = "Empty"
  disk_size_gb         = each.value.size_gb

  tags = local.vm_instances_normalized[each.value.vm_key].tags
}

# Attach Data Disks to VMs
resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  for_each = {
    for disk in local.data_disks_flat : disk.disk_key => disk
  }

  managed_disk_id    = azurerm_managed_disk.data[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.vm[each.value.vm_key].id
  lun                = each.value.lun
  caching            = each.value.caching
}