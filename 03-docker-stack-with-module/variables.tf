variable "SERVER_NAME" {
    description = "The server name for the WordPress site"
    type = string
    default = "localhost"

    # snake case, slug format
    validation {
        condition     = length(var.SERVER_NAME) > 0 && can(regex("^[a-z0-9_]+$", var.SERVER_NAME))
        error_message = "The server name must not be empty and must be in snake case (lowercase letters, numbers, and underscores only)"
    }
}

variable "WP_VARS" {
    description = "All WordPress variables"
    type = map(string)
    default = {
        MYSQL_ROOT_PWD = "MySQLRootPassword"
        MYSQL_DB_NAME = "wordpress"
        MYSQL_USER = "wp_user"
        MYSQL_USER_PWD = "wp_password"
    }
    sensitive = true
}