# 7 — Revue : votre infra, vos choix

Clôture du **Jour 2**. Pas de nouvelle syntaxe ici : on prend du recul. Vous avez tous les
outils (HCL, providers, state, CI). La question devient : **comment les appliquer à VOTRE
infra ?** Ce chapitre est une **grille de décision** à remplir pour votre contexte.

---

## Ce qu'on a construit en J2

```
1  workflow Terraform (local_file) : write/init/plan/apply/destroy + state
2  provider docker : ressources d'infra (réseau, volumes, conteneurs) — la logique HCL
3  HCL avancé : variables, tfvars/secrets, types, locals, count/for_each, modules
4  state distant + verrouillage (backend GitLab)
5  LocalStack : vrai HCL AWS (site S3) sans coût
6  env à la demande : terraform apply/destroy dans la CI + inventaire pour Ansible
```

La brique J1 (`deploy:review` simulé) est désormais **réelle**. Reste à la brancher sur **votre**
réalité.

---

## Décision 1 — Quel provider pour votre infra ?

Le **raisonnement Terraform est identique** quel que soit le provider ; seuls les **types de
ressources** changent.

| Votre cible | Provider | Ressources typiques |
|---|---|---|
| Conteneurs (lab, edge, on-prem léger) | `kreuzwerker/docker` | `docker_container`, `_network`, `_volume` |
| AWS | `hashicorp/aws` | `aws_instance`, `aws_vpc`, `aws_s3_bucket`, `aws_db_instance`… |
| Azure / GCP | `azurerm` / `google` | équivalents |
| VMware / on-prem | `vsphere`, `libvirt` | VMs, datastores, réseaux |

> **À décider :** sur quoi tourne réellement votre infra ? C'est le seul vrai choix — le reste
> (modules, state, CI) se transpose tel quel.

---

## Décision 2 — Que met-on dans GitLab CI, et comment ?

Tout n'a pas vocation à être déclenché automatiquement. Repères :

| Étape | Auto sur MR ? | Pourquoi |
|---|---|---|
| `terraform fmt` / `validate` | ✅ toujours | rapide, garde-fou de qualité |
| `terraform plan` | ✅ sur MR | **revue du diff** avant merge (à publier en commentaire de MR) |
| `terraform apply` (review app) | ✅ sur MR | l'environnement à la demande (6) |
| `terraform apply` (staging/prod) | ⚠️ **manuel** | un humain valide (`when: manual` + environnement protégé) |
| `terraform destroy` (review) | ✅ à la fermeture MR | nettoyage (6) |

> **Pattern senior :** `plan` automatique + commentaire de MR, `apply` de prod **manuel** et
> **protégé** (environnement protégé GitLab, `resource_group` pour sérialiser). On réutilise les
> `rules`, `environment`, `resource_group` du [J1-2](../J1-GITLAB/J1-2-SERIOUS-TIPS.md).

---

## Décision 3 — La limite LocalStack ↔ Ansible (cap vers J3)

C'est **le** point d'architecture pour enchaîner sur Ansible (J3).

**Le problème :** LocalStack **émule** les API AWS — quand vous créez une `aws_instance`, il n'y
a **pas de vraie VM** derrière. Donc **on ne peut pas s'y connecter en SSH** ni y exécuter des
commandes. Or Ansible a besoin d'une **cible réelle** à configurer.

Deux voies pour J3 :

| Voie | Cible Ansible | Connexion | Pour qui |
|---|---|---|---|
| **A — conteneurs Docker locaux** *(défaut du lab)* | les conteneurs créés par TF (provider docker) | `community.docker` (**exec dans le conteneur, sans SSH**) | tout le monde, 100 % local |
| **B — vrai AWS EC2** | une instance EC2 réelle (TF `aws_instance`) | **SSH** + clé | si vous avez des creds AWS |

> **Notre choix pour J3 : la voie A.** Terraform (provider docker, 6) provisionne les
> conteneurs WordPress ; Ansible les configure via la connexion `community.docker`, **sans
> SSH**. C'est cohérent, local, et tout le monde peut le faire. La **voie B (EC2 + SSH)** reste
> la variante « vrai cloud » pour ceux qui veulent aller jusqu'au bout.

> **Pourquoi pas Ansible sur LocalStack ?** Parce qu'il n'y a rien à configurer *dans* une
> instance émulée. LocalStack sert à **provisionner/tester le HCL AWS** (5), pas à héberger
> un OS qu'on configure. Les deux outils, deux rôles : **Terraform provisionne, Ansible
> configure** — encore faut-il une vraie cible à configurer.

---

## Décision 4 — Les secrets (transition vers J3)

Jusqu'ici on a « laissé filer » les secrets (variable CI, valeur de lab). En J3 on
industrialise :

- **Ansible Vault** : chiffrer les variables sensibles **dans le repo** (mots de passe DB, etc.).
- Ouverture : **HashiCorp Vault** pour une gestion centralisée/dynamique des secrets.

> Message à retenir du J2 : **ne mettez pas de secrets en clair** (ni dans le `.tf`, ni dans le
> state commité, ni en variable non masquée). On les traite **proprement demain**.

---

## Votre grille de décision (à remplir)

> **🧪 Atelier — votre contexte**
>
> Répondez pour votre organisation :
>
> 1. **Provider** : ma cible réelle = ______ (docker / AWS / Azure / on-prem…).
> 2. **Modules** : quelles briques réutilisables ? (réseau, base de données, app…).
> 3. **State** : backend = ______ (GitLab managé / S3+lock / autre). Un state par
>    quoi ? (projet / environnement / branche).
> 4. **CI** : qu'est-ce qui est **auto** (plan, review app) vs **manuel** (apply prod) ?
> 5. **Cible Ansible (J3)** : conteneurs locaux (voie A) ou VM/EC2 réelle (voie B) ?
> 6. **Secrets** : où ? (Ansible Vault → puis Vault).
>
> *Il n'y a pas une réponse unique — l'objectif est d'avoir un plan cohérent de bout en bout.*

---

## Recap — fin du J2

- Le **raisonnement Terraform** (déclarer, référencer, planifier, modulariser, gérer le state)
  se **transpose à n'importe quel provider** ; on l'a appris sur Docker + AWS (LocalStack).
- Dans la CI : **`plan` auto** (revue), **`apply` review app** auto, **`apply` prod** manuel et
  protégé.
- **Terraform provisionne, Ansible configure** — il faut une **cible réelle** : J3 prendra les
  **conteneurs locaux** (voie A, `community.docker`), avec l'EC2 réel en variante.
- **Secrets** → traités proprement en **J3 (Ansible Vault, puis HashiCorp Vault)**.

### Ce qu'on a construit en J1 + J2

```
J1  pipeline CI/CD complet → review app SIMULÉE (echo)
J2  Terraform → la review app est RÉELLEMENT provisionnée (terraform apply/destroy)
    + Terraform écrit l'inventaire Ansible
```

➡️ **J3 — Ansible** : configurer ce que Terraform a provisionné, et assembler le **capstone**
(pipeline = `terraform apply` + `ansible-playbook`, `on_stop` = `terraform destroy`).
