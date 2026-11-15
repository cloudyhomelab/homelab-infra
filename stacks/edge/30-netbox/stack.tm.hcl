stack {
  id   = "0dbb005c-0c56-4d41-a38e-04f13a06bc60"
  tags = ["dns", "keycloak", "proxmox"]
}

globals {
  uses = ["timezone", "dns_zone", "reverse_zone"]
}
