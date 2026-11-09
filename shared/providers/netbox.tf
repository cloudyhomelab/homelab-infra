variable "netbox_server_url" {
  type = string
}

variable "netbox_api_token" {
  type      = string
  sensitive = true
  ephemeral = true
}

provider "netbox" {
  server_url = var.netbox_server_url
  api_token  = var.netbox_api_token
}
