stack {
  id          = "ab2de887-57c8-4b24-b2b8-8e5c3a2f6483"
  name        = "22-dns-resolver"
  description = "DNS resolver"
  tags        = ["dns", "http", "keycloak", "proxmox"]
  watch = [
    "/stacks/edge/workloads.yaml",
  ]
}

globals {
  uses = ["timezone", "dns_zone", "reverse_zone", "image_index_url"]
}
