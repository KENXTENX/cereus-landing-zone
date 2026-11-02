# One-time adoption of the hand-built demo. Each block tells Terraform
# "this resource already exists, take ownership of it" instead of creating
# it. After the first apply they are no-ops, kept as the record of what
# was imported.

locals {
  import_rg = "/subscriptions/${var.subscription_id}/resourceGroups/rg-cereus-demo"
}

import {
  to = azurerm_resource_group.demo
  id = local.import_rg
}

import {
  to = azurerm_management_lock.no_delete
  id = "${local.import_rg}/providers/Microsoft.Authorization/locks/lock-no-delete"
}

import {
  to = azurerm_resource_group_policy_assignment.allowed_locations
  id = "${local.import_rg}/providers/Microsoft.Authorization/policyAssignments/allowed-locations-cereus"
}

import {
  to = azurerm_virtual_network.demo
  id = "${local.import_rg}/providers/Microsoft.Network/virtualNetworks/vnet-cereus-cus"
}

import {
  to = azurerm_subnet.apps
  id = "${local.import_rg}/providers/Microsoft.Network/virtualNetworks/vnet-cereus-cus/subnets/snet-apps"
}

import {
  to = azurerm_subnet.db
  id = "${local.import_rg}/providers/Microsoft.Network/virtualNetworks/vnet-cereus-cus/subnets/snet-db"
}

import {
  to = azurerm_private_dns_zone.postgres
  id = "${local.import_rg}/providers/Microsoft.Network/privateDnsZones/cereus-demo.private.postgres.database.azure.com"
}

import {
  to = azurerm_private_dns_zone_virtual_network_link.postgres
  id = "${local.import_rg}/providers/Microsoft.Network/privateDnsZones/cereus-demo.private.postgres.database.azure.com/virtualNetworkLinks/link-vnet-cus"
}

import {
  to = azurerm_postgresql_flexible_server.demo
  id = "${local.import_rg}/providers/Microsoft.DBforPostgreSQL/flexibleServers/cereus-demo-db-kxc1"
}

import {
  to = azurerm_key_vault.demo
  id = "${local.import_rg}/providers/Microsoft.KeyVault/vaults/kv-cereus-demo-kx"
}

import {
  to = azurerm_user_assigned_identity.app
  id = "${local.import_rg}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-cereus-app"
}

import {
  to = azurerm_user_assigned_identity.ops
  id = "${local.import_rg}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-cereus-ops"
}

import {
  to = azurerm_log_analytics_workspace.demo
  id = "${local.import_rg}/providers/Microsoft.OperationalInsights/workspaces/log-cereus-demo"
}

import {
  to = azurerm_container_app_environment.demo
  id = "${local.import_rg}/providers/Microsoft.App/managedEnvironments/cae-cereus-demo"
}

import {
  to = azurerm_container_app.demo
  id = "${local.import_rg}/providers/Microsoft.App/containerApps/ca-cereus-demo"
}

import {
  to = azurerm_container_app_job.setup
  id = "${local.import_rg}/providers/Microsoft.App/jobs/job-cereus-setup"
}

import {
  to = azurerm_container_app_job.db_stop
  id = "${local.import_rg}/providers/Microsoft.App/jobs/job-cereus-db-stop"
}
