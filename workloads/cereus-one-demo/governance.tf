# Guardrails scoped to the demo, on top of the landing zone's
# subscription-wide policies.

resource "azurerm_management_lock" "no_delete" {
  name       = "lock-no-delete"
  scope      = azurerm_resource_group.demo.id
  lock_level = "CanNotDelete"
  notes      = "Protects the Cereus demo from accidental deletion"
}

data "azurerm_policy_definition" "allowed_locations" {
  display_name = "Allowed locations"
}

# Narrower than the subscription policy: this resource group may only use
# Central US.
resource "azurerm_resource_group_policy_assignment" "allowed_locations" {
  name                 = "allowed-locations-cereus"
  display_name         = "Cereus demo: Central US only"
  resource_group_id    = azurerm_resource_group.demo.id
  policy_definition_id = data.azurerm_policy_definition.allowed_locations.id

  parameters = jsonencode({
    listOfAllowedLocations = { value = [local.location] }
  })
}
