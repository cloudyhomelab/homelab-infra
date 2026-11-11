locals {
  vms = yamldecode(file("${path.module}/../vms.yaml"))

  # Keys of ../vms.yaml created here => settings with the domain defaults
  vm = { for key in ["homeassistant"] : key => merge(local.vms.defaults, { name = key }, local.vms.vms[key]) }

  addresses = data.terraform_remote_state.vm_addresses.outputs.addresses

  vm_defaults = {
    username     = var.vm_username
    user_id      = var.vm_user_id
    timezone     = var.timezone
    searchdomain = var.dns_zone
    reverse_zone = var.reverse_zone
  }

  vm_config = {
    for key, vm in local.vm : key => merge(
      local.vm_defaults,
      { for field, value in vm : field => value if !contains(["image", "network"], field) },
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
