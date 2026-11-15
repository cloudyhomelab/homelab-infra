# Lab-wide variables and locals. A stack gets only the entries named in its `uses` global, so
# terraform_unused_declarations holds everywhere. Secrets have no default; they come from SOPS.

globals {
  uses = []

  timezone              = "Europe/Helsinki"
  token_rotation_days   = 30
  token_grace_days      = 15
  pve_search_domain     = "ip.cloudyhome.net"
  dns_zone              = "ip.cloudyhome.net"
  reverse_zone          = "88.10.in-addr.arpa."
  truenas_app_data_root = "zpool0/cloudyhome_app_data"
  s3_url                = "http://moria.ip.cloudyhome.net:9000"

  # One per tm_dynamic block below; an unmatched name in `uses` would otherwise generate nothing, silently
  shared_entries = [
    "timezone",
    "token_rotation_days",
    "token_grace_days",
    "acme_account_name",
    "acme_contact_email",
    "pve_search_domain",
    "porkbun_api_key",
    "porkbun_secret_api_key",
    "dns_zone",
    "reverse_zone",
    "truenas_app_data_root",
    "s3_url",
    "acme_dns",
  ]
}

assert {
  assertion = tm_length(tm_setsubtract(global.uses, global.shared_entries)) == 0
  message   = "uses has names with no block in stacks/shared.tm.hcl: ${tm_join(", ", tm_setsubtract(global.uses, global.shared_entries))}"
}

generate_hcl "_terramate_generated_shared.tf" {
  condition = tm_length(global.uses) > 0

  content {
    tm_dynamic "variable" {
      labels    = ["timezone"]
      condition = tm_contains(global.uses, "timezone")
      content {
        description = "IANA time zone of every node, e.g. Europe/Helsinki."
        type        = string
        default     = global.timezone
      }
    }

    tm_dynamic "variable" {
      labels    = ["token_rotation_days"]
      condition = tm_contains(global.uses, "token_rotation_days")
      content {
        description = "Days between API token rotations."
        type        = number
        default     = global.token_rotation_days
      }
    }

    tm_dynamic "variable" {
      labels    = ["token_grace_days"]
      condition = tm_contains(global.uses, "token_grace_days")
      content {
        description = "Days a token stays valid after its rotation is due, covering a late apply."
        type        = number
        default     = global.token_grace_days
      }
    }

    tm_dynamic "variable" {
      labels    = ["acme_account_name"]
      condition = tm_contains(global.uses, "acme_account_name")
      content {
        description = "The ACME account config name."
        type        = string
        nullable    = false
      }
    }

    tm_dynamic "variable" {
      labels    = ["acme_contact_email"]
      condition = tm_contains(global.uses, "acme_contact_email")
      content {
        description = "The contact email address."
        type        = string
        sensitive   = true
        nullable    = false
      }
    }

    tm_dynamic "variable" {
      labels    = ["pve_search_domain"]
      condition = tm_contains(global.uses, "pve_search_domain")
      content {
        description = "Domain for the PVE nodes."
        type        = string
        nullable    = false
        default     = global.pve_search_domain
      }
    }

    tm_dynamic "variable" {
      labels    = ["porkbun_api_key"]
      condition = tm_contains(global.uses, "porkbun_api_key")
      content {
        description = "Porkbun API key for DNS."
        type        = string
        sensitive   = true
      }
    }

    tm_dynamic "variable" {
      labels    = ["porkbun_secret_api_key"]
      condition = tm_contains(global.uses, "porkbun_secret_api_key")
      content {
        description = "Porkbun secret API key for DNS."
        type        = string
        sensitive   = true
      }
    }

    tm_dynamic "variable" {
      labels    = ["dns_zone"]
      condition = tm_contains(global.uses, "dns_zone")
      content {
        description = "DNS zone the VMs live in, used as their search domain."
        type        = string
        nullable    = false
        default     = global.dns_zone
      }
    }

    tm_dynamic "variable" {
      labels    = ["reverse_zone"]
      condition = tm_contains(global.uses, "reverse_zone")
      content {
        description = "in-addr.arpa zone that holds the PTR records of the VM addresses."
        type        = string
        nullable    = false
        default     = global.reverse_zone
      }
    }

    tm_dynamic "variable" {
      labels    = ["truenas_app_data_root"]
      condition = tm_contains(global.uses, "truenas_app_data_root")
      content {
        description = "TrueNAS dataset holding the app data datasets of every domain; created by hand."
        type        = string
        nullable    = false
        default     = global.truenas_app_data_root
      }
    }

    tm_dynamic "locals" {
      condition = tm_contains(global.uses, "s3_url")
      content {
        s3_url = global.s3_url
      }
    }

    tm_dynamic "locals" {
      condition = tm_contains(global.uses, "acme_dns")
      content {
        acme_dns = {
          plugin           = "porkbun"
          api              = "porkbun"
          validation_delay = 120

          data = {
            PORKBUN_API_KEY        = var.porkbun_api_key
            PORKBUN_SECRET_API_KEY = var.porkbun_secret_api_key
          }
        }
      }
    }
  }
}
