output "ipv4_address" {
  description = "The droplet's public IPv4 address"
  value       = digitalocean_droplet.this.ipv4_address
}

output "volume_name" {
  description = "The name of the droplet's data volume"
  value       = digitalocean_volume.data.name
}
