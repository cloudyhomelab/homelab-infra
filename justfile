set shell := ["bash", "-euo", "pipefail", "-c"]

# Apply order across failure domains
domains := "level0 edge network infra apps"

# One state bucket per domain: <prefix><domain>
state_bucket_prefix := "tofu-state-"

# S3 server holding state, passed to the backend and read by scripts/s3-state.sh
state_endpoint := "http://moria.ip.cloudyhome.net:9000"
state_region := "home"

# Show this list
default:
    @just --list

# List stacks in apply order, optionally for one domain
stacks domain="":
    #!/usr/bin/env bash
    set -euo pipefail
    for d in {{ if domain == "" { domains } else { domain } }}; do
      [[ -d "stacks/$d" ]] || continue
      find "stacks/$d" -mindepth 2 -maxdepth 2 -name '*.tf' -printf '%h\n' | sort -u | sed 's|^stacks/||'
    done

# Run any tofu command in a stack with the global and its domain's secrets loaded
tofu stack +args:
    #!/usr/bin/env bash
    set -euo pipefail
    dir="stacks/{{ stack }}"
    domain="{{ stack }}"
    domain="${domain%%/*}"
    compgen -G "$dir/*.tf" >/dev/null || { echo "not a stack: {{ stack }} (see: just stacks)" >&2; exit 1; }
    source scripts/load-secrets.sh "$domain"
    export TF_VAR_state_endpoint="{{ state_endpoint }}"
    export TF_VAR_state_region="{{ state_region }}"
    export TF_VAR_state_bucket="{{ state_bucket_prefix }}${domain}"
    export TF_VAR_state_key="${dir#stacks/*/}"
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
    compgen -G "stacks/{{ stack }}/*.tf" >/dev/null || { echo "not a stack: {{ stack }} (see: just stacks)" >&2; exit 1; }
    [[ ! -e "stacks/$domain/{{ name }}" ]] || { echo "already exists: $domain/{{ name }}" >&2; exit 1; }
    # Other stacks read state by key and link files by path; those would silently break
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
    mv "stacks/{{ stack }}" "stacks/$domain/{{ name }}"
    just tofu "$domain/{{ name }}" init -migrate-state
    just tofu "$domain/{{ name }}" plan -detailed-exitcode

# Initialise every stack in a domain
init-domain domain:
    #!/usr/bin/env bash
    set -euo pipefail
    stacks="$(just stacks {{ domain }})"
    for s in $stacks; do
      echo "==> $s"
      just init "$s"
    done

# Re-initialise every tofu stack in a domain after a config change, keeping state in place
reconfigure-domain domain:
    #!/usr/bin/env bash
    set -euo pipefail
    stacks="$(just stacks {{ domain }})"
    for s in $stacks; do
      echo "==> $s"
      just tofu "$s" init -reconfigure
    done

# Upgrade every tofu stack in a domain to reselect module and provider after version upgrades
upgrade-domain domain:
    #!/usr/bin/env bash
    set -euo pipefail
    stacks="$(just stacks {{ domain }})"
    for s in $stacks; do
      echo "==> $s"
      just tofu "$s" init -upgrade
    done


# Plan every stack in a domain, in apply order
plan-domain domain:
    #!/usr/bin/env bash
    set -euo pipefail
    stacks="$(just stacks {{ domain }})"
    for s in $stacks; do
      echo "==> $s"
      just plan "$s"
    done

# Apply every stack in a domain in order, each with its own approval prompt
apply-domain domain:
    #!/usr/bin/env bash
    set -euo pipefail
    stacks="$(just stacks {{ domain }})"
    for s in $stacks; do
      echo "==> $s"
      just apply "$s"
    done

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
