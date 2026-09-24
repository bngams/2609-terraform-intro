# A CHILD module must NOT contain a `provider` block.
# It only declares which providers it needs; the provider CONFIGURATION
# (the host, credentials, ...) is inherited from the root module.
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "4.6.0"
    }
  }
}
