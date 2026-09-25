variable "environment" {
  description = "Nom de l'environnement (sert au contenu et au nom du fichier généré)"
  type        = string
  default     = "dev"
}

# La MÊME ressource que dans test/, mais ce dossier a son PROPRE state
# (terraform.tfstate local à ce dossier) => aucune collision entre envs.
resource "local_file" "greeting" {
  content  = "Hello from ${var.environment} !\n"
  filename = "${path.module}/output/greeting_${var.environment}.txt"
}

output "file_path" {
  value = local_file.greeting.filename
}
