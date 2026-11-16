stack {
  id          = "cdad65fe-1c95-43af-bf80-475f3da65cb7"
  name        = "40-ingress-control"
  description = "Ingress controllers, one per network"
  tags        = ["dns", "keycloak", "proxmox"]
  after       = ["/stacks/edge", "/stacks/network"]
  watch = [
    "/stacks/infra/vms.yaml",
  ]
}

globals {
  uses = ["timezone", "dns_zone", "reverse_zone"]
}
