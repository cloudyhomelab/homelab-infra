stack {
  id          = "60ad5cf2-8ab4-4431-abe6-35e629885963"
  name        = "30-observability"
  description = "Observability server"
  tags        = ["dns", "http", "keycloak", "proxmox"]
  after       = ["/stacks/edge", "/stacks/network"]
  watch = [
    "/stacks/infra/vms.yaml",
  ]
}

globals {
  uses = ["timezone", "dns_zone", "reverse_zone"]
}
