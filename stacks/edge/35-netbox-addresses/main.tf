locals {
  zones = yamldecode(file("${path.module}/../bootstrap-static-dns.yaml"))
  vms   = yamldecode(file("${path.module}/../vms.yaml"))

  # The file, not NetBox: network/10-ipam creates the prefixes after this domain, and NetBox nests
  # addresses under prefixes by containment whenever they appear
  ipam = yamldecode(file("${path.module}/../../../global-data/ipam.yaml"))

  active_prefixes = concat(
    flatten([for vlans in values(local.ipam.vlan_groups) : [for vlan in values(vlans) : vlan.prefix if vlan.prefix != null]]),
    [for prefix, config in local.ipam.prefixes : prefix if config.status == "active"],
  )

  a_records = flatten([
    for zone, names in local.zones : [
      for name, record in names : [
        for address in record.a : {
          address  = address
          dns_name = "${name}.${trimsuffix(zone, ".")}"
        }
      ]
    ]
  ])

  vm_records = [
    for key, vm in local.vms.vms : {
      address  = split("/", vm.ip4_address_cidr)[0]
      dns_name = "${try(vm.name, key)}.${var.dns_zone}"
    } if !merge(local.vms.defaults, vm).dhcp
  ]

  # NetBox keeps one DNS name per address; a second name for the same address fails here as a duplicate key
  addresses = { for record in concat(local.a_records, local.vm_records) : record.address => record.dns_name }

  # The mask comes from the most specific active prefix holding the address; 0 means none does
  prefix_lengths = {
    for address in keys(local.addresses) : address => max(0, [
      for prefix in local.active_prefixes :
      tonumber(split("/", prefix)[1]) if cidrcontains(prefix, address)
    ]...)
  }
}

resource "netbox_ip_address" "this" {
  for_each = local.addresses

  ip_address = "${each.key}/${local.prefix_lengths[each.key]}"
  dns_name   = each.value
  status     = "active"

  lifecycle {
    precondition {
      condition     = local.prefix_lengths[each.key] > 0
      error_message = "${each.key} (${each.value}) lies in no active prefix of global-data/ipam.yaml."
    }
  }
}
