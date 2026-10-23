locals {
  # The name of an SSH key uploaded to DigitalOcean, which can log in as root
  ssh_key_name = "inglesp"

  # One droplet per app
  apps = {
    infra-demo = {
      region = "lon1"
      size   = "s-1vcpu-1gb"
    }
  }
}

data "digitalocean_ssh_key" "admin" {
  name = local.ssh_key_name
}

module "web_app" {
  source   = "./modules/web-app"
  for_each = local.apps

  name        = each.key
  region      = each.value.region
  size        = each.value.size
  ssh_key_ids = [data.digitalocean_ssh_key.admin.id]
}

output "ips" {
  description = "Each app's droplet's public IPv4 address"
  value       = { for name, app in module.web_app : name => app.ipv4_address }
}
