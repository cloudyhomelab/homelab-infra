globals {
  opnsense_uri = "https://gateway.ip.cloudyhome.net:8443"
}

generate_hcl "_terramate_generated_opnsense.tf" {
  condition = tm_contains(terramate.stack.tags, "opnsense")

  content {
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
  }
}

generate_hcl "_terramate_generated_opnsense.auto.tfvars" {
  condition = tm_contains(terramate.stack.tags, "opnsense")

  content {
    opnsense_uri = global.opnsense_uri
  }
}
