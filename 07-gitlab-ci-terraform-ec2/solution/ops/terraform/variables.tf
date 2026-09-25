variable "aws_region" {
  description = "Region AWS de deploiement"
  type        = string
  default     = "eu-west-3"
}

variable "environment" {
  description = "Nom de l'environnement (dev / prod) - fixe par le var-file"
  type        = string
}

variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t3.micro"
}

variable "ssh_public_key" {
  description = "Cle publique SSH, injectee depuis le secret CI/CD SSH_PUBLIC_KEY"
  type        = string
}
