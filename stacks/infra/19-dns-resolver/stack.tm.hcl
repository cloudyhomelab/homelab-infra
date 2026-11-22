stack {
  id          = "05c2f203-7837-4de5-ad39-06e991c4c17d"
  name        = "19-dns-resolver"
  description = "DNS resolver"
  tags        = ["dns", "http", "keycloak", "proxmox"]
  after       = ["/stacks/edge", "/stacks/network"]
  watch = [
    "/stacks/infra/vms.yaml",
  ]
}

globals {
  uses = ["timezone", "dns_zone"]
}
