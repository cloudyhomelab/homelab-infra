// TERRAMATE: GENERATED AUTOMATICALLY DO NOT EDIT

variable "minio_user" {
  ephemeral = true
  sensitive = true
  type      = string
}
variable "minio_password" {
  ephemeral = true
  sensitive = true
  type      = string
}
provider "minio" {
  minio_password = var.minio_password
  minio_region   = "home"
  minio_server   = "moria.ip.cloudyhome.net:9000"
  minio_ssl      = false
  minio_user     = var.minio_user
}
