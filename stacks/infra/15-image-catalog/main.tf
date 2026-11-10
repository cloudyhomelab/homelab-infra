module "images" {
  source = "git::https://github.com/cloudyhomelab/terraform-homelab-modules.git//cloudyhome-proxmox-image-catalog?ref=main"

  index_base_url = "${local.s3_url}/os-image-staging"
  images         = yamldecode(file("${path.module}/images.yaml"))
  keep_latest    = 1
}

output "latest" {
  description = "Newest build of every image type, keyed by <os>/<type>; read by VM stacks."
  value       = module.images.latest
}
