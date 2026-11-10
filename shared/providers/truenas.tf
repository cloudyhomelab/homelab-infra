variable "truenas_endpoint" {
  description = "TrueNAS JSON-RPC WebSocket endpoint, e.g. wss://nas.example.net/api/current."
  type        = string
}

variable "truenas_api_key" {
  type      = string
  sensitive = true
  ephemeral = true
}

provider "truenas" {
  endpoint = var.truenas_endpoint
  api_key  = var.truenas_api_key

  insecure = true
}
