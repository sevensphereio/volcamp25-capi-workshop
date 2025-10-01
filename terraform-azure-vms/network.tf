# =============================================================================
# NETWORK RESOURCES
# =============================================================================

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = local.vnet_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = var.vnet_address_space

  tags = local.common_tags
}

# Subnet
resource "azurerm_subnet" "main" {
  name                 = local.subnet_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.subnet_address_prefixes
}

# Network Security Group
resource "azurerm_network_security_group" "main" {
  name                = local.nsg_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = local.common_tags
}

# Associate NSG with Subnet
resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = azurerm_subnet.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# Public IP addresses for VMs
resource "azurerm_public_ip" "vm" {
  for_each = {
    for key, vm in local.vm_instances_normalized : key => vm
    if vm.enable_public_ip
  }

  name                = "${each.value.name}-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = var.public_ip_allocation_method
  sku                 = var.enable_load_balancer ? var.load_balancer_sku : "Basic"
  zones               = each.value.zone != null ? [each.value.zone] : null

  tags = each.value.tags
}

# Network Interfaces
resource "azurerm_network_interface" "vm" {
  for_each = local.vm_instances_normalized

  name                          = "${each.value.name}-nic"
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  enable_accelerated_networking = var.enable_accelerated_networking

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = each.value.enable_public_ip ? azurerm_public_ip.vm[each.key].id : null
  }

  tags = each.value.tags
}

# Associate NICs with NSG
resource "azurerm_network_interface_security_group_association" "vm" {
  for_each = local.vm_instances_normalized

  network_interface_id      = azurerm_network_interface.vm[each.key].id
  network_security_group_id = azurerm_network_security_group.main.id
}

# =============================================================================
# LOAD BALANCER (OPTIONAL)
# =============================================================================

# Public IP for Load Balancer
resource "azurerm_public_ip" "lb" {
  count = var.enable_load_balancer ? 1 : 0

  name                = "${local.lb_name}-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = var.load_balancer_sku == "Standard" ? "Static" : "Dynamic"
  sku                 = var.load_balancer_sku

  tags = local.common_tags
}

# Load Balancer
resource "azurerm_lb" "main" {
  count = var.enable_load_balancer ? 1 : 0

  name                = local.lb_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = var.load_balancer_sku

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb[0].id
  }

  tags = local.common_tags
}

# Backend Address Pool
resource "azurerm_lb_backend_address_pool" "main" {
  count = var.enable_load_balancer ? 1 : 0

  loadbalancer_id = azurerm_lb.main[0].id
  name            = "BackendPool"
}

# Associate NICs with Backend Pool
resource "azurerm_network_interface_backend_address_pool_association" "main" {
  for_each = local.lb_backend_vms

  network_interface_id    = azurerm_network_interface.vm[each.key].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.main[0].id
}

# Health Probe
resource "azurerm_lb_probe" "main" {
  count = var.enable_load_balancer ? 1 : 0

  loadbalancer_id = azurerm_lb.main[0].id
  name            = "ssh-probe"
  protocol        = "Tcp"
  port            = 22
  interval_in_seconds = 15
  number_of_probes    = 2
}

# Load Balancing Rule
resource "azurerm_lb_rule" "main" {
  count = var.enable_load_balancer ? 1 : 0

  loadbalancer_id                = azurerm_lb.main[0].id
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main[0].id]
  probe_id                       = azurerm_lb_probe.main[0].id
}