# Lab-wide values, set in stacks/global.auto.tfvars. Declared in every stack so the shared
# tfvars never assigns an undeclared variable; not every stack uses every value.

# tflint-ignore: terraform_unused_declarations
variable "timezone" {
  description = "IANA time zone of every node, e.g. Europe/Helsinki."
  type        = string
}

# tflint-ignore: terraform_unused_declarations
variable "token_rotation_days" {
  description = "Days between API token rotations."
  type        = number
}

# tflint-ignore: terraform_unused_declarations
variable "token_grace_days" {
  description = "Days a token stays valid after its rotation is due, covering a late apply."
  type        = number
}

# tflint-ignore: terraform_unused_declarations
variable "acme_account_name" {
  description = "The ACME account config name."
  type        = string
  nullable    = false
}

# tflint-ignore: terraform_unused_declarations
variable "acme_contact_email" {
  description = "The contact email address."
  type        = string
  sensitive   = true
  nullable    = false
}

# tflint-ignore: terraform_unused_declarations
variable "pve_search_domain" {
  description = "Domain for the PVE nodes."
  type        = string
  nullable    = false
}

# tflint-ignore: terraform_unused_declarations
variable "porkbun_api_key" {
  description = "Porkbun API key for DNS."
  type        = string
  sensitive   = true
}

# tflint-ignore: terraform_unused_declarations
variable "porkbun_secret_api_key" {
  description = "Porkbun secret API key for DNS."
  type        = string
  sensitive   = true
}

# tflint-ignore: terraform_unused_declarations
variable "dns_zone" {
  description = "DNS zone the VMs live in, used as their search domain."
  type        = string
  nullable    = false
}

# tflint-ignore: terraform_unused_declarations
variable "dns_server" {
  description = "DNS server that takes the RFC 2136 updates."
  type        = string
  nullable    = false
}

# tflint-ignore: terraform_unused_declarations
variable "reverse_zone" {
  description = "in-addr.arpa zone that holds the PTR records of the VM addresses."
  type        = string
  nullable    = false
}

# tflint-ignore: terraform_unused_declarations
variable "truenas_app_data_root" {
  description = "TrueNAS dataset holding the app data datasets of every domain; created by hand."
  type        = string
  nullable    = false
}
