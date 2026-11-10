data "netbox_vlan" "this" {
  name = var.network
}

data "netbox_prefix" "this" {
  vlan_id = data.netbox_vlan.this.id
}

data "netbox_ip_ranges" "static" {
  filters = [
    { name = "role", value = "static" },
    { name = "status", value = "active" },
  ]
}

data "netbox_ip_addresses" "gateway" {
  filters = [{ name = "id", value = data.netbox_prefix.this.custom_fields["gateway"] }]
}

data "netbox_ip_addresses" "dns" {
  filters = [for id in jsondecode(data.netbox_prefix.this.custom_fields["dns_servers"]) : { name = "id", value = tostring(id) }]
}

locals {
  prefix_length = split("/", data.netbox_prefix.this.prefix)[1]

  # A range belongs to the prefix with its mask, so it never matches an enclosing or nested prefix
  static_ranges = [
    for range in data.netbox_ip_ranges.static.ip_ranges : range
    if cidrcontains(data.netbox_prefix.this.prefix, split("/", range.start_address)[0])
    && split("/", range.start_address)[1] == local.prefix_length
  ]
}

resource "netbox_available_ip_address" "this" {
  count = var.ip4_address_cidr == null ? 1 : 0

  ip_range_id = try(one(local.static_ranges).id, null)
  dns_name    = var.dns_name
  status      = "active"

  lifecycle {
    precondition {
      condition     = length(local.static_ranges) == 1
      error_message = "${data.netbox_prefix.this.prefix} (${var.network}) needs exactly one active static range, has ${length(local.static_ranges)}."
    }
  }
}

resource "netbox_ip_address" "this" {
  count = var.ip4_address_cidr == null ? 0 : 1

  ip_address = var.ip4_address_cidr
  dns_name   = var.dns_name
  status     = "active"

  lifecycle {
    precondition {
      condition = (
        cidrcontains(data.netbox_prefix.this.prefix, split("/", var.ip4_address_cidr)[0])
        && split("/", var.ip4_address_cidr)[1] == local.prefix_length
      )
      error_message = "${var.ip4_address_cidr} does not lie in ${data.netbox_prefix.this.prefix} (${var.network}) with its mask."
    }
  }
}
