data "netbox_prefixes" "active" {
  filters = [{ name = "status", value = "active" }]
}

data "netbox_ip_ranges" "dhcp" {
  filters = [
    { name = "role", value = "dhcp" },
    { name = "status", value = "active" },
  ]
}

locals {
  # One Kea subnet per active prefix that holds a DHCP range; a range belongs to the prefix
  # with its mask, so it never matches an enclosing or nested prefix
  subnets = {
    for prefix in data.netbox_prefixes.active.prefixes : prefix.prefix => {
      description = prefix.description
      pools = [
        for range in data.netbox_ip_ranges.dhcp.ip_ranges :
        "${split("/", range.start_address)[0]} - ${split("/", range.end_address)[0]}"
        if cidrcontains(prefix.prefix, split("/", range.start_address)[0])
        && split("/", range.start_address)[1] == split("/", prefix.prefix)[1]
      ]
    }
  }
}

resource "opnsense_kea_dhcpv4_subnet" "this" {
  for_each = { for prefix, subnet in local.subnets : prefix => subnet if length(subnet.pools) > 0 }

  subnet      = each.key
  pools       = each.value.pools
  description = each.value.description

  lifecycle {
    # auto_collect fills these from the interface, but the provider defaults them to [] and
    # would clear them on every plan
    ignore_changes = [routers, dns_servers, ntp_servers]
  }
}
