# ---------------------------------------------------------------
# Time-boxed exemption (finding F16)
#
# The Cereus One Azure demo (rg-cereus-demo) was built in Central US
# before this landing zone existed. The subscription-wide
# allowed-locations policy denies every update to it, including
# incident response: patching its image and closing its ingress.
#
# Scope: one resource group, one assignment, with an expiry. The
# demo moves to East US through Terraform before this expires.
# ---------------------------------------------------------------
data "azurerm_resource_group" "cereus_demo" {
  name = "rg-cereus-demo"
}

resource "azurerm_resource_group_policy_exemption" "cereus_demo_location" {
  name                 = "ex-cereus-demo-centralus"
  display_name         = "Cereus One demo: Central US until rebuilt in East US"
  description          = "Waiver for the pre-landing-zone demo so it can be patched. Remove when the demo is rebuilt in an approved region."
  resource_group_id    = data.azurerm_resource_group.cereus_demo.id
  policy_assignment_id = azurerm_subscription_policy_assignment.allowed_locations.id
  exemption_category   = "Waiver"
  expires_on           = "2026-12-01T00:00:00Z"
}
