stack {
  id          = "9d612b7d-6529-46dd-ade5-c15a40c108f3"
  name        = "17-storage"
  description = "TrueNAS datasets and NFS shares for all VMs in the environment"
  tags        = ["truenas"]
  after       = ["/stacks/edge", "/stacks/network"]
  watch = [
    "/stacks/infra/vms.yaml",
  ]
}

globals {
  uses = ["truenas_app_data_root"]
}
