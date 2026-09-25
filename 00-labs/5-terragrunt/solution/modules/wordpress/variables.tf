variable "SERVER_NAME" {
  description = "Nom de l'environnement (sert à préfixer toutes les ressources)"
  type        = string

  validation {
    condition     = length(var.SERVER_NAME) > 0 && can(regex("^[a-z0-9_]+$", var.SERVER_NAME))
    error_message = "SERVER_NAME doit être en snake_case (minuscules, chiffres, underscores)."
  }
}

variable "WP_VARS" {
  description = "Identifiants WordPress / MySQL"
  type        = map(string)
  sensitive   = true
}

variable "WP_PORT" {
  description = "Port hôte exposé pour WordPress (port conteneur 80)"
  type        = number
  default     = 8888
}
