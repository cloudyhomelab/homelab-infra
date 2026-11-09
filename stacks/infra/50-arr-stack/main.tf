locals {
  vms = yamldecode(file("${path.module}/../vms.yaml"))
}

data "terraform_remote_state" "image_catalog" {
  backend = "s3"
  config  = merge(local.state_backend, { key = "15-image-catalog.tfstate" })
}

module "arr-stack" {
  source = "git::https://github.com/cloudyhomelab/terraform-homelab-modules.git//cloudyhome-debian?ref=main"

  image = data.terraform_remote_state.image_catalog.outputs.latest[local.vms["arr-stack"]].image

  ca_server_url    = var.ca_server_url
  ca_sso_realm     = var.ca_sso_realm
  ca_sso_token_url = var.ca_sso_token_url
  age_secret       = var.age_secret

  config = {
    node         = "pve-infra-1"
    name         = "arr-stack"
    bridge       = "LabNet"
    dhcp         = true
    username     = var.vm_username
    user_id      = var.vm_user_id
    timezone     = var.timezone
    searchdomain = var.dns_zone
    reverse_zone = var.reverse_zone
  }
}
