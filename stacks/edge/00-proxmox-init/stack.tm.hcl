stack {
  id          = "ee303577-f3d1-498c-9072-96625260e4ac"
  name        = "00-proxmox-init"
  description = "Initial preparation steps for the Proxmox environment"
  tags        = ["proxmox-root"]
}

globals {
  uses = ["token_rotation_days", "token_grace_days", "acme_account_name", "acme_contact_email"]
}
