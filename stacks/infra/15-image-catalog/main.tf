locals {
  vms = yamldecode(file("${path.module}/../vms.yaml"))

  # <os>/<type> keys of ../vms.yaml => os => types, the shape the module takes
  images = {
    for key in distinct([for vm in values(local.vms.vms) : vm.image]) :
    split("/", key)[0] => split("/", key)[1]...
  }
}

module "images" {
  source = "git::https://github.com/cloudyhomelab/terraform-homelab-modules.git//cloudyhome-proxmox-image-catalog?ref=main"

  index_base_url = "${local.s3_url}/os-image-staging"
  images         = local.images
  keep_latest    = 1
}

output "latest" {
  description = "Newest build of every image type, keyed by <os>/<type>; read by VM stacks."
  value       = module.images.latest
}
