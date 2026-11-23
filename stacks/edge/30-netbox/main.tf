locals {
  workloads = yamldecode(file("${path.module}/../workloads.yaml"))

  vm_defaults = {
    username     = var.vm_username
    user_id      = var.vm_user_id
    timezone     = var.timezone
    searchdomain = var.dns_zone
    reverse_zone = var.reverse_zone
  }

  # Keys of ../workloads.yaml created here => module config
  vm_config = {
    for key in ["netbox"] : key => merge(
      local.vm_defaults,
      local.workloads.defaults,
      { name = key },
      { for field, value in local.workloads.workloads[key] : field => value if !contains(["image", "image_version", "network", "create_vm"], field) },
      { bridge = data.terraform_remote_state.proxmox_base.outputs.bridges[local.workloads.workloads[key].network] },
    )
    if merge(local.workloads.defaults, local.workloads.workloads[key]).create_vm
  }
}

data "terraform_remote_state" "proxmox_base" {
  backend = "s3"
  config  = merge(local.state_backend, { key = "10-proxmox-base.tfstate" })
}

module "image_index" {
  source   = "git::https://github.com/cloudyhomelab/terraform-homelab-modules.git//cloudyhome-image-index?ref=main"
  for_each = local.vm_config

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
