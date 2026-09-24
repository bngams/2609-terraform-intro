# LOCALS
locals {
  wp_volume_name    = "wordpress_data_${var.SERVER_NAME}"
  db_volume_name    = "db_data_${var.SERVER_NAME}"
  wp_network_name   = "wp_net_${var.SERVER_NAME}"
  wp_container_name = "wp_container_${var.SERVER_NAME}"
  db_container_name = "db_container_${var.SERVER_NAME}"
  wp_image_name     = "wordpress:latest"
  db_image_name     = "mariadb:10.6.4-focal"
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

# --- MariaDB / MySQL ---
resource "docker_container" "mariadb" {
  name    = local.db_container_name
  image   = docker_image.mariadb.image_id # image_id => implicit dependency: pull before run
  restart = "always"

  env = [
    "MYSQL_ROOT_PASSWORD=${var.WP_VARS["MYSQL_ROOT_PWD"]}",
    "MYSQL_DATABASE=${var.WP_VARS["MYSQL_DB_NAME"]}",
    "MYSQL_USER=${var.WP_VARS["MYSQL_USER"]}",
    "MYSQL_PASSWORD=${var.WP_VARS["MYSQL_USER_PWD"]}"
  ]

  networks_advanced {
    name = docker_network.wp_net.name
  }

  volumes {
    volume_name    = docker_volume.db_data.name
    container_path = "/var/lib/mysql"
  }
}

# --- WordPress ---
resource "docker_container" "wordpress" {
  name    = local.wp_container_name
  image   = docker_image.wordpress.image_id
  restart = "always"

  env = [
    "WORDPRESS_DB_HOST=${local.db_container_name}",
    "WORDPRESS_DB_USER=${var.WP_VARS["MYSQL_USER"]}",
    "WORDPRESS_DB_PASSWORD=${var.WP_VARS["MYSQL_USER_PWD"]}",
    "WORDPRESS_DB_NAME=${var.WP_VARS["MYSQL_DB_NAME"]}"
  ]

  ports {
    internal = 80
    external = var.WP_PORT
  }

  networks_advanced {
    name = docker_network.wp_net.name
  }

  volumes {
    volume_name    = docker_volume.wp_data.name
    container_path = "/var/www/html"
  }
}
