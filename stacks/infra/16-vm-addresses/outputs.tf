output "addresses" {
  description = "Key of ../vms.yaml => ip4_address_cidr, gateway and dns_addresses, for every VM without DHCP."
  value       = module.address
}
