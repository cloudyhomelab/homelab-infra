# S3 only, against the lab's S3-compatible server. Credentials come from AWS_ACCESS_KEY_ID /
# AWS_SECRET_ACCESS_KEY in the environment, the same domain key the state backend uses.
generate_hcl "_terramate_generated_aws.tf" {
  condition = tm_contains(terramate.stack.tags, "aws")

  content {
    provider "aws" {
      region                      = global.s3_region
      s3_use_path_style           = true
      skip_credentials_validation = true
      skip_requesting_account_id  = true
      skip_metadata_api_check     = true
      skip_region_validation      = true

      endpoints {
        s3 = global.s3_url
      }
    }
  }
}
