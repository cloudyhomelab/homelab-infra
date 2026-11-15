// TERRAMATE: GENERATED AUTOMATICALLY DO NOT EDIT

variable "token_rotation_days" {
  default     = 30
  description = "Days between API token rotations."
  type        = number
}
variable "token_grace_days" {
  default     = 15
  description = "Days a token stays valid after its rotation is due, covering a late apply."
  type        = number
}
variable "acme_account_name" {
  description = "The ACME account config name."
  nullable    = false
  type        = string
}
variable "acme_contact_email" {
  description = "The contact email address."
  nullable    = false
  sensitive   = true
  type        = string
}
