# Threat model

## What we're protecting

| Asset | Why it matters |
|---|---|
| **Terraform state** | Full map of the environment; may contain sensitive attributes. Tampering changes what gets deployed |
| **Key Vault secrets** | Credentials for the apps that will run on this foundation |
| **Deployment pipeline** | Whoever controls it can change everything in the subscription |
| **Audit logs** | The only record of who did what; attackers try to avoid or erase them |
| **The subscription itself** | Compute, data, and spend |

## Trust boundaries

1. **GitHub → Azure:** only short-lived OIDC tokens from this repo, on specific triggers, are accepted.
2. **Internet → Azure services:** Key Vault limited to an IP allowlist; storage requires Entra identity; NSGs deny inbound internet.
3. **Human → Azure:** Entra ID sign-in; roles scoped to what each person needs.
4. **Parent tenant → subscription:** inherited admin access from the tenant root (see F1).

## Threats and mitigations (STRIDE)

| Threat | Example | Mitigation | Status |
|---|---|---|---|
| **Spoofing** | Attacker uses a leaked deployment password | No passwords exist: OIDC federation with short-lived tokens | ✅ |
| **Spoofing** | Attacker recreates a deleted repo with the same name to inherit trust | Federated credentials match immutable owner/repo IDs | ✅ |
| **Spoofing** | Attacker uses a leaked storage account key | Shared keys disabled; key requests rejected | ✅ |
| **Tampering** | Malicious PR adds insecure infrastructure | Checkov gate fails the build; plan identity is read-only; apply only runs on `main`; branch protection requires checks | ✅ |
| **Tampering** | Someone creates insecure resources directly in the portal or CLI, bypassing Terraform | Azure Policy denies them regardless of who or what asks | ✅ |
| **Tampering** | Bad apply corrupts state | Blob versioning and soft delete on state; GRS copy in a second region | ✅ |
| **Repudiation** | "I didn't change that" | Activity Log, Key Vault audit, and state-file access logs, all centralized with caller identity | ✅ |
| **Information disclosure** | Public storage leaks data | Policy denies public storage; Checkov flags it before deploy | ✅ |
| **Information disclosure** | IDs exposed in public CI logs | Pipeline IDs stored as masked secrets | ✅ |
| **Information disclosure** | Key Vault reachable from the internet | IP allowlist + RBAC; private endpoint deferred | ⚠️ Accepted (F6) |
| **Denial of service** | Secret or vault deleted maliciously | Soft delete + purge protection | ✅ |
| **Denial of service** | Runaway spend | Budget alerts; log ingestion cap | ✅ |
| **Elevation of privilege** | Pipeline identity used to grant itself broad access | Plan identity is read-only; apply identity's role-assignment rights limited to one resource group | ⚠️ Partial — apply still holds subscription Contributor |
| **Elevation of privilege** | Tenant-root admins grant themselves access | Out of my control in this tenant | ⚠️ Accepted (F1) |

## Residual risks

- **Apply identity is powerful.** It holds Contributor at subscription scope. Next step: narrow to resource-group scope and add a manual approval environment.
- **No private endpoints yet** (F6).
- **Bootstrap state is local** (F14).
- **Parent-tenant admin inheritance** (F1). This is the reason production workloads belong in a tenant I fully control.
