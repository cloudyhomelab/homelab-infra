locals {
  vms = yamldecode(file("${path.module}/../vms.yaml"))

  # Keys of ../vms.yaml created here => settings with the domain defaults
  vm = { for key in ["mgmt-ctl", "lab-ctl", "iot-ctl", "edge-ctl"] : key => merge(local.vms.defaults, { name = key }, local.vms.vms[key]) }

  vm_defaults = {
    username     = var.vm_username
    user_id      = var.vm_user_id
    timezone     = var.timezone
    searchdomain = var.dns_zone
    reverse_zone = var.reverse_zone
  }

  # Keys of local.vm => module config; edge-ctl separate for its depends_on,
  # which cannot point at sibling for_each instances
  vm_config = {
    for key in ["mgmt-ctl", "lab-ctl", "iot-ctl"] : key => merge(
      local.vm_defaults,
      { for field, value in local.vm[key] : field => value if !contains(["image", "network"], field) },
      { bridge = data.terraform_remote_state.proxmox_base.outputs.bridges[local.vm[key].network] },
      {
        ip4_address_cidr = try(module.address[key].ip4_address_cidr, null)
        gateway          = try(module.address[key].gateway, null)
        dns_addresses    = try(module.address[key].dns_addresses, [])
      },
    )
  }

  edge_vm_config = {
    for key in ["edge-ctl"] : key => merge(
      local.vm_defaults,
      { for field, value in local.vm[key] : field => value if !contains(["image", "network"], field) },
      { bridge = data.terraform_remote_state.proxmox_base.outputs.bridges[local.vm[key].network] },
      {
        ip4_address_cidr = try(module.address[key].ip4_address_cidr, null)
        gateway          = try(module.address[key].gateway, null)
        dns_addresses    = try(module.address[key].dns_addresses, [])
      },
    )
  }
}

module "address" {
  source   = "../../../shared/modules/vm-address"
  for_each = { for key, vm in local.vm : key => vm if !vm.dhcp }

  network          = each.value.network
  dns_name         = "${each.value.name}.${var.dns_zone}"
  ip4_address_cidr = try(each.value.ip4_address_cidr, null)
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

module "edge_vm" {
  source   = "git::https://github.com/cloudyhomelab/terraform-homelab-modules.git//cloudyhome-debian?ref=main"
  for_each = local.edge_vm_config

  image = data.terraform_remote_state.image_catalog.outputs.latest[local.vms.vms[each.key].image].image

  ca_server_url    = var.ca_server_url
  ca_sso_realm     = var.ca_sso_realm
  ca_sso_token_url = var.ca_sso_token_url
  age_secret       = var.age_secret

  config = each.value

  depends_on = [module.vm]
}
