globals {
  dns_server = "ns1.ip.cloudyhome.net"
}

generate_hcl "_terramate_generated_dns.tf" {
  condition = tm_contains(terramate.stack.tags, "dns")

  content {
    variable "dns_server" {
      description = "DNS server that takes the RFC 2136 updates."
      type        = string
      nullable    = false
    }

    variable "dns_tsig_key_name" {
      type = string
    }

    variable "dns_tsig_key_algorithm" {
      type = string
    }

    variable "dns_tsig_key_secret" {
      type      = string
      sensitive = true
      ephemeral = true
    }

    provider "dns" {
      update {
        server        = var.dns_server
        key_name      = var.dns_tsig_key_name
        key_algorithm = var.dns_tsig_key_algorithm
        key_secret    = var.dns_tsig_key_secret
      }
    }
  }
}

generate_hcl "_terramate_generated_dns.auto.tfvars" {
  condition = tm_contains(terramate.stack.tags, "dns")

  content {
    dns_server = global.dns_server
  }
}
