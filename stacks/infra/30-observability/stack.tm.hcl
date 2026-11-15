stack {
  id   = "60ad5cf2-8ab4-4431-abe6-35e629885963"
  tags = ["dns", "keycloak", "proxmox"]
}

globals {
  uses = ["timezone", "dns_zone", "reverse_zone"]
}
