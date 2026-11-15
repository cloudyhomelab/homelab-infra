assert {
  assertion = !(tm_contains(terramate.stack.tags, "proxmox") && tm_contains(terramate.stack.tags, "proxmox-root"))
  message   = "tags proxmox and proxmox-root are two ways of connecting to proxmox; use one"
}

generate_hcl "_terramate_generated_proxmox_root.tf" {
  condition = tm_contains(terramate.stack.tags, "proxmox-root")

  content {
    variable "proxmox_endpoint" {
      type = string
    }

    variable "proxmox_username" {
      description = "Admin user that creates the API token, as name@realm."
      type        = string
    }

    variable "proxmox_password" {
      description = "Password of proxmox_username; only the stack that creates the API token uses it."
      type        = string
      sensitive   = true
      ephemeral   = true
    }

    provider "proxmox" {
      endpoint = var.proxmox_endpoint
      username = var.proxmox_username
      password = var.proxmox_password

      insecure = true
    }
  }
}
