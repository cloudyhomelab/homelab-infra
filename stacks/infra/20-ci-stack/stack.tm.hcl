stack {
  id          = "fd0feb69-84a7-4869-b7cc-f99eb916c764"
  name        = "20-ci-stack"
  description = "CI control plane and runners"
  tags        = ["aws", "dns", "http", "keycloak", "proxmox"]
  after       = ["/stacks/edge", "/stacks/network"]
  watch = [
    "/stacks/infra/workloads.yaml",
  ]
}

globals {
  uses = ["timezone", "dns_zone", "reverse_zone", "image_index_url", "image_pin"]
}
