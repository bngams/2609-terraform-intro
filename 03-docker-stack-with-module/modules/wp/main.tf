# LOCALS
locals {
  wp_volume_name = "wordpress_data_${var.SERVER_NAME}"
  db_volume_name = "db_data_${var.SERVER_NAME}"
  wp_network_name = "wp_net_${var.SERVER_NAME}"
  wp_container_name = "wp_container_${var.SERVER_NAME}"
  db_container_name = "db_container_${var.SERVER_NAME}"
  wp_image_name = "wordpress:latest"
  db_image_name = "mariadb:10.6.4-focal"
}


# IMAGES
resource "docker_image" "wordpress" {
  name = local.wp_image_name
}

resource "docker_image" "mariadb" {
  name = local.db_image_name
}

# NETWORKS
resource "docker_network" "wp_net" {
  name = local.wp_network_name
}

# VOLUMES
resource "docker_volume" "wp_data" {
  name = local.wp_volume_name
}

resource "docker_volume" "db_data" {
  name = local.db_volume_name
}

# CONTAINERS
resource "docker_container" "wordpress" {
  name  = local.wp_container_name
  image = local.wp_image_name
  networks_advanced {
    name = local.wp_network_name
  }
  volumes {
    volume_name    = local.wp_volume_name
    container_path = "/var/www/html"
  }
}

resource "docker_container" "mariadb" {
  name  = local.db_container_name
  image = local.db_image_name
  networks_advanced {
    name = local.wp_network_name
  }
  volumes {
    volume_name    = local.db_volume_name
    container_path = "/var/lib/mysql"
  }
}