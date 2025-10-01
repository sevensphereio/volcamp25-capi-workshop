terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  # Example remote state configuration
  # backend "azurerm" {
  #   resource_group_name  = "terraform-state-rg"
  #   storage_account_name = "tfstateprodXXXXX"
  #   container_name       = "tfstate"
  #   key                  = "capi-prod.tfstate"
  # }
}

provider "azurerm" {
  features {}
}