variable "keycloak_url" {
  type = string
}

variable "keycloak_realm" {
  type = string
}

variable "keycloak_admin_client_id" {
  type = string
}

variable "keycloak_admin_client_secret" {
  type      = string
  sensitive = true
  ephemeral = true
}

provider "keycloak" {
  url           = var.keycloak_url
  realm         = var.keycloak_realm
  client_id     = var.keycloak_admin_client_id
  client_secret = var.keycloak_admin_client_secret
}
