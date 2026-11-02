resource "azurerm_log_analytics_workspace" "demo" {
  name                = "log-cereus-demo"
  location            = local.location
  resource_group_name = azurerm_resource_group.demo.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  daily_quota_gb      = 0.1 # cost guardrail
  tags                = local.tags

  # Stays on: the Container Apps environment ships its logs with the
  # workspace key. Azure doesn't report this setting back, so the first
  # apply records it in state (a no-op write).
  local_authentication_enabled = true
}
