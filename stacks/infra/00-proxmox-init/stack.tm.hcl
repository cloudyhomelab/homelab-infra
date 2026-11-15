stack {
  id   = "b5b23765-3fb0-40d7-80d0-6ac0ee7f96e2"
  tags = ["proxmox-root"]
}

globals {
  uses = ["token_rotation_days", "token_grace_days", "acme_account_name", "acme_contact_email"]
}
