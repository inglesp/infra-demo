variable "name" {
  description = "The app's name, used as the droplet's name"
  type        = string
}

variable "region" {
  description = "The DigitalOcean region, e.g. lon1"
  type        = string
}

variable "size" {
  description = "The droplet size, e.g. s-1vcpu-1gb"
  type        = string
}

variable "ssh_key_ids" {
  description = "IDs of the DigitalOcean SSH keys that can log in as root"
  type        = list(string)
}
