stack {
  id          = "53001bfc-cd71-4a9d-9e56-ff10afe3f7c0"
  name        = "10-ipam"
  description = "NetBox VLANs, prefixes, IP ranges and gateways from global-data/ipam.yaml"
  tags        = ["netbox"]
  after       = ["/stacks/edge"]
  watch = [
    "/global-data/ipam.yaml",
  ]
}
