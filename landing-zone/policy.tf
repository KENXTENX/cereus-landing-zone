# ---------------------------------------------------------------
# Guardrails: Azure itself refuses insecure or out-of-policy
# resources, no matter who tries to create them (you, a script,
# a teammate, or an AI agent).
# ---------------------------------------------------------------
locals {
  sub_scope         = "/subscriptions/${var.subscription_id}"
  allowed_locations = ["eastus", "eastus2"]
}

data "azurerm_policy_definition" "allowed_locations" {
  display_name = "Allowed locations"
}

data "azurerm_policy_definition" "rg_require_tag" {
  display_name = "Require a tag on resource groups"
}

data "azurerm_policy_definition" "storage_no_public_access" {
  display_name = "Storage account public access should be disallowed"
}

# 1. Data stays in approved regions
resource "azurerm_subscription_policy_assignment" "allowed_locations" {
  name                 = "pa-allowed-locations"
  display_name         = "Cereus: resources only in approved regions"
  subscription_id      = local.sub_scope
  policy_definition_id = data.azurerm_policy_definition.allowed_locations.id

  parameters = jsonencode({
    listOfAllowedLocations = { value = local.allowed_locations }
  })
}

# 2. Every resource group must say who owns it
resource "azurerm_subscription_policy_assignment" "rg_owner_tag" {
  name                 = "pa-rg-owner-tag"
  display_name         = "Cereus: resource groups must have an owner tag"
  subscription_id      = local.sub_scope
  policy_definition_id = data.azurerm_policy_definition.rg_require_tag.id

  parameters = jsonencode({
    tagName = { value = "owner" }
  })
}

# 3. No storage account may ever expose data publicly
resource "azurerm_subscription_policy_assignment" "storage_no_public" {
  name                 = "pa-storage-no-public"
  display_name         = "Cereus: block public storage access"
  subscription_id      = local.sub_scope
  policy_definition_id = data.azurerm_policy_definition.storage_no_public_access.id

  parameters = jsonencode({
    effect = { value = "deny" }
  })
}
