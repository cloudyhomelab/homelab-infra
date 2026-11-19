locals {
  # Matches the TTL the VM module gives its own records
  ttl = 300

  allow_zone = "rpz.allow"
  deny_zone  = "rpz.deny"

  zones    = yamldecode(file("${path.module}/../bootstrap-static-dns.yaml"))
  rpz_data = yamldecode(file("${path.module}/rpz-records.yaml"))

  records = merge([
    for zone, names in local.zones : {
      for name, record in names : "${name}.${trimsuffix(zone, ".")}" => {
        zone = "${trimsuffix(zone, ".")}."
        name = name
        a    = record.a
      }
    }
  ]...)

  deny_records  = local.rpz_data["deny"]
  allow_records = local.rpz_data["allow"]
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

module "rpz" {
  source = "git::https://github.com/cloudyhomelab/terraform-homelab-modules.git//cloudyhome-dns-rpz?ref=main"

  config = {
    allow_zone = local.allow_zone
    deny_zone  = local.deny_zone
    allow      = local.allow_records
    deny       = local.deny_records
    ttl        = local.ttl
  }
}
