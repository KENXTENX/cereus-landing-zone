# Workload: Cereus One demo

The [Cereus One](https://github.com/KENXTENX/cereus-one-azure) Azure demo was
built by hand with the Azure CLI before this landing zone existed. This stack
**adopts it into Terraform with import blocks** instead of rebuilding it, so
the database, Key Vault secrets and public URL stay exactly as they were.

| | |
|---|---|
| Region | Central US ([F17](../../docs/findings.md): no approved East region could host the database) |
| State | `cereus-one-demo.tfstate`, separate from the landing zone core |
| Pipeline | Same identities and gates: Checkov, then a read-only plan on pull requests, then apply on `main` |
| What it owns | Resource group, lock, location policy, VNet and subnets, private DNS, PostgreSQL server, Key Vault, managed identities, Log Analytics, the Container Apps environment, the app, and its setup and nightly stop jobs |

## What it deliberately doesn't own

- **Secret values.** Terraform manages the Key Vault, never what's in it. The
  app and jobs hold Key Vault *references*; values are set with the CLI and
  never enter state.
- **The database inside the server.** Azure can't read it while the server
  is stopped, which is most of the time.
- **The running image tag.** Shipping a new build is a deployment, not an
  infrastructure change, so the image is in `ignore_changes`.
- **Role assignments** (yet). The apply identity can only assign roles in the
  core resource group.

## Safety rails

- `prevent_destroy` on the resource group, database server, Key Vault, the
  Container Apps environment and the app. A plan that would replace any of
  them fails instead.
- The resource group's `CanNotDelete` lock is itself managed here.
- Known gaps from the hand-built era are skipped in Checkov **with a reason
  and a finding number** (F18 to F21), not silently.
