set shell := ["bash", "-euo", "pipefail", "-c"]

# Show this list
default:
    @just --list

# List stacks in apply order, optionally for one domain
stacks domain="":
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ -z "{{ domain }}" ]]; then
      terramate -C stacks list --run-order
    else
      [[ -d "stacks/{{ domain }}" ]] || { echo "not a domain: {{ domain }}" >&2; exit 1; }
      terramate -C "stacks/{{ domain }}" list --run-order | sed "s|^|{{ domain }}/|"
    fi

# Run any tofu command in a stack with the global and its domain's secrets loaded
tofu stack +args:
    #!/usr/bin/env bash
    set -euo pipefail
    dir="stacks/{{ stack }}"
    domain="{{ stack }}"
    domain="${domain%%/*}"
    compgen -G "$dir/*.tf" >/dev/null || { echo "not a stack: {{ stack }} (see: just stacks)" >&2; exit 1; }
    source scripts/load-secrets.sh "$domain"
    exec tofu -chdir="$dir" {{ args }}

# Initialise one stack's backend and providers
init stack *args:
    just tofu {{ stack }} init {{ args }}

# Plan one stack
plan stack *args:
    just tofu {{ stack }} plan {{ args }}

# Apply one stack
apply stack *args:
    just tofu {{ stack }} apply {{ args }}

# Destroy one stack's resources; its emptied state object stays in the bucket
destroy stack *args:
    just tofu {{ stack }} destroy {{ args }}

# Rename a stack within its domain, copying its state to the new key; the old state object stays in the bucket
mv-stack stack name:
    #!/usr/bin/env bash
    set -euo pipefail
    domain="{{ stack }}"
    domain="${domain%%/*}"
    old="{{ stack }}"
    old="${old#*/}"
    [[ "{{ name }}" != */* ]] || { echo "new name is a directory inside the domain, not a path: {{ name }}" >&2; exit 1; }
    # Keeps both names safe to splice into the sed expression below
    [[ "$old" =~ ^[A-Za-z0-9._-]+$ && "{{ name }}" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "stack names may only contain letters, digits, '.', '_' and '-'" >&2; exit 1; }
    compgen -G "stacks/{{ stack }}/*.tf" >/dev/null || { echo "not a stack: {{ stack }} (see: just stacks)" >&2; exit 1; }
    [[ ! -e "stacks/$domain/{{ name }}" ]] || { echo "already exists: $domain/{{ name }}" >&2; exit 1; }
    # Other stacks read state by key or files by path; those would silently break
    refs="$( {
      grep -rnF --exclude-dir=.terraform -e "$old.tfstate" "stacks/$domain" || true
      grep -rnF --exclude-dir=.terraform -e "/$old" stacks scripts justfile || true
    } | grep -v "^stacks/{{ stack }}/" | sort -u || true )"
    if [[ -n "$refs" ]]; then
      echo "still referenced elsewhere, update these first:" >&2
      echo "$refs" >&2
      exit 1
    fi
    # Init under the old key first so -migrate-state knows where to copy from
    just tofu {{ stack }} init -input=false
    # Before the mv, so a failure leaves the stack where it was; only inside the top-level stack block
    sed -i -E "/^stack[[:space:]]*\{/,/^\}/ s|^([[:space:]]*name[[:space:]]*=[[:space:]]*)\"${old//./\\.}\"|\1\"{{ name }}\"|" "stacks/{{ stack }}/stack.tm.hcl"
    mv "stacks/{{ stack }}" "stacks/$domain/{{ name }}"
    just tofu "$domain/{{ name }}" init -migrate-state
    just tofu "$domain/{{ name }}" plan -detailed-exitcode

# Run a terramate run command line in every stack of a domain, with the global and the domain's secrets loaded
[private]
domain-run domain +args:
    #!/usr/bin/env bash
    set -euo pipefail
    [[ -d "stacks/{{ domain }}" ]] || { echo "not a domain: {{ domain }}" >&2; exit 1; }
    source scripts/load-secrets.sh "{{ domain }}"
    exec terramate -C "stacks/{{ domain }}" run {{ args }}

# Initialise every stack in a domain
init-domain domain:
    just domain-run {{ domain }} --disable-safeguards=git -- tofu init

# Re-initialise every tofu stack in a domain after a config change, keeping state in place
reconfigure-domain domain:
    just domain-run {{ domain }} --disable-safeguards=git -- tofu init -reconfigure

# Upgrade every tofu stack in a domain to reselect module and provider after version upgrades
upgrade-domain domain:
    just domain-run {{ domain }} --disable-safeguards=git -- tofu init -upgrade

# Plan every stack in a domain, in apply order; uncommitted changes are planned too
plan-domain domain:
    just domain-run {{ domain }} --disable-safeguards=git -- tofu plan

# Apply every stack in a domain in order, each with its own approval prompt; only from committed code in sync with the remote
apply-domain domain:
    just domain-run {{ domain }} -- tofu apply

# Copy a domain's S3 key from the storage domain into its secrets file; creates its state passphrase once
s3-key domain:
    #!/usr/bin/env bash
    set -euo pipefail
    [[ -d "stacks/{{ domain }}" ]] || { echo "not a domain: {{ domain }}" >&2; exit 1; }
    # The storage domain authenticates with the S3 admin credentials it manages everything else with
    [[ "{{ domain }}" != storage ]] || { echo "storage uses the S3 admin credentials; set them with: just secrets storage" >&2; exit 1; }
    secrets="secrets/{{ domain }}.sops.yaml"
    passphrase_bytes=32
    keys="$(just tofu storage/10-s3-access output -json s3_keys)"
    jq -e --arg d "{{ domain }}" 'has($d)' <<<"$keys" >/dev/null \
      || { echo "no S3 key for {{ domain }}; add it to stacks/storage/s3-access.yaml and apply storage/10-s3-access" >&2; exit 1; }
    if [[ ! -f "$secrets" ]]; then
      empty="$(mktemp --suffix=.yaml)"
      echo '{}' >"$empty"
      sops encrypt --filename-override "$secrets" "$empty" >"$secrets"
      rm -f "$empty"
    fi
    jq --arg d "{{ domain }}" '.[$d].access_key' <<<"$keys" | sops set --idempotent --value-stdin "$secrets" '["AWS_ACCESS_KEY_ID"]'
    jq --arg d "{{ domain }}" '.[$d].secret_key' <<<"$keys" | sops set --idempotent --value-stdin "$secrets" '["AWS_SECRET_ACCESS_KEY"]'
    # Created once: a new passphrase makes the domain's existing state unreadable
    if ! sops decrypt --extract '["TF_VAR_state_passphrase"]' "$secrets" >/dev/null 2>&1; then
      openssl rand -base64 "$passphrase_bytes" | jq -R . | sops set --value-stdin "$secrets" '["TF_VAR_state_passphrase"]'
      echo "created TF_VAR_state_passphrase in $secrets"
    fi
    echo "S3 key of {{ domain }} written to $secrets"

# Edit a domain's secrets file
secrets domain:
    mkdir -p secrets
    sops secrets/{{ domain }}.sops.yaml

# Format all OpenTofu files
fmt:
    tofu fmt -recursive

# Run all pre-commit checks on every file
lint:
    pre-commit run --all-files

# Pin workloads to their newest image build; no workload means all of them
update-images *workloads:
    scripts/update-image-pins.sh {{ workloads }}
