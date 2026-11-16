stack {
  id          = "923f67ad-8627-4c5c-b735-71a8c1f11156"
  name        = "60-homeassistant"
  description = "Home Assistant server"
  tags        = ["dns", "keycloak", "proxmox"]
  watch = [
    "/stacks/infra/vms.yaml",
  ]
}

globals {
  uses = ["timezone", "dns_zone", "reverse_zone"]
}
