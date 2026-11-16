stack {
  id          = "9e998a6d-bb95-4080-a65f-e0bf38d1547e"
  name        = "10-proxmox-base"
  description = "Prepare the Proxmox environment for deployments"
  tags        = ["proxmox"]
  watch = [
    "/global-data/ipam.yaml",
  ]
}

globals {
  uses = ["timezone", "acme_account_name", "pve_search_domain", "acme_dns", "porkbun_api_key", "porkbun_secret_api_key"]
}
