variable "subscription_id" {
  description = "Azure subscription ID (set via TF_VAR_subscription_id)"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "allowed_ip" {
  description = "Your public IP; the only address allowed to reach Key Vault (set via TF_VAR_allowed_ip)"
  type        = string
}

variable "alert_email" {
  description = "Where budget alerts go (set via TF_VAR_alert_email)"
  type        = string
}

variable "monthly_budget" {
  description = "Monthly lab budget in USD"
  type        = number
  default     = 20
}

variable "admin_object_id" {
  description = "Entra object ID of the human admin for Key Vault (set via TF_VAR_admin_object_id)"
  type        = string
}

variable "state_storage_account_name" {
  description = "Name of the Terraform state storage account (set via TF_VAR_state_storage_account_name)"
  type        = string
}
