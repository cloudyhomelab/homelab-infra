variable "opnsense_uri" {
  type = string
}

variable "opnsense_api_key" {
  type      = string
  sensitive = true
  ephemeral = true
}

variable "opnsense_api_secret" {
  type      = string
  sensitive = true
  ephemeral = true
}

provider "opnsense" {
  uri        = var.opnsense_uri
  api_key    = var.opnsense_api_key
  api_secret = var.opnsense_api_secret

  # The web GUI still serves a self-signed certificate; see #12 in docs/plan.org
  allow_insecure = true
}
