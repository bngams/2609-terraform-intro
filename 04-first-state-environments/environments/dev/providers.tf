terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5" # existe côté Terraform ET OpenTofu
    }
  }
  # Pas de bloc `backend` => backend "local" implicite :
  # le state vit dans CE dossier (./terraform.tfstate). Chaque env = son state.
}

provider "local" {}
