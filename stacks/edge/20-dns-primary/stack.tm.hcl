stack {
  id          = "ca099087-fe30-42f5-b0dd-b2e7d8e5ab34"
  name        = "20-dns-primary"
  description = "Primary authoritative DNS server"
  tags        = ["dns", "http", "keycloak", "opnsense", "proxmox"]
  watch = [
    "/stacks/edge/vms.yaml",
  ]
}

globals {
  uses = ["timezone", "dns_zone", "reverse_zone", "image_index_url"]
}
