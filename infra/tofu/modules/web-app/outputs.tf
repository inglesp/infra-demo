output "ipv4_address" {
  description = "The droplet's public IPv4 address"
  value       = digitalocean_droplet.this.ipv4_address
}

output "domain" {
  description = "The app's domain"
  value       = digitalocean_domain.this.name
}

output "secret_key" {
  description = "The app's Django secret key"
  value       = random_password.secret_key.result
  sensitive   = true
}

output "volume_name" {
  description = "The name of the droplet's data volume"
  value       = digitalocean_volume.data.name
}
