// TERRAMATE: GENERATED AUTOMATICALLY DO NOT EDIT

variable "timezone" {
  default     = "Europe/Helsinki"
  description = "IANA time zone of every node, e.g. Europe/Helsinki."
  type        = string
}
variable "acme_account_name" {
  description = "The ACME account config name."
  nullable    = false
  type        = string
}
variable "pve_search_domain" {
  default     = "ip.cloudyhome.net"
  description = "Domain for the PVE nodes."
  nullable    = false
  type        = string
}
variable "porkbun_api_key" {
  description = "Porkbun API key for DNS."
  sensitive   = true
  type        = string
}
variable "porkbun_secret_api_key" {
  description = "Porkbun secret API key for DNS."
  sensitive   = true
  type        = string
}
locals {
  acme_dns = {
    plugin           = "porkbun"
    api              = "porkbun"
    validation_delay = 120
    data = {
      PORKBUN_API_KEY        = var.porkbun_api_key
      PORKBUN_SECRET_API_KEY = var.porkbun_secret_api_key
    }
  }
}
