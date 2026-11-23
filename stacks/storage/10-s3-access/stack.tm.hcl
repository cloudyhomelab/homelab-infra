stack {
  id          = "42094dfb-527d-4626-aba8-e6791cba7ac4"
  name        = "10-s3-access"
  description = "State buckets, and one S3 user and policy per domain"
  tags        = ["minio"]
  before      = ["/stacks/edge", "/stacks/network", "/stacks/infra"]
  watch = [
    "/stacks/storage/s3-access.yaml",
  ]
}

globals {
  uses = ["state_bucket_prefix", "image_pin"]
}
