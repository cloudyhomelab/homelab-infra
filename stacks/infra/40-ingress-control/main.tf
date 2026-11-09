locals {
  vms = yamldecode(file("${path.module}/../vms.yaml"))
}

data "terraform_remote_state" "image_catalog" {
  backend = "s3"
  config  = merge(local.state_backend, { key = "15-image-catalog.tfstate" })
}

module "mgmt-ctl" {
  source = "git::https://github.com/cloudyhomelab/terraform-homelab-modules.git//cloudyhome-debian?ref=main"

  image = data.terraform_remote_state.image_catalog.outputs.latest[local.vms["mgmt-ctl"]].image

  ca_server_url    = var.ca_server_url
  ca_sso_realm     = var.ca_sso_realm
  ca_sso_token_url = var.ca_sso_token_url
  age_secret       = var.age_secret

  config = {
    node         = "pve-infra-1"
    name         = "mgmt-ctl"
    bridge       = "vmbr0"
    dhcp         = true
    username     = var.vm_username
    user_id      = var.vm_user_id
    timezone     = var.timezone
    searchdomain = var.dns_zone
    reverse_zone = var.reverse_zone
  }
}

module "lab-ctl" {
  source = "git::https://github.com/cloudyhomelab/terraform-homelab-modules.git//cloudyhome-debian?ref=main"

  image = data.terraform_remote_state.image_catalog.outputs.latest[local.vms["lab-ctl"]].image

  ca_server_url    = var.ca_server_url
  ca_sso_realm     = var.ca_sso_realm
  ca_sso_token_url = var.ca_sso_token_url
  age_secret       = var.age_secret

  config = {
    node         = "pve-infra-1"
    name         = "lab-ctl"
    bridge       = "LabNet"
    dhcp         = true
    username     = var.vm_username
    user_id      = var.vm_user_id
    timezone     = var.timezone
    searchdomain = var.dns_zone
    reverse_zone = var.reverse_zone
  }
}

module "iot-ctl" {
  source = "git::https://github.com/cloudyhomelab/terraform-homelab-modules.git//cloudyhome-debian?ref=main"

  image = data.terraform_remote_state.image_catalog.outputs.latest[local.vms["iot-ctl"]].image

  ca_server_url    = var.ca_server_url
  ca_sso_realm     = var.ca_sso_realm
  ca_sso_token_url = var.ca_sso_token_url
  age_secret       = var.age_secret

  config = {
    node         = "pve-infra-1"
    name         = "iot-ctl"
    bridge       = "IoTNet"
    dhcp         = true
    username     = var.vm_username
    user_id      = var.vm_user_id
    timezone     = var.timezone
    searchdomain = var.dns_zone
    reverse_zone = var.reverse_zone
  }
}

module "edge-ctl" {
  source = "git::https://github.com/cloudyhomelab/terraform-homelab-modules.git//cloudyhome-debian?ref=main"

  image = data.terraform_remote_state.image_catalog.outputs.latest[local.vms["edge-ctl"]].image

  ca_server_url    = var.ca_server_url
  ca_sso_realm     = var.ca_sso_realm
  ca_sso_token_url = var.ca_sso_token_url
  age_secret       = var.age_secret

  config = {
    node             = "pve-infra-1"
    name             = "edge-ctl"
    bridge           = "vmbr0"
    dhcp             = false
    ip4_address_cidr = "10.88.0.211/24"
    gateway          = "10.88.0.1"
    dns_addresses    = ["10.88.0.1"]
    username         = var.vm_username
    user_id          = var.vm_user_id
    timezone         = var.timezone
    searchdomain     = var.dns_zone
    reverse_zone     = var.reverse_zone
  }

  depends_on = [
    module.mgmt-ctl,
    module.lab-ctl,
    module.iot-ctl,
  ]
}
