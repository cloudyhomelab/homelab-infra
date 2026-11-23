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
locals {
  image_index_url = "http://moria.ip.cloudyhome.net:9000/os-image-staging"
}
locals {
  image_pin = {
    bucket = "os-image-staging"
    domain = "infra"
    prefix = "protected"
  }
}
