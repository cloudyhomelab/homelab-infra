locals {
  vms = yamldecode(file("${path.module}/../vms.yaml"))

  vm_defaults = {
    node         = "pve-infra-1"
    username     = var.vm_username
    user_id      = var.vm_user_id
    timezone     = var.timezone
    searchdomain = var.dns_zone
  }

  # VM name => settings over vm_defaults; name is the vms.yaml key, overridable
  vm_settings = {
    dns-secondary = {
      name              = "ns2"
      bridge            = "LabNet"
      dhcp              = false
      ip4_address_cidr  = "10.88.16.12/24"
      gateway           = "10.88.16.1"
      dns_addresses     = ["10.88.16.1"]
      create_dns_record = false
    }
  }
}

data "terraform_remote_state" "image_catalog" {
  backend = "s3"
  config  = merge(local.state_backend, { key = "15-image-catalog.tfstate" })
}

module "vm" {
  source   = "git::https://github.com/cloudyhomelab/terraform-homelab-modules.git//cloudyhome-debian?ref=main"
  for_each = local.vm_settings

  image = data.terraform_remote_state.image_catalog.outputs.latest[local.vms[each.key]].image

  ca_server_url    = var.ca_server_url
  ca_sso_realm     = var.ca_sso_realm
  ca_sso_token_url = var.ca_sso_token_url
  age_secret       = var.age_secret

  config = merge(local.vm_defaults, { name = each.key }, each.value)
}
