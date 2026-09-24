terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "4.6.0"
    }
  }
}

# Provider configuration lives in the ROOT only; every child module inherits it.
provider "docker" {
  host = "unix:///var/run/docker.sock"
}
