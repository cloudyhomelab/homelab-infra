// TERRAMATE: GENERATED AUTOMATICALLY DO NOT EDIT

variable "netbox_server_url" {
  type = string
}
variable "netbox_api_token" {
  ephemeral = true
  sensitive = true
  type      = string
}
provider "netbox" {
  api_token  = var.netbox_api_token
  server_url = var.netbox_server_url
}
