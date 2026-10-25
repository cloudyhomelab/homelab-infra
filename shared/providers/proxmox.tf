variable "proxmox_endpoint" {
  type = string
}

variable "proxmox_ssh_private_key" {
  type      = string
  sensitive = true
  ephemeral = true
}

data "terraform_remote_state" "proxmox_init" {
  backend = "s3"
  config  = merge(local.state_backend, { key = "00-proxmox-init.tfstate" })
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = data.terraform_remote_state.proxmox_init.outputs.user_token

  insecure = true
  ssh {
    agent       = false
    private_key = var.proxmox_ssh_private_key
    username    = "root"
  }
}
