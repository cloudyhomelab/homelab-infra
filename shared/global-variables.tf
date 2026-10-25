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
