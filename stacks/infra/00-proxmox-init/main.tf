module "proxmox_init" {
  source          = "git::https://github.com/cloudyhomelab/terraform-homelab-modules.git//cloudyhome-proxmox-init?ref=main"
  expiration_date = "2027-01-01T00:00:00Z"
}

output "user_token" {
  value     = module.proxmox_init.user_token
  sensitive = true
}
