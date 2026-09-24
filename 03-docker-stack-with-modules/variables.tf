variable "SERVER_NAME" {
  description = "The server name (suffix used to name all resources)"
  type        = string
  default     = "localhost"

  validation {
    condition     = length(var.SERVER_NAME) > 0 && can(regex("^[a-z0-9_]+$", var.SERVER_NAME))
    error_message = "The server name must be snake case (lowercase letters, numbers, underscores)."
  }
}

variable "WP_VARS" {
  description = "All WordPress / MySQL variables"
  type        = map(string)
  default = {
    MYSQL_ROOT_PWD = "MySQLRootPassword"
    MYSQL_DB_NAME  = "wordpress"
    MYSQL_USER     = "wp_user"
    MYSQL_USER_PWD = "wp_password"
  }
  sensitive = true
}

variable "WP_PORT" {
  description = "Host port exposed for WordPress"
  type        = number
  default     = 8888
}
