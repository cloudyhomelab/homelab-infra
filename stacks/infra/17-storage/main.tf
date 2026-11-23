locals {
  vms = yamldecode(file("${path.module}/../vms.yaml"))
  vm  = { for key, settings in local.vms.vms : key => merge(local.vms.defaults, settings) }

  addresses = data.terraform_remote_state.vm_addresses.outputs.addresses
}

data "terraform_remote_state" "vm_addresses" {
  backend = "s3"
  config  = merge(local.state_backend, { key = "16-vm-addresses.tfstate" })
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

  # Keyed by image type: two entries of one type in a domain fail here as a duplicate key
  images = {
    for key, vm in local.vm : vm.image => {
      type    = split("/", vm.image)[1]
      storage = module.image_index[key].storage
    }
  }

  clients = {
    for key, vm in local.vm : key => {
      image   = vm.image
      address = vm.dhcp ? null : try(split("/", local.addresses[key].ip4_address_cidr)[0], null)
    }
  }
}

output "shares" {
  description = "<app>/<dataset> => dataset name, share path and allowed hosts."
  value       = module.storage.shares
}
