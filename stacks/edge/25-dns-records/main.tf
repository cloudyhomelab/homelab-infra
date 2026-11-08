locals {
  # Matches the TTL the VM module gives its own records
  ttl = 300

  zones = yamldecode(file("${path.module}/records.yaml"))

  records = merge([
    for zone, names in local.zones : {
      for name, record in names : "${name}.${trimsuffix(zone, ".")}" => {
        zone  = "${trimsuffix(zone, ".")}."
        name  = name
        a     = try(record.a, null)
        cname = try(record.cname, null)
      }
    }
  ]...)
}

resource "dns_a_record_set" "this" {
  for_each = { for key, record in local.records : key => record if record.a != null }

  zone      = each.value.zone
  name      = each.value.name
  addresses = each.value.a
  ttl       = local.ttl
}

resource "dns_cname_record" "this" {
  for_each = { for key, record in local.records : key => record if record.cname != null }

  zone  = each.value.zone
  name  = each.value.name
  cname = "${trimsuffix(each.value.cname, ".")}."
  ttl   = local.ttl
}
