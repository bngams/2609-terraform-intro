# 4 — Le state distant & le verrouillage

Suite de [3](3-HCL-AVANCE.md). Jusqu'ici votre `terraform.tfstate` est un **fichier local**.
Ça marche en solo, mais **pas à plusieurs ni dans un pipeline**. Ce chapitre règle le problème
du state partagé — la dernière brique avant de brancher Terraform dans GitLab CI (6).

### Ressources utiles

- [State (concept)](https://developer.hashicorp.com/terraform/language/state) ·
  [Backends](https://developer.hashicorp.com/terraform/language/backend) ·
  [Backend `http`](https://developer.hashicorp.com/terraform/language/backend/http)
- [State locking](https://developer.hashicorp.com/terraform/language/state/locking)
- [GitLab-managed Terraform/OpenTofu state](https://docs.gitlab.com/user/infrastructure/iac/terraform_state/)

---

## Pourquoi le state local pose problème

Rappel ([1](1-FIRST-CONFIG.md)) : le `tfstate` est la **mémoire** de Terraform. En local,
trois problèmes apparaissent dès qu'on n'est plus seul :

| Problème | Conséquence |
|---|---|
| **Pas partagé** | un collègue (ou le runner CI) n'a pas votre state → Terraform veut tout recréer |
| **Pas de verrou** | deux `apply` en même temps → state **corrompu** |
| **Secrets en clair** | le state contient les valeurs `sensitive` → **jamais dans git** |

> **🧪 Manip — voir le risque (sans verrou)**
>
> Sur la stack 3, lancez **deux `terraform apply` en parallèle** (deux terminaux).
> Avec un state local, **rien ne les empêche** de s'écraser mutuellement.
>
> *Observation : en équipe / en CI, il faut un state **partagé et verrouillé**. C'est le rôle
> d'un **backend distant**.*

---

## La solution : un backend distant

Un **backend** définit **où** est stocké le state. Le backend `local` (par défaut) le met dans
un fichier ; un backend **distant** le met dans un service partagé, **avec verrouillage**.

Options courantes : S3+DynamoDB (AWS), Azure Storage, GCS… et — c'est ce qu'on va utiliser —
le **backend `http` managé par GitLab**.

> **Pourquoi le backend GitLab ?** Cohérent avec tout le lab : **le state vit dans GitLab**, à
> côté du code et du pipeline. **Aucun service supplémentaire**, verrouillage inclus, auth par
> le token de job. Pas de bucket S3 ni de table de lock à gérer.

---

## Le backend HTTP managé par GitLab

GitLab expose, **par projet**, une API de state Terraform. L'adresse suit ce schéma :

```
${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/terraform/state/${TF_STATE_NAME}
```

On déclare un backend `http` **vide** dans le code (les valeurs viendront de `init`) :

```hcl
# providers.tf
terraform {
  backend "http" {}        # configuré au moment du `terraform init`
}
```

> ⚠️ Un backend **ne peut pas utiliser de variables** (`var.*`). On passe donc sa config via
> `-backend-config=...` au `terraform init`, ou via des variables d'environnement `TF_HTTP_*`.

### En local (depuis votre poste)

```bash
PROJECT_ID="<votre-project-id>"          # Settings > General
STATE_NAME="wp-lab"
GITLAB="https://gitlab.example.com"      # ou https://gitlab.com
TOKEN="<un Personal Access Token scope api>"

terraform init \
  -backend-config="address=${GITLAB}/api/v4/projects/${PROJECT_ID}/terraform/state/${STATE_NAME}" \
  -backend-config="lock_address=${GITLAB}/api/v4/projects/${PROJECT_ID}/terraform/state/${STATE_NAME}/lock" \
  -backend-config="unlock_address=${GITLAB}/api/v4/projects/${PROJECT_ID}/terraform/state/${STATE_NAME}/lock" \
  -backend-config="username=<votre-user-gitlab>" \
  -backend-config="password=${TOKEN}" \
  -backend-config="lock_method=POST" \
  -backend-config="unlock_method=DELETE" \
  -backend-config="retry_wait_min=5"
```

### Dans un pipeline GitLab (6)

Dans la CI, c'est **plus simple** : GitLab fournit tout via des variables prédéfinies, et l'auth
se fait avec le **`$CI_JOB_TOKEN`** (éphémère, rien à stocker — comme pour le registre en
[J1-4](../J1-GITLAB/J1-4-BUILD-IMAGE.md)).

```yaml
# extrait .gitlab-ci.yml (détaillé en 6)
variables:
  TF_STATE_NAME: "wp-lab"
  TF_HTTP_ADDRESS: "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/terraform/state/${TF_STATE_NAME}"
  TF_HTTP_LOCK_ADDRESS: "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/terraform/state/${TF_STATE_NAME}/lock"
  TF_HTTP_UNLOCK_ADDRESS: "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/terraform/state/${TF_STATE_NAME}/lock"
  TF_HTTP_USERNAME: "gitlab-ci-token"
  TF_HTTP_PASSWORD: "${CI_JOB_TOKEN}"
  TF_HTTP_LOCK_METHOD: "POST"
  TF_HTTP_UNLOCK_METHOD: "DELETE"
```

> Les variables `TF_HTTP_*` sont lues automatiquement par le backend `http` → un simple
> `terraform init` suffit dans le job.

---

## Migrer le state local vers GitLab

> **🧪 Manip — migration + verrou**
>
> 1. Ajoutez `backend "http" {}` dans `providers.tf`.
> 2. Lancez le `terraform init` avec les `-backend-config` ci-dessus. Terraform détecte le
>    changement de backend et propose de **migrer le state existant** → répondez **yes**.
> 3. Dans GitLab : **Operate > Terraform states** → votre state `wp-lab` apparaît, avec sa
>    taille et la date.
> 4. **Tester le verrou** : lancez un `terraform plan` qui dure, et en parallèle un autre
>    `apply` → le second affiche **« Error acquiring the state lock »**. C'est le verrouillage
>    qui protège le state.
>    - Débloquer manuellement si besoin : `terraform force-unlock <LOCK_ID>`.
>
> *Observation : state **partagé** (visible dans GitLab) + **verrouillé** (un seul apply à la
> fois), sans S3 ni DynamoDB.*

---

## Variante lab : un backend S3-compatible (MinIO / RustFS)

Le backend GitLab est notre choix. Mais dans un lab **sans GitLab** (ou pour pratiquer le
**`backend "s3"`** qu'on retrouvera côté AWS), on peut héberger un service **S3-compatible**
localement — **MinIO** (ou **RustFS**) — et l'ajouter au `compose.yml` du lab :

```hcl
terraform {
  backend "s3" {
    bucket                      = "tfstate"
    key                         = "wp-lab/terraform.tfstate"
    endpoints                   = { s3 = "http://localhost:9000" }   # MinIO
    region                      = "us-east-1"
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    use_path_style              = true
  }
}
```

> C'est le **même `backend "s3"`** que pour un vrai bucket AWS (qu'on verra en
> [5](5-LOCALSTACK.md)) — seuls les `endpoints`/skips changent. Pratique pour acquérir le
> réflexe S3 sans cloud. **Pour la suite du lab, on reste sur le backend GitLab.**

---

## Recap

- Le state **local** ne tient pas à plusieurs / en CI : pas partagé, pas verrouillé, contient
  des secrets → **jamais dans git**.
- Un **backend distant** stocke le state partagé **avec verrouillage**.
- **Backend GitLab (`http`)** : adresse
  `…/projects/<id>/terraform/state/<name>`, auth par `$CI_JOB_TOKEN` en CI (variables
  `TF_HTTP_*`), state visible dans **Operate > Terraform states**. Aucun service à ajouter.
- Alternative lab S3-compatible : **MinIO / RustFS** (même `backend "s3"` que l'AWS de 5).

➡️ **[5 — LocalStack & un site statique S3](5-LOCALSTACK.md)** : on écrit du **vrai HCL
AWS**, sans dépenser un centime.

> 🌉 **Bonus (optionnels, non bloquants) — autour du state :**
> - [4-BONUS — Un state ≠ plusieurs envs (dossiers)](4-BONUS-STATE-ENVIRONMENTS.md) : pourquoi
>   un seul state ne gère pas `dev` **et** `test`, et la solution « un dossier = un state ».
> - [4-BONUS — Workspaces](4-BONUS-STATE-WORKSPACES.md) : plusieurs states depuis **une seule**
>   config (et pourquoi on ne peut pas variabiliser le `backend`).
> - [4-BONUS — Terragrunt](4-BONUS-TERRAGRUNT.md) : **factoriser le backend** et **dédupliquer
>   les variables** entre `dev`/`staging` sans recopie.
