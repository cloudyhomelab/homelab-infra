locals {
  vms = yamldecode(file("${path.module}/../vms.yaml"))
  vm  = { for key, settings in local.vms.vms : key => merge(local.vms.defaults, settings) }

  dhcp_with_storage = sort([for key, vm in local.vm : key if vm.dhcp && length(module.image_index[key].storage) > 0])
}

module "image_index" {
  source   = "git::https://github.com/cloudyhomelab/terraform-homelab-modules.git//cloudyhome-image-index?ref=main"
  for_each = local.vm

  index_base_url = local.image_index_url
  image          = local.vms.vms[each.key].image
  image_version  = local.vms.vms[each.key].image_version
}

module "storage" {
  source = "git::https://github.com/cloudyhomelab/terraform-homelab-modules.git//cloudyhome-truenas-app-storage?ref=main"

  root = var.truenas_app_data_root

  clients = {
    for key, vm in local.vm : key => {
      storage = module.image_index[key].storage
      address = vm.dhcp ? null : split("/", vm.ip4_address_cidr)[0]
    }
  }
}

output "shares" {
  description = "<app>/<dataset> => dataset name, share path and allowed hosts."
  value       = module.storage.shares

  precondition {
    condition     = length(local.dhcp_with_storage) == 0
    error_message = "VMs ${join(", ", local.dhcp_with_storage)} use DHCP but their images need storage; shares allow hosts by static address only."
  }
}
