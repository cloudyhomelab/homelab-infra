module "images" {
  source = "git::https://github.com/cloudyhomelab/terraform-homelab-modules.git//cloudyhome-proxmox-image-catalog?ref=main"

  index_base_url = "${local.s3_url}/os-image-staging"
  images         = yamldecode(file("${path.module}/images.yaml"))
}
