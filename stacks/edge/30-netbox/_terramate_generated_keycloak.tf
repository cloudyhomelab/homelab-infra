// TERRAMATE: GENERATED AUTOMATICALLY DO NOT EDIT

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
  ephemeral = true
  sensitive = true
  type      = string
}
provider "keycloak" {
  client_id     = var.keycloak_admin_client_id
  client_secret = var.keycloak_admin_client_secret
  realm         = var.keycloak_realm
  url           = var.keycloak_url
}
