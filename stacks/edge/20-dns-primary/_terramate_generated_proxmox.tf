// TERRAMATE: GENERATED AUTOMATICALLY DO NOT EDIT

variable "proxmox_endpoint" {
  type = string
}
variable "proxmox_ssh_private_key" {
  ephemeral = true
  sensitive = true
  type      = string
}
data "terraform_remote_state" "proxmox_init" {
  backend = "s3"
  config = merge(local.state_backend, {
    key = "00-proxmox-init.tfstate"
  })
}
provider "proxmox" {
  api_token = data.terraform_remote_state.proxmox_init.outputs.user_token
  endpoint  = var.proxmox_endpoint
  insecure  = true
  ssh {
    agent       = false
    private_key = var.proxmox_ssh_private_key
    username    = "root"
  }
}
