terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "4.6.0"
    }
  }
}

locals {
  wp_container_name = "wp_container_${var.SERVER_NAME}"
  db_container_name = "db_container_${var.SERVER_NAME}"
}

# This module ONLY creates the containers.
# Networks / volumes / images are created by the other modules and their
# values are injected through the variables above (wiring done in the root).

# --- MariaDB / MySQL ---
resource "docker_container" "mariadb" {
  name    = local.db_container_name
  image   = var.db_image
  restart = "always"

  env = [
    "MYSQL_ROOT_PASSWORD=${var.WP_VARS["MYSQL_ROOT_PWD"]}",
    "MYSQL_DATABASE=${var.WP_VARS["MYSQL_DB_NAME"]}",
    "MYSQL_USER=${var.WP_VARS["MYSQL_USER"]}",
    "MYSQL_PASSWORD=${var.WP_VARS["MYSQL_USER_PWD"]}"
  ]

  networks_advanced {
    name = var.network_name
  }

  volumes {
    volume_name    = var.db_volume
    container_path = "/var/lib/mysql"
  }
}

# --- WordPress ---
resource "docker_container" "wordpress" {
  name    = local.wp_container_name
  image   = var.wp_image
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
    name = var.network_name
  }

  volumes {
    volume_name    = var.wp_volume
    container_path = "/var/www/html"
  }
}
