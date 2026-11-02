# Holds every secret the app and its jobs use. Terraform manages the vault
# only; secret values are set with the Azure CLI and never enter state.
resource "azurerm_key_vault" "demo" {
  #checkov:skip=CKV_AZURE_109:F19 open. Network-reachable from the internet (access still needs Entra ID + RBAC). Fix: deny by default with a subnet rule.
  #checkov:skip=CKV_AZURE_189:F19 open, same fix.
  #checkov:skip=CKV2_AZURE_32:F19 open. Same as landing zone F6: private endpoints are out of scope for the lab.
  #checkov:skip=CKV_AZURE_110:F20 open. Purge protection off; enabling it is a one-way change, made in its own PR.
  #checkov:skip=CKV_AZURE_42:F20 open, same fix.
  name                          = "kv-cereus-demo-kx"
  location                      = local.location
  resource_group_name           = azurerm_resource_group.demo.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  rbac_authorization_enabled    = true
  soft_delete_retention_days    = 7
  purge_protection_enabled      = false
  public_network_access_enabled = true
  tags                          = local.tags

  network_acls {
    bypass         = "AzureServices"
    default_action = "Allow"
  }

  lifecycle {
    prevent_destroy = true
  }
}
