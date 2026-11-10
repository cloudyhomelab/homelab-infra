output "shares" {
  description = "<app>/<dataset> => dataset name, share path and allowed hosts."
  value = {
    for pair, export in local.exports : pair => {
      dataset = truenas_dataset.data[pair].name
      path    = truenas_nfs_share.data[pair].path
      hosts   = truenas_nfs_share.data[pair].hosts
    }
  }

  precondition {
    condition     = length(local.unknown_images) == 0
    error_message = "Clients use images missing from images: ${join(", ", local.unknown_images)}."
  }
}
