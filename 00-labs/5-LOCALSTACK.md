# 5 — LocalStack & un site statique S3

Suite de [4](4-STATE.md). Jusqu'ici on a provisionné du **Docker**. On passe maintenant au
**cloud AWS** — mais **émulé en local** avec **LocalStack** : on écrit du **vrai HCL AWS**
(`aws_s3_bucket`, etc.), sans compte AWS et **sans dépenser un centime**.

> **Pourquoi LocalStack ?** Pour écrire et tester des ressources AWS réalistes dans le lab. Le
> HCL est **strictement le même** que pour un vrai AWS — seule la configuration du provider
> (les *endpoints*) change. Progression : Docker local → **LocalStack** → (vrai AWS, hors lab).

### Ressources utiles

- [Provider `aws`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs) ·
  [`aws_s3_bucket`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) ·
  [`aws_s3_bucket_website_configuration`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_website_configuration)
- [LocalStack + Terraform](https://docs.localstack.cloud/user-guide/integrations/terraform/)

---

## Démarrer LocalStack (profil `localstack`)

LocalStack est dans le `compose.yml` du lab, **sous le profil `localstack`** (il ne démarre pas
avec un `docker compose up` standard). On le lance explicitement :

```bash
docker compose --profile localstack up -d localstack

# vérifier (endpoint unique sur :4566)
curl http://localhost:4566/_localstack/health
```

> Tous les services AWS émulés répondent sur **`http://localhost:4566`**.

> **⚠️ Version de l'image LocalStack.** Depuis le **23/03/2026**, les images **récentes**
> (`latest`/`stable`) exigent un `LOCALSTACK_AUTH_TOKEN`, **même pour le tier gratuit** (sinon
> le conteneur quitte avec *exit code 55 / License activation failed*). Le `compose.yml` du lab
> **épingle donc `localstack/localstack:3.8`** (antérieure, gratuite, sans token). *(Alternative :
> créer un token Hobby gratuit sur app.localstack.cloud et le passer en `LOCALSTACK_AUTH_TOKEN`.)*

> **💡 Tip — la CLI `aws` a besoin de creds (bidon) pour LocalStack.** Même si LocalStack ne
> vérifie rien, la commande `aws` refuse de partir sans credentials (`NoCredentials`). Exportez
> des valeurs **bidon** une fois dans votre shell :
> ```bash
> export AWS_ACCESS_KEY_ID=test
> export AWS_SECRET_ACCESS_KEY=test
> export AWS_DEFAULT_REGION=eu-west-3
>
> aws --endpoint-url=http://localhost:4566 s3 ls    # liste les buckets
> ```
> *(Terraform, lui, n'en a pas besoin : on a mis ces creds dans le bloc `provider "aws"`.)*

---

## Pointer le provider AWS sur LocalStack

Le provider `aws` se configure normalement… puis on lui dit d'utiliser les **endpoints**
LocalStack au lieu des vrais. Les credentials sont **bidon** (LocalStack ne vérifie rien).

```hcl
# providers.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = "eu-west-3"
  access_key                  = "test"      # bidon (LocalStack)
  secret_key                  = "test"      # bidon
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3  = "http://localhost:4566"
    iam = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}
```

> **Le seul écart avec un vrai AWS** = le bloc `endpoints { … }` + les `skip_*` + les creds
> bidon. **Retirez ce bloc** et mettez de vraies creds → le **même `main.tf`** déploie sur le
> vrai AWS. C'est tout l'intérêt.

---

## Backend vs Provider (rappel important)

Deux blocs distincts qu'on confond souvent :

| | **Backend** (où vit le state) | **Provider** (comment créer les ressources) |
|---|---|---|
| Variables `var.*` | ❌ interdites | ✅ autorisées |
| Rôle | stockage du `tfstate` | parler à l'API (AWS, Docker…) |
| Init | tôt (avant les variables) | après les variables |
| Auth | ses propres creds | creds AWS (CLI / env / IAM role) |

> On garde notre **backend GitLab** ([4](4-STATE.md)) pour le state ; le **provider AWS**
> (ci-dessus) sert juste à créer les ressources dans LocalStack.

### Stratégies d'authentification AWS (pour un vrai AWS)

| Option | Comment |
|---|---|
| **AWS CLI** (recommandé en local) | `aws configure` → provider sans creds explicites |
| **Variables d'env** | `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_DEFAULT_REGION` |
| **IAM role** (recommandé en CI/prod) | rôle attaché à l'instance/au job, pas de creds en dur |

> En CI (6), on privilégie un **IAM role / OIDC** plutôt que des clés long-lived — même
> logique d'intégrité que [J1-3](../J1-GITLAB/J1-3-SAST.md).

---

## Le site statique S3 (vrai HCL AWS)

On héberge un site statique : un **bucket**, sa **config de site web**, les **fichiers**, et une
**policy** de lecture publique.

```hcl
# main.tf
resource "aws_s3_bucket" "site" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.site.id
  index_document { suffix = "index.html" }
  error_document { key = "error.html" }
}

# Débloquer l'accès public (sinon AWS bloque par défaut)
resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Policy : lecture publique des objets
resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = ["s3:GetObject"]
      Resource  = ["${aws_s3_bucket.site.arn}/*"]
    }]
  })
}

# Uploader les fichiers
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.site.id
  key          = "index.html"
  source       = "${path.module}/assets/index.html"
  content_type = "text/html; charset=utf-8"
}

resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.site.id
  key          = "error.html"
  source       = "${path.module}/assets/error.html"
  content_type = "text/html; charset=utf-8"
}
```

> `jsonencode({ … })` : on écrit la policy comme un **objet HCL**, Terraform la sérialise en
> JSON. Plus lisible et vérifiable qu'une grosse string JSON.

---

## Manips

> **🧪 Manip — déployer le site sur LocalStack**
>
> 1. Créez `assets/index.html` et `assets/error.html` (un `<h1>` suffit).
> 2. `terraform init && terraform apply`.
> 3. Vérifiez via l'endpoint LocalStack :
>    ```bash
>    aws --endpoint-url=http://localhost:4566 s3 ls
>    curl http://<bucket>.s3-website.localhost.localstack.cloud:4566/
>    ```
>    (ou l'URL renvoyée par un `output`.)
>
> *Observation : un vrai bucket S3 + site web, créé par du HCL AWS standard, **0 € de facture**.*

> **🧪 Manip — casser puis réparer**
>
> 1. Changez le `content_type` de `index.html` en `"text/plain"`, `apply` → le navigateur
>    **affiche le HTML brut** au lieu de le rendre.
> 2. Remettez `text/html`, `apply` → corrigé.
>
> *Observation : `apply` ne touche **que** l'objet modifié (le diff), pas tout le bucket.*

> **🧪 Manip (réflexion) — vers le vrai AWS**
>
> Listez ce qu'il faudrait changer pour déployer sur **un vrai AWS** : retirer `endpoints`/
> `skip_*`, mettre de vraies creds (CLI/IAM), un `bucket` **globalement unique**. Le `main.tf`,
> lui, **ne bouge pas**.
>
> *Observation : LocalStack = même code, sans cloud. Le passage en prod est une affaire de
> provider, pas de ressources.*

---

## Recap

- **LocalStack** = AWS émulé sur `:4566`, lancé via le **profil `localstack`**. On écrit du
  **vrai HCL AWS** sans coût.
- Seul écart avec le vrai AWS : le bloc **`endpoints { … }`** + `skip_*` + creds bidon dans le
  **provider**. Le `main.tf` est identique.
- **Backend ≠ Provider** : le state reste sur **GitLab** (4), le provider AWS crée les
  ressources.
- Site statique S3 : `bucket` + `website_configuration` + `public_access_block` + `bucket_policy`
  + `s3_object`.

> **Limite à garder en tête pour J3 :** LocalStack **émule** les ressources — il n'y a pas de
> vraie VM joignable en SSH derrière une « instance ». On en tiendra compte au moment de choisir
> ce qu'Ansible configure (7 / J3).

➡️ **[6 — Brancher Terraform dans GitLab CI (env à la demande)](6-ONDEMAND-ENV.md)** : on
remplace les `echo` du J1 par un vrai `terraform apply` / `destroy`.
