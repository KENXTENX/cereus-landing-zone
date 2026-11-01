# ---------------------------------------------------------------
# Network: one VNet, subnets split by purpose, each behind an NSG
# ---------------------------------------------------------------
locals {
  subnets = {
    "snet-app"               = "10.10.1.0/24"
    "snet-data"              = "10.10.2.0/24"
    "snet-private-endpoints" = "10.10.3.0/24"
  }
}

resource "azurerm_virtual_network" "core" {
  name                = "vnet-cereus-core"
  location            = azurerm_resource_group.core.location
  resource_group_name = azurerm_resource_group.core.name
  address_space       = ["10.10.0.0/16"]
  tags                = local.tags
}

resource "azurerm_subnet" "this" {
  for_each = local.subnets

  name                 = each.key
  resource_group_name  = azurerm_resource_group.core.name
  virtual_network_name = azurerm_virtual_network.core.name
  address_prefixes     = [each.value]

  # No implicit internet egress; outbound must be designed on purpose
  default_outbound_access_enabled = false
}

resource "azurerm_network_security_group" "this" {
  for_each = local.subnets

  name                = "nsg-${each.key}"
  location            = azurerm_resource_group.core.location
  resource_group_name = azurerm_resource_group.core.name
  tags                = local.tags

  # Azure's default rules already block internet inbound; this makes
  # the intent explicit and visible to auditors
  security_rule {
    name                       = "DenyInternetInbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = local.subnets

  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = azurerm_network_security_group.this[each.key].id
}
