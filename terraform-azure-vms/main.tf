# =============================================================================
# AZURE MULTI-VM TERRAFORM MODULE
# =============================================================================
# This module creates multiple Azure VMs with networking, security, and
# optional load balancing. Designed for CAPI workshop infrastructure.
#
# Author: Virtual Team (@DevOps-Engineer, @Cloud-Architect)
# Version: 1.0.0
# =============================================================================

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location

  tags = local.common_tags
}

# Random suffix for unique resource names
resource "random_id" "suffix" {
  byte_length = 4
}