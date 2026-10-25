# Module inputs from secrets/global.sops.yaml. Not ephemeral: the module writes them into
# cloud-init, so they end up in (encrypted) state.

variable "ca_server_url" {
  type      = string
  sensitive = true
}

variable "ca_sso_realm" {
  type      = string
  sensitive = true
}

variable "ca_sso_token_url" {
  type      = string
  sensitive = true
}

variable "age_secret" {
  type      = string
  sensitive = true
}

variable "vm_username" {
  type = string
}

variable "vm_user_id" {
  type = number
}

variable "dns_zone" {
  type = string
}
