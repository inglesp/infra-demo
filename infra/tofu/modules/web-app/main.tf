terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
    }
  }
}

resource "digitalocean_droplet" "this" {
  name     = var.name
  image    = "ubuntu-24-04-x64"
  region   = var.region
  size     = var.size
  ssh_keys = var.ssh_key_ids
  ipv6     = true
}
