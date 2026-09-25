# =============================================================================
# root.hcl  —  CONFIGURATION GLOBALE (racine)
# Héritée par TOUS les environnements de live/ via un bloc `include`.
# (Terragrunt récent recommande `root.hcl` plutôt que `terragrunt.hcl` à la racine.)
# =============================================================================

# Terragrunt récent utilise OpenTofu (`tofu`) par défaut. On le force sur
# `terraform` pour rester cohérent avec le reste du cours.
terraform_binary = "terraform"

# 1) Quel module Terraform exécuter — le MÊME pour tous les environnements.
#    Le `//` indique à Terragrunt où commence la racine du module à copier.
terraform {
  source = "${get_parent_terragrunt_dir()}/modules//wordpress"
}

# 2) Backend (où vit le state).
#    En Terraform pur, le bloc `backend` ne peut PAS être variabilisé.
#    Terragrunt le génère pour nous -> un state ISOLÉ par environnement,
#    rangé automatiquement d'après le chemin du dossier.
remote_state {
  backend = "local"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    path = "${get_parent_terragrunt_dir()}/state/${path_relative_to_include()}/terraform.tfstate"
  }
}

# 3) Variables communes à TOUS les environnements — déclarées UNE SEULE FOIS.
inputs = {
  # SERVER_NAME est déduit du nom du dossier (dev, staging, …) : plus besoin
  # de le répéter ni de risquer un copier-coller oublié.
  SERVER_NAME = basename(get_terragrunt_dir())

  WP_VARS = {
    MYSQL_ROOT_PWD = "MySQLRootPassword"
    MYSQL_DB_NAME  = "wordpress"
    MYSQL_USER     = "wp_user"
    MYSQL_USER_PWD = "wp_password"
  }
}
