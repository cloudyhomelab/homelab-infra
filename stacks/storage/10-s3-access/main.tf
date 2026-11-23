locals {
  domains       = yamldecode(file("${path.module}/../s3-access.yaml")).domains
  state_buckets = toset(concat(["storage"], keys(local.domains)))
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

locals {
  state_statements = {
    for key in keys(local.domains) : key => [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = [minio_s3_bucket.state[key].arn]
      },
      {
        # DeleteObject releases the use_lockfile lock
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = ["${minio_s3_bucket.state[key].arn}/*"]
      },
    ]
  }

  image_pin_statements = {
    for key, domain in local.domains : key => [
      {
        # Without ListBucket a missing pin reads as 403, not 404, and its refresh fails instead of re-creating it
        Effect    = "Allow"
        Action    = ["s3:ListBucket"]
        Resource  = ["arn:aws:s3:::${local.image_pin.bucket}"]
        Condition = { StringLike = { "s3:prefix" = ["${local.image_pin.prefix}/${key}/*"] } }
      },
      {
        # aws_s3_object reads the object's tags on every refresh
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:GetObjectTagging", "s3:PutObjectTagging"]
        Resource = ["arn:aws:s3:::${local.image_pin.bucket}/${local.image_pin.prefix}/${key}/*"]
      },
    ] if try(domain.image_pins, false)
  }
}

resource "minio_iam_policy" "domain" {
  for_each = local.domains

  name = "tofu-${each.key}"
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = concat(local.state_statements[each.key], lookup(local.image_pin_statements, each.key, []))
  })
}

resource "minio_iam_user_policy_attachment" "domain" {
  for_each = local.domains

  user_name   = minio_iam_user.domain[each.key].name
  policy_name = minio_iam_policy.domain[each.key].name
}
