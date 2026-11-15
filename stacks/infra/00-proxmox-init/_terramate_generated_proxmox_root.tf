// TERRAMATE: GENERATED AUTOMATICALLY DO NOT EDIT

variable "proxmox_endpoint" {
  type = string
}
variable "proxmox_username" {
  description = "Admin user that creates the API token, as name@realm."
  type        = string
}
variable "proxmox_password" {
  description = "Password of proxmox_username; only the stack that creates the API token uses it."
  ephemeral   = true
  sensitive   = true
  type        = string
}
provider "proxmox" {
  endpoint = var.proxmox_endpoint
  insecure = true
  password = var.proxmox_password
  username = var.proxmox_username
}
