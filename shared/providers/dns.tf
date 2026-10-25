variable "dns_server" {
  type = string
}

variable "dns_tsig_key_name" {
  type = string
}

variable "dns_tsig_key_algorithm" {
  type = string
}

variable "dns_tsig_key_secret" {
  type      = string
  sensitive = true
  ephemeral = true
}

provider "dns" {
  update {
    server        = var.dns_server
    key_name      = var.dns_tsig_key_name
    key_algorithm = var.dns_tsig_key_algorithm
    key_secret    = var.dns_tsig_key_secret
  }
}
