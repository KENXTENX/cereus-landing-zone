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
