data "netbox_prefixes" "active" {
  filters = [{ name = "status", value = "active" }]
}

locals {
  zones = yamldecode(file("${path.module}/../../../global-data/bootstrap-static-dns.yaml"))

  # CNAMEs carry no address of their own, so only A records reach NetBox
  a_records = flatten([
    for zone, names in local.zones : [
      for name, record in names : [
        for address in try(record.a, []) : {
          address  = address
          dns_name = "${name}.${trimsuffix(zone, ".")}"
        }
      ]
    ]
  ])

  # NetBox keeps one DNS name per address; a second name for the same address fails here as a duplicate key
  addresses = { for record in local.a_records : record.address => record.dns_name }

  # The mask comes from the most specific active NetBox prefix holding the address; 0 means none does
  prefix_lengths = {
    for address in keys(local.addresses) : address => max(0, [
      for prefix in data.netbox_prefixes.active.prefixes :
      tonumber(split("/", prefix.prefix)[1]) if cidrcontains(prefix.prefix, address)
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
      error_message = "${each.key} (${each.value}) lies in no active NetBox prefix."
    }
  }
}
