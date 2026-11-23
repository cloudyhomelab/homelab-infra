# Admin access to the lab's MinIO server, for the stack that manages S3 buckets and access
generate_hcl "_terramate_generated_minio.tf" {
  condition = tm_contains(terramate.stack.tags, "minio")

  content {
    variable "minio_user" {
      type      = string
      sensitive = true
      ephemeral = true
    }

    variable "minio_password" {
      type      = string
      sensitive = true
      ephemeral = true
    }

    provider "minio" {
      minio_server   = global.s3_host
      minio_ssl      = global.s3_ssl
      minio_region   = global.s3_region
      minio_user     = var.minio_user
      minio_password = var.minio_password
    }
  }
}
