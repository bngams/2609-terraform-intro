# 4-BONUS — Un state ≠ plusieurs envs (Solution A : un dossier par environnement)

> **Chapitre BONUS, en marge de [4](4-STATE.md).** Vous savez maintenant *où* vit le state.
> Question naturelle : **peut-on gérer `dev` et `test` de la même ressource dans un seul state ?**
> Réponse courte : **non**. Ce chapitre le démontre, puis applique la **1ʳᵉ des deux solutions** :
> un dossier (= un state) par environnement. La 2ᵈᵉ est dans
> [4-BONUS — Workspaces](4-BONUS-STATE-WORKSPACES.md).
>
> **Optionnel & non bloquant** : à lire quand vous voulez, puis reprendre en
> [5](5-LOCALSTACK.md). Solution complète dans
> `solutions/j2-4-bonus-state-environments/`.

On repart de l'exemple minimal `local_file` (créer un fichier) pour se concentrer sur **le state**,
sans le bruit de Docker — mais **le raisonnement est identique** pour votre stack WordPress de
[2](2-DOCKER-PROVIDER.md).

> Provider : `hashicorp/local ~> 2.5` (Terraform **et** OpenTofu).

---

## 🤔 1 — Le problème : une adresse de ressource + un state = un seul env

Prenez **un seul dossier**, une variable `environment`, et cette ressource :

```hcl
variable "environment" {
  type    = string
  default = "dev"
}

resource "local_file" "greeting" {
  filename = "${path.module}/output/greeting_${var.environment}.txt"
  content  = "Hello from ${var.environment} !"
}
```

Appliquez `dev`, puis rejouez `test` **dans le même dossier** :

```bash
terraform init
terraform apply -auto-approve -var environment=dev    # crée greeting_dev.txt
terraform plan               -var environment=test
```

```text
  # local_file.greeting must be replaced
  ~ filename = "./output/greeting_dev.txt" -> "./output/greeting_test.txt" # forces replacement
Plan: 1 to add, 0 to change, 1 to destroy.
```

💥 Terraform ne voit pas « deux environnements » : il voit **une seule** ressource
(`local_file.greeting`) dans **un seul** state, dont on change un attribut. Il **détruit**
`greeting_dev.txt` pour recréer `greeting_test.txt`. Après l'`apply`, il n'en reste **qu'un** :

```bash
terraform apply -auto-approve -var environment=test
ls output/          # -> greeting_test.txt   (dev a disparu)
```

> Garder les deux dans un même state obligerait à **dupliquer le bloc** avec des noms distincts
> (`local_file.dev`, `local_file.test`) ou un `for_each` — ingérable dès qu'un env grossit. D'où les
> deux vraies solutions : **un state par dossier** (ici) ou les **workspaces** (chapitre suivant).

---

## ✅ 2 — Solution A : un dossier = un state

Chaque environnement a **son dossier**, donc son **`terraform.tfstate`** (backend `local` implicite).
La ressource peut **garder le même nom** : states séparés => aucune collision.

```
solutions/j2-4-bonus-state-environments/
└── environments/
    ├── dev/    (main.tf + providers.tf)   -> ./terraform.tfstate  (isolé)
    └── test/   (main.tf + providers.tf)   -> ./terraform.tfstate  (isolé)
```

> **🧪 Manip — deux envs qui coexistent**
>
> Depuis la racine du dossier `solutions/j2-4-bonus-state-environments/` :
>
> 1. `(cd environments/dev  && terraform init && terraform apply -auto-approve)` -> `greeting_dev.txt`.
> 2. `(cd environments/test && terraform init && terraform apply -auto-approve)` -> `greeting_test.txt`.
> 3. Vérifiez que **les deux fichiers existent** (toujours depuis la racine) :
>    ```bash
>    cat environments/dev/output/greeting_dev.txt      # Hello from dev !
>    cat environments/test/output/greeting_test.txt    # Hello from test !
>    ```
> 4. Chaque dossier a `local_file.greeting` dans **son** state (sous-shells `( … )` pour ne pas
>    changer de dossier courant) :
>    ```bash
>    (cd environments/dev  && terraform state list)    # local_file.greeting
>    (cd environments/test && terraform state list)    # local_file.greeting  (autre state !)
>    ```
>
> *Observé : la même adresse de ressource, deux states distincts => zéro collision, les deux
> environnements coexistent.*

---

## ⚖️ 3 — Le compromis

| 👍 Avantages | 👎 Inconvénients |
|---|---|
| Isolation **totale** (state, backend, provider par env) | Le `main.tf` est **dupliqué** par env (anti-DRY) |
| Détruire un env sans toucher aux autres | Dérive entre copies (on corrige `dev`, on oublie `test`) |
| Chaque env peut diverger fortement (versions, régions) | Passe mal à l'échelle avec beaucoup d'envs |

La duplication de code est exactement ce que corrigent, dans l'ordre : les **modules**
([3](3-HCL-AVANCE.md)), puis **Terragrunt** ([4-BONUS — Terragrunt](4-BONUS-TERRAGRUNT.md))
qui factorise config **et** backend sans recopie.

---

## Récap

- Un **state** ne distingue pas les environnements : deux `apply` sur la **même adresse** de
  ressource se **remplacent**, ils ne s'ajoutent pas.
- **Solution A** : **un dossier = un state** par env. Isolation totale, au prix de la **duplication**.
- Alternatives : **workspaces** ([chapitre suivant](4-BONUS-STATE-WORKSPACES.md)) pour rester DRY,
  ou **Terragrunt** pour factoriser config + backend.

➡️ **[4-BONUS — Workspaces](4-BONUS-STATE-WORKSPACES.md)** : plusieurs states depuis **une
seule** config.
