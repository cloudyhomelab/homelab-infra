locals {
  # Matches the TTL the VM module gives its own records
  ttl = 300

  zones = yamldecode(file("${path.module}/../bootstrap-static-dns.yaml"))

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

module "a_record" {
  source   = "git::https://github.com/cloudyhomelab/terraform-homelab-modules.git//cloudyhome-dns-record?ref=main"
  for_each = { for key, record in local.records : key => record if record.a != null }

  config = {
    name         = each.value.name
    zone         = each.value.zone
    ipv4         = one(each.value.a)
    reverse_zone = var.reverse_zone
    ttl          = local.ttl
  }
}

resource "dns_cname_record" "this" {
  for_each = { for key, record in local.records : key => record if record.cname != null }

  zone  = each.value.zone
  name  = each.value.name
  cname = "${trimsuffix(each.value.cname, ".")}."
  ttl   = local.ttl
}
