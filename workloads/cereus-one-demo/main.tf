locals {
  # Central US: neither East region can host the database on this
  # subscription (landing zone finding F17).
  location = "centralus"

  tags = {
    environment = "demo"
    owner       = "kenny"
    project     = "cereus-one-demo"
  }
}

data "azurerm_client_config" "current" {}

# The resource group's own metadata lives in East US; everything in it is
# in Central US. Moving a resource group's location means recreating it.
resource "azurerm_resource_group" "demo" {
  name     = "rg-cereus-demo"
  location = "eastus"
  tags     = local.tags

  lifecycle {
    prevent_destroy = true
  }
}
