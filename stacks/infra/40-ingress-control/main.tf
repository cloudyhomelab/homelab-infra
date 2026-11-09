locals {
  vms = yamldecode(file("${path.module}/../vms.yaml"))

  vm_defaults = {
    username     = var.vm_username
    user_id      = var.vm_user_id
    timezone     = var.timezone
    searchdomain = var.dns_zone
    reverse_zone = var.reverse_zone
  }

  # Keys of ../vms.yaml created here => module config; edge-ctl separate for its depends_on,
  # which cannot point at sibling for_each instances
  vm_config = {
    for key in ["mgmt-ctl", "lab-ctl", "iot-ctl"] : key => merge(
      local.vm_defaults,
      local.vms.defaults,
      { name = key },
      { for field, value in local.vms.vms[key] : field => value if field != "image" },
    )
  }

  edge_vm_config = {
    for key in ["edge-ctl"] : key => merge(
      local.vm_defaults,
      local.vms.defaults,
      { name = key },
      { for field, value in local.vms.vms[key] : field => value if field != "image" },
    )
  }
}

data "terraform_remote_state" "image_catalog" {
  backend = "s3"
  config  = merge(local.state_backend, { key = "15-image-catalog.tfstate" })
}

module "vm" {
  source   = "git::https://github.com/cloudyhomelab/terraform-homelab-modules.git//cloudyhome-debian?ref=main"
  for_each = local.vm_config

  image = data.terraform_remote_state.image_catalog.outputs.latest[local.vms.vms[each.key].image].image

  ca_server_url    = var.ca_server_url
  ca_sso_realm     = var.ca_sso_realm
  ca_sso_token_url = var.ca_sso_token_url
  age_secret       = var.age_secret

  config = each.value
}

module "edge_vm" {
  source   = "git::https://github.com/cloudyhomelab/terraform-homelab-modules.git//cloudyhome-debian?ref=main"
  for_each = local.edge_vm_config

  image = data.terraform_remote_state.image_catalog.outputs.latest[local.vms.vms[each.key].image].image

  ca_server_url    = var.ca_server_url
  ca_sso_realm     = var.ca_sso_realm
  ca_sso_token_url = var.ca_sso_token_url
  age_secret       = var.age_secret

  config = each.value

  depends_on = [module.vm]
}
