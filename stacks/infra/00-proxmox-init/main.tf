resource "time_rotating" "token" {
  rotation_days = var.token_rotation_days
}

locals {
  token_expiration = timeadd(time_rotating.token.rotation_rfc3339, "${var.token_grace_days * 24}h")
}

module "proxmox_init" {
  source          = "git::https://github.com/cloudyhomelab/terraform-homelab-modules.git//cloudyhome-proxmox-init?ref=main"
  expiration_date = local.token_expiration
  # A new name per rotation forces a new token; changing only the expiry would keep the old secret
  token_name = "terraform-${formatdate("YYYYMMDD", time_rotating.token.id)}"
}

output "user_token" {
  value     = module.proxmox_init.user_token
  sensitive = true
}
