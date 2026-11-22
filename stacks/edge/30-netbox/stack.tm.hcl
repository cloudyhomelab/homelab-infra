stack {
  id          = "0dbb005c-0c56-4d41-a38e-04f13a06bc60"
  name        = "30-netbox"
  description = "NetBox, the IPAM source of truth"
  tags        = ["dns", "http", "keycloak", "proxmox"]
  watch = [
    "/stacks/edge/vms.yaml",
  ]
}

globals {
  uses = ["timezone", "dns_zone", "reverse_zone"]
}
