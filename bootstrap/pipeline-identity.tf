# ---------------------------------------------------------------
# Pipeline identities for GitHub Actions: no passwords, no secrets.
# GitHub proves who it is with a short-lived OIDC token, and Azure
# only trusts tokens from this exact repo and this exact trigger.
#
# Two identities, least privilege:
#   plan  - pull requests only, read-only on Azure
#   apply - pushes to main only, can change infrastructure
# ---------------------------------------------------------------
variable "github_repo" {
  description = "GitHub repo allowed to use these identities (owner/name)"
  type        = string
  default     = "KENXTENX@197035361/cereus-landing-zone@1441591649"
}

locals {
  sub_scope  = "/subscriptions/${var.subscription_id}"
  core_scope = "${local.sub_scope}/resourceGroups/rg-cereus-core"
  gh_issuer  = "https://token.actions.githubusercontent.com"
  gh_aud     = ["api://AzureADTokenExchange"]
}

# --------------------------- plan ---------------------------
resource "azurerm_user_assigned_identity" "gh_plan" {
  name                = "id-cereus-gh-plan"
  resource_group_name = azurerm_resource_group.tfstate.name
  location            = azurerm_resource_group.tfstate.location
  tags                = local.tags
}

resource "azurerm_federated_identity_credential" "gh_plan_pr" {
  name                      = "github-pull-request"
  user_assigned_identity_id = azurerm_user_assigned_identity.gh_plan.id
  issuer                    = local.gh_issuer
  audience                  = local.gh_aud
  subject                   = "repo:${var.github_repo}:pull_request"
}

resource "azurerm_role_assignment" "gh_plan_reader" {
  scope                = local.sub_scope
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.gh_plan.principal_id
}

# Plan must read state and take the state lock
resource "azurerm_role_assignment" "gh_plan_state" {
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.gh_plan.principal_id
}

# --------------------------- apply --------------------------
resource "azurerm_user_assigned_identity" "gh_apply" {
  name                = "id-cereus-gh-apply"
  resource_group_name = azurerm_resource_group.tfstate.name
  location            = azurerm_resource_group.tfstate.location
  tags                = local.tags
}

resource "azurerm_federated_identity_credential" "gh_apply_main" {
  name                      = "github-main-branch"
  user_assigned_identity_id = azurerm_user_assigned_identity.gh_apply.id
  issuer                    = local.gh_issuer
  audience                  = local.gh_aud
  subject                   = "repo:${var.github_repo}:ref:refs/heads/main"
}

resource "azurerm_role_assignment" "gh_apply_contributor" {
  scope                = local.sub_scope
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.gh_apply.principal_id
}

# Contributor cannot manage Azure Policy assignments
resource "azurerm_role_assignment" "gh_apply_policy" {
  scope                = local.sub_scope
  role_definition_name = "Resource Policy Contributor"
  principal_id         = azurerm_user_assigned_identity.gh_apply.principal_id
}

# Role assignments only inside the core resource group, not the subscription
resource "azurerm_role_assignment" "gh_apply_rbac_core" {
  scope                = local.core_scope
  role_definition_name = "Role Based Access Control Administrator"
  principal_id         = azurerm_user_assigned_identity.gh_apply.principal_id
}

resource "azurerm_role_assignment" "gh_apply_state" {
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.gh_apply.principal_id
}

# --------------------------- outputs ------------------------
output "gh_plan_client_id" {
  value = azurerm_user_assigned_identity.gh_plan.client_id
}

output "gh_apply_client_id" {
  value = azurerm_user_assigned_identity.gh_apply.client_id
}

output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}
