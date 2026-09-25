#!/bin/bash
# Script pour changer d'environnement Terraform en utilisant les workspaces.
# Usage : ./switch-env.sh <environment>

if [ -z "$1" ]; then
  echo "Veuillez spécifier l'environnement (dev, test, ...)."
  exit 1
fi

ENVIRONMENT=$1
# checkout de la branche correspondant à l'environnement
# git checkout "$ENVIRONMENT"
# sélection ou création du workspace Terraform correspondant à l'environnement
terraform workspace select "$ENVIRONMENT" || terraform workspace new "$ENVIRONMENT"
echo "Environnement Terraform changé pour : $ENVIRONMENT"
# create the env.auto.tfvars from the environment-specific tfvars file
cp "env.${ENVIRONMENT}.tfvars" "env.auto.tfvars"