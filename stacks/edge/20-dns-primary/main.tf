locals {
  vms = yamldecode(file("${path.module}/../vms.yaml"))

  vm_defaults = {
    username     = var.vm_username
    user_id      = var.vm_user_id
    timezone     = var.timezone
    searchdomain = var.dns_zone
  }

  # Keys of ../vms.yaml created here => module config
  vm_config = {
    for key in ["dns-primary"] : key => merge(
      local.vm_defaults,
      local.vms.defaults,
      { name = key },
      { for field, value in local.vms.vms[key] : field => value if !contains(["image", "network"], field) },
      { bridge = data.terraform_remote_state.proxmox_base.outputs.bridges[local.vms.vms[key].network] },
    )
  }

  forward_zones = toset([trimsuffix(var.dns_zone, "."), trimsuffix(var.reverse_zone, ".")])
}

data "terraform_remote_state" "proxmox_base" {
  backend = "s3"
  config  = merge(local.state_backend, { key = "10-proxmox-base.tfstate" })
}

data "terraform_remote_state" "image_catalog" {
  backend = "s3"
  config  = merge(local.state_backend, { key = "15-image-catalog.tfstate" })
}

module "vm" {
  source   = "git::https://github.com/cloudyhomelab/terraform-homelab-modules.git//cloudyhome-debian?ref=main"
  for_each = local.vm_config

  image = data.terraform_remote_state.image_catalog.outputs.latest[local.vms.vms[each.key].image].image

  ca_server_url    = var.ca_server_url
  ca_sso_realm     = var.ca_sso_realm
  ca_sso_token_url = var.ca_sso_token_url
  age_secret       = var.age_secret

  config = each.value
}

resource "opnsense_unbound_forward" "this" {
  for_each = local.forward_zones

  domain    = each.key
  server_ip = module.vm["dns-primary"].vm_ipv4_address
}
