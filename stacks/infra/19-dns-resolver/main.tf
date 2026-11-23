locals {
  vms = yamldecode(file("${path.module}/../vms.yaml"))

  # Keys of ../vms.yaml created here => settings with the domain defaults
  vm = { for key in ["resolver2"] : key => merge(local.vms.defaults, { name = key }, local.vms.vms[key]) }

  addresses = data.terraform_remote_state.vm_addresses.outputs.addresses

  vm_defaults = {
    username     = var.vm_username
    user_id      = var.vm_user_id
    timezone     = var.timezone
    searchdomain = var.dns_zone
  }

  vm_config = {
    for key, vm in local.vm : key => merge(
      local.vm_defaults,
      { for field, value in vm : field => value if !contains(["image", "image_version", "network"], field) },
      { bridge = data.terraform_remote_state.proxmox_base.outputs.bridges[vm.network] },
      {
        # 16-vm-addresses records static VMs in DNS; the module records only DHCP ones
        create_dns_record = vm.dhcp && try(vm.create_dns_record, true)
        ip4_address_cidr  = vm.dhcp ? null : local.addresses[key].ip4_address_cidr
        gateway           = vm.dhcp ? null : local.addresses[key].gateway
        dns_addresses     = vm.dhcp ? [] : local.addresses[key].dns_addresses
      },
    )
  }
}

data "terraform_remote_state" "vm_addresses" {
  backend = "s3"
  config  = merge(local.state_backend, { key = "16-vm-addresses.tfstate" })
}

data "terraform_remote_state" "proxmox_base" {
  backend = "s3"
  config  = merge(local.state_backend, { key = "10-proxmox-base.tfstate" })
}

module "image_index" {
  source   = "git::https://github.com/cloudyhomelab/terraform-homelab-modules.git//cloudyhome-image-index?ref=main"
  for_each = local.vm_config

  index_base_url = local.image_index_url
  image          = local.vms.vms[each.key].image
  image_version  = local.vms.vms[each.key].image_version
}

module "image" {
  source   = "git::https://github.com/cloudyhomelab/terraform-homelab-modules.git//cloudyhome-proxmox-image?ref=main"
  for_each = module.image_index

  config = each.value.download
}

module "vm" {
  source   = "git::https://github.com/cloudyhomelab/terraform-homelab-modules.git//cloudyhome-debian?ref=main"
  for_each = local.vm_config

  image = {
    file_name    = module.image[each.key].file_name
    content_type = module.image[each.key].content_type
    datastore_id = module.image[each.key].datastore_id
  }

  ca_server_url    = var.ca_server_url
  ca_sso_realm     = var.ca_sso_realm
  ca_sso_token_url = var.ca_sso_token_url
  age_secret       = var.age_secret

  config = each.value
}
