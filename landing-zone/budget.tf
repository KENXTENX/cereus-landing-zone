# ---------------------------------------------------------------
# Cost guardrail: budget alerts defined in code, not by hand
# ---------------------------------------------------------------
resource "azurerm_consumption_budget_subscription" "lab" {
  name            = "budget-cereus-lab"
  subscription_id = local.sub_scope
  amount          = var.monthly_budget
  time_grain      = "Monthly"

  time_period {
    start_date = "2026-11-01T00:00:00Z"
  }

  # Warn at half the budget actually spent
  notification {
    enabled        = true
    threshold      = 50
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = [var.alert_email]
  }

  # Warn early if the month is on track to go over
  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    threshold_type = "Forecasted"
    contact_emails = [var.alert_email]
  }

  lifecycle {
    ignore_changes = [time_period]
  }
}
