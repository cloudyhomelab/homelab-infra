stack {
  id   = "f0ca6ccb-dbae-44b9-8a2b-15fe431feec0"
  tags = ["proxmox"]
}

globals {
  uses = ["timezone", "acme_account_name", "pve_search_domain", "acme_dns", "porkbun_api_key", "porkbun_secret_api_key"]
}
