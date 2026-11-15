stack {
  id          = "f385d410-fd32-4537-8ba0-95f49c832da7"
  name        = "17-storage"
  description = "TrueNAS datasets and NFS shares for all VMs in the environment"
  tags        = ["truenas"]
}

globals {
  uses = ["truenas_app_data_root"]
}
