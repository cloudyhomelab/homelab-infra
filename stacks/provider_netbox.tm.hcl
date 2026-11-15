globals {
  netbox_server_url = "http://netbox.ip.cloudyhome.net:8080"
}

generate_hcl "_terramate_generated_netbox.tf" {
  condition = tm_contains(terramate.stack.tags, "netbox")

  content {
    variable "netbox_server_url" {
      type = string
    }

    variable "netbox_api_token" {
      type      = string
      sensitive = true
      ephemeral = true
    }

    provider "netbox" {
      server_url = var.netbox_server_url
      api_token  = var.netbox_api_token
    }
  }
}

generate_hcl "_terramate_generated_netbox.auto.tfvars" {
  condition = tm_contains(terramate.stack.tags, "netbox")

  content {
    netbox_server_url = global.netbox_server_url
  }
}
