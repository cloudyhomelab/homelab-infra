locals {
  ipam = yamldecode(file("${path.module}/ipam.yaml"))

  # Keyed group/name: NetBox allows the same VLAN name in different groups
  vlans = merge([
    for group, vlans in local.ipam.vlan_groups : {
      for name, vlan in vlans : "${group}/${name}" => {
        group       = group
        name        = name
        vid         = vlan.vid
        prefix      = try(vlan.prefix, null)
        description = try(vlan.description, null)
        dhcp        = try(vlan.dhcp, null)
      }
    }
  ]...)

  prefixes = merge(
    {
      for key, vlan in local.vlans : vlan.prefix => {
        status      = "active"
        description = vlan.description
        dhcp        = vlan.dhcp
        vlan        = key
      } if vlan.prefix != null
    },
    {
      for prefix, config in local.ipam.prefixes : prefix => {
        status      = try(config.status, "active")
        description = try(config.description, null)
        dhcp        = try(config.dhcp, null)
        vlan        = null
      }
    },
  )

  dhcp_pools = { for prefix, config in local.prefixes : prefix => config.dhcp if config.dhcp != null }
}

resource "netbox_vlan_group" "this" {
  for_each = local.ipam.vlan_groups

  name = each.key
}

resource "netbox_vlan" "this" {
  for_each = local.vlans

  name        = each.value.name
  vid         = each.value.vid
  group_id    = netbox_vlan_group.this[each.value.group].id
  status      = "active"
  description = each.value.description
}

resource "netbox_prefix" "this" {
  for_each = local.prefixes

  prefix      = each.key
  status      = each.value.status
  description = each.value.description
  vlan_id     = each.value.vlan == null ? null : netbox_vlan.this[each.value.vlan].id
}

resource "netbox_ipam_role" "dhcp" {
  name = "DHCP"
  # 20-kea selects the DHCP pools by this slug
  slug = "dhcp"
}

resource "netbox_ip_range" "dhcp" {
  for_each = local.dhcp_pools

  start_address = "${each.value.start}/${split("/", each.key)[1]}"
  end_address   = "${each.value.end}/${split("/", each.key)[1]}"
  status        = "active"
  role_id       = netbox_ipam_role.dhcp.id
  # Keeps "next available IP" from handing out leased addresses as static ones
  mark_populated = true

  lifecycle {
    precondition {
      condition     = cidrcontains(each.key, each.value.start) && cidrcontains(each.key, each.value.end)
      error_message = "DHCP pool ${each.value.start}-${each.value.end} lies outside ${each.key}."
    }
  }
}
