# 2 — Du Docker au Terraform (provider `docker`)

Suite de [1](1-FIRST-CONFIG.md). On passe du `local_file` à de **vraies ressources
d'infrastructure** : des conteneurs, des réseaux, des volumes. On utilise pour cela le provider
**`docker`**.

> **Pourquoi Docker pour apprendre Terraform ?** Docker est un système capable de **piloter des
> ressources** (conteneurs, réseaux, volumes) — exactement le **type** de ressources qu'on
> manipulera plus tard sur une vraie infra (IaaS : VPC, sous-réseaux, volumes, instances…).
> Ici, Docker n'est qu'un **terrain d'entraînement local** pour comprendre la logique
> Terraform/HCL **sans cloud ni coût**. Le raisonnement est identique ; seuls les types de
> ressources changeront.

### Ressources utiles

- [Provider `kreuzwerker/docker`](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs)
- Ressources : [`docker_image`](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/image) ·
  [`docker_container`](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/container) ·
  [`docker_network`](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/network) ·
  [`docker_volume`](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/volume)

---

## Déclarer le provider docker

```hcl
# providers.tf
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}
```

> `version = "~> 3.0"` = « la dernière 3.x » (opérateur *pessimistic*). On verra le
> [version constraint](https://developer.hashicorp.com/terraform/language/expressions/version-constraints)
> plus en détail ; retenez qu'on **épingle** pour la reproductibilité.

---

# Partie 1 — Démo guidée : comprendre la logique

On construit pas à pas, en observant à chaque étape. **Suivez la démo**, on fera l'exercice
complet ensuite.

## Démo 1 — un conteneur qui tourne

```hcl
# main.tf
resource "docker_image" "ubuntu" {
  name = "ubuntu:24.04"          # /!\ éviter :latest en vrai — résultats imprévisibles
}

resource "docker_container" "demo" {
  name    = "demo"
  image   = docker_image.ubuntu.image_id     # référence à la ressource ci-dessus
  command = ["sleep", "infinity"]            # garde le conteneur vivant
}
```

> **🧪 Manip — créer un conteneur**
>
> ```bash
> terraform init && terraform apply
> docker ps                       # le conteneur "demo" tourne
> ```
> Notez la **référence** `docker_image.ubuntu.image_id` : Terraform comprend que le conteneur
> **dépend** de l'image → il crée l'image **avant** le conteneur. C'est une **dépendance
> implicite**.
>
> *Observation : on a décrit l'état voulu (une image + un conteneur), Terraform a trouvé l'ordre.*

## Démo 2 — ajouter un volume

Un conteneur seul ne persiste rien. On ajoute un **volume** et on le monte :

```hcl
resource "docker_volume" "demo_data" {
  name = "demo_data"
}

resource "docker_container" "demo" {
  name    = "demo"
  image   = docker_image.ubuntu.image_id
  command = ["sleep", "infinity"]

  volumes {                                   # bloc imbriqué
    volume_name    = docker_volume.demo_data.name
    container_path = "/data"
  }
}
```

> **🧪 Manip — le volume**
>
> 1. `terraform plan` → Terraform veut **recréer** le conteneur (un volume monté n'est pas
>    modifiable à chaud) et **créer** le volume. Lisez bien le plan : `+` (create), `-/+`
>    (replace).
> 2. `terraform apply`, puis :
>    ```bash
>    docker volume ls            # demo_data existe
>    docker exec demo sh -c 'echo coucou > /data/test && cat /data/test'
>    ```
>
> *Observation : on assemble des ressources (image → conteneur → volume) en les **reliant** par
> références. C'est exactement la logique qu'on appliquera à une vraie infra.*

> **Le parallèle infra.** `docker_network` ≈ un VPC/sous-réseau, `docker_volume` ≈ un disque
> (EBS), `docker_container` ≈ une instance. On apprend les **réflexes Terraform** (déclarer,
> référencer, planifier, appliquer) sur des briques gratuites et locales.

---

# Partie 2 — Exercice : traduire un `docker-compose` en Terraform

Objectif : prendre une stack **WordPress + MySQL** décrite en `docker-compose.yml` et la
**réécrire en HCL**. C'est l'exercice qui ancre la logique : un `compose` et un `.tf` décrivent
la **même intention**, avec des outils différents.

> **Important — le but est pédagogique.** On ne « remplace pas docker-compose par Terraform »
> en vrai. L'exercice sert à **manipuler les ressources Terraform** (réseau, volumes,
> conteneurs, variables) sur une stack qu'on connaît. La vraie valeur de Terraform apparaîtra
> sur le cloud (5) et l'env à la demande (6).

## Le point de départ (docker-compose)

```yaml
volumes:
  mysql_data: {}
  wp_data: {}
networks:
  wp_net: {}
services:
  db:
    image: mysql:8.0
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: MySQLRootPassword
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wp_user
      MYSQL_PASSWORD: wp_password
    volumes:
      - mysql_data:/var/lib/mysql
    networks: [wp_net]
  wordpress:
    depends_on: [db]
    image: wordpress:latest
    restart: always
    ports:
      - "8888:80"
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: wp_user
      WORDPRESS_DB_PASSWORD: wp_password
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - wp_data:/var/www/html
    networks: [wp_net]
```

## La traduction (squelette à compléter)

Créez `j2-2-wordpress/` avec `providers.tf` (provider docker) + `main.tf`. À compléter :

```hcl
# --- IMAGES ---
resource "docker_image" "mysql" {
  name = "mysql:8.0"
}
resource "docker_image" "wordpress" {
  name = "wordpress:latest"
}

# --- NETWORK ---
resource "docker_network" "wp_net" {
  name = "wp_net"
}

# --- VOLUMES ---
resource "docker_volume" "mysql_data" {
  name = "mysql_data"
}
resource "docker_volume" "wp_data" {
  name = "wp_data"
}

# --- CONTAINER db ---
resource "docker_container" "db" {
  name    = "db"
  image   = docker_image.mysql.image_id
  restart = "always"
  env = [
    "MYSQL_ROOT_PASSWORD=MySQLRootPassword",
    "MYSQL_DATABASE=wordpress",
    "MYSQL_USER=wp_user",
    "MYSQL_PASSWORD=wp_password",
  ]
  volumes {
    volume_name    = docker_volume.mysql_data.name
    container_path = "/var/lib/mysql"
  }
  networks_advanced {
    name = docker_network.wp_net.name
  }
}

# --- CONTAINER wordpress ---  (À COMPLÉTER en s'inspirant de db)
resource "docker_container" "wordpress" {
  name  = "wp"
  image = docker_image.wordpress.image_id
  # restart, env (WORDPRESS_DB_HOST = nom du conteneur db, etc.),
  # ports { internal = 80, external = 8888 },
  # volumes { wp_data → /var/www/html },
  # networks_advanced { wp_net }
}
```

> **`WORDPRESS_DB_HOST`** doit pointer vers le conteneur `db`. On peut écrire
> `"WORDPRESS_DB_HOST=${docker_container.db.name}"` → encore une **référence** qui crée la
> dépendance db → wordpress.

> **🧪 Manip — monter la stack**
>
> ```bash
> cd j2-2-wordpress
> terraform init && terraform apply
> docker ps                          # db + wp
> curl -I http://localhost:8888      # WordPress répond (installeur)
> ```
> Ouvrez `http://localhost:8888` → l'assistant WordPress s'affiche.
>
> *Observation : la même stack qu'en compose, mais décrite en HCL et gérée par le state.*

## Voir le graphe de dépendances

> **🧪 Manip — `terraform graph`**
>
> ```bash
> terraform graph > graph.dot
> # visualiser : coller graph.dot dans https://dreampuf.github.io/GraphvizOnline/
> # ou : terraform graph | dot -Tpng > graph.png   (si graphviz installé)
> ```
> On voit le **DAG** : images → volumes/réseau → conteneurs ; `wp` après `db`. Terraform
> **calcule cet ordre tout seul** à partir des références.
> ([doc `graph`](https://developer.hashicorp.com/terraform/cli/commands/graph))
>
> *Observation : on ne déclare jamais l'ordre — il découle des dépendances. (Comme le DAG des
> jobs en [J1-2](../J1-GITLAB/J1-2-SERIOUS-TIPS.md) !)*

## Complément

> **🧪 Manip (bonus) — ajouter Adminer**
>
> Ajoutez un conteneur `adminer` (image `adminer:latest`, port `8080:8080`, sur `wp_net`) pour
> accéder à la base. Re-`apply` → `http://localhost:8080`.
>
> *Objectif : ajouter une ressource = ajouter un bloc + `apply`. Le state suit.*

---

## Recap

- Provider **`kreuzwerker/docker`** : `docker_image` / `container` / `network` / `volume`.
- Les **références** entre ressources (`docker_image.x.image_id`) créent les **dépendances
  implicites** → Terraform en déduit l'ordre (le **DAG**, visible avec `terraform graph`).
- Bloc **imbriqué** (`volumes { … }`, `networks_advanced { … }`, `ports { … }`).
- On a traduit une stack **WP+MySQL** compose → HCL : même intention, gestion par le **state**.
- **Docker ici = terrain d'entraînement** ; la logique se transposera au cloud (5) et à
  l'env à la demande (6).

> ⚠️ Les mots de passe sont **en clair** dans le `.tf` — inacceptable. On corrige ça au
> chapitre suivant avec les **variables**, et les secrets seront traités proprement en **J3
> (Ansible Vault)**.

➡️ **[3 — HCL avancé : variables, structures, boucles, modules](3-HCL-AVANCE.md)**
