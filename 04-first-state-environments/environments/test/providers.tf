terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
  # backend "local" implicite => ./terraform.tfstate propre à ce dossier.
}

provider "local" {}
