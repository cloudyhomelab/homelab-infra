stack {
  id          = "6009325a-2a4a-4ad9-844e-0dac97c5af27"
  name        = "35-netbox-addresses"
  description = "NetBox IP addresses of the VMs and bootstrap DNS records"
  tags        = ["netbox"]
  watch = [
    "/global-data/ipam.yaml",
    "/stacks/edge/bootstrap-static-dns.yaml",
    "/stacks/edge/vms.yaml",
  ]
}

globals {
  uses = ["dns_zone"]
}
