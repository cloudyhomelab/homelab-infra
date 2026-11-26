stack {
  id          = "3c853271-02fe-4837-b1d8-a41901753ada"
  name        = "28-identity"
  description = "Identity server"
  tags        = ["aws", "dns", "http", "keycloak", "proxmox"]
  watch = [
    "/stacks/edge/workloads.yaml",
  ]
}

globals {
  uses = ["timezone", "dns_zone", "reverse_zone", "image_index_url", "image_pin"]
}
