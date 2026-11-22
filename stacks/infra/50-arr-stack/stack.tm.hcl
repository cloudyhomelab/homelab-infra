stack {
  id          = "585bf157-d0f1-4d54-8b4d-3a05c6a741f8"
  name        = "50-arr-stack"
  description = "Media automation server"
  tags        = ["dns", "http", "keycloak", "proxmox"]
  after       = ["/stacks/edge", "/stacks/network"]
  watch = [
    "/stacks/infra/vms.yaml",
  ]
}

globals {
  uses = ["timezone", "dns_zone", "reverse_zone"]
}
