# Projet 01 — Le socle serveur

> **Parcours** : Administration système & réseau *Groupe MERIDIAN*
> **Type de projet** : Projet personnel
> **Statut** : Terminé


---

## 1. Contexte métier

**Groupe MERIDIAN** est une PME de transport et logistique : 12 salariés, 2 entrepôts, un bureau. Jusqu'à aujourd'hui, l'informatique tient sur un NAS grand public acheté en 2019, des clés USB qui circulent entre les entrepôts, et un fichier `TARIFS_FINAL_v4_OK_vraiment.xlsx` que personne n'ose supprimer.

Le gérant vient de signer un contrat qui va faire passer l'effectif à 30 personnes en 18 mois. Il nous recrute comme **premier administrateur système**. Notre première mission tient en une phrase, prononcée dans son bureau :

> *« Monte-moi un serveur. Et fais-le bien, parce que je ne veux pas qu'on le refasse dans six mois. »*

Ce serveur va devenir le socle de **toute** l'infrastructure des projets suivants : partages de fichiers, DNS, DHCP, supervision, sauvegarde. Chaque décision que nous prenons maintenant, surtout le partitionnement, sera soit un cadeau, soit une dette technique que nous traînerons pendant onze projets.

**Aucun service applicatif n'est demandé ici.** Ce projet ne produit rien de visible pour l'utilisateur final. C'est précisément ce qui le rend difficile.

---

## 2. Objectifs pédagogiques

À la fin de ce projet, nous devons être capables de :

| # | Compétence |
|---|---|
| O-01 | Installer une distribution Linux serveur en mode manuel, sans environnement graphique |
| O-02 | Concevoir un schéma de partitionnement LVM et justifier chaque choix |
| O-03 | Configurer une adresse IP statique et comprendre la chaîne de résolution de noms |
| O-04 | Mettre en place une authentification SSH par clé et supprimer l'authentification par mot de passe |
| O-05 | Gérer l'élévation de privilèges avec `sudo` plutôt qu'en travaillant en root |
| O-06 | Filtrer le trafic entrant avec un pare-feu et vérifier les règles actives |
| O-07 | Lire les journaux système avec `journalctl` pour diagnostiquer un démarrage |
| O-08 | Documenter une installation de façon à ce qu'un tiers puisse la reproduire |

---

## 3. Prérequis

**Connaissances**
- Navigation dans l'arborescence (`cd`, `ls`, `pwd`)
- Édition d'un fichier texte (`nano` suffit ; c'est le bon moment pour commencer `vim`)
- Notion d'adresse IP et de masque de sous-réseau 

**Matériel et logiciels**
- Un PC avec au minimum 8 Go de RAM et 30 Go de disque libre
- VirtualBox ou KVM/virt-manager installé et fonctionnel
- L'image ISO **Debian 13 « Trixie » netinst** (≈ 700 Mo)
- Un compte GitHub et `git` configuré sur notre poste (pour la documentation et le suivi)

**Configuration de la VM à créer**

| Paramètre | Valeur |
|---|---|
| Nom | `srv-meridian-01` |
| vCPU | 2 |
| RAM | 2048 Mo |
| Disque | 20 Go, dynamiquement alloué |
| Interface réseau 1 | NAT (accès Internet) |
| Interface réseau 2 | Réseau privé hôte / *host-only* (`192.168.56.0/24`) |

> La double interface n'est pas un détail. Un serveur a besoin de sortir vers Internet **et** d'être joignable depuis notre poste, et que ce ne sont pas les mêmes besoins. Cette séparation nous servira de base au projet 07 sur la segmentation réseau.

---

## 4. Périmètre

- Installation du système en mode texte, sans interface graphique
- Partitionnement avec LVM
- Configuration réseau statique + résolution DNS
- Création du compte d'administration et configuration de `sudo`
- Durcissement SSH
- Pare-feu limité au strict nécessaire
- Mises à jour de sécurité automatiques
- Documentation et journal de bord

---

## 5. Spécifications

### 5.1 Système

| # | Exigence |
|---|---|
| EX-01 | Debian 13 « Trixie », installation **sans** environnement de bureau. Seuls les paquets *standard system utilities* et *SSH server* sont sélectionnés. |
| EX-02 | Nom d'hôte : `srv-meridian-01`. Domaine : `meridian.lan`. Le FQDN doit être résolu localement. |
| EX-03 | Fuseau horaire et locale cohérents avec la France métropolitaine, clavier AZERTY. |
| EX-04 | Le compte `root` possède un mot de passe, mais **aucune session interactive `root` n'est utilisée après l'installation**. |

### 5.2 Partitionnement

| # | Exigence |
|---|---|
| EX-05 | `/boot` : 1 Go, ext4, **en dehors** de LVM. |
| EX-06 | Le reste du disque forme un unique volume physique dans un groupe de volumes nommé `vg_system`. |
| EX-07 | Volumes logiques : `lv_root` (8 Go, `/`), `lv_var` (4 Go, `/var`), `lv_home` (2 Go, `/home`), `lv_tmp` (1 Go, `/tmp`), `lv_swap` (2 Go, swap). |
| EX-08 | **Au moins 2 Go doivent rester non alloués dans `vg_system`.** Cette contrainte est volontaire et sera exploitée au projet 04. |
| EX-09 | `/tmp` est monté avec les options `nodev,nosuid,noexec`. |


### 5.3 Réseau

| # | Exigence |
|---|---|
| EX-10 | Interface NAT : configuration automatique par DHCP. |
| EX-11 | Interface *host-only* : adresse statique `192.168.56.10/24`, sans passerelle. |
| EX-12 | Résolveurs DNS configurés et fonctionnels ; `ping deb.debian.org` doit aboutir. |
| EX-13 | La configuration réseau doit survivre à un redémarrage **et** au renommage éventuel des interfaces par le noyau. |

### 5.4 Comptes et privilèges

| # | Exigence |
|---|---|
| EX-14 | Un compte nominatif `essotom` appartenant au groupe `sudo`. |
| EX-15 | Toutes les commandes lancées via `sudo` sont journalisées dans `/var/log/sudo.log`. |
| EX-16 | Aucun compte utilisateur autre que `root` et notre compte nominatif. |

### 5.5 Accès distant

| # | Exigence |
|---|---|
| EX-17 | Connexion SSH par **clé Ed25519** uniquement. La clé privée reste sur notre poste hôte et n'est jamais copiée sur le serveur. |
| EX-18 | `PasswordAuthentication no` et `PermitRootLogin no` dans la configuration du démon SSH. |
| EX-19 | Le service SSH n'écoute **que** sur `192.168.56.10`, pas sur l'interface NAT. |
| EX-20 | Une bannière d'avertissement s'affiche avant l'invite de connexion. |

### 5.6 Sécurité et maintenance

| # | Exigence |
|---|---|
| EX-21 | Pare-feu actif au démarrage. Politique par défaut : tout trafic entrant refusé, sauf SSH depuis `192.168.56.0/24` et le trafic sur l'interface de bouclage. |
| EX-22 | Les mises à jour de sécurité s'installent automatiquement sans intervention. |
| EX-23 | Le serveur redémarre proprement sans erreur critique dans les journaux. |

---

## 6. Zones de recherche imposées

`docs/recherches.md` (pour les réponses)

1. **PV, VG, LV** — Expliquer les trois niveaux d'abstraction de LVM. Pourquoi isoler `/var` sur son propre volume logique ? Quel incident précis cela évite-t-il ?
2. **`/boot` hors LVM** — Pourquoi cette règle a longtemps existé, et dans quelles conditions elle ne s'applique plus aujourd'hui. Que fait GRUB au démarrage qui explique cette contrainte ?
3. **Empreinte de clé SSH** — Lors de notre première connexion, SSH affiche une empreinte et demande confirmation. Que vérifie-t-il exactement ? Que se passe-t-il si on répond « yes » sans vérifier ? Comment obtenir l'empreinte attendue **depuis le serveur, avant** de se connecter ?
4. **`sudo -i` vs `sudo su -` vs `su -`** — Ces trois commandes semblent équivalentes. Elles ne le sont pas. Quelles différences d'environnement, de journalisation, de mot de passe demandé ?
5. **Gestion du réseau sous Debian** — `ifupdown`, `systemd-networkd`, `NetworkManager` : lequel une installation serveur Debian utilise-t-elle par défaut ? Comment le vérifier avec certitude sur notre machine ? Que se passe-t-il si deux d'entre eux tournent en même temps ?
6. **Nommage prédictible des interfaces** — Pourquoi notre interface s'appelle-t-elle `enp0s3` et non `eth0` ? Décomposer le nom morceau par morceau.

---

## 7. Livrables GitHub

### Arborescence du projet

```
meridian-infra/
├── README.md                       # Vue d'ensemble du fil rouge + index des projets
└── 01-socle-serveur/
    ├── README.md                   # Cahier des charges + ce qui a été réellement fait
    ├── JOURNAL.md                  # Journal de bord (voir ci-dessous)
    ├── docs/
    │   ├── installation.md         # Procédure reproductible, pas à pas
    │   ├── partitionnement.md      # Schéma + justification de chaque choix
    │   ├── recherches.md           # Réponses aux 6 questions de la section 6
    │   └── validation.md           # Sorties réelles des commandes de la section 5
    └── conf/
        ├── sshd_config
        ├── nftables.conf
        ├── 50unattended-upgrades
        └── fstab
