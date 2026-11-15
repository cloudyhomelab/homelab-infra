stack {
  id   = "ab2de887-57c8-4b24-b2b8-8e5c3a2f6483"
  tags = ["dns", "keycloak", "proxmox"]
}

globals {
  uses = ["timezone", "dns_zone", "reverse_zone"]
}
