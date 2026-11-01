# Cereus One Azure demo (rg-cereus-demo).
#
# The demo was built by hand with the Azure CLI before this landing zone
# existed. This stack brings it under Terraform with import blocks
# (imports.tf) instead of rebuilding it, so the database, Key Vault
# secrets and public URL are untouched. State is separate from the
# landing zone core, in the same storage account.

terraform {
  required_version = ">= 1.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.81"
    }
  }

  # storage_account_name is passed at init time, as for the landing zone:
  # terraform init -backend-config="storage_account_name=<name>"
  backend "azurerm" {
    resource_group_name = "rg-cereus-tfstate"
    container_name      = "tfstate"
    key                 = "cereus-one-demo.tfstate"
    use_azuread_auth    = true # sign in with Entra ID, no account key
  }
}

provider "azurerm" {
  features {}
  subscription_id     = var.subscription_id
  storage_use_azuread = true
}
