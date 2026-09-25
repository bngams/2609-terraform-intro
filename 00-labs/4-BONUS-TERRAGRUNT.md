# 4-BONUS — Terragrunt : ne répétez plus vos variables

> **Chapitre BONUS, en marge de [4](4-STATE.md).** Vous venez de voir que le **state** et le
> **backend** sont le nerf de la guerre en équipe. Terragrunt pousse cette logique plus loin : il
> **factorise le backend** (que Terraform, lui, refuse de variabiliser) et **déduplique les
> variables** entre environnements. Ce chapitre est **optionnel** et ne casse pas la progression :
> vous pouvez le lire après 4 puis reprendre le fil normal en [5](5-LOCALSTACK.md).
>
> **Scénario à réaliser en autonomie.** À la fin de [3](3-HCL-AVANCE.md) vous aviez une idée
> puissante : *le même module WordPress appelé plusieurs fois = plusieurs environnements isolés*.
> Mais en Terraform pur, dupliquer un environnement veut dire **recopier ses variables** — et un
> copier-coller oublié finit toujours par coûter cher. Dans ce chapitre, vous montez un `dev` **et**
> un `staging` de votre stack WordPress avec **Terragrunt**, un *wrapper* de Terraform pensé pour le
> **DRY** (*Don't Repeat Yourself*). Vous remplissez vous-même les `# TODO` ;
> `solutions/j2-4-bonus-terragrunt/` n'est là qu'en cas de blocage 😉.
>
> **Niveau : intermédiaire.** On suppose acquis [3](3-HCL-AVANCE.md) (variables, `tfvars`,
> **modules**, outputs). On ne suppose **aucune** connaissance de Terragrunt ni d'un cloud : tout
> tourne en local sur Docker.

### Ressources utiles

- [Terragrunt — Getting started](https://terragrunt.gruntwork.io/docs/getting-started/quick-start/) ·
  [Installation](https://terragrunt.gruntwork.io/docs/getting-started/install/)
- Blocs : [`terraform` / `source`](https://terragrunt.gruntwork.io/docs/reference/config-blocks-and-attributes/#terraform) ·
  [`include`](https://terragrunt.gruntwork.io/docs/reference/config-blocks-and-attributes/#include) ·
  [`inputs`](https://terragrunt.gruntwork.io/docs/reference/config-blocks-and-attributes/#inputs) ·
  [`remote_state`](https://terragrunt.gruntwork.io/docs/reference/config-blocks-and-attributes/#remote_state)
- Fonctions : [`find_in_parent_folders`](https://terragrunt.gruntwork.io/docs/reference/built-in-functions/#find_in_parent_folders) ·
  [`path_relative_to_include`](https://terragrunt.gruntwork.io/docs/reference/built-in-functions/#path_relative_to_include) ·
  [`get_terragrunt_dir`](https://terragrunt.gruntwork.io/docs/reference/built-in-functions/#get_terragrunt_dir) ·
  [`get_parent_terragrunt_dir`](https://terragrunt.gruntwork.io/docs/reference/built-in-functions/#get_parent_terragrunt_dir)
- Pour aller plus loin : l'[article de Zwindler & zed](https://blog.zwindler.fr/) dont ce TP
  s'inspire (contexte GCP, ici simplifié en local).

---

## ✨ Objectifs

- Comprendre **pourquoi** Terraform se répète quand on multiplie les environnements.
- Appeler un module Terraform depuis un **`terragrunt.hcl`** (bloc `terraform { source }`).
- **Factoriser** la config commune à la racine (`include` + `find_in_parent_folders`).
- Ne déclarer les variables partagées **qu'une seule fois** (`inputs`).
- Faire générer par Terragrunt un **state isolé par environnement** (`remote_state` — ce que
  Terraform **ne sait pas** variabiliser).
- Déployer **tous** les environnements d'un coup avec **`run --all`**.

---

## 📁 Point de départ & arborescence cible

Vous repartez du **module `wordpress`** de [3](3-HCL-AVANCE.md) : une brique autonome qui, à
partir d'un `SERVER_NAME`, d'un `WP_PORT` et de `WP_VARS`, crée images + réseau + volumes + les 2
conteneurs (WordPress + MariaDB). Voici l'arborescence que vous obtiendrez à la fin de ce chapitre :

```
j2-4-bonus-terragrunt/
├── root.hcl                    # config GLOBALE : source du module, backend, inputs communs
├── modules/
│   └── wordpress/              # le module de 3 (autonome, AVEC son bloc provider)
│       ├── providers.tf
│       ├── variables.tf
│       ├── main.tf
│       └── outputs.tf
└── live/                       # un dossier par environnement
    ├── dev/
    │   └── terragrunt.hcl      # include root + ce qui est propre à dev (port)
    └── staging/
        └── terragrunt.hcl      # include root + ce qui est propre à staging (port)
```

> ℹ️ **Le module `wordpress` a une nuance par rapport à 3.** Copiez le module de 3 dans un
> dossier `modules/wordpress/` (créez-le). **Attention :** en 3 le `provider "docker"` était
> configuré dans le *root* du projet, **pas** dans le module. Ici c'est **Terragrunt qui appelle le
> module directement** => c'est *lui* le « root module » côté Terraform, il doit donc porter **son
> propre** provider. Ajoutez ce bloc dans `modules/wordpress/providers.tf`, à côté du
> `required_providers` :
>
> ```hcl
> provider "docker" {
>   host = "unix:///var/run/docker.sock"
> }
> ```

---

## 🤔 1 — Le problème : la duplication entre environnements

En Terraform pur, pour avoir un `dev` **et** un `staging`, deux options, toutes deux frustrantes :

| Approche | Ce qu'on recopie | Le risque |
|---|---|---|
| Un dossier par env, chacun son `main.tf` + ses `*.tfvars` | **toute** la config à chaque env | un `tfvars` modifié à moitié, des identifiants qui divergent |
| Un seul projet + `terraform workspace` | moins de fichiers, mais… | le **backend** (chemin du state) **ne peut pas** dépendre d'une variable |

Le cœur du souci : **les mêmes valeurs sont écrites plusieurs fois** (les identifiants MySQL, la
version des images…), et **le bloc `backend` de Terraform refuse toute variable** :

```hcl
terraform {
  backend "local" {
    path = "state/${var.SERVER_NAME}/terraform.tfstate"  # ❌ interdit
  }
}
# Error: Variables not allowed — a backend block cannot refer to named values.
```

> C'est **exactement** le problème que Terragrunt résout : écrire la config **une fois**, et laisser
> le wrapper la décliner par environnement — **y compris le backend**.

---

## 🧰 2 — Terragrunt, le wrapper

Terragrunt (par [Gruntwork](https://gruntwork.io/)) est un **wrapper** autour de Terraform : il lit
un fichier `terragrunt.hcl` (même syntaxe HCL, + des fonctions en plus), génère les fichiers qui vont
bien, puis appelle Terraform pour vous.

Installez-le, puis vérifiez :

```bash
brew install terragrunt        # macOS ; sinon voir le lien "Installation" ci-dessus
terragrunt --version           # -> terragrunt version 1.1.6 (ou plus récent)
```

> ⚠️ **Piège — Terragrunt récent appelle OpenTofu, pas Terraform.**
> - *Symptôme :* à l'`init`, la sortie affiche `OpenTofu has been successfully initialized!` alors
>   que le reste du cours utilise `terraform`.
> - *Cause :* depuis sa version 1.x, Terragrunt utilise le binaire **`tofu`** (OpenTofu) par défaut.
> - *Correctif :* on le force sur `terraform` avec l'attribut **`terraform_binary = "terraform"`**
>   dans la config globale (voir section 3). Les deux moteurs sont compatibles ; on choisit
>   `terraform` par cohérence avec 2 => 4.

L'idée de base : au lieu d'un `main.tf` qui *contient* la stack, chaque environnement n'a plus qu'un
petit `terragrunt.hcl` qui **pointe vers le module** et lui passe ses valeurs.

🚧 **À compléter** — un premier `live/dev/terragrunt.hcl`, version « naïve » (on factorisera juste
après) :

```hcl
terraform_binary = "terraform"   # sinon Terragrunt appellerait `tofu` (cf. piège ci-dessus)

terraform {
  # TODO : chemin RELATIF vers le module wordpress. Le `//` marque la racine du module.
  #        (indice : depuis live/dev/, remontez de 2 dossiers -> `../../` puis `modules/wordpress`)
  source = "../../modules//wordpress"
}

inputs = {
  SERVER_NAME = "dev"
  WP_PORT     = 8081
  WP_VARS = {
    # TODO : les 4 identifiants MySQL (comme en 3)
  }
}
```

> 📖 [bloc `terraform { source }`](https://terragrunt.gruntwork.io/docs/reference/config-blocks-and-attributes/#terraform)
>
> 💡 **Tester :** depuis `live/dev/`, `terragrunt plan`. Vous devez voir `Plan: 7 to add`.

Ça marche… mais `SERVER_NAME`, `WP_PORT`, `WP_VARS` sont **écrits en dur dans dev**, et il faudrait
tout recopier dans `staging`. On n'a rien gagné. **On factorise.**

---

## 🧩 3 — `include` : factoriser la config globale

On crée **une** config à la racine — `root.hcl` — qui contiendra tout ce qui est **commun**. Chaque
environnement l'**inclut** au lieu de la recopier.

> ℹ️ **Pourquoi `root.hcl` et pas `terragrunt.hcl` ?** Historiquement (et dans beaucoup de tutos), la
> config racine s'appelle `terragrunt.hcl`. Terragrunt récent **déconseille** ce nom à la racine
> (message *« using `terragrunt.hcl` as the root … is an anti-pattern »*) et recommande un nom
> distinct comme **`root.hcl`**. On suit la reco actuelle.

`root.hcl` (à la racine `5-terragrunt/`) :

```hcl
terraform_binary = "terraform"          # cf. section 2

terraform {
  # TODO : source du module, mais cette fois indépendante de l'endroit d'où on lance.
  #        get_parent_terragrunt_dir() = le dossier de CE fichier root.hcl.
  source = "${get_parent_terragrunt_dir()}/modules//wordpress"
}
```

Puis chaque environnement se réduit à un `include`. `live/dev/terragrunt.hcl` devient :

🚧 **À compléter :**

```hcl
include "root" {
  # TODO : remonte les dossiers parents jusqu'à trouver le fichier de config racine
  path = find_in_parent_folders("root.hcl")
}
```

| Élément | Rôle |
|---|---|
| `include "root"` | tire toute la config du fichier trouvé (source, backend, inputs…) |
| `find_in_parent_folders("root.hcl")` | cherche `root.hcl` en **remontant** les dossiers parents |
| `get_parent_terragrunt_dir()` | dossier du `root.hcl` inclus => chemins **stables** quel que soit l'env |

> 📖 [`include`](https://terragrunt.gruntwork.io/docs/reference/config-blocks-and-attributes/#include) ·
> [`find_in_parent_folders`](https://terragrunt.gruntwork.io/docs/reference/built-in-functions/#find_in_parent_folders)

---

## 🌍 4 — `inputs` : les variables communes, déclarées une seule fois

Les variables **identiques** pour tous les environnements (les identifiants MySQL) ne doivent vivre
**qu'à un seul endroit** : dans les `inputs` de `root.hcl`. Terragrunt les injecte comme si vous aviez
fait `-var …` pour chaque `variable` déclarée dans le module.

🚧 **À compléter** dans `root.hcl` :

```hcl
inputs = {
  WP_VARS = {
    # TODO : les 4 identifiants MySQL — écrits UNE fois, hérités par dev ET staging
  }
}
```

> 📖 [`inputs`](https://terragrunt.gruntwork.io/docs/reference/config-blocks-and-attributes/#inputs)
>
> *Observation : une seule source de vérité pour les creds. Les changer = un seul fichier à éditer.*

---

## 🎯 5 — Ce qui change par environnement (et ce qui se déduit tout seul)

Il reste deux valeurs qui **diffèrent** d'un env à l'autre :

- **`WP_PORT`** — vraiment spécifique : on le met dans le `inputs` de **chaque** `live/*/terragrunt.hcl`.
- **`SERVER_NAME`** — on *pourrait* le répéter… mais il vaut mieux le **déduire du nom du dossier** :
  plus rien à recopier, et impossible de se tromper.

Dans `root.hcl`, complétez le **même** bloc `inputs` que celui de la section 4 — il n'y a qu'**un
seul** bloc `inputs` par fichier, on y ajoute simplement `SERVER_NAME` à côté de `WP_VARS` :

```hcl
inputs = {
  # TODO : SERVER_NAME déduit du nom du dossier de l'environnement
  #        (fonction qui renvoie le dossier courant + basename())
  SERVER_NAME = basename(get_terragrunt_dir())
  WP_VARS = { /* … les 4 identifiants de la section 4 … */ }
}
```

Et dans chaque environnement, **uniquement** ce qui lui est propre — `live/dev/terragrunt.hcl` :

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  WP_PORT = 8081        # dev
}
```

`live/staging/terragrunt.hcl` : le même `include`, avec `WP_PORT = 8082`.

| Fonction | Renvoie |
|---|---|
| `get_terragrunt_dir()` | le dossier de l'environnement en cours (`.../live/dev`) |
| `basename(...)` | juste le dernier segment => `dev`, `staging`, … |

> 📖 [`get_terragrunt_dir`](https://terragrunt.gruntwork.io/docs/reference/built-in-functions/#get_terragrunt_dir)
>
> 💡 **Tester :** depuis `live/dev/`, `terragrunt plan` — le conteneur s'appelle bien
> `wp_container_dev` (le `dev` vient du **dossier**, pas d'un `SERVER_NAME` écrit à la main) :
>
> ```
> + name = "wp_container_dev"
> Plan: 7 to add, 0 to change, 0 to destroy.
> ```

> **🧪 Manip — la déduction en action**
>
> 1. `cd live/dev` puis `terragrunt plan` => ressources préfixées `*_dev`.
> 2. `cd ../staging` puis `terragrunt plan` => **les mêmes** ressources, préfixées `*_staging`.
> 3. Vous n'avez écrit `SERVER_NAME` **nulle part** : il sort du nom du dossier.
>
> *Observé : deux environnements complets, et la seule chose qui diffère dans le code est le port.*

---

## 🗄️ 6 — Le backend : ce que Terraform ne sait PAS faire

Souvenez-vous de la section 1 : en Terraform, `backend { path = var.… }` est **interdit**. Résultat,
sans outil, les deux environnements écriraient dans **le même** `terraform.tfstate` et se
marcheraient dessus.

Terragrunt lève exactement ce verrou avec un bloc **`remote_state`** : il **génère** la config de
backend pour vous, et le chemin du state peut, lui, dépendre de fonctions.

🚧 **À compléter** dans `root.hcl` :

```hcl
remote_state {
  backend = "local"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    # TODO : un chemin de state DIFFÉRENT par environnement.
    #        path_relative_to_include() = "live/dev" pour dev, "live/staging" pour staging.
    path = "${get_parent_terragrunt_dir()}/state/${path_relative_to_include()}/terraform.tfstate"
  }
}
```

| Élément | Rôle |
|---|---|
| `remote_state` | Terragrunt **génère** le bloc `backend` (impossible à variabiliser en TF pur) |
| `generate` | écrit un `backend.tf` dans le dossier de travail au moment du run |
| `path_relative_to_include()` | chemin de l'env **relatif** au `root.hcl` => `live/dev`, `live/staging` |

> 📖 [`remote_state`](https://terragrunt.gruntwork.io/docs/reference/config-blocks-and-attributes/#remote_state) ·
> [`path_relative_to_include`](https://terragrunt.gruntwork.io/docs/reference/built-in-functions/#path_relative_to_include)
>
> 💡 **Tester :** après un `apply`, deux states bien séparés apparaissent à la racine :
>
> ```
> state/
> ├── live/dev/terraform.tfstate
> └── live/staging/terraform.tfstate
> ```

> ℹ️ **En entreprise…** on remplace `backend = "local"` par `"s3"`, `"gcs"`, `"azurerm"`… La
> mécanique est **identique** : un seul `remote_state` à la racine, et chaque env obtient son
> emplacement de state automatiquement. C'est *la* fonctionnalité qui a fait connaître Terragrunt.

---

## 🚀 7 — `run-all` : piloter tous les environnements d'un coup

Jusqu'ici on lançait `terragrunt apply` dossier par dossier. La commande **`run --all`** exécute la
même action dans **tous** les sous-dossiers contenant un `terragrunt.hcl`.

```bash
cd live/
terragrunt run --all -- plan     # plan de dev ET staging
terragrunt run --all -- apply    # déploie les DEUX environnements
```

> ⚠️ **Piège — `run-all` a été renommé (Terragrunt 1.x).**
> - *Symptôme :* `terragrunt run-all apply` => `ERROR unknown command: "run-all"`.
> - *Cause :* la refonte de la CLI (Terragrunt 1.x) a remplacé `run-all <cmd>` par
>   **`run --all -- <cmd>`** : la commande Terraform (et ses options) passe **après le `--`**.
> - *Correctif :* `terragrunt run --all -- apply`. De même en non-interactif :
>   `terragrunt run --all --non-interactive -- apply -auto-approve`. Beaucoup de tutos (dont
>   l'article d'origine) montrent encore l'ancienne forme `run-all` — d'où la confusion.
>
> 📖 [CLI redesign — la nouvelle commande `run`](https://docs.terragrunt.com/migrate/cli-redesign/)

> 💡 **Tester :** `docker ps` doit montrer **quatre** conteneurs — `wp_container_dev` +
> `db_container_dev` (port 8081) et `wp_container_staging` + `db_container_staging` (port 8082) :
>
> ```
> curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8081   # -> 302 (dev, WordPress install)
> curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8082   # -> 302 (staging)
> ```

> ⚠️ **Piège — l'image partagée entre environnements.**
> - *Symptôme :* détruire un env casse l'autre (« image utilisée par un conteneur »), ou l'image est
>   re-téléchargée à chaque fois.
> - *Cause :* les deux environnements gèrent la **même** image locale (`wordpress:latest`). Par
>   défaut le provider docker **supprime** l'image à la destruction.
> - *Correctif :* dans le module, `keep_locally = true` sur les `docker_image` => l'image locale
>   survit à un `destroy` et reste dispo pour l'autre env.

Pour tout nettoyer :

```bash
cd live/
terragrunt run --all -- destroy   # détruit dev ET staging
```

---

## ✅ Bonus

- **Variables intermédiaires (`read_terragrunt_config` + `merge`).** Pour des valeurs partagées par
  *certains* environnements seulement (ex. une « team »), placez un `common.hcl` à un niveau
  intermédiaire et fusionnez : `inputs = merge(read_terragrunt_config(find_in_parent_folders("common.hcl")).inputs, { … })`.
- **`generate "provider"`.** Plutôt que de laisser le bloc `provider "docker"` dans le module, on
  peut le faire **générer** par Terragrunt (bloc `generate`) — le provider devient DRY, comme le
  backend. Essayez de sortir le provider du module et de le générer depuis `root.hcl`.
- **Un 3ᵉ environnement en 30 secondes.** Créez `live/prod/terragrunt.hcl` (include + `WP_PORT = 8083`).
  `terragrunt run --all -- apply` => un `prod` complet, sans toucher au reste. *C'est la base de
  l'« environnement à la demande » (6).*

---

## 🎉 Challenge final

- [ ] `terragrunt --version` fonctionne et la config force `terraform` (pas `tofu`).
- [ ] `root.hcl` centralise : `source` du module, `remote_state`, et les `inputs` communs (`WP_VARS`).
- [ ] `live/dev` et `live/staging` ne contiennent **que** un `include` + leur `WP_PORT`.
- [ ] `SERVER_NAME` n'est écrit **nulle part** : il est déduit du nom du dossier.
- [ ] `terragrunt run --all -- apply` depuis `live/` déploie **dev + staging** ; `curl :8081` et
      `:8082` renvoient `302` (WordPress redirige vers son install).
- [ ] Deux states séparés existent sous `state/live/dev/` et `state/live/staging/`.

---

## Récap

- **Terragrunt = wrapper DRY de Terraform.** Un `terragrunt.hcl` par environnement, une config
  **globale** partagée via `include` + `find_in_parent_folders`.
- **`terraform { source }`** appelle **un seul** module ; **`inputs`** injecte les variables — les
  communes une seule fois à la racine, les spécifiques dans chaque env.
- **`remote_state`** génère le **backend** que Terraform refuse de variabiliser => un **state isolé
  par environnement** (`path_relative_to_include`).
- **`get_terragrunt_dir` + `basename`** déduisent le nom de l'env du **dossier** : zéro recopie.
- **`run --all`** applique/détruit **tous** les environnements d'un coup — la brique de base des
  environnements à la demande (**6**).

➡️ **6 — Environnements à la demande** : industrialiser « une review app = un dossier + un
`terragrunt apply` » dans un pipeline.
