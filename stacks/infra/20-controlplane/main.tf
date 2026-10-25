data "terraform_remote_state" "image_catalog" {
  backend = "s3"
  config  = merge(local.state_backend, { key = "15-image-catalog.tfstate" })
}

module "controlplane" {
  source = "git::https://github.com/cloudyhomelab/terraform-homelab-modules.git//cloudyhome-debian?ref=main"

  image = data.terraform_remote_state.image_catalog.outputs.latest["debian/debian-controlplane"].image

  ca_server_url    = var.ca_server_url
  ca_sso_realm     = var.ca_sso_realm
  ca_sso_token_url = var.ca_sso_token_url
  age_secret       = var.age_secret

  config = {
    node         = "pve-infra-1"
    name         = "controlplane"
    bridge       = "vmbr0"
    dhcp         = true
    cpu          = "host"
    cores        = 2
    memory       = 6144
    disk_size    = 50
    username     = var.vm_username
    user_id      = var.vm_user_id
    timezone     = var.timezone
    searchdomain = var.dns_zone
  }
}
