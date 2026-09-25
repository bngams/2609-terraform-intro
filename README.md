# Terraform — Formation AELION 2609

Support de formation **Terraform** : des scénarios guidés (labs à compléter soi-même,
avec un dossier `solution/`), le code des démos, des schémas de synthèse et les tableaux
blancs de la session.

> 🧭 **Par où commencer ?** Faites d'abord le [0 — Installation & concepts](00-labs/0-SETUP.md),
> puis déroulez les scénarios dans l'ordre.

---

## 🚀 Labs — les scénarios

Chaque lab est un énoncé « à compléter » (`# TODO`) ; le code de référence vit dans le
dossier de démo associé.

| # | Scénario | Code / démo |
|---|---|---|
| 0 | [Terraform : installation & concepts](00-labs/0-SETUP.md) | — |
| 1 | [Première configuration Terraform](00-labs/1-FIRST-CONFIG.md) | [01-first-demo/](01-first-demo/) |
| 2 | [Du Docker au Terraform (provider `docker`)](00-labs/2-DOCKER-PROVIDER.md) | [02-docker-local-demo/](02-docker-local-demo/) · [03-docker-stack/](03-docker-stack/) |
| 3 | [HCL avancé : variables, structures, boucles, modules](00-labs/3-HCL-AVANCE.md) | [03-docker-stack-with-modules/](03-docker-stack-with-modules/) |
| 4 | [Le state distant & le verrouillage](00-labs/4-STATE.md) | [04-first-state-environments/](04-first-state-environments/) |
| 4·bonus | [Un state ≠ plusieurs envs — un dossier par environnement](00-labs/4-BONUS-STATE-ENVIRONMENTS.md) | [04-first-state-environments/](04-first-state-environments/) |
| 4·bonus | [Un state ≠ plusieurs envs — les workspaces](00-labs/4-BONUS-STATE-WORKSPACES.md) | [04-first-state-workspaces/](04-first-state-workspaces/) |
| 4·bonus | [Terragrunt : ne répétez plus vos variables](00-labs/4-BONUS-TERRAGRUNT.md) | [05-terragrunt/](05-terragrunt/) |
| 5 | [LocalStack & un site statique S3](00-labs/5-LOCALSTACK.md) | [06-aws-terraform-intro-static-website/](06-aws-terraform-intro-static-website/) |
| 5 | [Terragrunt : ne répétez plus vos variables](00-labs/5-TERRAGRUNT.md) | [05-terragrunt/](05-terragrunt/) |
| 6 | [Brancher Terraform dans GitLab CI (l'environnement à la demande)](00-labs/6-ONDEMAND-ENV.md) | [06-aws-terraform-intro-simple-ec2/](06-aws-terraform-intro-simple-ec2/) |
| 7 | [Un pipeline GitLab qui provisionne un EC2 (dev / prod)](00-labs/7-GITLAB-PIPELINE-TF-EC2.md) | [07-gitlab-ci-terraform-ec2/](07-gitlab-ci-terraform-ec2/) |
| 8 | [Revue : votre infra, vos choix](00-labs/8-REVIEW.md) | — |

> 🦊 **Exemple de pipeline Terraform en ligne :**
> [gitlab.com/bngams/aelion-2609-terraform-pipeline-demo](https://gitlab.com/bngams/aelion-2609-terraform-pipeline-demo)
> — le pipeline du lab 7, déployé et exécutable sur GitLab.

---

## 🖼️ Ressources — les schémas de synthèse

Des visuels récapitulatifs à afficher / distribuer.

| Schéma | Aperçu |
|---|---|
| **Terraform : gérer plusieurs environnements** (variables + nommage + workspaces) | [PNG](00-ressources/Terraform_gerer_plusieurs_env.png) |
| **Terragrunt : mutualiser les variables** (config centralisée, moins de duplication) | [PNG](00-ressources/Terragrunt_gerer_plusieurs_env.png) |
| **Pipeline CI/CD × Terraform : environnements à la demande** (secrets, pipeline type, env par branche, enjeux) | [HTML interactif](00-ressources/Pipeline_env_a_la_demande.html) · [PNG](00-ressources/Terraform_pipelines_on_demand_envs.png) |

---

## ✍️ Tableaux blancs

Les schémas dessinés en séance (fichiers [Excalidraw](https://excalidraw.com) — ouvrez le
`.excalidraw`, ou consultez l'aperçu `.svg`).

- [terraform-2026-09-25-1654.excalidraw](terraform-2026-09-25-1654.excalidraw) — tableau blanc de session · [aperçu SVG](terraform-2026-09-25-1654.svg)
- [ssh-key-flow.excalidraw](07-gitlab-ci-terraform-ec2/ssh-key-flow.excalidraw) — flux des clés SSH dans le pipeline (lab 7)

---

## 📂 Code des démos

Tous les dossiers de code, dans l'ordre du parcours :

- [01-first-demo/](01-first-demo/)
- [02-docker-local-demo/](02-docker-local-demo/)
- [03-docker-stack/](03-docker-stack/) · [03-docker-stack-with-module/](03-docker-stack-with-module/) · [03-docker-stack-with-modules/](03-docker-stack-with-modules/)
- [04-first-state-environments/](04-first-state-environments/) · [04-first-state-workspaces/](04-first-state-workspaces/)
- [05-terragrunt/](05-terragrunt/)
- [06-aws-terraform-intro-simple-ec2/](06-aws-terraform-intro-simple-ec2/) · [06-aws-terraform-intro-static-website/](06-aws-terraform-intro-static-website/)
- [07-gitlab-ci-terraform-ec2/](07-gitlab-ci-terraform-ec2/)
