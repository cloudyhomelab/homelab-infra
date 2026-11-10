locals {
  # <app>/<dataset> => id of its existing NFS share (`midclt call sharing.nfs.query`), adopted with the
  # dataset and its app parent; empty once adopted
  adopted_shares = {
    "netbox/data"  = 17
    "netbox/db"    = 18
    "netbox/redis" = 19
  }
}

import {
  for_each = toset([for pair in keys(local.adopted_shares) : split("/", pair)[0]])
  to       = module.storage.truenas_dataset.app[each.key]
  id       = "${var.truenas_app_data_root}/${each.key}"
}

import {
  for_each = local.adopted_shares
  to       = module.storage.truenas_dataset.data[each.key]
  id       = "${var.truenas_app_data_root}/${each.key}"
}

import {
  for_each = local.adopted_shares
  to       = module.storage.truenas_nfs_share.data[each.key]
  id       = tostring(each.value)
}
