locals {
  # Matches the TTL the VM module gives its own records
  ttl = 300

  zones = yamldecode(file("${path.module}/../bootstrap-static-dns.yaml"))

  records = merge([
    for zone, names in local.zones : {
      for name, record in names : "${name}.${trimsuffix(zone, ".")}" => {
        zone = "${trimsuffix(zone, ".")}."
        name = name
        a    = record.a
      }
    }
  ]...)
}

module "a_record" {
  source   = "git::https://github.com/cloudyhomelab/terraform-homelab-modules.git//cloudyhome-dns-record?ref=main"
  for_each = local.records

  config = {
    name         = each.value.name
    zone         = each.value.zone
    ipv4         = one(each.value.a)
    reverse_zone = var.reverse_zone
    ttl          = local.ttl
  }
}
