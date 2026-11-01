# ---------------------------------------------------------------
# Audit the state file itself: every read, write, and delete of
# Terraform state is logged with the caller's identity.
# The ID is built as a string so the read-only CI identity does not
# need permission to look up the storage account.
# ---------------------------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "state_blob" {
  name                       = "diag-tfstate-blob-to-law"
  target_resource_id         = "/subscriptions/${var.subscription_id}/resourceGroups/rg-cereus-tfstate/providers/Microsoft.Storage/storageAccounts/${var.state_storage_account_name}/blobServices/default"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.core.id

  dynamic "enabled_log" {
    for_each = toset(["StorageRead", "StorageWrite", "StorageDelete"])
    content {
      category = enabled_log.value
    }
  }
}
