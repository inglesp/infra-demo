output "ipv4_address" {
  description = "The droplet's public IPv4 address"
  value       = digitalocean_droplet.this.ipv4_address
}

output "domain" {
  description = "The app's domain"
  value       = digitalocean_domain.this.name
}

output "volume_name" {
  description = "The name of the droplet's data volume"
  value       = digitalocean_volume.data.name
}
