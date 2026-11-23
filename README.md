# homelab-infra

## Adding a stack

A stack is a directory under `stacks/<domain>/`. Terramate generates the backend, provider and shared-variable wiring from the stack's tags and `uses` global. The stack's own resources are hand-written.

### 1. Create

```sh
terramate create stacks/<domain>/40-foo \
  --description "What it manages" \
  --watch /stacks/<domain>/workloads.yaml \
  --no-generate
```

- Writes `stack.tm.hcl` with a fresh UUID `id`; `name` defaults to the directory name.
- `name` must equal the directory name: the state key is `<basename>.tfstate`.
- The number prefix sets the run order inside the domain.
- `infra` stacks also need `--after /stacks/edge,/stacks/network`, so they run after the domains they depend on.
- `--watch` lists files outside the stack that it reads, so changing them marks the stack as changed.
- `--tags` on `create` filters existing stacks; it does not set tags on the new one.

### 2. Set tags and `uses`

Edit `stack.tm.hcl`:

```hcl
stack {
  # ...
  tags = ["dns", "keycloak", "proxmox"]
}

globals {
  uses = ["timezone", "dns_zone", "reverse_zone"]
}
```

- `tags`: each one adds a provider and its wiring.
  - Tags: `proxmox`, `proxmox-root` (only for `00-proxmox-init`), `time`, `http`, `keycloak`, `dns`, `netbox`, `opnsense`, `truenas`.
  - Provider versions are in `stacks/opentofu.tm.hcl`.
- `uses`: entries from `shared_entries` in `stacks/shared.tm.hcl`; an unknown name fails an assert.

### 3. Generate

```sh
terramate generate
```

Generated files (`_terramate_generated_*`) are never edited by hand; the `terramate-generate` pre-commit hook fails when they are stale.

| File | Generated when | Contents |
|---|---|---|
| `_terramate_generated_opentofu.tf` | always | `required_providers` for the tags, S3 backend (bucket `tofu-state-<domain>`), state encryption, `local.state_backend`, `var.state_passphrase` |
| `_terramate_generated_shared.tf` | `uses` is non-empty | the listed variables and locals |
| `_terramate_generated_proxmox.tf` and `.auto.tfvars` | `proxmox` tag | provider, endpoint, API token read from the `00-proxmox-init` state |
| `_terramate_generated_<provider>.tf` and `.auto.tfvars` | matching tag | provider block and its variables |

### 4. Write by hand

- `main.tf`: resources and module calls.
  - Read another stack's outputs with `terraform_remote_state`, `config = merge(local.state_backend, { key = "<stack>.tfstate" })`.
  - For a VM, pick its key from `../workloads.yaml` and skip it while `create_vm` is false, read `10-proxmox-base` (bridges) and resolve its pinned image with `cloudyhome-image-index`, downloaded by `cloudyhome-proxmox-image`; see an existing VM stack.
- `variables.tf`: only variables no generated file declares.
- `outputs.tf`, `locals.tf` as needed.
- Data files:
  - A new workload gets an entry in `stacks/<domain>/workloads.yaml`.
  - A new address goes in `global-data/ipam.yaml` if needed.
- Secrets: `just secrets <domain>`, keyed `TF_VAR_<variable>`; `scripts/load-secrets.sh` exports them.

### 5. Lock and check

```sh
just init <domain>/40-foo     # writes .terraform.lock.hcl, which is committed
just plan <domain>/40-foo
just stacks <domain>          # confirms the place in the run order
just lint
```
