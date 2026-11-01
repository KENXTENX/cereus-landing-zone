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
