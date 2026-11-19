stack {
  id          = "461404b5-b1ef-4dd7-8ce1-b2c8d6c6f339"
  name        = "25-dns-records"
  description = "Static DNS records and the RPZ allow/deny lists"
  tags        = ["dns", "http"]
  watch = [
    "/stacks/edge/bootstrap-static-dns.yaml",
  ]
}

globals {
  uses = ["reverse_zone"]
}
