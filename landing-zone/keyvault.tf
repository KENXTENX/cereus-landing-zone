# ---------------------------------------------------------------
# Key Vault: secrets live here, never in code or app settings
# ---------------------------------------------------------------
resource "azurerm_key_vault" "core" {
  #checkov:skip=CKV2_AZURE_32:Private endpoint deferred (cost + unreachable from GitHub-hosted runners); access limited by IP allowlist and Entra RBAC
  name                       = "kv-cereus-${random_string.suffix.result}"
  location                   = azurerm_resource_group.core.location
  resource_group_name        = azurerm_resource_group.core.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true # Entra ID roles, not legacy access policies
  soft_delete_retention_days = 7
  purge_protection_enabled   = true # deleted secrets/vault cannot be destroyed before retention ends (found by Checkov CKV_AZURE_110)

  # Only your IP can reach the vault; everything else is denied
  public_network_access_enabled = true
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = [var.allowed_ip]
  }

  tags = local.tags
}

# You manage the vault; apps will later get read-only "Secrets User"
resource "azurerm_role_assignment" "kv_admin_me" {
  scope                = azurerm_key_vault.core.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.admin_object_id # explicit, so CI does not swap in its own identity
}

# Every read/write of a secret gets logged to the workspace
resource "azurerm_monitor_diagnostic_setting" "kv" {
  name                       = "diag-kv-to-law"
  target_resource_id         = azurerm_key_vault.core.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.core.id

  enabled_log {
    category_group = "audit"
  }
}
