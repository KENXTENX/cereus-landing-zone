resource "azurerm_virtual_network" "demo" {
  name                = "vnet-cereus-cus"
  location            = local.location
  resource_group_name = azurerm_resource_group.demo.name
  address_space       = ["10.20.0.0/16"]
  tags                = local.tags
}

# Container Apps environment (VNet-injected, workload profiles).
resource "azurerm_subnet" "apps" {
  #checkov:skip=CKV2_AZURE_31:F21 open. No NSG on the demo subnets; to be added in its own PR.
  name                            = "snet-apps"
  resource_group_name             = azurerm_resource_group.demo.name
  virtual_network_name            = azurerm_virtual_network.demo.name
  address_prefixes                = ["10.20.0.0/23"]
  default_outbound_access_enabled = true

  delegation {
    name = "0"

    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# PostgreSQL Flexible Server, private access only.
resource "azurerm_subnet" "db" {
  #checkov:skip=CKV2_AZURE_31:F21 open, same fix.
  name                            = "snet-db"
  resource_group_name             = azurerm_resource_group.demo.name
  virtual_network_name            = azurerm_virtual_network.demo.name
  address_prefixes                = ["10.20.2.0/24"]
  default_outbound_access_enabled = true
  service_endpoints               = ["Microsoft.Storage"]

  delegation {
    name = "0"

    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# The database's private name resolves only inside this VNet.
resource "azurerm_private_dns_zone" "postgres" {
  name                = "cereus-demo.private.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.demo.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "link-vnet-cus"
  resource_group_name   = azurerm_resource_group.demo.name
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = azurerm_virtual_network.demo.id
  registration_enabled  = false
}
