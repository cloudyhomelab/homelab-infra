stack {
  id          = "bd63f2bb-3f11-41ef-9aef-e88402ce123e"
  name        = "70-media"
  description = "Media server"
  tags        = ["dns", "keycloak", "proxmox"]
  after       = ["/stacks/edge", "/stacks/network"]
  watch = [
    "/stacks/infra/vms.yaml",
  ]
}

globals {
  uses = ["timezone", "dns_zone", "reverse_zone"]
}
