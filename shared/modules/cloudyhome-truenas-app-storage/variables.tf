variable "root" {
  description = "Existing dataset under which every app gets its own dataset, e.g. tank/app_data."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[^/]+(/[^/]+)*$", var.root))
    error_message = "root must be a dataset path without leading or trailing slash, e.g. tank/app_data."
  }
}

variable "images" {
  description = "Image key => image type and the datasets the image needs, each as {app, dataset, recordsize?}."
  type = map(object({
    type = string
    storage = optional(list(object({
      app        = string
      dataset    = string
      recordsize = optional(string)
    })), [])
  }))
  nullable = false

  validation {
    # app and dataset become ZFS and filesystem path segments
    condition = alltrue(flatten([
      for image in values(var.images) : [
        for entry in image.storage :
        can(regex("^[A-Za-z0-9_-][A-Za-z0-9._-]*$", entry.app)) && can(regex("^[A-Za-z0-9_-][A-Za-z0-9._-]*$", entry.dataset))
      ]
    ]))
    error_message = "Every storage app and dataset must match ^[A-Za-z0-9_-][A-Za-z0-9._-]*$."
  }
}

variable "clients" {
  description = "Client key => the image it runs and its IPv4 address, null when it has none. Clients whose image needs no storage are ignored."
  type = map(object({
    image   = string
    address = optional(string)
  }))
  nullable = false

  validation {
    # cidrnetmask accepts IPv4 only, unlike cidrhost
    condition     = alltrue([for client in values(var.clients) : client.address == null || can(cidrnetmask("${client.address}/32"))])
    error_message = "A client address must be a bare IPv4 address, e.g. 192.0.2.10."
  }
}
