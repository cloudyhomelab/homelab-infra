# Export the global and one domain's SOPS secrets as environment variables; a domain's value overrides a global one.
# Usage: source scripts/load-secrets.sh <domain>

# NUL-separated so multi-line values such as SSH keys survive
_load_secrets_file() {
  [[ -f "$1" ]] || return 0
  local json key value
  json="$(sops decrypt --output-type json "$1")"
  while IFS= read -r -d '' key && IFS= read -r -d '' value; do
    export "$key=$value"
  done < <(jq -j 'del(.sops) | to_entries[] | .key, "\u0000", (.value | tostring), "\u0000"' <<<"$json")
}

_load_secrets_file secrets/global.sops.yaml
_load_secrets_file "secrets/$1.sops.yaml"
unset -f _load_secrets_file
