output "key_vault_name" {
  value = azurerm_key_vault.core.name
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.core.id
}

output "vnet_id" {
  value = azurerm_virtual_network.core.id
}

output "subnet_ids" {
  value = { for k, s in azurerm_subnet.this : k => s.id }
}
