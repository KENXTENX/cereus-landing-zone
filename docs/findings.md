# Findings log

Every issue found while building and attacking this landing zone, and what was done about it.

| ID | Finding | Risk | Status | Resolution |
|---|---|---|---|---|
| F1 | Subscription inherits **User Access Administrator** from the parent tenant root (university tenant) | Tenant admins outside my control can grant themselves access to this subscription | Accepted | Lab data only. Production workloads go to a dedicated tenant I control |
| F2 | State storage allowed **shared account keys** | A leaked key gives full read/write to Terraform state with no per-user audit trail | ✅ Fixed | Entra ID auth for Terraform (`use_azuread_auth`) and users; `shared_access_key_enabled = false`. Verified: key access rejected, identity access works |
| F3 | Key Vault **purge protection** off (Checkov CKV_AZURE_110, CKV_AZURE_42) | A deleted vault or secret can be destroyed immediately, including by an attacker | ✅ Fixed | Purge protection on. Irreversible by design |
| F4 | State storage was **locally redundant** (CKV_AZURE_206) | A regional outage loses Terraform's record of all infrastructure | ✅ Fixed | GRS replication. Plan verified as update-in-place before apply |
| F5 | **Access to the state file** wasn't logged (CKV2_AZURE_21) | Can't tell who read or changed the state | ✅ Fixed | Blob read/write/delete logs sent to the central workspace (`landing-zone/state-logging.tf`) |
| F6 | **Private endpoints** absent for Key Vault and state storage (CKV2_AZURE_32, CKV2_AZURE_33) | Services are reachable from the internet at the network layer | Accepted | GitHub-hosted runners can't reach private endpoints. Mitigated by Entra-only auth, IP allowlist on Key Vault, TLS 1.2. Revisit with self-hosted runners |
| F7 | Microsoft-managed encryption keys, not customer-managed (CKV2_AZURE_1) | Less control over key lifecycle | Accepted | No compliance driver; CMK adds rotation burden for a lab |
| F8 | Queue logging not configured (CKV_AZURE_33) | — | Not applicable | Queue service isn't used |
| F9 | **Local Checkov run silently skipped the graph-based (CKV2) checks** that ran in CI | A clean local scan can be falsely reassuring | ✅ Fixed | CI pins Python and Checkov versions and is the authoritative gate |
| F10 | Public-storage policy **also denies requests that omit the setting** | Positive: blocks insecure-by-omission | Noted | Tests needed explicit flags to prove each control independently |
| F11 | GitHub OIDC subject uses **immutable owner/repo IDs** | Name-based trust could be hijacked if a repo name were reused | ✅ Fixed | Federated credentials match `repo:OWNER@ID/REPO@ID:...` |
| F12 | Key Vault admin role was assigned to **whoever runs Terraform** | First CI run would have replaced the human admin with the pipeline identity | ✅ Fixed | Admin pinned to an explicit object ID variable |
| F13 | Pipeline IDs printed in **workflow logs** | Subscription/tenant/object IDs visible once the repo is public (reconnaissance) | ✅ Fixed | Moved to GitHub secrets so they're masked; old run logs deleted before going public |
| F14 | **Bootstrap state** lives only on my laptop | Losing the machine loses Terraform's record of the state storage and identities | Open | Planned: move to remote state or a backed-up location |
| F15 | Merge to `main` wasn't **blocked** by a failing scan on a free private repo | A failing PR could still be merged (deploy would still be blocked by the gate) | ✅ Fixed | Repo made public; branch protection requires the scan and plan checks |
| F16 | The allowed-locations policy **blocked incident response** on a resource that predates it: patching a critical Next.js CVE and closing public ingress on the Central US demo were both denied | A Deny guardrail can stop the fix as well as the mistake, leaving a vulnerable app exposed | ✅ Mitigated | Revision deactivated (an action, which policy doesn't evaluate), then a Terraform exemption scoped to one resource group and one assignment, expiring 2026-12-01. Permanent fix: rebuild the demo in East US |
