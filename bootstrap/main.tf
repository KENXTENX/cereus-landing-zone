# Bootstrap: creates the secure storage that will hold Terraform state
# for the whole landing zone. This is the only config that keeps its
# state locally (chicken-and-egg: the backend has to exist first).

terraform {
  required_version = ">= 1.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id

  # Talk to storage with Entra ID identities, not shared account keys
  storage_use_azuread = true
}

data "azurerm_client_config" "current" {}

variable "subscription_id" {
  description = "Azure subscription ID (set via TF_VAR_subscription_id)"
  type        = string
}

variable "allow_shared_keys" {
  description = "Shared account keys on the state storage. Off: every access must use an Entra ID identity and is attributable in logs."
  type        = bool
  default     = false
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

locals {
  tags = {
    project    = "cereus-landing-zone"
    owner      = "kenny"
    managed_by = "terraform"
  }
}

# Storage account names must be globally unique, so add a random suffix
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_resource_group" "tfstate" {
  name     = "rg-cereus-tfstate"
  location = var.location
  tags     = local.tags
}

resource "azurerm_storage_account" "tfstate" {
  name                            = "stcereustf${random_string.suffix.result}"
  resource_group_name             = azurerm_resource_group.tfstate.name
  location                        = azurerm_resource_group.tfstate.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = var.allow_shared_keys

  # Keep old versions of the state file so a bad apply can be rolled back
  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 7
    }

    container_delete_retention_policy {
      days = 7
    }
  }

  tags = local.tags
}

# Data-plane access for you via Entra ID: replaces the shared key
resource "azurerm_role_assignment" "state_blob_me" {
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}

output "resource_group_name" {
  value = azurerm_resource_group.tfstate.name
}

output "storage_account_name" {
  value = azurerm_storage_account.tfstate.name
}

output "container_name" {
  value = azurerm_storage_container.tfstate.name
}
