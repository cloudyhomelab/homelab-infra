locals {
  # Matches the TTL the VM module gives its own records
  ttl = 300

  allow_zone = "rpz.allow"
  deny_zone  = "rpz.deny"

  zones      = yamldecode(file("${path.module}/../bootstrap-static-dns.yaml"))
  allow_data = yamldecode(file("${path.module}/rpz-allow.yaml"))

  records = merge([
    for zone, names in local.zones : {
      for name, record in names : "${name}.${trimsuffix(zone, ".")}" => {
        zone = "${trimsuffix(zone, ".")}."
        name = name
        a    = record.a
      }
    }
  ]...)

  allow_records = local.allow_data["allow"]

  deny_records = [
    for line in split("\n", data.http.deny_list.response_body) : trimspace(line)
    if trimspace(line) != "" && !startswith(trimspace(line), "#")
  ]
}

data "http" "deny_list" {
  url = "https://raw.githubusercontent.com/cloudyhomelab/dns-rpz-deny-list/main/deny-list.txt"

  lifecycle {
    # An error page would parse as an empty list and delete every deny record
    postcondition {
      condition     = self.status_code == 200
      error_message = "Deny list fetch returned HTTP ${self.status_code}"
    }
  }
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
