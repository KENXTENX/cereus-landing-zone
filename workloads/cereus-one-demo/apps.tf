locals {
  kv_secrets = "${azurerm_key_vault.demo.vault_uri}secrets"

  # Azure stores the identity path in Key Vault secret references exactly as
  # it was supplied, and the CLI supplied "resourcegroups" in lower case.
  # Matching it keeps the plan clean.
  app_identity_ref = replace(azurerm_user_assigned_identity.app.id, "/resourceGroups/", "/resourcegroups/")

  # Only used if the app is ever recreated. Day-to-day image updates are
  # deployments, not infrastructure changes, so Terraform ignores them.
  demo_image = "ghcr.io/kenxtenx/cereus-one-demo:49720eb265a998c7fbc075dca749899f865f4390"
}

resource "azurerm_container_app_environment" "demo" {
  name                               = "cae-cereus-demo"
  location                           = local.location
  resource_group_name                = azurerm_resource_group.demo.name
  log_analytics_workspace_id         = azurerm_log_analytics_workspace.demo.id
  infrastructure_subnet_id           = azurerm_subnet.apps.id
  infrastructure_resource_group_name = "ME_cae-cereus-demo_rg-cereus-demo_centralus"
  internal_load_balancer_enabled     = false
  zone_redundancy_enabled            = false
  tags                               = local.tags

  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# The public app. Scales to zero when idle.
resource "azurerm_container_app" "demo" {
  name                         = "ca-cereus-demo"
  resource_group_name          = azurerm_resource_group.demo.name
  container_app_environment_id = azurerm_container_app_environment.demo.id
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"
  max_inactive_revisions       = 100
  tags                         = local.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app.id]
  }

  ingress {
    external_enabled           = true
    target_port                = 3000
    transport                  = "auto"
    allow_insecure_connections = false

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  registry {
    server               = "ghcr.io"
    username             = "kenxtenx"
    password_secret_name = "ghcr-token"
  }

  # Container App secret name => Key Vault secret name
  dynamic "secret" {
    for_each = {
      "database-url"   = "database-url"
      "ghcr-token"     = "ghcr-pull-token"
      "mapbox-token"   = "mapbox-token"
      "session-secret" = "session-secret"
      "sweep-secret"   = "sweep-secret"
    }

    content {
      name                = secret.key
      key_vault_secret_id = "${local.kv_secrets}/${secret.value}"
      identity            = local.app_identity_ref
    }
  }

  template {
    min_replicas = 0
    max_replicas = 1

    container {
      name   = "app"
      image  = local.demo_image
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "APP_URL"
        value = "https://ca-cereus-demo.${azurerm_container_app_environment.demo.default_domain}"
      }
      env {
        name        = "DATABASE_URL"
        secret_name = "database-url"
      }
      env {
        name        = "SESSION_SECRET"
        secret_name = "session-secret"
      }
      env {
        name        = "MAPBOX_TOKEN"
        secret_name = "mapbox-token"
      }
      env {
        name        = "SWEEP_SECRET"
        secret_name = "sweep-secret"
      }
      env {
        name  = "DEFAULT_TENANT_SLUG"
        value = "ceretech"
      }
      env {
        name  = "TRANSPORT_MODE" # SMS and email are logged, never sent
        value = "console"
      }
    }
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [template[0].container[0].image]
  }
}

# One-off: migrations, least-privilege app role, and demo seed data.
# Runs with the admin connection; the app itself never gets it.
resource "azurerm_container_app_job" "setup" {
  name                         = "job-cereus-setup"
  location                     = local.location
  resource_group_name          = azurerm_resource_group.demo.name
  container_app_environment_id = azurerm_container_app_environment.demo.id
  workload_profile_name        = "Consumption"
  replica_timeout_in_seconds   = 1800
  replica_retry_limit          = 0
  tags                         = local.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app.id]
  }

  manual_trigger_config {
    parallelism              = 1
    replica_completion_count = 1
  }

  registry {
    server               = "ghcr.io"
    username             = "kenxtenx"
    password_secret_name = "ghcr-token"
  }

  dynamic "secret" {
    for_each = {
      "admin-url"           = "database-admin-url"
      "app-db-password"     = "app-db-password"
      "demo-admin-password" = "demo-admin-password"
      "ghcr-token"          = "ghcr-pull-token"
      "mapbox-token"        = "mapbox-token"
    }

    content {
      name                = secret.key
      key_vault_secret_id = "${local.kv_secrets}/${secret.value}"
      identity            = local.app_identity_ref
    }
  }

  template {
    container {
      name    = "setup"
      image   = local.demo_image
      cpu     = 0.5
      memory  = "1Gi"
      command = ["sh"]
      args    = ["-c", "node scripts/migrate-on-boot.mjs && node scripts/bootstrap-app-role.mjs && npm run db:seed && npm run seed:protocol"]

      env {
        name        = "DATABASE_ADMIN_URL"
        secret_name = "admin-url"
      }
      env {
        name        = "DATABASE_URL"
        secret_name = "admin-url"
      }
      env {
        name        = "APP_DB_PASSWORD"
        secret_name = "app-db-password"
      }
      env {
        name        = "MAPBOX_TOKEN"
        secret_name = "mapbox-token"
      }
      env {
        name        = "SEED_ADMIN_PASSWORD"
        secret_name = "demo-admin-password"
      }
      env {
        name  = "SEED_ADMIN_EMAIL"
        value = "demo-admin@cereus-demo.invalid"
      }
      env {
        name  = "SEED_ADMIN_MOBILE"
        value = "+15555550100"
      }
      env {
        name  = "MIGRATE_ON_BOOT"
        value = "true"
      }
      env {
        # A date, not a boolean: the protocol seeder refuses unless this is
        # today or yesterday (UTC), so a leftover value expires on its own.
        name  = "SEED_PROTOCOL_CONFIRM"
        value = "2026-10-30"
      }
    }
  }

  lifecycle {
    ignore_changes = [template[0].container[0].image]
  }
}

# Nightly at 08:00 UTC (3 AM Eastern): stops the database if it's running.
# Azure restarts a stopped Flexible Server after 7 days; this catches that.
resource "azurerm_container_app_job" "db_stop" {
  name                         = "job-cereus-db-stop"
  location                     = local.location
  resource_group_name          = azurerm_resource_group.demo.name
  container_app_environment_id = azurerm_container_app_environment.demo.id
  workload_profile_name        = "Consumption"
  replica_timeout_in_seconds   = 600
  replica_retry_limit          = 1
  tags                         = local.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.ops.id]
  }

  schedule_trigger_config {
    cron_expression          = "0 8 * * *"
    parallelism              = 1
    replica_completion_count = 1
  }

  template {
    container {
      name    = "stop-db"
      image   = "mcr.microsoft.com/azure-cli:latest"
      cpu     = 0.25
      memory  = "0.5Gi"
      command = ["sh"]
      args    = ["-c", "az login --identity --client-id $OPS_CLIENT_ID --allow-no-subscriptions --output none && STATE=$(az postgres flexible-server show --ids $DB_ID --query state -o tsv) && echo \"Database state: $STATE\" && if [ \"$STATE\" = Ready ]; then az postgres flexible-server stop --ids $DB_ID --output none && echo 'Stopped it.'; else echo 'Nothing to do.'; fi"]

      env {
        name  = "OPS_CLIENT_ID"
        value = azurerm_user_assigned_identity.ops.client_id
      }
      env {
        name  = "DB_ID"
        value = azurerm_postgresql_flexible_server.demo.id
      }
    }
  }
}
