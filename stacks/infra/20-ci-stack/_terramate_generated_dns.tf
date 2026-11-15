// TERRAMATE: GENERATED AUTOMATICALLY DO NOT EDIT

variable "dns_server" {
  description = "DNS server that takes the RFC 2136 updates."
  nullable    = false
  type        = string
}
variable "dns_tsig_key_name" {
  type = string
}
variable "dns_tsig_key_algorithm" {
  type = string
}
variable "dns_tsig_key_secret" {
  ephemeral = true
  sensitive = true
  type      = string
}
provider "dns" {
  update {
    key_algorithm = var.dns_tsig_key_algorithm
    key_name      = var.dns_tsig_key_name
    key_secret    = var.dns_tsig_key_secret
    server        = var.dns_server
  }
}
