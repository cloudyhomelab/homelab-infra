stack {
  id          = "7d363149-a87d-4a61-9426-d9188702e20a"
  name        = "18-dns-secondary"
  description = "Secondary authoritative DNS server"
  tags        = ["dns", "http", "keycloak", "opnsense", "proxmox"]
  after       = ["/stacks/edge", "/stacks/network"]
  watch = [
    "/stacks/infra/workloads.yaml",
  ]
}

globals {
  uses = ["timezone", "dns_zone", "reverse_zone", "image_index_url"]
}
