# OUTPUTS
output "wp_container_name" {
  value = docker_container.wordpress.name
}

output "db_container_name" {
  value = docker_container.mariadb.name
}

output "wp_volume_name" {
  value = docker_volume.wp_data.name
}

output "db_volume_name" {
  value = docker_volume.db_data.name
}

output "wp_network_name" {
  value = docker_network.wp_net.name
}

output "wordpress_url" {
  value = "http://localhost:${var.WP_PORT}"
}
