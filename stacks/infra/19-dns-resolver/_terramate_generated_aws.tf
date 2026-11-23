// TERRAMATE: GENERATED AUTOMATICALLY DO NOT EDIT

provider "aws" {
  region                      = "home"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_requesting_account_id  = true
  endpoints {
    s3 = "http://moria.ip.cloudyhome.net:9000"
  }
}
