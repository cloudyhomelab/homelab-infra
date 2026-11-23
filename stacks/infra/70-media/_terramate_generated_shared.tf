// TERRAMATE: GENERATED AUTOMATICALLY DO NOT EDIT

variable "timezone" {
  default     = "Europe/Helsinki"
  description = "IANA time zone of every node, e.g. Europe/Helsinki."
  type        = string
}
variable "dns_zone" {
  default     = "ip.cloudyhome.net"
  description = "DNS zone the VMs live in, used as their search domain."
  nullable    = false
  type        = string
}
variable "reverse_zone" {
  default     = "88.10.in-addr.arpa."
  description = "in-addr.arpa zone that holds the PTR records of the VM addresses."
  nullable    = false
  type        = string
}
locals {
  image_index_url = "http://moria.ip.cloudyhome.net:9000/os-image-staging"
}
