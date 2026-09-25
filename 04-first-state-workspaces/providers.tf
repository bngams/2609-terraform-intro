terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }

  # ❌ CE QU'ON AIMERAIT FAIRE (mais qui est INTERDIT) :
  #
  # variable "environment" { type = string }
  # backend "local" {
  #   path = "terraform.tfstate.d/${var.environment}/terraform.tfstate"
  # }
  #
  # => Error: Variables not allowed
  #    A backend block cannot refer to named values (variables, locals, ...).
  #
  # La réponse de Terraform à ce besoin : les WORKSPACES (voir README).
  # backend "local" implicite => les states des workspaces vont dans
  # terraform.tfstate.d/<workspace>/terraform.tfstate, automatiquement.
}

provider "local" {}
