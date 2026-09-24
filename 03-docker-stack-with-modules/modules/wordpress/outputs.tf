output "wp_container_name" {
  value = docker_container.wordpress.name
}

output "db_container_name" {
  value = docker_container.mariadb.name
}

output "wordpress_url" {
  value = "http://localhost:${var.WP_PORT}"
}
