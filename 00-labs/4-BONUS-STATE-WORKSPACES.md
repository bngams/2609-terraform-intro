# 4-BONUS — Un state ≠ plusieurs envs (Solution B : les workspaces)

> **Chapitre BONUS, en marge de [4](4-STATE.md).** Suite directe de
> [4-BONUS — un dossier par env](4-BONUS-STATE-ENVIRONMENTS.md). Même besoin (`dev` **et**
> `test`), mais cette fois on garde **une seule config** et on multiplie les states avec les
> **workspaces**.
>
> **Optionnel & non bloquant.** Solution complète dans `solutions/j2-4-bonus-state-workspaces/`.

> Provider : `hashicorp/local ~> 2.5` (Terraform **et** OpenTofu). On reste sur l'exemple `local_file`
> pour se concentrer sur le state.

---

## 🤔 1 — La fausse bonne idée : variabiliser le backend

Pour ranger le state par env, on aimerait écrire :

```hcl
terraform {
  backend "local" {
    path = "terraform.tfstate.d/${var.environment}/terraform.tfstate"
  }
}
```

`terraform init` refuse **catégoriquement** :

```text
Error: Variables not allowed

  on providers.tf line 8, in terraform:
   8:     path = "terraform.tfstate.d/${var.environment}/terraform.tfstate"

Variables may not be used here.
```

> Le bloc `backend` est évalué **avant** tout le reste (avant même les variables) : il ne peut
> référencer **aucune valeur nommée** (variable, local, data…). C'est une limite volontaire de
> Terraform — et c'est *exactement* le besoin auquel répondent les **workspaces**.

---

## ✅ 2 — Solution B : les workspaces

Un **workspace** = un **state séparé**, géré par le **même** backend. Avec le backend `local`, chaque
workspace obtient automatiquement son fichier sous `terraform.tfstate.d/<workspace>/`. Dans la config,
on lit le workspace courant via **`terraform.workspace`** :

```hcl
resource "local_file" "greeting" {
  filename = "output/greeting_${terraform.workspace}.txt"
  content  = "Hello from workspace ${terraform.workspace} !"
}
```

> **🧪 Manip — deux workspaces, deux states, une seule config**
>
> 1. `terraform init`
> 2. `terraform workspace new dev  && terraform apply -auto-approve`  -> `greeting_dev.txt`
> 3. `terraform workspace new test && terraform apply -auto-approve`  -> `greeting_test.txt`
> 4. Constatez l'isolation automatique :
>    ```bash
>    terraform workspace list
>    #   default
>    #   dev
>    # * test              <- l'astérisque = workspace courant
>
>    find terraform.tfstate.d -name '*.tfstate'
>    # terraform.tfstate.d/dev/terraform.tfstate
>    # terraform.tfstate.d/test/terraform.tfstate
>
>    ls output/           # greeting_dev.txt  greeting_test.txt   (les deux coexistent)
>    ```
> 5. Basculer : `terraform workspace select dev` puis `terraform show` -> l'état de `dev`, pas `test`.
>
> *Observé : une seule config, mais N states nommés par workspace, rangés tout seuls.*

---

## ⚖️ 3 — Le compromis

| 👍 Avantages | 👎 Inconvénients |
|---|---|
| **Une seule** config (DRY) pour N environnements | On oublie vite « dans quel workspace suis-je ? » => `apply` au mauvais endroit |
| States isolés automatiquement (`terraform.tfstate.d/<ws>/`) | **Même** backend/provider pour tous : mauvais si les envs divergent fortement |
| Bascule rapide (`workspace select`) | Le nom d'env n'apparaît pas dans les fichiers => peu visible en revue |

> **En entreprise**, les workspaces vont bien pour des variantes légères (review apps éphémères).
> Pour des environnements durables et très différents (comptes/régions/droits distincts), on préfère
> souvent **un dossier par env** ([chapitre précédent](4-BONUS-STATE-ENVIRONMENTS.md)) ou
> **Terragrunt** ([4-BONUS — Terragrunt](4-BONUS-TERRAGRUNT.md)), qui factorise config **et**
> backend sans recopie.

---

## Récap

- Le bloc **`backend` ne se variabilise pas** : `Error: Variables not allowed`.
- **Workspaces** = plusieurs states depuis **une seule** config/backend, différenciés par
  **`terraform.workspace`** ; le backend `local` les range sous `terraform.tfstate.d/<ws>/`.
- Léger et DRY, mais mêmes backend/provider pour tous => pour de la vraie divergence, préférez
  **dossiers** ou **Terragrunt**.

➡️ Retour au fil principal : **[5 — LocalStack & un site statique S3](5-LOCALSTACK.md)**.
