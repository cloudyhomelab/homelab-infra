stack {
  id          = "60ad5cf2-8ab4-4431-abe6-35e629885963"
  name        = "30-observability"
  description = "Observability server"
  tags        = ["aws", "dns", "http", "keycloak", "proxmox"]
  after       = ["/stacks/edge", "/stacks/network"]
  watch = [
    "/stacks/infra/workloads.yaml",
  ]
}

globals {
  uses = ["timezone", "dns_zone", "reverse_zone", "image_index_url", "image_pin"]
}
