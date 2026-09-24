# main.tf (root)
# One module encapsulating the WHOLE stack (images + network + volumes + containers).
module "wp" {
  source      = "./modules/wp"
  SERVER_NAME = var.GLOBAL_CONFIG["SERVER_NAME"]
  WP_VARS     = var.GLOBAL_CONFIG["WP_VARS"]
  # variable from module = variable from project/global configuration
  WP_PORT     = var.GLOBAL_CONFIG["WP_PORT"]
}