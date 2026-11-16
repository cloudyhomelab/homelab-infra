generate_hcl "_terramate_generated_proxmox.tf" {
  condition = tm_contains(terramate.stack.tags, "proxmox")

  content {
    variable "proxmox_endpoint" {
      type = string
    }

    variable "proxmox_ssh_private_key" {
      type      = string
      sensitive = true
      ephemeral = true
    }

    data "terraform_remote_state" "proxmox_init" {
      backend = "s3"
      config  = merge(local.state_backend, { key = "00-proxmox-init.tfstate" })
    }

    provider "proxmox" {
      endpoint  = var.proxmox_endpoint
      api_token = data.terraform_remote_state.proxmox_init.outputs.user_token

      insecure = true
      ssh {
        agent       = false
        private_key = var.proxmox_ssh_private_key
        username    = "root"
      }
    }
  }
}

# Shared with proxmox-root stacks; the assert in provider_proxmox_root.tm.hcl keeps the tags exclusive
generate_hcl "_terramate_generated_proxmox.auto.tfvars" {
  condition = tm_contains(terramate.stack.tags, "proxmox") || tm_contains(terramate.stack.tags, "proxmox-root")

  content {
    proxmox_endpoint = global.pve_endpoints[global.pve_type]
  }
}
