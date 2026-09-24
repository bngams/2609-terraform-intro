terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "4.6.0"
    }
  }
}

# Generic module: create X volumes from the input map, one per entry.
resource "docker_volume" "this" {
  for_each = var.volumes
  name     = each.value
}
