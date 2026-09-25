variable "environment" {
  description = "Nom de l'environnement (sert au contenu et au nom du fichier généré)"
  type        = string
  default     = "test"
}

# Même ressource que dans dev/, state SÉPARÉ (propre à ce dossier).
resource "local_file" "greeting" {
  content  = "Hello from ${var.environment} !\n"
  filename = "${path.module}/output/greeting_${var.environment}.txt"
}

output "file_path" {
  value = local_file.greeting.filename
}
