globals {
  truenas_endpoint = "wss://moria.ip.cloudyhome.net/api/current"
}

generate_hcl "_terramate_generated_truenas.tf" {
  condition = tm_contains(terramate.stack.tags, "truenas")

  content {
    variable "truenas_endpoint" {
      description = "TrueNAS JSON-RPC WebSocket endpoint, e.g. wss://nas.example.net/api/current."
      type        = string
    }

    variable "truenas_api_key" {
      type      = string
      sensitive = true
      ephemeral = true
    }

    provider "truenas" {
      endpoint = var.truenas_endpoint
      api_key  = var.truenas_api_key

      insecure = true
    }
  }
}

generate_hcl "_terramate_generated_truenas.auto.tfvars" {
  condition = tm_contains(terramate.stack.tags, "truenas")

  content {
    truenas_endpoint = global.truenas_endpoint
  }
}
