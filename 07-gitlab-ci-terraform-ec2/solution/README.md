# Solution — 7 · Pipeline GitLab + Terraform (EC2 dev/prod)

Version complète et fonctionnelle du lab [../README.md](../README.md). **À ne consulter qu'en
cas de blocage.**

## Contenu

```
solution/
├── .gitlab-ci.yml                 # pipeline complet (fmt/validate/plan auto ; apply/ssh/destroy manuels)
├── .gitignore                     # secrets, cles, state -> jamais dans Git
└── ops/terraform/
    ├── providers.tf               # backend S3 partiel + provider AWS (credentials via env)
    ├── variables.tf
    ├── main.tf                    # VPC default + AMI AL2023 + key_pair + SG + instance + nginx
    ├── outputs.tf
    └── environments/
        ├── dev.tfvars             # environment=dev, t3.micro
        └── prod.tfvars            # environment=prod, t3.small
```

## Pour l'utiliser dans un vrai projet GitLab

1. Copiez `.gitlab-ci.yml` et le dossier `ops/` à la **racine** de votre dépôt.
2. Adaptez `bucket` dans `ops/terraform/providers.tf` (votre bucket S3, qui doit exister).
3. Créez les 5 variables CI/CD (voir section 4 du README) et **protégez les branches `dev` et
   `main`**.
4. Poussez sur `dev`, puis lancez le job manuel `apply`.

Le `.gitlab-ci.yml` de cette solution inclut le **bonus dotenv** (URL cliquable sur
l'environnement via `DEPLOY_URL`).
