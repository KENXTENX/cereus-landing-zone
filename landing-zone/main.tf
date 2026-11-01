locals {
  tags = {
    project    = "cereus-landing-zone"
    owner      = "kenny"
    managed_by = "terraform"
    env        = "lab"
  }
}

data "azurerm_client_config" "current" {}

# Globally unique names need a suffix
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_resource_group" "core" {
  name     = "rg-cereus-core"
  location = var.location
  tags     = local.tags
}

# ---------------------------------------------------------------
# Central logging: every audit trail in the landing zone lands here
# ---------------------------------------------------------------
resource "azurerm_log_analytics_workspace" "core" {
  name                = "log-cereus-core"
  location            = azurerm_resource_group.core.location
  resource_group_name = azurerm_resource_group.core.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  daily_quota_gb      = 1 # cost guardrail for the lab
  tags                = local.tags
}

# Send the subscription's Activity Log (who created, changed, or
# deleted what) to the workspace so it can be searched and alerted on
resource "azurerm_monitor_diagnostic_setting" "activity_log" {
  name                       = "diag-activity-to-law"
  target_resource_id         = "/subscriptions/${var.subscription_id}"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.core.id

  dynamic "enabled_log" {
    for_each = toset(["Administrative", "Security", "Policy", "Alert"])
    content {
      category = enabled_log.value
    }
  }
}
