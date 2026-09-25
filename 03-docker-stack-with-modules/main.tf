# main.tf (root) — COMPOSITION happens here.
#
# The root:
#   1. calls the generic modules (images / networks / volumes)
#   2. reads their outputs
#   3. injects those outputs into the wordpress module
#
# Sibling modules never talk to each other directly: they communicate
# THROUGH the root. That is the whole point of this lab.

module "images" {
  source = "./modules/images"
  images = {
    wordpress = "wordpress:latest" # var.GLOBAL_CONFIG["WP_IMAGE"]
    mariadb   = "mariadb:10.6.4-focal"
  }
}

module "networks" {
  source = "./modules/networks"
  networks = {
    wp = "wp_net_${var.SERVER_NAME}"
  }
}

module "volumes" {
  source = "./modules/volumes"
  volumes = {
    wp = "wordpress_data_${var.SERVER_NAME}"
    db = "db_data_${var.SERVER_NAME}"
  }
}

module "wordpress" {
  source      = "./modules/wordpress"
  SERVER_NAME = var.SERVER_NAME
  WP_VARS     = var.WP_VARS
  WP_PORT     = var.WP_PORT

  # wiring: outputs of the generic modules -> inputs of the wordpress module
  network_name = module.networks.names["wp"]
  wp_image     = module.images.image_ids["wordpress"]
  db_image     = module.images.image_ids["mariadb"]
  wp_volume    = module.volumes.names["wp"]
  db_volume    = module.volumes.names["db"]
}
