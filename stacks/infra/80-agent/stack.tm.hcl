stack {
  id          = "a4b325a0-c850-4066-bd54-3b5fabee66bb"
  name        = "80-agent"
  description = "Agent server"
  tags        = ["aws", "dns", "http", "keycloak", "proxmox"]
  after       = ["/stacks/edge", "/stacks/network"]
  watch = [
    "/stacks/infra/workloads.yaml",
  ]
}

globals {
  uses = ["timezone", "dns_zone", "reverse_zone", "image_index_url", "image_pin"]
}
