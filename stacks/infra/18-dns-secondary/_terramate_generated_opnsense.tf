// TERRAMATE: GENERATED AUTOMATICALLY DO NOT EDIT

variable "opnsense_uri" {
  type = string
}
variable "opnsense_api_key" {
  ephemeral = true
  sensitive = true
  type      = string
}
variable "opnsense_api_secret" {
  ephemeral = true
  sensitive = true
  type      = string
}
provider "opnsense" {
  allow_insecure = true
  api_key        = var.opnsense_api_key
  api_secret     = var.opnsense_api_secret
  uri            = var.opnsense_uri
}
