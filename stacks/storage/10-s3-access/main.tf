locals {
  domains       = yamldecode(file("${path.module}/../s3-access.yaml")).domains
  state_buckets = toset(concat(["storage"], keys(local.domains)))
}

# The buckets predate this stack. Remove after the first apply: a domain added later has no bucket to import.
import {
  for_each = local.state_buckets
  to       = minio_s3_bucket.state[each.key]
  id       = "${local.state_bucket_prefix}${each.key}"
}

resource "minio_s3_bucket" "state" {
  for_each = local.state_buckets

  bucket = "${local.state_bucket_prefix}${each.key}"
}

resource "minio_s3_bucket_versioning" "state" {
  for_each = minio_s3_bucket.state

  bucket = each.value.bucket

  versioning_configuration {
    status = "Enabled"
  }
}

resource "minio_iam_user" "domain" {
  for_each = local.domains

  name = "tofu-${each.key}"
}

resource "minio_iam_policy" "domain" {
  for_each = local.domains

  name = "tofu-${each.key}"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = [minio_s3_bucket.state[each.key].arn]
      },
      {
        # DeleteObject releases the use_lockfile lock
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = ["${minio_s3_bucket.state[each.key].arn}/*"]
      },
    ]
  })
}

resource "minio_iam_user_policy_attachment" "domain" {
  for_each = local.domains

  user_name   = minio_iam_user.domain[each.key].name
  policy_name = minio_iam_policy.domain[each.key].name
}
