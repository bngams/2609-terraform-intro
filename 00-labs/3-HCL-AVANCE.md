# 3 — HCL avancé : variables, structures, boucles, modules

Suite de [2](2-DOCKER-PROVIDER.md). Votre stack WP+MySQL marche, mais elle est **rigide
et avec des secrets en clair**. Dans ce chapitre, vous montez en compétence sur le **langage
HCL** : variables, types, `locals`, boucles (`count`, `for_each`), expressions `for`,
conditions, et **modules**. On refactore la stack à chaque étape.

### Ressources utiles

- [Variables d'entrée](https://developer.hashicorp.com/terraform/language/values/variables) ·
  [Outputs](https://developer.hashicorp.com/terraform/language/values/outputs) ·
  [Locals](https://developer.hashicorp.com/terraform/language/values/locals)
- [Types & valeurs](https://developer.hashicorp.com/terraform/language/expressions/types) ·
  [`count`](https://developer.hashicorp.com/terraform/language/meta-arguments/count) ·
  [`for_each`](https://developer.hashicorp.com/terraform/language/meta-arguments/for_each) ·
  [expressions `for`](https://developer.hashicorp.com/terraform/language/expressions/for) ·
  [conditions](https://developer.hashicorp.com/terraform/language/expressions/conditional)
- [Modules](https://developer.hashicorp.com/terraform/language/modules)

---

## 1. Variables & outputs

Une **variable d'entrée** paramètre la config ; un **output** en expose une valeur.

```hcl
# variables.tf
variable "mysql_user" {
  description = "Utilisateur applicatif MySQL"
  type        = string
  default     = "wp_user"
}

variable "wp_port" {
  description = "Port HTTP exposé pour WordPress"
  type        = number
  default     = 8888
}
```

```hcl
# outputs.tf
output "wordpress_url" {
  description = "URL d'accès à WordPress"
  value       = "http://localhost:${var.wp_port}"
}
```

On référence avec `var.<nom>` :

```hcl
ports {
  internal = 80
  external = var.wp_port
}
```

> **🧪 Manip — extraire en variables**
>
> 1. Remplacez les valeurs en dur de la stack 2 par des `var.*` (user, port…).
> 2. Ajoutez l'`output wordpress_url`.
> 3. `terraform apply` puis `terraform output` → l'URL s'affiche.
>
> *Observation : la même config, mais paramétrable sans toucher au `main.tf`.*

---

## 2. Fournir les valeurs : `tfvars` & secrets

On ne met **pas** les valeurs sensibles dans le `.tf`. On les passe via des fichiers
**`*.tfvars`**.

| Fichier | Chargé… | Usage |
|---|---|---|
| `terraform.tfvars` | automatiquement | valeurs par défaut du projet |
| `*.auto.tfvars` | **automatiquement** (tous) | valeurs d'environnement |
| `xxx.tfvars` | si `-var-file=xxx.tfvars` | explicite |
| `-var "k=v"` | en ligne de commande | ponctuel |

Marquez les variables sensibles avec **`sensitive = true`** (Terraform les masque dans la sortie) :

```hcl
variable "mysql_user_pwd" {
  description = "Mot de passe applicatif MySQL"
  type        = string
  sensitive   = true            # masqué dans les logs / output
}
```

```hcl
# secrets.auto.tfvars   (chargé automatiquement)
mysql_user_pwd = "wp_password"
mysql_root_pwd = "MySQLRootPassword"
```

> ⚠️ **Secrets — règle du lab.**
> - Ces `*.tfvars` de secrets **ne doivent JAMAIS être commités**. On les met en `.gitignore`
>   et on versionne un **`.sample`** (sans valeurs) pour documenter les clés attendues.
> - `sensitive = true` **n'est pas du chiffrement** : ça masque l'affichage, mais la valeur
>   est **en clair dans le `terraform.tfstate`**. → c'est pourquoi le state ne va jamais dans
>   git (chapitre [4](4-STATE.md)).
> - **Ne vous inquiétez pas des secrets dans GitLab pour l'instant.** La gestion propre des
>   secrets sera traitée en **J3 avec Ansible Vault** (et une ouverture vers HashiCorp Vault).

`.gitignore` (extrait) :

```gitignore
# Terraform
.terraform/
*.tfstate
*.tfstate.*
# secrets — ne jamais commiter
*.auto.tfvars
secrets.tfvars
```

Et on garde un modèle versionné :

```hcl
# secrets.auto.tfvars.sample   (commité, SANS valeurs réelles)
mysql_user_pwd = "<à remplir>"
mysql_root_pwd = "<à remplir>"
```

> **🧪 Manip — secrets hors du code**
>
> 1. Passez les mots de passe en variables `sensitive = true`.
> 2. Créez `secrets.auto.tfvars` (avec valeurs) + `secrets.auto.tfvars.sample` (sans).
> 3. Ajoutez les règles au `.gitignore`. `git status` → le fichier de secrets **n'apparaît pas**.
> 4. `terraform plan` → les valeurs sensibles sont affichées comme `(sensitive value)`.
>
> *Observation : les secrets sortent du code et de git, sans rien casser.*

---

## 3. Les types

HCL est typé. Les types de base + les types complexes :

| Type | Exemple |
|---|---|
| `string` / `number` / `bool` | `"wp_user"` / `8888` / `true` |
| `list(...)` | `["a", "b"]` |
| `map(...)` | `{ user = "wp_user" }` |
| `object({...})` | `{ name = string, port = number }` |

```hcl
variable "db_config" {
  type = object({
    user     = string
    password = string
    database = string
  })
  sensitive = true
}
```

> **🧪 Manip — typer la config DB**
>
> Modélisez la config MySQL en un seul `object`, et référencez `var.db_config.user`, etc.,
> dans le conteneur `db`. `apply` → comportement identique, config plus claire.

---

## 4. `locals` — valeurs calculées

Un **local** est une valeur dérivée, calculée une fois, réutilisée partout.

```hcl
locals {
  project     = "wp-lab"
  name_prefix = "${local.project}-${terraform.workspace}"   # ex: wp-lab-default
}

resource "docker_network" "wp_net" {
  name = "${local.name_prefix}-net"
}
```

> **🧪 Manip — un préfixe cohérent**
>
> Définissez `local.name_prefix` et préfixez les noms du réseau/volumes/conteneurs. `apply` →
> toutes les ressources portent le même préfixe.
>
> *Observation : `var` = entrée externe ; `local` = valeur interne calculée. (Comme `extends`/
> templates en [J1-2](../J1-GITLAB/J1-2-SERIOUS-TIPS.md) : éviter la répétition.)*

---

## 5. Boucles : `count` et `for_each`

### `count` — N copies identiques

```hcl
resource "docker_container" "worker" {
  count = var.worker_count          # ex: 3
  name  = "worker-${count.index}"   # worker-0, worker-1, worker-2
  image = docker_image.ubuntu.image_id
  command = ["sleep", "infinity"]
}
```

### `for_each` — à partir d'une map/set (chaque élément a une clé stable)

```hcl
variable "images" {
  type = map(string)
  default = {
    mysql     = "mysql:8.0"
    wordpress = "wordpress:latest"
  }
}

resource "docker_image" "imgs" {
  for_each = var.images
  name     = each.value            # each.key = "mysql", each.value = "mysql:8.0"
}
# référence : docker_image.imgs["mysql"].image_id
```

> **`count` vs `for_each` :** `count` indexe par **position** (0,1,2…) → supprimer un élément du
> milieu **décale** tout. `for_each` indexe par **clé** → stable. En pratique : `for_each` dès
> qu'on gère des ressources « nommées ».

> **🧪 Manip — boucler sur les images**
>
> 1. `count` : créez `var.worker_count` conteneurs `sleep infinity`. `apply`, `docker ps`.
> 2. `for_each` : créez les images mysql/wordpress depuis une `map`. Référencez-les via
>    `docker_image.imgs["mysql"].image_id` dans les conteneurs.
>
> *Observation : ajouter un worker = changer un nombre ; ajouter une image = une ligne dans la map.*

---

## 6. Expressions `for` et conditions

### Expression `for` — transformer une collection

```hcl
# construire la liste env = ["MYSQL_USER=wp_user", ...] à partir d'une map
locals {
  db_env = [for k, v in var.db_config : "${upper(k)}=${v}"]
}
```

### Conditions — `condition ? si_vrai : si_faux`

```hcl
variable "with_adminer" {
  type    = bool
  default = false
}

resource "docker_container" "adminer" {
  count = var.with_adminer ? 1 : 0      # créé seulement si with_adminer = true
  name  = "adminer"
  image = docker_image.adminer[0].image_id
  ports {
    internal = 8080
    external = 8080
  }
}
```

> **🧪 Manip — Adminer optionnel**
>
> Conditionnez le conteneur Adminer à `var.with_adminer`. `apply` avec
> `-var with_adminer=true` → il apparaît ; sans → absent.
>
> *Observation : une seule base de code, deux variantes d'infra selon un drapeau.*

---

## 7. Modules — factoriser & réutiliser

Un **module** est un dossier de `.tf` réutilisable, avec ses **variables** (entrées) et
**outputs** (sorties). On y range une brique cohérente (ici : la stack WordPress).

```
j2-3-modules/
├── main.tf              # appelle le module
├── variables.tf
├── secrets.auto.tfvars  (gitignore)
└── modules/
    └── wordpress/
        ├── main.tf      # network + volumes + db + wp
        ├── variables.tf # user, pwd, port, name_prefix…
        ├── versions.tf  # /!\ required_providers DU MODULE (voir piège ci-dessous)
        └── outputs.tf   # url
```

> **⚠️ Piège classique — le module doit déclarer ses providers.** Un module qui utilise
> `docker_*` doit avoir **son propre** `required_providers` (dans un `versions.tf`), sinon
> Terraform suppose `hashicorp/docker` au lieu de `kreuzwerker/docker` et `init` échoue :
> ```hcl
> # modules/wordpress/versions.tf
> terraform {
>   required_providers {
>     docker = { source = "kreuzwerker/docker" }
>   }
> }
> ```

Appel du module (le root devient minuscule) :

```hcl
# main.tf (racine)
module "wp_review" {
  source         = "./modules/wordpress"
  name_prefix    = "review"
  wp_port        = 8888
  mysql_user     = var.mysql_user
  mysql_user_pwd = var.mysql_user_pwd
}

output "review_url" {
  value = module.wp_review.url       # output remonté du module
}
```

> **L'intérêt réel.** Le même module, appelé **deux fois** avec des `name_prefix`/`wp_port`
> différents, donne **deux environnements** isolés. C'est exactement ce qui servira pour les
> **environnements à la demande** (6) : une review app = un appel de module.

> **🧪 Manip — la stack en module, appelée 2 fois**
>
> 1. Déplacez la stack WP dans `modules/wordpress/` (variables : `name_prefix`, `wp_port`,
>    creds). Préfixez tous les noms par `var.name_prefix`.
> 2. Dans le root, appelez le module **deux fois** (`wp_review` port 8888, `wp_staging` port 8889).
> 3. `apply` → **deux stacks** WP isolées. `terraform output` → deux URLs.
>
> *Observation : une brique, N environnements. La DRY de l'infrastructure.*

---

## Recap

- **`variable`** (entrée, `var.x`) + **`output`** (sortie) + **`locals`** (calcul interne).
- **`*.tfvars`** pour les valeurs ; **`*.auto.tfvars`** chargés automatiquement ; secrets en
  `sensitive = true`, **gitignore + `.sample`**, jamais commités (et **rien à gérer côté GitLab
  pour l'instant → J3 Vault**).
- Types : `string/number/bool/list/map/object`.
- Boucles : **`count`** (par position) vs **`for_each`** (par clé, préféré) ; expressions
  **`for`** ; **conditions** `? :`.
- **Modules** : factoriser une brique, l'appeler N fois → N environnements isolés (base de l'env
  à la demande).

➡️ **[4 — Le state distant & le verrouillage](4-STATE.md)** : où vit le `tfstate` quand
on travaille en équipe / dans un pipeline.
