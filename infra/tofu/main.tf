locals {
  # The name of an SSH key uploaded to DigitalOcean, which can log in as root
  ssh_key_name = "inglesp"

  # One droplet per app
  apps = {
    infra-demo = {
      region      = "lon1"
      size        = "s-1vcpu-1gb"
      volume_size = 1 # GiB
      domain      = "infra-demo.opensafely.org"
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
  volume_size = each.value.volume_size
  domain      = each.value.domain
  ssh_key_ids = [data.digitalocean_ssh_key.admin.id]
}

output "ips" {
  description = "Each app's droplet's public IPv4 address"
  value       = { for name, app in module.web_app : name => app.ipv4_address }
}

output "ansible_inventory" {
  description = "Ansible inventory, as JSON, for just configure"
  # It includes each app's secret key
  sensitive = true
  value = {
    all = {
      hosts = {
        for name, app in module.web_app : name => {
          ansible_host = app.ipv4_address
          domain       = app.domain
          secret_key   = app.secret_key
          volume_name  = app.volume_name
        }
      }
    }
  }
}
