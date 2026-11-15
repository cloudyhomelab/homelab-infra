stack {
  id   = "9e998a6d-bb95-4080-a65f-e0bf38d1547e"
  tags = ["proxmox"]
}

globals {
  uses = ["timezone", "acme_account_name", "pve_search_domain", "acme_dns", "porkbun_api_key", "porkbun_secret_api_key"]
}
