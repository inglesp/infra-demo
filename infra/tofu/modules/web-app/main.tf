terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
    }
  }
}

resource "digitalocean_droplet" "this" {
  name       = var.name
  image      = "ubuntu-24-04-x64"
  region     = var.region
  size       = var.size
  ssh_keys   = var.ssh_key_ids
  ipv6       = true
  volume_ids = [digitalocean_volume.data.id]

  lifecycle {
    # Changing either would replace the droplet. A new image only matters
    # for new droplets, and SSH keys are managed on the droplet once it's
    # created.
    ignore_changes = [image, ssh_keys]
  }
}

resource "digitalocean_volume" "data" {
  name                     = "${var.name}-data"
  region                   = var.region
  size                     = var.volume_size
  initial_filesystem_type  = "ext4"
  initial_filesystem_label = "data"
  description              = "Persistent data for ${var.name}"

  lifecycle {
    # Holds all persistent data, so OpenTofu refuses to destroy it
    prevent_destroy = true
  }
}

locals {
  anywhere = ["0.0.0.0/0", "::/0"]
}

resource "digitalocean_firewall" "this" {
  name        = var.name
  droplet_ids = [digitalocean_droplet.this.id]

  # Open to everyone until SSH is closed; logins are key-only
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = local.anywhere
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = local.anywhere
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = local.anywhere
  }

  # HTTP/3
  inbound_rule {
    protocol         = "udp"
    port_range       = "443"
    source_addresses = local.anywhere
  }

  # Needed for IPv6 path MTU discovery, and allows ping
  inbound_rule {
    protocol         = "icmp"
    source_addresses = local.anywhere
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = local.anywhere
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = local.anywhere
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = local.anywhere
  }
}

resource "digitalocean_domain" "this" {
  name = var.domain
}

resource "digitalocean_record" "a" {
  domain = digitalocean_domain.this.id
  type   = "A"
  name   = "@"
  value  = digitalocean_droplet.this.ipv4_address
}

resource "digitalocean_record" "aaaa" {
  domain = digitalocean_domain.this.id
  type   = "AAAA"
  name   = "@"
  value  = digitalocean_droplet.this.ipv6_address
}
