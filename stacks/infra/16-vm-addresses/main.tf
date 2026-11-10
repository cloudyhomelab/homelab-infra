locals {
  vms = yamldecode(file("${path.module}/../vms.yaml"))

  # Reserved here, ahead of the VM stacks, so 17-storage can allow each VM on its NFS shares by address
  # and the address survives rebuilding the VM
  vm = {
    for key, settings in local.vms.vms : key => merge(local.vms.defaults, { name = key }, settings)
    if !merge(local.vms.defaults, settings).dhcp
  }
}

module "address" {
  source   = "../../../shared/modules/vm-address"
  for_each = local.vm

  network          = each.value.network
  dns_name         = "${each.value.name}.${var.dns_zone}"
  ip4_address_cidr = try(each.value.ip4_address_cidr, null)
}

module "dns_record" {
  source   = "git::https://github.com/cloudyhomelab/terraform-homelab-modules.git//cloudyhome-dns-record?ref=main"
  for_each = { for key, vm in local.vm : key => vm if try(vm.create_dns_record, true) }

  config = {
    name         = each.value.name
    zone         = var.dns_zone
    ipv4         = split("/", module.address[each.key].ip4_address_cidr)[0]
    reverse_zone = var.reverse_zone
  }
}
