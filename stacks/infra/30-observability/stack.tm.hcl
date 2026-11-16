stack {
  id          = "60ad5cf2-8ab4-4431-abe6-35e629885963"
  name        = "30-observability"
  description = "Observability server"
  tags        = ["dns", "keycloak", "proxmox"]
  watch = [
    "/stacks/infra/vms.yaml",
  ]
}

globals {
  uses = ["timezone", "dns_zone", "reverse_zone"]
}
