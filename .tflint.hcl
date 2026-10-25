plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# Modules track main until terraform-homelab-modules v1.0.0; re-enable then.
rule "terraform_module_pinned_source" {
  enabled = false
}
