stack {
  id          = "a18f609c-d790-4836-9c08-cf399bbc42eb"
  name        = "15-image-catalog"
  description = "Import OS image builds to the Proxmox storage"
  tags        = ["http", "proxmox"]
  watch = [
    "/stacks/edge/vms.yaml",
  ]
}

globals {
  uses = ["s3_url"]
}
