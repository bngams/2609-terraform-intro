# 6 — Brancher Terraform dans GitLab CI (l'environnement à la demande)

Suite de [5](5-LOCALSTACK.md). C'est **le chapitre qui relie J1 et J2**. En J1, le job
`deploy:review` faisait des `echo` ([J1-5](../J1-GITLAB/J1-5-REVIEW-ENV.md)). On remplace ces
`echo` par un **vrai `terraform apply`**, et le `stop:review` par un **`terraform destroy`**.

> **Le résultat :** à chaque Merge Request, le pipeline **provisionne réellement** un
> environnement (une stack WordPress isolée), accessible par URL, et le **détruit** à la
> fermeture de la MR. La brique posée en J1 est maintenant remplie. 🎉

### Ressources utiles

- [Terraform dans GitLab CI](https://docs.gitlab.com/user/infrastructure/iac/) ·
  [GitLab-managed state](https://docs.gitlab.com/user/infrastructure/iac/terraform_state/)
- [`docker` provider — auth host distant](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs#registry-credentials)
- [`local_file`](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) (pour générer l'inventaire)

---

## La question clé : où atterrissent les conteneurs ?

Quand un **job CI** lance `terraform apply` avec le provider `docker`, Terraform parle à **un
démon Docker**. Lequel ? C'est **la** décision d'architecture. Deux approches :

### Approche A (défaut du lab) — le socket Docker de l'hôte

Notre runner docker monte déjà `/var/run/docker.sock` (cf. [J1-0](../J1-GITLAB/J1-0-LAB-SETUP.md)).
Terraform parle à **ce** socket → les conteneurs sont créés **sur l'hôte**, comme des
**frères** du conteneur de job. Ils **persistent après le job** et sont **joignables par URL**.

```
[ runner docker ] --monte--> /var/run/docker.sock (hôte)
   └─ job CI: terraform apply  ──>  crée  [ wp ] [ db ]  SUR L'HÔTE (persistent)
```

> ✅ Simple, les conteneurs survivent au job et exposent une URL. **C'est le défaut du lab.**
> ⚠️ Monter le socket = quasi-`privileged` (le job peut piloter Docker de l'hôte). **Acceptable
> en Mode Local auto-hébergé**, **à proscrire sur des runners partagés** — exactement la
> discussion sécurité de [J1-4](../J1-GITLAB/J1-4-BUILD-IMAGE.md).

### Approche B (variante « vrai serveur d'env ») — démon Docker distant via TCP

On pointe le provider sur un démon Docker **distant**, exposé en TCP (mTLS) :

```hcl
provider "docker" {
  host = "tcp://env-server.example.com:2376"
  # + certificats client (ca/cert/key) pour mTLS
}
```

```
[ job CI ] --TCP/mTLS--> [ serveur d'env dédié : dockerd ]  ──> [ wp ] [ db ]
```

> Plus propre (l'hôte du runner reste neutre), plus proche d'un vrai « serveur d'environnements
> à la demande ». Demande un démon Docker joignable et sécurisé.

**Pour ce lab : Approche A (socket).** L'Approche B est la voie « production » à connaître.

---

## Le module d'environnement (réutilise 3)

Un environnement = **un appel du module `wordpress`** (3), paramétré par la branche :

```hcl
# ops/terraform/main.tf
variable "env_name" { type = string }     # ex: review-feat-login
variable "wp_port"  { type = number }

module "env" {
  source         = "../../modules/wordpress"
  name_prefix    = var.env_name
  wp_port        = var.wp_port
  mysql_user     = var.mysql_user
  mysql_user_pwd = var.mysql_user_pwd
  mysql_root_pwd = var.mysql_root_pwd
}

output "url" {
  value = module.env.url
}
```

---

## Générer l'inventaire pour Ansible (le handoff J3)

C'est **le point de jonction J2 → J3** : Terraform sait ce qu'il a créé, donc **il écrit
l'inventaire** qu'Ansible (J3) consommera pour configurer la stack.

```hcl
# ops/terraform/inventory.tf
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/inventory.ini"
  content  = <<-EOT
    [wordpress]
    ${module.env.wp_container_name} ansible_connection=community.docker.docker
  EOT
}
```

> On utilise la **connexion `community.docker`** (pas de SSH) : Ansible exécutera ses tâches
> **directement dans le conteneur** créé par Terraform. C'est le combo classique TF→Ansible,
> adapté à notre lab local (J3).

---

## Le state en CI (rappel 4)

On déclare le backend `http` vide et on laisse GitLab fournir l'adresse + l'auth via les
variables `TF_HTTP_*` et `$CI_JOB_TOKEN`. **Un state par environnement** (clé = la branche) :

```yaml
variables:
  TF_STATE_NAME: "review-$CI_COMMIT_REF_SLUG"      # un state par branche/MR
  TF_HTTP_ADDRESS: "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/terraform/state/${TF_STATE_NAME}"
  TF_HTTP_LOCK_ADDRESS: "${TF_HTTP_ADDRESS}/lock"
  TF_HTTP_UNLOCK_ADDRESS: "${TF_HTTP_ADDRESS}/lock"
  TF_HTTP_USERNAME: "gitlab-ci-token"
  TF_HTTP_PASSWORD: "${CI_JOB_TOKEN}"
  TF_HTTP_LOCK_METHOD: "POST"
  TF_HTTP_UNLOCK_METHOD: "DELETE"
```

---

## Le pipeline : `echo` → `terraform apply` / `destroy`

On reprend **exactement** les jobs `deploy:review` / `stop:review` de
[J1-5](../J1-GITLAB/J1-5-REVIEW-ENV.md) — seul le **`script:`** change.

```yaml
stages: [deploy]

.terraform:                                  # base commune (DRY, cf. J1-2)
  image:
    name: hashicorp/terraform:latest
    entrypoint: [""]
  tags: [docker]                             # runner avec le socket monté (Approche A)
  variables:
    TF_STATE_NAME: "review-$CI_COMMIT_REF_SLUG"
    TF_HTTP_ADDRESS: "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/terraform/state/${TF_STATE_NAME}"
    TF_HTTP_LOCK_ADDRESS: "${TF_HTTP_ADDRESS}/lock"
    TF_HTTP_UNLOCK_ADDRESS: "${TF_HTTP_ADDRESS}/lock"
    TF_HTTP_USERNAME: "gitlab-ci-token"
    TF_HTTP_PASSWORD: "${CI_JOB_TOKEN}"
    TF_HTTP_LOCK_METHOD: "POST"
    TF_HTTP_UNLOCK_METHOD: "DELETE"
  before_script:
    - cd ops/terraform
    - terraform init

deploy:review:
  extends: .terraform
  stage: deploy
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  resource_group: review/$CI_COMMIT_REF_SLUG     # un seul apply à la fois (cf. J1-2)
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    url: http://$CI_COMMIT_REF_SLUG.lab.example.com
    on_stop: stop:review
    auto_stop_in: 2 hours
  script:
    # === LE vrai déploiement (remplace les echo de J1) ===
    - terraform apply -auto-approve -var "env_name=review-$CI_COMMIT_REF_SLUG" -var "wp_port=8888"
    - terraform output -raw url

stop:review:
  extends: .terraform
  stage: deploy
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      when: manual
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    action: stop
  script:
    - terraform destroy -auto-approve -var "env_name=review-$CI_COMMIT_REF_SLUG" -var "wp_port=8888"
```

> **Comparez à J1-5 :** la structure (`environment`, `on_stop`, `auto_stop_in`, `resource_group`,
> les `rules`) est **identique**. On a juste remplacé `echo …` par `terraform apply/destroy`.
> C'est exactement « construire une brique par jour » : le squelette était prêt.

---

## Et les secrets (mysql_user_pwd…) ?

> **Ne vous en occupez pas côté GitLab pour l'instant.** Vous *pourriez* les mettre en variables
> CI/CD masquées, mais la **gestion propre des secrets** est le sujet de **J3 — Ansible Vault**
> (avec une ouverture vers **HashiCorp Vault**). Pour faire tourner le lab maintenant, une
> variable CI/CD `TF_VAR_mysql_user_pwd` suffit ; on industrialisera en J3.

---

## Manips

> **🧪 Manip — une MR provisionne un vrai environnement**
>
> 1. Mettez le module + `ops/terraform/` dans le repo, et le pipeline ci-dessus.
> 2. Créez une branche, **ouvrez une MR**.
> 3. Le job `deploy:review` lance `terraform apply` → dans **Operate > Environments**, l'env
>    `review/<branche>` apparaît ; `docker ps` sur l'hôte montre `review-…-wp` / `-db`.
> 4. Ouvrez l'URL → l'installeur WordPress de **cet** environnement répond.
>
> *Observation : un environnement réel, isolé, par MR — l'« env à la demande » est là.*

> **🧪 Manip — fermer la MR détruit l'environnement**
>
> Mergez ou fermez la MR → GitLab déclenche `stop:review` → `terraform destroy` → `docker ps`
> ne montre plus les conteneurs ; l'environnement passe **stopped**. (Sinon, `auto_stop_in`
> s'en charge après 2 h.)
>
> *Observation : jetable et auto-nettoyé — pas de fuite de ressources.*

> **🧪 Manip — l'inventaire pour J3**
>
> Après l'`apply`, vérifiez que `ops/terraform/inventory.ini` a été généré (exposez-le en
> `artifacts:` pour le récupérer). Il liste le conteneur WordPress en connexion
> `community.docker`.
>
> *Observation : Terraform a écrit ce qu'Ansible consommera demain (J3). Le handoff est prêt.*

---

## Recap

- On a remplacé les **`echo`** de J1-5 par **`terraform apply`** (`deploy:review`) et
  **`terraform destroy`** (`stop:review`) — **même squelette `environment`/`on_stop`**.
- **Où tournent les conteneurs ?** Approche **A (socket de l'hôte)** = défaut du lab (siblings,
  persistants) ; Approche **B (Docker distant TCP/mTLS)** = variante « serveur d'env ». Socket =
  Mode Local seulement (sécurité, cf. J1-4).
- **State par environnement** sur le backend GitLab (`TF_STATE_NAME = review-<branche>`).
- **Terraform écrit l'inventaire Ansible** → **handoff J3** (connexion `community.docker`, sans SSH).
- **Secrets** : on attend **J3 (Ansible Vault)** ; une variable CI suffit pour l'instant.

➡️ **[7 — Revue : votre infra, vos choix](7-REVIEW.md)** : adapter tout ça à une infra
réelle et décider quoi mettre dans la CI.
