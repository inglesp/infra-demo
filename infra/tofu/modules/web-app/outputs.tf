output "ipv4_address" {
  description = "The droplet's public IPv4 address"
  value       = digitalocean_droplet.this.ipv4_address
}
