output "s3_keys" {
  description = "S3 access key and secret key per domain; just s3-key copies one into the domain's secrets file."
  value = {
    for key, user in minio_iam_user.domain : key => {
      access_key = user.name
      secret_key = user.secret
    }
  }
  sensitive = true
}
