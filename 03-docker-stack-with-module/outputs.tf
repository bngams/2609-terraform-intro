# Re-expose the module outputs at the root so `terraform output` shows them.
output "wordpress_url" {
  value = module.wp.wordpress_url
}

output "wp_container_name" {
  value = module.wp.wp_container_name
}

output "db_container_name" {
  value = module.wp.db_container_name
}

output "wp_network_name" {
  value = module.wp.wp_network_name
}
