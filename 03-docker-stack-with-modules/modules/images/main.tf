terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "4.6.0"
    }
  }
}

# Generic module: pull X images from the input map, one per entry.
resource "docker_image" "this" {
  for_each = var.images
  name     = each.value
}
