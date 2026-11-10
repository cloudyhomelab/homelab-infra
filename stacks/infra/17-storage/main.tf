locals {
  vms = yamldecode(file("${path.module}/../vms.yaml"))
  vm  = { for key, settings in local.vms.vms : key => merge(local.vms.defaults, settings) }

  addresses = data.terraform_remote_state.vm_addresses.outputs.addresses
}

data "terraform_remote_state" "image_catalog" {
  backend = "s3"
  config  = merge(local.state_backend, { key = "15-image-catalog.tfstate" })
}

data "terraform_remote_state" "vm_addresses" {
  backend = "s3"
  config  = merge(local.state_backend, { key = "16-vm-addresses.tfstate" })
}

module "storage" {
  source = "git::https://github.com/cloudyhomelab/terraform-homelab-modules.git//cloudyhome-truenas-app-storage?ref=main"

  root   = var.truenas_app_data_root
  images = data.terraform_remote_state.image_catalog.outputs.latest

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
