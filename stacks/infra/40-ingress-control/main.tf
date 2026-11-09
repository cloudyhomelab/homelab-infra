locals {
  vms = yamldecode(file("${path.module}/../vms.yaml"))

  vm_defaults = {
    node         = "pve-infra-1"
    username     = var.vm_username
    user_id      = var.vm_user_id
    timezone     = var.timezone
    searchdomain = var.dns_zone
    reverse_zone = var.reverse_zone
  }

  # VM name => settings over vm_defaults; name is the vms.yaml key, overridable
  vm_settings = {
    mgmt-ctl = {
      bridge = "vmbr0"
      dhcp   = true
    }
    lab-ctl = {
      bridge = "LabNet"
      dhcp   = true
    }
    iot-ctl = {
      bridge = "IoTNet"
      dhcp   = true
    }
  }

  # Separate from vm_settings for its depends_on, which cannot point at sibling for_each instances
  edge_vm_settings = {
    edge-ctl = {
      bridge           = "vmbr0"
      dhcp             = false
      ip4_address_cidr = "10.88.0.211/24"
      gateway          = "10.88.0.1"
      dns_addresses    = ["10.88.0.1"]
    }
  }
}

data "terraform_remote_state" "image_catalog" {
  backend = "s3"
  config  = merge(local.state_backend, { key = "15-image-catalog.tfstate" })
}

module "vm" {
  source   = "git::https://github.com/cloudyhomelab/terraform-homelab-modules.git//cloudyhome-debian?ref=main"
  for_each = local.vm_settings

  image = data.terraform_remote_state.image_catalog.outputs.latest[local.vms[each.key]].image

  ca_server_url    = var.ca_server_url
  ca_sso_realm     = var.ca_sso_realm
  ca_sso_token_url = var.ca_sso_token_url
  age_secret       = var.age_secret

  config = merge(local.vm_defaults, { name = each.key }, each.value)
}

module "edge_vm" {
  source   = "git::https://github.com/cloudyhomelab/terraform-homelab-modules.git//cloudyhome-debian?ref=main"
  for_each = local.edge_vm_settings

  image = data.terraform_remote_state.image_catalog.outputs.latest[local.vms[each.key]].image

  ca_server_url    = var.ca_server_url
  ca_sso_realm     = var.ca_sso_realm
  ca_sso_token_url = var.ca_sso_token_url
  age_secret       = var.age_secret

  config = merge(local.vm_defaults, { name = each.key }, each.value)

  depends_on = [module.vm]
}
