set shell := ["bash", "-euo", "pipefail", "-c"]

# Apply order across failure domains
domains := "level0 edge infra apps"

# One state bucket per domain: <prefix><domain>
state_bucket_prefix := "tofu-state-"

# S3 server holding state, passed to the backend and read by scripts/s3-state.sh
state_endpoint := "https://s3-api.cloudyhome.net"
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
      find "stacks/$d" -name '*.tf' -not -path '*/.terraform/*' -printf '%h\n' | sort -u | sed 's|^stacks/||'
    done

# Run any tofu command in a stack with the global and its domain's secrets loaded
tofu stack +args:
    #!/usr/bin/env bash
    set -euo pipefail
    dir="stacks/{{ stack }}"
    domain="{{ stack }}"
    domain="${domain%%/*}"
    compgen -G "$dir/*.tf" >/dev/null || { echo "not a stack: {{ stack }} (see: just stacks)" >&2; exit 1; }
    # NUL-separated so multi-line values such as SSH keys survive; later files override earlier ones
    load_secrets() {
      [[ -f "$1" ]] || return 0
      local json key value
      json="$(sops decrypt --output-type json "$1")"
      while IFS= read -r -d '' key && IFS= read -r -d '' value; do
        export "$key=$value"
      done < <(jq -j 'del(.sops) | to_entries[] | .key, "\u0000", (.value | tostring), "\u0000"' <<<"$json")
    }
    load_secrets secrets/global.sops.yaml
    load_secrets "secrets/${domain}.sops.yaml"
    export TF_VAR_state_endpoint="{{ state_endpoint }}"
    export TF_VAR_state_region="{{ state_region }}"
    export TF_VAR_state_bucket="{{ state_bucket_prefix }}${domain}"
    export TF_VAR_state_key="${dir#stacks/*/}"
    exec tofu -chdir="$dir" {{ args }}

# Initialise one stack's backend and providers
init stack *args:
    @just tofu {{ stack }} init {{ args }}

# Plan one stack
plan stack *args:
    @just tofu {{ stack }} plan {{ args }}

# Apply one stack
apply stack *args:
    @just tofu {{ stack }} apply {{ args }}

# Initialise every stack in a domain
init-domain domain:
    #!/usr/bin/env bash
    set -euo pipefail
    for s in $(just stacks {{ domain }}); do
      echo "==> $s"
      just init "$s"
    done

# Re-initialise every stack in a domain after a backend config change, keeping state in place
reconfigure-domain domain:
    #!/usr/bin/env bash
    set -euo pipefail
    for s in $(just stacks {{ domain }}); do
      echo "==> $s"
      just tofu "$s" init -reconfigure
    done

# Plan every stack in a domain, in apply order
plan-domain domain:
    #!/usr/bin/env bash
    set -euo pipefail
    for s in $(just stacks {{ domain }}); do
      echo "==> $s"
      just plan "$s"
    done

# Apply every stack in a domain in order, each with its own approval prompt
apply-domain domain:
    #!/usr/bin/env bash
    set -euo pipefail
    for s in $(just stacks {{ domain }}); do
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
