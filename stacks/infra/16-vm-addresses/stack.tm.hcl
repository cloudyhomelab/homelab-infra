stack {
  id          = "245fa788-ddc6-478a-b736-c38288e091d9"
  name        = "16-vm-addresses"
  description = "NetBox IP reservations and DNS records of the static VMs"
  tags        = ["dns", "netbox"]
  watch = [
    "/stacks/infra/vms.yaml",
  ]
}

globals {
  uses = ["dns_zone", "reverse_zone"]
}
