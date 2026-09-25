terraform {
  # S3 native locking (use_lockfile) demande Terraform >= 1.10
  required_version = ">= 1.10"

  # Backend S3 PARTIEL : bucket + region sont ici, mais la clé (key) du state
  # est fournie au `terraform init` par le pipeline -> une clé par environnement.
  # (cf. section 2 du README : -backend-config="key=ec2/${TF_ENV}/terraform.tfstate")
  backend "s3" {
    bucket       = "aelion-2609-borisn" # TODO : mettez le nom de VOTRE bucket S3
    region       = "eu-west-3"
    use_lockfile = true # verrou natif S3 (pas besoin de DynamoDB)
    # key est volontairement absente ici : injectee au init selon la branche
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Aucune credential ici : le provider (comme le backend S3) lit automatiquement
# les variables d'environnement AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY /
# AWS_DEFAULT_REGION, injectees par les secrets GitLab CI/CD.
provider "aws" {
  region = var.aws_region
}
