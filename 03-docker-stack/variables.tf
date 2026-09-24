variable "MYSQL_ROOT_PWD" {
  description = "MySQL root password"
  sensitive = true
  type = string
  # default = "MySQLRootPassword" # not mandatory, but good for demo purposes
}

variable "MYSQL_DB_NAME" {
  description = "MySQL database name"
  sensitive = true
  type = string
  # default = "wordpress" # not mandatory, but good for demo purposes
}

variable "MYSQL_USER" {
  description = "MySQL user name"
  sensitive = true
  type = string
  # default = "wp_user" # not mandatory, but good for demo purposes
}

variable "MYSQL_USER_PWD" {
  description = "MySQL user password"
  sensitive = true
  type = string
  # default = "wp_password" # not mandatory, but good for demo purposes
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