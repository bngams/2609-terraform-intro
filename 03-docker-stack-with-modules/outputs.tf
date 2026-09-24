output "wordpress_url" {
  value = module.wordpress.wordpress_url
}

output "wp_container_name" {
  value = module.wordpress.wp_container_name
}

output "db_container_name" {
  value = module.wordpress.db_container_name
}

output "network_ids" {
  value = module.networks.ids
}

output "volume_ids" {
  value = module.volumes.ids
}

output "image_ids" {
  value = module.images.image_ids
}
