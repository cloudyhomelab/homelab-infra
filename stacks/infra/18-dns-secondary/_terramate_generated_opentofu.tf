// TERRAMATE: GENERATED AUTOMATICALLY DO NOT EDIT

terraform {
  required_version = ">= 1.11.2"
  required_providers {
    dns = {
      source  = "hashicorp/dns"
      version = "3.6.2"
    }
    keycloak = {
      source  = "keycloak/keycloak"
      version = "5.9.0"
    }
    opnsense = {
      source  = "browningluke/opnsense"
      version = "0.26.0"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.115.0"
    }
  }
  backend "s3" {
    bucket                      = local.state_backend.bucket
    endpoints                   = local.state_backend.endpoints
    key                         = "18-dns-secondary.tfstate"
    region                      = local.state_backend.region
    skip_credentials_validation = local.state_backend.skip_credentials_validation
    skip_metadata_api_check     = local.state_backend.skip_metadata_api_check
    skip_region_validation      = local.state_backend.skip_region_validation
    skip_requesting_account_id  = local.state_backend.skip_requesting_account_id
    use_lockfile                = local.state_backend.use_lockfile
    use_path_style              = local.state_backend.use_path_style
  }
  encryption {
    key_provider "pbkdf2" "state" {
      passphrase = var.state_passphrase
    }
    method "aes_gcm" "state" {
      keys = key_provider.pbkdf2.state
    }
    state {
      enforced = true
      method   = method.aes_gcm.state
    }
    plan {
      enforced = true
      method   = method.aes_gcm.state
    }
    remote_state_data_sources {
      default {
        method = method.aes_gcm.state
      }
    }
  }
}
locals {
  state_backend = {
    bucket = "tofu-state-infra"
    endpoints = {
      s3 = "http://moria.ip.cloudyhome.net:9000"
    }
    region                      = "home"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    use_lockfile                = true
    use_path_style              = true
  }
}
variable "state_passphrase" {
  ephemeral = true
  sensitive = true
  type      = string
}
