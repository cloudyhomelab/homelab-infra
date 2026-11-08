locals {
  # tflint-ignore: terraform_unused_declarations
  s3_url = "http://moria.ip.cloudyhome.net:9000"

  # tflint-ignore: terraform_unused_declarations
  acme_dns = {
    plugin           = "porkbun"
    api              = "porkbun"
    validation_delay = 120

    data = {
      PORKBUN_API_KEY        = var.porkbun_api_key
      PORKBUN_SECRET_API_KEY = var.porkbun_secret_api_key
    }
  }
}
