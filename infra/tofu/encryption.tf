variable "state_passphrase" {
  description = "Passphrase for encrypting OpenTofu state (at least 16 characters)"
  type        = string
  sensitive   = true
}

terraform {
  encryption {
    key_provider "pbkdf2" "main" {
      passphrase = var.state_passphrase
    }

    method "aes_gcm" "main" {
      keys = key_provider.pbkdf2.main
    }

    # Lets existing unencrypted state be read, so that it can be rewritten
    # encrypted. Removed once that's done.
    method "unencrypted" "migrate" {}

    state {
      method = method.aes_gcm.main

      fallback {
        method = method.unencrypted.migrate
      }
    }
  }
}
