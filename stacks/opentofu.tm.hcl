globals {
  # One state bucket per domain: <prefix><domain>; scripts/s3-state.sh creates it
  state_bucket_prefix = "tofu-state-"
  state_endpoint      = global.s3_url
  state_region        = global.s3_region

  # A stack gets the providers whose tags it carries; proxmox-root stacks use the proxmox provider too
  providers = {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.123.1"
      tags    = ["proxmox", "proxmox-root"]
    }
    time = {
      source  = "hashicorp/time"
      version = "0.14.2"
      tags    = ["time"]
    }
    http = {
      source  = "hashicorp/http"
      version = "3.6.3"
      tags    = ["http"]
    }
    keycloak = {
      source  = "keycloak/keycloak"
      version = "5.10.0"
      tags    = ["keycloak"]
    }
    dns = {
      source  = "hashicorp/dns"
      version = "3.6.2"
      tags    = ["dns"]
    }
    netbox = {
      source  = "e-breuninger/netbox"
      version = "6.0.1"
      tags    = ["netbox"]
    }
    opnsense = {
      source  = "browningluke/opnsense"
      version = "0.26.0"
      tags    = ["opnsense"]
    }
    truenas = {
      source  = "truenas/truenas"
      version = "1.9.3"
      tags    = ["truenas"]
    }
  }
}

generate_hcl "_terramate_generated_opentofu.tf" {
  lets {
    domain = tm_basename(tm_dirname(terramate.stack.path.absolute))
  }

  content {
    terraform {
      required_version = ">= 1.11.2"

      # The one required_providers block per stack: OpenTofu allows no second one
      tm_dynamic "required_providers" {
        attributes = {
          for name, p in global.providers : name => {
            source  = p.source
            version = p.version
          } if tm_length(tm_setintersection(p.tags, terramate.stack.tags)) > 0
        }
      }

      # The AWS SDK reads AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY (from the domain's SOPS file) from
      # the environment. Credentials stay out of this block because `tofu init` saves backend arguments
      # in plain text under .terraform/.
      backend "s3" {
        bucket                      = local.state_backend.bucket
        key                         = "${terramate.stack.path.basename}.tfstate"
        endpoints                   = local.state_backend.endpoints
        region                      = local.state_backend.region
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
        bucket                      = "${global.state_bucket_prefix}${let.domain}"
        endpoints                   = { s3 = global.state_endpoint }
        region                      = global.state_region
        use_path_style              = true
        use_lockfile                = true
        skip_credentials_validation = true
        skip_requesting_account_id  = true
        skip_metadata_api_check     = true
        skip_region_validation      = true
      }
    }

    variable "state_passphrase" {
      type      = string
      sensitive = true
      ephemeral = true
    }
  }
}
