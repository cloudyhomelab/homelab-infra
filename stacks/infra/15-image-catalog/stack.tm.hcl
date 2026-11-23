stack {
  id          = "05394179-5773-4716-bbae-e5cdba5d00d7"
  name        = "15-image-catalog"
  description = "Being retired: its apply deletes the image builds it imported"
  tags        = ["http", "proxmox"]
  after       = ["/stacks/edge", "/stacks/network"]
}
