# 1 — Première configuration Terraform

Suite de [0](0-SETUP.md). On exécute le **workflow complet** (write → init → plan →
apply → destroy) sur l'exemple le plus simple possible : créer un **fichier local**. Pas de
cloud, pas de Docker — juste pour **comprendre la mécanique et le `state`**.

### Ressources utiles

- [Syntaxe HCL — Resources](https://developer.hashicorp.com/terraform/language/resources/syntax)
- [Provider `local`](https://registry.terraform.io/providers/hashicorp/local/latest/docs) · ressource [`local_file`](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file)
- [Variables `path.*` (built-in)](https://developer.hashicorp.com/terraform/language/expressions/references#filesystem-and-workspace-info)

---

## L'anatomie d'un bloc HCL

Tout en HCL est une suite de **blocs**. Le plus important : la **ressource**
([doc](https://developer.hashicorp.com/terraform/language/resources/syntax)).

```hcl
resource "local_file" "sample" {
  content  = "Hello Terraform!!! :)"
  filename = "${path.module}/sample.txt"
}
```

| Élément | Ici | Rôle |
|---|---|---|
| **type de bloc** | `resource` | on déclare une ressource d'infrastructure |
| **type de ressource** | [`local_file`](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | quoi créer (fourni par le *provider* `local`) |
| **nom local** | `sample` | nom arbitraire pour **référencer** cette ressource ailleurs (ex. `local_file.sample.filename`) |
| **arguments** | `content`, `filename` | la configuration de la ressource |

> [`path.module`](https://developer.hashicorp.com/terraform/language/expressions/references#filesystem-and-workspace-info)
> = le dossier du module courant (une variable intégrée). Le fichier sera créé à côté de votre `.tf`.

---

## Déclarer le provider

Un **provider** est le plugin qui sait parler à une plateforme (ici, le système de fichiers
local). On le déclare dans `providers.tf` ([bloc `terraform`](https://developer.hashicorp.com/terraform/language/terraform) ·
[`required_providers`](https://developer.hashicorp.com/terraform/language/providers/requirements) ·
[bloc `provider`](https://developer.hashicorp.com/terraform/language/providers/configuration)) :

```hcl
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "2.7.0"
    }
  }
}

provider "local" {
  # rien à configurer pour ce provider
}
```

> **Conventions de fichiers.** Terraform lit **tous** les `.tf` du dossier (l'ordre n'importe
> pas). Par convention on sépare : `providers.tf` (providers + backend), `main.tf` (ressources),
> `variables.tf`, `outputs.tf`. C'est purement organisationnel.
> ([doc — Files & directories](https://developer.hashicorp.com/terraform/language/files))

---

## Etape — Le workflow de bout en bout

Créez un dossier `j2-1-first/` avec les deux fichiers ci-dessus.

> **🧪 Manip — write → init → plan → apply**
>
> ```bash
> cd j2-1-first
>
> terraform init       # télécharge le provider local → crée .terraform/ et le lock file
> terraform plan       # affiche : "1 to add" — le fichier qui SERA créé
> terraform apply      # demande confirmation (yes) → crée sample.txt
>
> cat sample.txt       # → Hello Terraform!!! :)
> ```
>
> *Observation : `plan` montre l'intention (rien n'est encore fait), `apply` exécute.*
>
> Doc CLI : [`init`](https://developer.hashicorp.com/terraform/cli/commands/init) ·
> [`plan`](https://developer.hashicorp.com/terraform/cli/commands/plan) ·
> [`apply`](https://developer.hashicorp.com/terraform/cli/commands/apply)

---

## Le `state` : la mémoire de Terraform

Après l'`apply`, un fichier **`terraform.tfstate`** est apparu. C'est **la mémoire** de
Terraform : la correspondance entre votre code et les ressources réelles.
([doc — State](https://developer.hashicorp.com/terraform/language/state))

> **🧪 Manip — lire le state**
>
> ```bash
> cat terraform.tfstate          # JSON : on y retrouve local_file.sample, son contenu, etc.
> terraform state list           # local_file.sample
> terraform show                 # état lisible
> ```
>
> Doc : [`state list`](https://developer.hashicorp.com/terraform/cli/commands/state/list) ·
> [`show`](https://developer.hashicorp.com/terraform/cli/commands/show)
>
> *Observation : Terraform ne « devine » rien — il compare le code à CE fichier pour décider
> quoi faire. D'où l'importance de ne jamais le perdre (chapitre [4](4-STATE.md)).*

---

## Modifier : le diff en action

> **🧪 Manip — un changement in-place**
>
> 1. Changez `content` en `"Hello Terraform — v2"` dans `main.tf`.
> 2. `terraform plan` → Terraform affiche un **`~` (update in-place)** : il sait que la
>    ressource existe (via le state) et qu'un attribut a changé.
> 3. `terraform apply` → `cat sample.txt` montre la nouvelle valeur.
>
> *Observation : on ne recrée pas tout — Terraform applique **uniquement le delta**.*

---

## Détruire

> **🧪 Manip — destroy**
>
> ```bash
> terraform destroy     # confirme (yes) → sample.txt supprimé
> terraform state list  # (vide) — le state ne contient plus rien
> ```
>
> *Observation : `destroy` défait proprement ce que `apply` a créé. C'est ce qui rendra nos
> environnements à la demande **jetables** (6).*
>
> Doc : [`destroy`](https://developer.hashicorp.com/terraform/cli/commands/destroy)

---

## Recap

- Une **ressource** = `resource "<type>" "<nom>" { arguments }` ; référençable par
  `<type>.<nom>.<attribut>`.
- Un **provider** = le plugin qui crée la ressource (`local`, puis `docker`, `aws`…).
- Workflow : `init` (providers) → `plan` (diff) → `apply` (exécute) → `destroy` (défait).
- Le **`terraform.tfstate`** est la mémoire : Terraform compare code ↔ state pour agir au delta.

➡️ **[2 — Du Docker au Terraform (provider docker)](2-DOCKER-PROVIDER.md)** : on passe à
de vraies ressources d'infra (conteneurs, réseaux, volumes).
