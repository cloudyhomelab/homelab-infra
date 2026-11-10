terraform {
  required_version = ">= 1.11.2"

  required_providers {
    truenas = {
      source  = "truenas/truenas"
      version = ">= 1.9.0"
    }
  }
}
