variable "do_token" {}
variable "pvt_key" {}
variable "ssh_fingerprint" {}
variable "sentry_dsn" {}
variable "do_access_secret" {}
variable "do_access_key" {}

provider "digitalocean" {
  token = "${var.do_token}"
}
