# Landing zone core: network, Key Vault, and central logging.
# State lives in the storage account created by ../bootstrap.

terraform {
  required_version = ">= 1.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.42"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # storage_account_name is passed at init time:
  # terraform init -backend-config="storage_account_name=<name>"
  backend "azurerm" {
    resource_group_name = "rg-cereus-tfstate"
    container_name      = "tfstate"
    key                 = "landing-zone.tfstate"
    use_azuread_auth    = true # sign in with Entra ID, no account key
  }
}

provider "azurerm" {
  features {}
  subscription_id     = var.subscription_id
  storage_use_azuread = true
}
