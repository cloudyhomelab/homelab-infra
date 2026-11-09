locals {
  ipam = yamldecode(file("${path.module}/../../../global-data/ipam.yaml"))

  # Keyed group/name: NetBox allows the same VLAN name in different groups
  vlans = merge([
    for group, vlans in local.ipam.vlan_groups : {
      for name, vlan in vlans : "${group}/${name}" => {
        group       = group
        name        = name
        vid         = vlan.vid
        prefix      = vlan.prefix
        description = vlan.description
        ranges      = vlan.ranges
      }
    }
  ]...)

  prefixes = merge(
    {
      for key, vlan in local.vlans : vlan.prefix => {
        status      = "active"
        description = vlan.description
        ranges      = vlan.ranges
        vlan        = key
      } if vlan.prefix != null
    },
    {
      for prefix, config in local.ipam.prefixes : prefix => {
        status      = config.status
        description = config.description
        ranges      = config.ranges
        vlan        = null
      }
    },
  )

  ip_ranges = merge([
    for prefix, config in local.prefixes : {
      for role, range in config.ranges : "${prefix}:${role}" => {
        prefix = prefix
        role   = role
        start  = range.start
        end    = range.end
      }
    }
  ]...)
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

resource "netbox_ipam_role" "this" {
  for_each = local.ipam.roles

  name        = each.value.name
  slug        = each.key
  description = each.value.description
}

resource "netbox_ip_range" "this" {
  for_each = local.ip_ranges

  start_address  = "${each.value.start}/${split("/", each.value.prefix)[1]}"
  end_address    = "${each.value.end}/${split("/", each.value.prefix)[1]}"
  status         = "active"
  role_id        = netbox_ipam_role.this[each.value.role].id
  mark_populated = local.ipam.roles[each.value.role].mark_populated

  lifecycle {
    precondition {
      condition     = cidrcontains(each.value.prefix, each.value.start) && cidrcontains(each.value.prefix, each.value.end)
      error_message = "Range ${each.value.start}-${each.value.end} (${each.value.role}) lies outside ${each.value.prefix}."
    }
  }
}
