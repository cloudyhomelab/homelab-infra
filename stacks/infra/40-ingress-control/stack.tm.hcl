stack {
  id   = "cdad65fe-1c95-43af-bf80-475f3da65cb7"
  tags = ["dns", "keycloak", "proxmox"]
}

globals {
  uses = ["timezone", "dns_zone", "reverse_zone"]
}
