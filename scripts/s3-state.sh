#!/usr/bin/env bash
# Prepare the S3 state bucket for one domain and store its credentials in SOPS.
# Usage: scripts/s3-state.sh <domain>
#
# Bucket operations use the aws CLI profile ADMIN_PROFILE (override with S3_ADMIN_PROFILE),
# whose key must be allowed to create buckets. The domain's own access key is created beforehand with
# the S3 server's admin tool, granted access to that bucket only, and entered when prompted.
# Re-running rotates the stored key; the state passphrase is only created once, because
# changing it makes existing state unreadable.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASSPHRASE_BYTES=32
ADMIN_PROFILE="${S3_ADMIN_PROFILE:-homelab-s3}"

# Recent aws CLI v2 sends checksums that several S3-compatible servers reject
export AWS_REQUEST_CHECKSUM_CALCULATION=when_required
export AWS_RESPONSE_CHECKSUM_VALIDATION=when_required

die() { echo "error: $*" >&2; exit 1; }

[[ $# -eq 1 ]] || die "usage: $0 <domain>"
domain="$1"

command -v aws >/dev/null || die "aws CLI not found"

cd "$REPO_DIR"

domains="$(just --evaluate domains)"
[[ " $domains " == *" $domain "* ]] || die "unknown domain '$domain' (known: $domains)"

bucket="$(just --evaluate state_bucket_prefix)$domain"
endpoint="$(just --evaluate AWS_ENDPOINT_URL_S3)"
region="$(just --evaluate AWS_REGION)"
secrets="secrets/$domain.sops.yaml"

# --profile outranks AWS_* credential variables, so a stray key in the shell cannot be used
s3api() { aws s3api --profile "$ADMIN_PROFILE" --endpoint-url "$endpoint" --region "$region" "$@"; }

if s3api head-bucket --bucket "$bucket" >/dev/null 2>&1; then
  echo "bucket $bucket exists"
else
  create_args=(--bucket "$bucket")
  # us-east-1 is the one region S3 rejects as an explicit location constraint
  if [[ "$region" != "us-east-1" ]]; then
    create_args+=(--create-bucket-configuration "LocationConstraint=$region")
  fi
  s3api create-bucket "${create_args[@]}" >/dev/null
  echo "created bucket $bucket"
fi

if s3api put-bucket-versioning --bucket "$bucket" --versioning-configuration Status=Enabled 2>/dev/null; then
  echo "versioning enabled on $bucket"
else
  echo "warning: $bucket does not support versioning; roll back state through storage snapshots" >&2
fi

read -rp "Access key ID for $bucket: " access_key
read -rsp "Secret access key: " secret_key
echo
[[ -n "$access_key" && -n "$secret_key" ]] || die "access key and secret are required"

if [[ ! -f "$secrets" ]]; then
  mkdir -p secrets
  empty="$(mktemp --suffix=.yaml)"
  echo '{}' >"$empty"
  sops encrypt --filename-override "$secrets" "$empty" >"$secrets"
  rm -f "$empty"
fi

access_json="$(jq -Rn --arg v "$access_key" '$v')"
secret_json="$(jq -Rn --arg v "$secret_key" '$v')"
sops set "$secrets" '["AWS_ACCESS_KEY_ID"]' "$access_json"
sops set "$secrets" '["AWS_SECRET_ACCESS_KEY"]' "$secret_json"

if ! sops decrypt --extract '["TF_VAR_state_passphrase"]' "$secrets" >/dev/null 2>&1; then
  passphrase="$(openssl rand -base64 "$PASSPHRASE_BYTES")"
  passphrase_json="$(jq -Rn --arg v "$passphrase" '$v')"
  sops set "$secrets" '["TF_VAR_state_passphrase"]' "$passphrase_json"
  echo "created TF_VAR_state_passphrase in $secrets"
fi

echo "domain $domain: bucket $bucket; credentials in $secrets"
