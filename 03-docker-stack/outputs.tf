output "container_wordpress_id" {
  description = "My WordPress container id"
  value = docker_container.wordpress.id
}

output "container_mysql_id" {
  description = "My MySQL container id"
  value = docker_container.mysql.id
}