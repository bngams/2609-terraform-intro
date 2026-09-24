variable "SERVER_NAME" {
  description = "The server name (used to name the containers)"
  type        = string

  validation {
    condition     = length(var.SERVER_NAME) > 0 && can(regex("^[a-z0-9_]+$", var.SERVER_NAME))
    error_message = "The server name must be snake case (lowercase letters, numbers, underscores)."
  }
}

variable "WP_VARS" {
  description = "WordPress / MySQL credentials & db name"
  type        = map(string)
  sensitive   = true
}

variable "WP_PORT" {
  description = "Host port exposed for WordPress (container port 80)"
  type        = number
  default     = 8888
}

# --- Values injected FROM the other modules (via the root) ---

variable "network_name" {
  description = "Docker network name the containers attach to (from networks module)"
  type        = string
}

variable "wp_image" {
  description = "WordPress image id (from images module)"
  type        = string
}

variable "db_image" {
  description = "MariaDB image id (from images module)"
  type        = string
}

variable "wp_volume" {
  description = "WordPress volume name (from volumes module)"
  type        = string
}

variable "db_volume" {
  description = "DB volume name (from volumes module)"
  type        = string
}
