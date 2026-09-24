# Pulls the image (or use a data source image "docker_image" to reference an existing image)
resource "docker_image" "ubuntu" {
  name = "ubuntu:latest"
}

# Volume for persistent storage (optional)
resource "docker_volume" "my_tf_demo_volume" {
  name = "my_tf_demo_volume"
}

# Network for the container (optional)
resource "docker_network" "my_tf_demo_network" {
  name = "my_tf_demo_network"
}

# Create a container
resource "docker_container" "my_tf_demo_container" {
  image = docker_image.ubuntu.image_id
  name  = "my_tf_demo_container"
  command = ["sleep", "infinity"]
  volumes {
    volume_name = docker_volume.my_tf_demo_volume.name
    container_path = "/my_tf_demo_volume"
  }
  networks_advanced {
    name = docker_network.my_tf_demo_network.name
  }
}


# Outputs the container ID
output "my_tf_demo_container_id" {
  value = docker_container.my_tf_demo_container.id
}
output "my_tf_demo_volume_id" {
  value = docker_volume.my_tf_demo_volume.id
}
output "my_tf_demo_network_id" {
  value = docker_network.my_tf_demo_network.id
}