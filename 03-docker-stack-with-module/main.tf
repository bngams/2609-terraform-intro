# main.tf (racine)
module "wp" {
  source         = "./modules/wp"
  SERVER_NAME    = var.SERVER_NAME
  WP_VARS        = var.WP_VARS  
}