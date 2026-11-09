set shell := ["bash", "-euo", "pipefail", "-c"]

# Apply order across failure domains
domains := "level0 edge infra apps"

# One state bucket per domain: <prefix><domain>
state_bucket_prefix := "tofu-state-"

# S3 server holding state, passed to the backend and read by scripts/s3-state.sh
state_endpoint := "http://moria.ip.cloudyhome.net:9000"
state_region := "home"

ansible_config := justfile_directory() / "ansible/ansible.cfg"

# Show this list
default:
    @just --list

# List stacks in apply order, optionally for one domain
stacks domain="":
    #!/usr/bin/env bash
    set -euo pipefail
    for d in {{ if domain == "" { domains } else { domain } }}; do
      [[ -d "stacks/$d" ]] || continue
      find "stacks/$d" -mindepth 2 -maxdepth 2 \( -name '*.tf' -o -name playbook.yml \) -printf '%h\n' \
        | sort -u | sed 's|^stacks/||' \
        | while read -r s; do just _kind "$s" >/dev/null; echo "$s"; done
    done

# Print a stack's tool: tofu for *.tf, ansible for playbook.yml
[private]
_kind stack:
    #!/usr/bin/env bash
    set -euo pipefail
    dir="stacks/{{ stack }}"
    tf=0; pb=0
    compgen -G "$dir/*.tf" >/dev/null && tf=1
    [[ -f "$dir/playbook.yml" ]] && pb=1
    case "$tf$pb" in
      10) echo tofu ;;
      01) echo ansible ;;
      11) echo "stack holds both *.tf and playbook.yml: {{ stack }}" >&2; exit 1 ;;
      *) echo "not a stack: {{ stack }} (see: just stacks)" >&2; exit 1 ;;
    esac

# Run any tofu command in a stack with the global and its domain's secrets loaded
tofu stack +args:
    #!/usr/bin/env bash
    set -euo pipefail
    dir="stacks/{{ stack }}"
    domain="{{ stack }}"
    domain="${domain%%/*}"
    [[ "$(just _kind {{ stack }})" == tofu ]] || { echo "not a tofu stack: {{ stack }}" >&2; exit 1; }
    source scripts/load-secrets.sh "$domain"
    export TF_VAR_state_endpoint="{{ state_endpoint }}"
    export TF_VAR_state_region="{{ state_region }}"
    export TF_VAR_state_bucket="{{ state_bucket_prefix }}${domain}"
    export TF_VAR_state_key="${dir#stacks/*/}"
    exec tofu -chdir="$dir" {{ args }}

# Run a stack's playbook with ansible-playbook and extra args, the global and its domain's secrets loaded
ansible stack *args:
    #!/usr/bin/env bash
    set -euo pipefail
    domain="{{ stack }}"
    domain="${domain%%/*}"
    [[ "$(just _kind {{ stack }})" == ansible ]] || { echo "not an ansible stack: {{ stack }}" >&2; exit 1; }
    source scripts/load-secrets.sh "$domain"
    export ANSIBLE_CONFIG="{{ ansible_config }}"
    exec ansible-playbook "stacks/{{ stack }}/playbook.yml" {{ args }}

# Initialise one stack: tofu backend and providers, or the pinned Ansible collections
init stack *args:
    #!/usr/bin/env bash
    set -euo pipefail
    case "$(just _kind {{ stack }})" in
      tofu) just tofu {{ stack }} init {{ args }} ;;
      ansible) ANSIBLE_CONFIG="{{ ansible_config }}" ansible-galaxy collection install -r ansible/requirements.yml {{ args }} ;;
    esac

# Plan one stack; an Ansible stack runs in check mode with diff
plan stack *args:
    #!/usr/bin/env bash
    set -euo pipefail
    case "$(just _kind {{ stack }})" in
      tofu) just tofu {{ stack }} plan {{ args }} ;;
      ansible) just ansible {{ stack }} --check --diff {{ args }} ;;
    esac

# Apply one stack; an Ansible stack applies without an approval prompt
apply stack *args:
    #!/usr/bin/env bash
    set -euo pipefail
    case "$(just _kind {{ stack }})" in
      tofu) just tofu {{ stack }} apply {{ args }} ;;
      ansible) just ansible {{ stack }} --diff {{ args }} ;;
    esac

# Destroy one tofu stack's resources; its emptied state object stays in the bucket
destroy stack *args:
    #!/usr/bin/env bash
    set -euo pipefail
    [[ "$(just _kind {{ stack }})" == tofu ]] || { echo "only tofu stacks can be destroyed: {{ stack }}" >&2; exit 1; }
    just tofu {{ stack }} destroy {{ args }}

# Rename a tofu stack within its domain, copying its state to the new key; the old state object stays in the bucket
mv-stack stack name:
    #!/usr/bin/env bash
    set -euo pipefail
    domain="{{ stack }}"
    domain="${domain%%/*}"
    old="{{ stack }}"
    old="${old#*/}"
    [[ "{{ name }}" != */* ]] || { echo "new name is a directory inside the domain, not a path: {{ name }}" >&2; exit 1; }
    [[ "$(just _kind {{ stack }})" == tofu ]] || { echo "only tofu stacks can be moved: {{ stack }}" >&2; exit 1; }
    [[ ! -e "stacks/$domain/{{ name }}" ]] || { echo "already exists: $domain/{{ name }}" >&2; exit 1; }
    # Other stacks read state by key and playbooks call stacks by path; those would silently break
    refs="$( {
      grep -rnF --exclude-dir=.terraform -e "$old.tfstate" "stacks/$domain" || true
      grep -rnF --exclude-dir=.terraform --exclude-dir=collections -e "/$old" stacks ansible scripts justfile || true
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
      [[ "$(just _kind "$s")" == tofu ]] || continue
      echo "==> $s"
      just tofu "$s" init -reconfigure
    done

# Upgrade every tofu stack in a domain to reselect module and provider after version upgrades
upgrade-domain domain:
    #!/usr/bin/env bash
    set -euo pipefail
    stacks="$(just stacks {{ domain }})"
    for s in $stacks; do
      [[ "$(just _kind "$s")" == tofu ]] || continue
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
