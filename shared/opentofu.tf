terraform {
  required_version = ">= 1.11.2"

  # The AWS SDK reads AWS_ENDPOINT_URL_S3 and AWS_REGION (exported by the justfile) and
  # AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY (from the domain's SOPS file) from the environment.
  # Credentials stay out of this block because `tofu init` saves backend arguments in plain
  # text under .terraform/.
  backend "s3" {
    bucket                      = local.state_backend.bucket
    key                         = "${var.state_key}.tfstate"
    use_path_style              = local.state_backend.use_path_style
    use_lockfile                = local.state_backend.use_lockfile
    skip_credentials_validation = local.state_backend.skip_credentials_validation
    skip_requesting_account_id  = local.state_backend.skip_requesting_account_id
    skip_metadata_api_check     = local.state_backend.skip_metadata_api_check
    skip_region_validation      = local.state_backend.skip_region_validation
  }

  encryption {
    key_provider "pbkdf2" "state" {
      passphrase = var.state_passphrase
    }
    method "aes_gcm" "state" {
      keys = key_provider.pbkdf2.state
    }
    state {
      method   = method.aes_gcm.state
      enforced = true
    }
    plan {
      method   = method.aes_gcm.state
      enforced = true
    }
    remote_state_data_sources {
      default {
        method = method.aes_gcm.state
      }
    }
  }
}

locals {
  # Shared by the backend and terraform_remote_state reads of other stacks in the domain
  state_backend = {
    bucket                      = var.state_bucket
    use_path_style              = true
    use_lockfile                = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
  }
}

variable "state_bucket" {
  description = "The domain's state bucket, set by the justfile."
  type        = string
}

variable "state_key" {
  description = "The stack's path inside its domain, e.g. 10-proxmox-base, set by the justfile."
  type        = string
}

variable "state_passphrase" {
  type      = string
  sensitive = true
  ephemeral = true
}
