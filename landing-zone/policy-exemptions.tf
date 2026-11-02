# The F16 exemption on rg-cereus-demo is no longer needed (Central US is an
# approved region, F17), but it can't be deleted: the resource group's
# CanNotDelete lock also covers extension resources such as policy
# exemptions (F24). Rather than lifting the lock, Terraform stops tracking
# the exemption and leaves it in Azure, where it expires on 2026-12-01 and
# then has no effect.
removed {
  from = azurerm_resource_group_policy_exemption.cereus_demo_location

  lifecycle {
    destroy = false
  }
}
