terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "4.6.0"
    }
  }
}

# Provider configuration lives in the ROOT module only.
# Child modules inherit it (they just declare required_providers).
provider "docker" {
  host = "unix:///var/run/docker.sock"
}
