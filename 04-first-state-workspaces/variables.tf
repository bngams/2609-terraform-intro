# Variables alimentées par les fichiers env.<env>.tfvars (voir README).
variable "environment" {
  type        = string
  description = "Nom logique de l'environnement (dev, test, ...)"
}

variable "message" {
  type        = string
  description = "Message personnalisé injecté dans le fichier généré"
}