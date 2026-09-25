# Ce module est appelé DIRECTEMENT par Terragrunt : c'est donc lui le "root module"
# du point de vue de Terraform. Il porte donc SA configuration de provider.
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "4.6.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}
