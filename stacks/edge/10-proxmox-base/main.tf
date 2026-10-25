data "proxmox_virtual_environment_nodes" "this" {}

module "proxmox_setup" {
  source   = "git::https://github.com/cloudyhomelab/terraform-homelab-modules.git//cloudyhome-proxmox-setup?ref=main"
  timezone = var.timezone
}

import {
  to = module.proxmox_setup.proxmox_storage_directory.this
  id = "local"
}

import {
  to = module.proxmox_setup.proxmox_storage_lvmthin.this
  id = "local-lvm"
}

import {
  for_each = {
    for pair in setproduct(data.proxmox_virtual_environment_nodes.this.names, local.preinstalled_apt_repositories) :
    "${pair[0]}/${pair[1]}" => "${pair[0]},${pair[1]}"
  }
  to = module.proxmox_setup.proxmox_apt_standard_repository.this[each.key]
  id = each.value
}
