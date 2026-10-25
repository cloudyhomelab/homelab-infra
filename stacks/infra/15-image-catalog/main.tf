module "images" {
  source = "git::https://github.com/cloudyhomelab/terraform-homelab-modules.git//cloudyhome-proxmox-image-catalog?ref=main"

  index_base_url = "https://s3-api.cloudyhome.net/os-image-staging"
  images         = yamldecode(file("${path.module}/images.yaml"))
}

output "latest" {
  description = "Newest build of every image type, keyed by <os>/<type>; read by VM stacks."
  value       = module.images.latest
}
