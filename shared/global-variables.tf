# Lab-wide values, set in stacks/global.auto.tfvars. Declared in every stack so the shared
# tfvars never assigns an undeclared variable; not every stack uses every value.

# tflint-ignore: terraform_unused_declarations
variable "timezone" {
  description = "IANA time zone of every node, e.g. Europe/Helsinki."
  type        = string
}
