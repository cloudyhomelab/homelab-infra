generate_hcl "_terramate_generated_domain.auto.tfvars" {
  condition = tm_contains(terramate.stack.tags, "proxmox") || tm_contains(terramate.stack.tags, "proxmox-root")

  content {
    proxmox_endpoint = global.proxmox_endpoint
  }
}
