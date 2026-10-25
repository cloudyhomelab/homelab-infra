set shell := ["bash", "-euo", "pipefail", "-c"]

# Apply order across failure domains
domains := "level0 edge infra apps"

# One state bucket per domain: <prefix><domain>
state_bucket_prefix := "tofu-state-"

# S3 server holding state, read by the backend, remote state reads and scripts/s3-state.sh
export AWS_ENDPOINT_URL_S3 := "https://s3-api.cloudyhome.net"
export AWS_REGION := "home"

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

# Run any tofu command in a stack with its domain's secrets loaded
tofu stack +args:
    #!/usr/bin/env bash
    set -euo pipefail
    dir="stacks/{{ stack }}"
    domain="{{ stack }}"
    domain="${domain%%/*}"
    secrets="secrets/${domain}.sops.yaml"
    compgen -G "$dir/*.tf" >/dev/null || { echo "not a stack: {{ stack }} (see: just stacks)" >&2; exit 1; }
    export TF_VAR_state_bucket="{{ state_bucket_prefix }}${domain}"
    export TF_VAR_state_key="${dir#stacks/*/}"
    if [[ -f "$secrets" ]]; then
      exec sops exec-env "$secrets" "tofu -chdir=$dir {{ args }}"
    fi
    exec tofu -chdir="$dir" {{ args }}

init stack *args:
    @just tofu {{ stack }} init {{ args }}

plan stack *args:
    @just tofu {{ stack }} plan {{ args }}

apply stack *args:
    @just tofu {{ stack }} apply {{ args }}

init-domain domain:
    #!/usr/bin/env bash
    set -euo pipefail
    for s in $(just stacks {{ domain }}); do
      echo "==> $s"
      just init "$s"
    done

plan-domain domain:
    #!/usr/bin/env bash
    set -euo pipefail
    for s in $(just stacks {{ domain }}); do
      echo "==> $s"
      just plan "$s"
    done

# Applies each stack in order, each with its own approval prompt
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

fmt:
    tofu fmt -recursive

lint:
    pre-commit run --all-files
