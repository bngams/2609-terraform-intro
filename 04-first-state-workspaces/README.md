# 04 — State & Workspaces

Une **seule** configuration Terraform, mais **plusieurs states isolés** grâce aux
**workspaces**. Chaque workspace a son propre `terraform.tfstate`, rangé
automatiquement dans `terraform.tfstate.d/<workspace>/terraform.tfstate`.

Ici on combine deux mécanismes :

| Mécanisme            | Rôle                                              | Où                         |
| -------------------- | ------------------------------------------------- | -------------------------- |
| `terraform.workspace`| isole le **state** (dev ≠ test)                   | fourni par Terraform       |
| `*.tfvars`           | change les **valeurs** (emplacement + contenu)    | `env.dev.tfvars`, `env.test.tfvars` |
| `locals`             | dérive le chemin et le contenu du fichier généré  | `main.tf`                  |

> ⚠️ On ne peut PAS mettre de variable dans un bloc `backend` (voir `providers.tf`).
> Les workspaces sont la réponse de Terraform à ce besoin.

## Fichiers

- `env.dev.tfvars` → `environment = "dev"` + message dev
- `env.test.tfvars` → `environment = "test"` + message test

Le fichier généré change **d'emplacement** (`output/<env>/`) **et de contenu**
(message) selon le tfvars, et de **nom** (`greeting_<workspace>.txt`) selon le
workspace.

## 1. Initialiser

```bash
terraform init
```

## 2. Créer les workspaces

```bash
terraform workspace new dev
terraform workspace new test

# lister / voir le workspace courant (marqué d'un *)
terraform workspace list
terraform workspace show
```

## 3. Appliquer par environnement

On sélectionne le workspace, puis on passe le tfvars correspondant.

```bash
# --- DEV ---
terraform workspace select dev
terraform apply -var-file=env.dev.tfvars

# --- TEST ---
terraform workspace select test
terraform apply -var-file=env.test.tfvars
```

Résultat :

```
output/
├── dev/
│   └── greeting_dev.txt
└── test/
    └── greeting_test.txt
```

Chaque fichier contient le message issu de son `.tfvars`.

## 4. Vérifier

```bash
terraform workspace show          # workspace actif
terraform output                  # outputs du workspace courant
cat output/dev/greeting_dev.txt
cat output/test/greeting_test.txt

# les states sont bien séparés :
ls terraform.tfstate.d/
```

## 5. Nettoyer

```bash
# détruire dans chaque workspace avant de le supprimer
terraform workspace select dev  && terraform destroy -var-file=env.dev.tfvars
terraform workspace select test && terraform destroy -var-file=env.test.tfvars

# on ne peut pas supprimer le workspace courant : on revient sur default
terraform workspace select default
terraform workspace delete dev
terraform workspace delete test
```
