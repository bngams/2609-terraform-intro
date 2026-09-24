terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "4.6.0"
    }
  }
}

# Generic module: create X networks from the input map, one per entry.
resource "docker_network" "this" {
  for_each = var.networks
  name     = each.value
}
