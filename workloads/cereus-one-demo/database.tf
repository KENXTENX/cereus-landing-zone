resource "azurerm_postgresql_flexible_server" "demo" {
  #checkov:skip=CKV_AZURE_136:F18 accepted. Fixture data only, and geo-redundant backup can only be chosen when a server is created.
  #checkov:skip=CKV2_AZURE_57:F18 not applicable. Private access through a delegated subnet; there is no public endpoint to put a private endpoint in front of.
  name                          = "cereus-demo-db-kxc1"
  resource_group_name           = azurerm_resource_group.demo.name
  location                      = local.location
  version                       = "17"
  sku_name                      = "B_Standard_B1ms"
  zone                          = "1"
  storage_mb                    = 32768
  storage_tier                  = "P4"
  auto_grow_enabled             = false
  backup_retention_days         = 7
  geo_redundant_backup_enabled  = false
  public_network_access_enabled = false
  delegated_subnet_id           = azurerm_subnet.db.id
  private_dns_zone_id           = azurerm_private_dns_zone.postgres.id
  administrator_login           = "cereusadmin"
  tags                          = local.tags

  authentication {
    active_directory_auth_enabled = false
    password_auth_enabled         = true
  }

  lifecycle {
    prevent_destroy = true

    # The admin password lives only in Key Vault (db-admin-password). It is
    # never written in this code or stored in Terraform state.
    ignore_changes = [administrator_password]
  }
}

resource "azurerm_postgresql_flexible_server_database" "cereus_one" {
  name      = "cereus_one"
  server_id = azurerm_postgresql_flexible_server.demo.id
  charset   = "UTF8"
  collation = "en_US.utf8"

  lifecycle {
    prevent_destroy = true

    # Both force a new database. A spelling difference from what Azure
    # reports must never be able to drop the data.
    ignore_changes = [charset, collation]
  }
}
