locals {
  entries = flatten([
    for key, client in var.clients : [
      for entry in try(var.images[client.image].storage, []) : {
        pair       = "${entry.app}/${entry.dataset}"
        app        = entry.app
        dataset    = entry.dataset
        recordsize = entry.recordsize
        client     = key
        address    = client.address
        image      = var.images[client.image].type
      }
    ]
  ])

  by_pair = { for entry in local.entries : entry.pair => entry... }

  exports = {
    for pair, entries in local.by_pair : pair => {
      app         = entries[0].app
      dataset     = entries[0].dataset
      recordsizes = distinct([for entry in entries : coalesce(entry.recordsize, "inherit")])
      hosts       = sort(distinct([for entry in entries : entry.address if entry.address != null]))
      unaddressed = sort(distinct([for entry in entries : entry.client if entry.address == null]))
      images      = sort(distinct([for entry in entries : entry.image]))
    }
  }

  unknown_images = sort(distinct([for client in values(var.clients) : client.image if !contains(keys(var.images), client.image)]))
}

resource "truenas_dataset" "app" {
  for_each = toset([for export in values(local.exports) : export.app])

  name = "${var.root}/${each.key}"

  lifecycle {
    prevent_destroy = true
  }
}

resource "truenas_dataset" "data" {
  for_each = local.exports

  name       = "${truenas_dataset.app[each.value.app].name}/${each.value.dataset}"
  recordsize = each.value.recordsizes[0] == "inherit" ? null : each.value.recordsizes[0]

  lifecycle {
    prevent_destroy = true

    # Clients sharing a dataset must agree on its properties, or each apply would flip them
    precondition {
      condition     = length(each.value.recordsizes) == 1
      error_message = "${each.key}: images ${join(", ", each.value.images)} want different recordsize (${join(", ", each.value.recordsizes)})."
    }
  }
}

resource "truenas_nfs_share" "data" {
  for_each = local.exports

  path          = truenas_dataset.data[each.key].mountpoint
  comment       = join(", ", each.value.images)
  hosts         = each.value.hosts
  networks      = []
  maproot_user  = "root"
  maproot_group = "root"

  lifecycle {
    precondition {
      condition     = length(each.value.unaddressed) == 0
      error_message = "${each.key}: clients ${join(", ", each.value.unaddressed)} have no address; a share allows clients by address only."
    }

    # TrueNAS reads an empty host list as every host
    precondition {
      condition     = length(each.value.hosts) > 0
      error_message = "${each.key}: the share would allow no host, which TrueNAS reads as every host."
    }
  }
}
