stack {
  id          = "bd63f2bb-3f11-41ef-9aef-e88402ce123e"
  name        = "70-media"
  description = "Media server"
  tags        = ["aws", "dns", "http", "keycloak", "proxmox"]
  after       = ["/stacks/edge", "/stacks/network"]
  watch = [
    "/stacks/infra/workloads.yaml",
  ]
}

globals {
  uses = ["timezone", "dns_zone", "reverse_zone", "image_index_url", "image_pin"]
}
