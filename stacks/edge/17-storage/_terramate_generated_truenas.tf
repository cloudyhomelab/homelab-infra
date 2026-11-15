// TERRAMATE: GENERATED AUTOMATICALLY DO NOT EDIT

variable "truenas_endpoint" {
  description = "TrueNAS JSON-RPC WebSocket endpoint, e.g. wss://nas.example.net/api/current."
  type        = string
}
variable "truenas_api_key" {
  ephemeral = true
  sensitive = true
  type      = string
}
provider "truenas" {
  api_key  = var.truenas_api_key
  endpoint = var.truenas_endpoint
  insecure = true
}
