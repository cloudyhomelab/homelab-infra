variable "network" {
  description = "Name of the VLAN in NetBox the VM attaches to."
  type        = string
  nullable    = false
}

variable "dns_name" {
  description = "FQDN recorded on the address in NetBox."
  type        = string
  nullable    = false
}

variable "ip4_address_cidr" {
  description = "Address to register, with mask; null allocates the next free one from the static range of the VLAN's prefix."
  type        = string
  default     = null
}
