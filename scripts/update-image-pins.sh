#!/usr/bin/env bash
# Pin workloads to the newest build in their image index.
# Usage: scripts/update-image-pins.sh [workload ...]   (no workload: every workload of every domain)
#
# Newest is the highest BUILD_VERSION among complete builds; BUILD_VERSION is a sortable timestamp.
# Edits stacks/<domain>/workloads.yaml line by line instead of through a YAML tool, so comments and
# layout stay as written; this relies on workload keys at two spaces and their fields at four.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CURL_TIMEOUT_SECONDS=10

die() { echo "error: $*" >&2; exit 1; }

command -v jq >/dev/null || die "jq not found"
command -v terramate >/dev/null || die "terramate not found"

cd "$REPO_DIR"

# Prints "<key> <image> <image_version>" per workload; a missing field prints as "-"
list_workloads() {
  awk '
    function flush() { if (key != "") print key, (image == "" ? "-" : image), (version == "" ? "-" : version) }
    /^[^[:space:]#]/ { flush(); key = ""; in_wl = ($0 ~ /^workloads:[[:space:]]*$/); next }
    !in_wl { next }
    /^  [A-Za-z0-9._-]+:[[:space:]]*$/ { flush(); key = $1; sub(/:$/, "", key); image = ""; version = ""; next }
    key != "" && /^    image:/ { image = $2; gsub(/"/, "", image) }
    key != "" && /^    image_version:/ { version = $2; gsub(/"/, "", version) }
    END { flush() }
  ' "$1"
}

set_version() {
  local file="$1" key="$2" version="$3" tmp
  tmp="$(mktemp)"
  awk -v key="$key" -v version="$version" '
    /^[^[:space:]#]/ { in_wl = ($0 ~ /^workloads:[[:space:]]*$/); in_key = 0 }
    in_wl && /^  [A-Za-z0-9._-]+:[[:space:]]*$/ { k = $1; sub(/:$/, "", k); in_key = (k == key) }
    in_key && /^    image_version:/ { sub(/image_version:.*/, "image_version: \"" version "\"") }
    { print }
  ' "$file" >"$tmp"
  # Overwrite in place to keep the file mode
  cat "$tmp" >"$file"
  rm -f "$tmp"
}

declare -A wanted=() known=() latest=()
for w in "$@"; do wanted["$w"]=1; done

for file in stacks/*/workloads.yaml; do
  while read -r key _; do known["$key"]=1; done < <(list_workloads "$file")
done
missing=()
for w in "$@"; do [[ -n "${known[$w]:-}" ]] || missing+=("$w"); done
[[ ${#missing[@]} -eq 0 ]] || die "unknown workload(s): ${missing[*]}"

for file in stacks/*/workloads.yaml; do
  domain="$(basename "$(dirname "$file")")"
  index_url="$(terramate -C "stacks/$domain" experimental get-config-value global.image_index_url)"
  [[ -n "$index_url" ]] || die "no image_index_url global for domain $domain"

  while read -r key image current; do
    [[ $# -eq 0 || -n "${wanted[$key]:-}" ]] || continue
    [[ "$image" != "-" && "$current" != "-" ]] || die "$file: workload $key lacks image or image_version"

    cache_key="$index_url/$image"
    if [[ -z "${latest[$cache_key]:-}" ]]; then
      index="$(curl -fsS -m "$CURL_TIMEOUT_SECONDS" -H 'Accept: application/json' "${index_url%/}/$image/index.json")" \
        || die "cannot fetch the index of $image"
      latest["$cache_key"]="$(jq -r '
        [.BUILDS[]? | select(.BUILD_VERSION and .IMAGE_URL and .IMAGE_FILE and .IMAGE_CHECKSUM)]
        | max_by(.BUILD_VERSION) | .BUILD_VERSION // empty
      ' <<<"$index")"
      [[ -n "${latest[$cache_key]}" ]] || die "no complete build in the index of $image"
    fi
    newest="${latest[$cache_key]}"

    if [[ "$newest" == "$current" ]]; then
      echo "$domain/$key: $current (up to date)"
    else
      set_version "$file" "$key" "$newest"
      echo "$domain/$key: $current -> $newest"
    fi
  done < <(list_workloads "$file")
done
