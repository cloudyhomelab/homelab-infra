locals {
  vms = yamldecode(file("${path.module}/../vms.yaml"))
  vm  = { for key, settings in local.vms.vms : key => merge(local.vms.defaults, settings) }
}

data "terraform_remote_state" "image_catalog" {
  backend = "s3"
  config  = merge(local.state_backend, { key = "15-image-catalog.tfstate" })
}

module "storage" {
  source = "../../../shared/modules/cloudyhome-truenas-app-storage"

  root   = var.truenas_app_data_root
  images = data.terraform_remote_state.image_catalog.outputs.latest

  clients = {
    for key, vm in local.vm : key => {
      image   = vm.image
      address = vm.dhcp ? null : try(split("/", vm.ip4_address_cidr)[0], null)
    }
  }
}

output "shares" {
  description = "<app>/<dataset> => dataset name, share path and allowed hosts."
  value       = module.storage.shares
}
