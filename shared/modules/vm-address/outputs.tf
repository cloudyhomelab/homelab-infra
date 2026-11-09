output "ip4_address_cidr" {
  description = "The VM's address with mask, as registered in NetBox."
  value       = coalesce(one(netbox_available_ip_address.this[*].ip_address), one(netbox_ip_address.this[*].ip_address))
}

output "gateway" {
  description = "Gateway of the VLAN's prefix."
  value       = split("/", one(data.netbox_ip_addresses.gateway.ip_addresses[*].ip_address))[0]
}

output "dns_addresses" {
  description = "DNS servers of the VLAN's prefix."
  value       = [for address in data.netbox_ip_addresses.dns.ip_addresses : split("/", address.ip_address)[0]]
}
