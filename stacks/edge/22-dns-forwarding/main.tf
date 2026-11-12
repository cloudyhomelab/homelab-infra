locals {
  vms = yamldecode(file("${path.module}/../vms.yaml"))

  # Unbound cannot resolve the name of the server it forwards to, so the target is an address
  dns_server_ip = split("/", local.vms.vms["dns-primary"].ip4_address_cidr)[0]

  zones = toset([trimsuffix(var.dns_zone, "."), trimsuffix(var.reverse_zone, ".")])
}

resource "opnsense_unbound_forward" "this" {
  for_each = local.zones

  domain      = each.key
  server_ip   = local.dns_server_ip
  server_port = 53
  type        = "query"
}
