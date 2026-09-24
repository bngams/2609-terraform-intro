
# Variables for the module
# We need to redeclare them 
# if we want to populate them 
# in the global project (with *.auto.tfvars for instance)
# variable "SERVER_NAME" {}
# variable "WP_PORT" {}
# variable "WP_VARS" {}

# An idea is to use a global config map
# to avoid redeclaring each variable individually
# and avoid variables duplication ()
variable "GLOBAL_CONFIG" {
  description = "Global configuration for the Docker stack"
  type        = map(string)
  default     = {
    ENVIRONMENT = "development"
    SERVER_NAME = "localhost"
    WP_PORT     = 8888
    WP_VARS = {
      MYSQL_ROOT_PWD = "MySQLRootPassword"
      MYSQL_DB_NAME  = "wordpress"
      MYSQL_USER     = "wp_user"
      MYSQL_USER_PWD = "wp_password"
    }
  }
} 
