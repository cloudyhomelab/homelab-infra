stack {
  id          = "7d363149-a87d-4a61-9426-d9188702e20a"
  name        = "18-dns-secondary"
  description = "Secondary authoritative DNS server"
  tags        = ["dns", "keycloak", "opnsense", "proxmox"]
}

globals {
  uses = ["timezone", "dns_zone", "reverse_zone"]
}
