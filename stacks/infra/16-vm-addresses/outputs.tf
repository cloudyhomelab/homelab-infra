output "addresses" {
  description = "Key of ../workloads.yaml => ip4_address_cidr, gateway and dns_addresses, for every created VM without DHCP."
  value       = module.address
}
