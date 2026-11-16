stack {
  id          = "05394179-5773-4716-bbae-e5cdba5d00d7"
  name        = "15-image-catalog"
  description = "Import OS image builds to the Proxmox storage"
  tags        = ["http", "proxmox"]
  after       = ["/stacks/edge", "/stacks/network"]
  watch = [
    "/stacks/infra/vms.yaml",
  ]
}

globals {
  uses = ["s3_url"]
}
