stack {
  id          = "05394179-5773-4716-bbae-e5cdba5d00d7"
  name        = "15-image-catalog"
  description = "Import OS image builds to the Proxmox storage"
  tags        = ["proxmox"]
}

globals {
  uses = ["s3_url"]
}
