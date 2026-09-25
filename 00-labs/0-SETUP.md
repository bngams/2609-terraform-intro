# 0 — Terraform : installation & concepts

Précédemment (J1) vous avez construit un pipeline qui, à la fin, **simulait** un environnement
à la demande (`deploy:review` avec des `echo`). On va apprendre à **provisionner réellement**
cet environnement avec **Terraform**.

> **Le fil rouge.** En fin de J2, le `deploy:review` du pipeline lancera un vrai
> `terraform apply` (et `stop:review` un `terraform destroy`). On remplit la brique posée hier.

---

## Qu'est-ce que Terraform ?

**Terraform** est un outil d'**Infrastructure as Code (IaC)** : on décrit l'infrastructure
voulue dans des fichiers de code, et l'outil se charge de la créer/modifier/détruire pour
atteindre cet état.

| Notion | Définition |
|---|---|
| **IaC** | l'infra est décrite par du **code** versionné (git), pas cliquée à la main |
| **Déclaratif** | on décrit l'**état voulu**, pas les étapes — Terraform calcule le « comment » |
| **Agnostique** | indépendant de la plateforme : AWS, Azure, GCP, **Docker**, VMware… via des *providers* |
| **HCL** | *HashiCorp Configuration Language*, le langage des fichiers `.tf` |

> **Pourquoi c'est au cœur du GitOps.** IaC + git + un gestionnaire de configuration (Ansible,
> J3) = vous pouvez **reconstruire toute votre infra à l'identique** après un incident, un
> changement de fournisseur, etc. C'est exactement l'objectif des 3 jours.

---

## Terraform vs OpenTofu (la question licence)

En 2023, HashiCorp a fait passer Terraform sous licence **BSL** (Business Source License,
non strictement open-source). La communauté a réagi en créant un **fork open-source** géré par
la Linux Foundation : **OpenTofu**.

| | **Terraform** | **OpenTofu** |
|---|---|---|
| Éditeur | HashiCorp (IBM) | Linux Foundation (communauté) |
| Licence | BSL | open-source (MPL 2.0) |
| CLI | `terraform` | `tofu` (commandes **quasi identiques**) |
| HCL / providers | — | **compatibles** |

> **Pour le lab :** on utilise **Terraform** (le plus répandu en entreprise). Tout ce qu'on
> verra fonctionne **à l'identique** avec OpenTofu — il suffit de remplacer `terraform` par
> `tofu`. Si dans votre organisation la **licence BSL** pose question, vous savez désormais quoi
> proposer : **OpenTofu**, un remplaçant *drop-in* sans BSL.

---

## Le workflow Terraform

Cinq étapes clés, plus la notion de **state** :

| Commande | Rôle |
|---|---|
| **Write** | vous écrivez la configuration (`.tf`) |
| `terraform init` | initialise le dossier, **télécharge les providers** |
| `terraform plan` | **affiche le diff** entre l'état voulu et l'état réel (sans rien changer) |
| `terraform apply` | applique les changements à l'infra réelle |
| `terraform destroy` | détruit tout ce qui a été créé |

> Cycle réel : `write → plan → apply`, on modifie le code, on reboucle par `plan → apply`…
> et `destroy` seulement quand on n'a plus besoin des ressources. Le **`state`** (chapitre
> [4](4-STATE.md)) est ce qui permet à Terraform de savoir ce qu'il a déjà créé.

---

## Etape — Installer Terraform (ou OpenTofu)

### Terraform

Binaire unique à télécharger : [releases.hashicorp.com/terraform](https://releases.hashicorp.com/terraform/)
(ou via un gestionnaire de paquets : `brew install terraform`, `apt`, `choco`…).

### OpenTofu (alternative)

[opentofu.org/docs/intro/install](https://opentofu.org/docs/intro/install/) — `brew install opentofu`, etc.

> **🧪 Manip — vérifier l'installation**
>
> ```bash
> terraform version
> # Terraform v1.x.x
>
> terraform -help        # liste des commandes (init, plan, apply, destroy, console…)
> ```
>
> *(Si vous avez choisi OpenTofu : `tofu version`, `tofu -help` — mêmes sous-commandes.)*

---

## Recap

- Terraform = **IaC déclaratif, agnostique**, langage **HCL**.
- Workflow : **write → init → plan → apply** (+ `destroy`), avec un **state** pour la mémoire.
- **OpenTofu** = fork open-source (réponse à la licence BSL) ; CLI quasi identique.

➡️ **[1 — Première configuration Terraform](1-FIRST-CONFIG.md)** : on exécute le
workflow de bout en bout sur un exemple minimal.
