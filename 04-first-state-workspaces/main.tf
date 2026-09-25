# Une SEULE config, plusieurs states grâce aux WORKSPACES.
# `terraform.workspace` vaut "default", puis "dev" / "test" une fois créés.

# Le locals dérive l'EMPLACEMENT et le CONTENU du fichier à partir
# des variables d'environnement (tfvars) ET du workspace courant.
locals {
  # -> l'emplacement change : un sous-dossier par environnement
  output_dir = "${path.module}/output/${var.environment}"
  file_path  = "${local.output_dir}/greeting_${terraform.workspace}.txt"

  # -> le contenu change : message spécifique à l'environnement
  content = <<-EOT
    Hello from workspace "${terraform.workspace}" (env = ${var.environment}) !
    ${var.message}
  EOT
}

resource "local_file" "greeting" {
  content  = local.content
  filename = local.file_path
}
