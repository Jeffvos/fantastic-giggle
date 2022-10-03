provider "vault" {
    address = "http://127.0.0.1:8200"
    token = var.vault_token
}

data "vault_generic_secret" "saved_secret" {
  path = "secret/app"
}