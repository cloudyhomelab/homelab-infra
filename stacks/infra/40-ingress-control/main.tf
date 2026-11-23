locals {
  workloads = yamldecode(file("${path.module}/../workloads.yaml"))

  # Keys of ../workloads.yaml created here => settings with the domain defaults
  vm = {
    for key in ["mgmt-ctl", "lab-ctl", "iot-ctl", "edge-ctl"] : key => merge(local.workloads.defaults, { name = key }, local.workloads.workloads[key])
    if merge(local.workloads.defaults, local.workloads.workloads[key]).create_vm
  }

  addresses = data.terraform_remote_state.vm_addresses.outputs.addresses

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
    for key in keys(local.vm) : key => merge(
      local.vm_defaults,
      { for field, value in local.vm[key] : field => value if !contains(["image", "image_version", "network", "create_vm"], field) },
      { bridge = data.terraform_remote_state.proxmox_base.outputs.bridges[local.vm[key].network] },
      {
        # 16-vm-addresses records static VMs in DNS; the module records only DHCP ones
        create_dns_record = local.vm[key].dhcp && try(local.vm[key].create_dns_record, true)
        ip4_address_cidr  = local.vm[key].dhcp ? null : local.addresses[key].ip4_address_cidr
        gateway           = local.vm[key].dhcp ? null : local.addresses[key].gateway
        dns_addresses     = local.vm[key].dhcp ? [] : local.addresses[key].dns_addresses
      },
    )
    if key != "edge-ctl"
  }

  edge_vm_config = {
    for key in keys(local.vm) : key => merge(
      local.vm_defaults,
      { for field, value in local.vm[key] : field => value if !contains(["image", "image_version", "network", "create_vm"], field) },
      { bridge = data.terraform_remote_state.proxmox_base.outputs.bridges[local.vm[key].network] },
      {
        # 16-vm-addresses records static VMs in DNS; the module records only DHCP ones
        create_dns_record = local.vm[key].dhcp && try(local.vm[key].create_dns_record, true)
        ip4_address_cidr  = local.vm[key].dhcp ? null : local.addresses[key].ip4_address_cidr
        gateway           = local.vm[key].dhcp ? null : local.addresses[key].gateway
        dns_addresses     = local.vm[key].dhcp ? [] : local.addresses[key].dns_addresses
      },
    )
    if key == "edge-ctl"
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
  for_each = merge(local.vm_config, local.edge_vm_config)

  index_base_url = local.image_index_url
  image          = local.workloads.workloads[each.key].image
  image_version  = local.workloads.workloads[each.key].image_version
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

module "edge_vm" {
  source   = "git::https://github.com/cloudyhomelab/terraform-homelab-modules.git//cloudyhome-debian?ref=main"
  for_each = local.edge_vm_config

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

  depends_on = [module.vm]
}
