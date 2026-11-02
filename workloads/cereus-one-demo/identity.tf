# The app and its setup job: reads its own secrets from Key Vault.
resource "azurerm_user_assigned_identity" "app" {
  name                = "id-cereus-app"
  location            = local.location
  resource_group_name = azurerm_resource_group.demo.name
  tags                = local.tags
}

# The nightly stop job: holds only the custom "Cereus DB Stopper" role.
resource "azurerm_user_assigned_identity" "ops" {
  name                = "id-cereus-ops"
  location            = local.location
  resource_group_name = azurerm_resource_group.demo.name
  tags                = local.tags
}
