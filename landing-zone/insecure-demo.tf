# DELIBERATELY INSECURE - used to prove the pipeline blocks it
resource "azurerm_storage_account" "insecure_demo" {
  name                            = "stinsecuredemo001"
  resource_group_name             = azurerm_resource_group.core.name
  location                        = azurerm_resource_group.core.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = true
  https_traffic_only_enabled      = false
  min_tls_version                 = "TLS1_0"
}
