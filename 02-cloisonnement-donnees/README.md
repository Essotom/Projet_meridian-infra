# Projet 02 - Le cloisonnement des données

> **Parcours** : Administration système & réseau - Fil rouge *Groupe MERIDIAN*
> **Durée estimée** : 7 à 9 h
> **Dépend de** : Projet 01 (serveur opérationnel et accessible en SSH)
> **Statut** : Terminé

---

## 1. Contexte métier

Le serveur tourne. Le gérant est content, et il revient te voir avec un problème qu'il n'avait pas anticipé.

> *« Les fichiers de la compta se baladent partout. Le mois dernier, un gars de l'entrepôt est tombé sur les fiches de paie dans un dossier partagé. Il faut cloisonner. Mais attention : la comptable doit pouvoir consulter les dossiers de tout le monde pour ses rapprochements - sans rien modifier, elle est formelle là-dessus, elle ne veut pas être responsable si un document bouge. »*

Il ajoute deux contraintes en repartant :

> *« Un comptable externe intervient deux jours par mois jusqu'à fin décembre. Son accès doit se couper tout seul, je ne veux pas avoir à y penser. Et quand quelqu'un part, je veux que ses dossiers restent - on a déjà perdu des devis comme ça. »*

MERIDIAN compte 12 salariés répartis en 4 services. Ton travail : construire une arborescence partagée qui exprime exactement ces règles, sans qu'aucun utilisateur n'ait à réfléchir aux permissions.

Tu vas découvrir en chemin que les permissions Unix classiques - propriétaire, groupe, autres - ne savent pas exprimer « la compta lit tout en plus du groupe propriétaire ». Un fichier n'a qu'un seul groupe. Ce mur est le sujet du projet.

---

## 2. Objectifs pédagogiques

| # | Compétence |
|---|---|
| O-01 | Créer et gérer des comptes et des groupes selon une convention de nommage |
| O-02 | Appliquer une politique d'expiration de mots de passe et de comptes |
| O-03 | Concevoir une arborescence partagée reflétant un organigramme |
| O-04 | Maîtriser les permissions POSIX, y compris setgid et sticky bit |
| O-05 | Comprendre et configurer `umask` pour permettre le travail collaboratif |
| O-06 | Mettre en œuvre des ACL POSIX, y compris les ACL par défaut |
| O-07 | Rédiger une matrice d'habilitations exploitable par un tiers |
| O-08 | Exécuter une procédure de départ de collaborateur sans perte de données |

---

## 3. Prérequis

**Techniques**
- Le serveur du projet 01, fonctionnel, accessible par SSH
- Un instantané de la VM pris **avant** de commencer
- Le paquet `acl` installé (à vérifier)

**Connaissances**
- Lecture des permissions en notation symbolique et octale
- `chmod`, `chown`, `chgrp`
- Si la notation octale est floue : révise avant, tu bloqueras sinon

**L'organigramme de MERIDIAN**

| Service | Effectif | Rôle |
|---|---|---|
| Direction | 2 | Gérant et assistante de direction |
| Exploitation | 5 | Planning, chauffeurs, entrepôt |
| Commercial | 3 | Devis, clients, tarifs |
| Comptabilité | 2 | Facturation, paie, rapprochements |

Soit 12 salariés. Les noms sont à ton choix - invente-les et documente-les.

---

## 4. Périmètre

**Dans le périmètre**
- Comptes utilisateurs et groupes
- Politique d'expiration des mots de passe et des comptes
- Arborescence partagée et permissions
- ACL POSIX pour l'accès transverse de la comptabilité
- Matrice d'habilitations
- Procédure de départ

**Hors périmètre**
- Partage réseau (Samba/NFS) - projet 04
- Authentification centralisée (LDAP) - projet 08
- Quotas disque - bonus, ou projet 04
- Automatisation de la création de comptes - bonus, ou projet 03

---

## 5. Spécifications

### 5.1 Comptes

| # | Exigence |
|---|---|
| EX-01 | 12 comptes nominatifs suivant une convention de nommage unique, documentée. |
| EX-02 | Chaque compte dispose d'un répertoire personnel et d'un interpréteur de commandes interactif. |
| EX-03 | Les mots de passe expirent tous les 90 jours, avec avertissement 7 jours avant l'échéance. |
| EX-04 | Un 13ᵉ compte, `ext.comptable`, expire automatiquement le 31 décembre 2026. Aucune intervention manuelle ne doit être nécessaire à cette date. |
| EX-05 | Le compte `essotom` du projet 01 reste le **seul** membre du groupe `sudo`. Aucun salarié n'obtient de privilèges d'administration. |

### 5.2 Groupes

| # | Exigence |
|---|---|
| EX-06 | Quatre groupes de service : `g_direction`, `g_exploitation`, `g_commercial`, `g_comptabilite`. |
| EX-07 | Un groupe `g_meridian` dont les 13 comptes sont membres. |
| EX-08 | Chaque salarié appartient à exactement un groupe de service. Le choix entre groupe principal et groupe secondaire doit être justifié dans la documentation. |

### 5.3 Arborescence partagée

| # | Exigence |
|---|---|
| EX-09 | Les données partagées sont stockées sous `/srv/meridian/`, et **pas** sous `/home`. L'emplacement retenu doit être justifié par référence à la norme applicable. |
| EX-10 | Un répertoire par service, plus un répertoire `commun`. |
| EX-11 | Un répertoire de service est accessible en lecture et écriture aux seuls membres du groupe correspondant. Les autres salariés ne peuvent ni le lister, ni le traverser. |
| EX-12 | `commun` est accessible en lecture et écriture à tous les membres de `g_meridian`. |
| EX-13 | Tout fichier ou dossier créé dans un répertoire de service appartient automatiquement au groupe de ce service, quel que soit le groupe principal de son créateur. |
| EX-14 | Deux membres d'un même service peuvent modifier les fichiers l'un de l'autre sans intervention de l'administrateur. |
| EX-15 | Dans `commun`, un utilisateur ne peut supprimer que les fichiers dont il est propriétaire. |

### 5.4 Accès transverse de la comptabilité

| # | Exigence |
|---|---|
| EX-16 | Les membres de `g_comptabilite` disposent d'un accès **lecture seule** sur les répertoires `direction`, `exploitation` et `commercial`. |
| EX-17 | Cet accès s'applique automatiquement aux fichiers et dossiers créés ultérieurement, sans intervention. |
| EX-18 | Un membre de `g_comptabilite` ne peut ni créer, ni modifier, ni supprimer un fichier dans ces répertoires. |
| EX-19 | L'accès transverse ne modifie pas le groupe propriétaire des répertoires concernés. |

### 5.5 Exploitation

| # | Exigence |
|---|---|
| EX-20 | Une matrice d'habilitations documente, pour chaque groupe et chaque répertoire, le niveau d'accès accordé. |
| EX-21 | Une procédure de départ est rédigée **et exécutée** sur un compte de test : accès révoqué, données conservées et accessibles au service. |
| EX-22 | Le compte désactivé ne peut plus se connecter par SSH, ni changer d'identité depuis un autre compte. |

---

## 6. Critères de validation

Les tests d'accès s'exécutent depuis le compte `essotom`, en empruntant l'identité d'un utilisateur. Consigne les sorties **en texte** dans `docs/validation.md`.

### 6.1 Comptes et groupes

```bash
getent passwd | tail -15
getent group | grep -E 'g_|sudo'
sudo chage -l <un_salarie>          # expiration du mot de passe
sudo chage -l ext.comptable         # expiration du compte
groups <un_salarie>
```

### 6.2 Arborescence

```bash
ls -ld /srv/meridian/*
stat -c '%A %U %G %n' /srv/meridian/*
```

Vérifie la présence du bit setgid dans la sortie de `ls -ld`, et du sticky bit sur `commun`.

### 6.3 Cloisonnement - *ces tests doivent ÉCHOUER*

```bash
sudo -u <commercial> ls /srv/meridian/direction/
sudo -u <commercial> touch /srv/meridian/direction/intrus.txt
sudo -u <exploitation> cat /srv/meridian/comptabilite/<un_fichier>
```

Consigne le message d'erreur exact de chaque tentative. Un refus silencieux ne prouve rien.

### 6.4 Collaboration intra-service

```bash
sudo -u <commercial_1> touch /srv/meridian/commercial/devis-2026.txt
ls -l /srv/meridian/commercial/devis-2026.txt      # groupe = g_commercial
sudo -u <commercial_2> sh -c 'echo "ligne ajoutée" >> /srv/meridian/commercial/devis-2026.txt'
```

La dernière commande doit réussir (EX-14). Si elle échoue, le problème n'est pas dans les permissions du répertoire.

### 6.5 Accès de la comptabilité

```bash
getfacl /srv/meridian/commercial
sudo -u <comptable> cat /srv/meridian/commercial/devis-2026.txt        # réussit
sudo -u <comptable> touch /srv/meridian/commercial/test.txt            # échoue
sudo -u <commercial_1> touch /srv/meridian/commercial/nouveau.txt
getfacl /srv/meridian/commercial/nouveau.txt                           # ACL héritée
sudo -u <comptable> cat /srv/meridian/commercial/nouveau.txt           # réussit
```

Le test d'héritage (EX-17) est le cœur du projet. Crée le fichier **après** avoir posé les ACL.

### 6.6 Sticky bit

```bash
sudo -u <utilisateur_A> touch /srv/meridian/commun/note-A.txt
sudo -u <utilisateur_B> rm /srv/meridian/commun/note-A.txt    # doit échouer
sudo -u <utilisateur_A> rm /srv/meridian/commun/note-A.txt    # doit réussir
```

### 6.7 Départ d'un collaborateur

```bash
# Après application de ta procédure sur un compte de test :
sudo chage -l <compte_desactive>
ssh <compte_desactive>@192.168.56.10                  # doit échouer
sudo -u <collegue> ls -l /srv/meridian/<service>/     # les fichiers sont toujours là
```

### 6.8 Persistance

```bash
sudo reboot
# Après redémarrage : rejouer 6.2, 6.3 et 6.5
```

---

## 7. Zones de recherche imposées

Réponses rédigées avec tes mots dans `docs/recherches.md`.

1. **La norme d'arborescence** - Quelle norme définit le rôle de `/srv`, `/opt`, `/usr/local` et `/var/lib` ? Que dit-elle exactement de `/srv` ? Pourquoi les données de MERIDIAN n'ont-elles rien à faire dans `/home` ni dans `/opt` ?
2. **setgid sur un répertoire** - Le bit setgid existe sur les fichiers exécutables et sur les répertoires. Les deux comportements n'ont rien à voir. Décris chacun, et explique lequel EX-13 met en jeu.
3. **`umask`** - Quelle est la valeur par défaut sur Debian ? Quelles permissions en découlent pour un fichier neuf ? En quoi cette valeur empêche EX-14 de fonctionner, et où se configure-t-elle durablement ?
4. **Le masque ACL** - `getfacl` affiche une ligne `mask`. À quoi sert-elle ? Que devient-elle quand tu lances `chmod g-w` sur un fichier porteur d'ACL ? Pourquoi est-ce un piège classique ?
5. **ACL par défaut** - Quelle est la différence entre une ACL d'accès et une ACL par défaut ? S'appliquent-elles aux fichiers existants au moment où on les pose ? Quelles conséquences pour l'ordre des opérations ?
6. **Désactiver un compte** - `usermod -L`, `chage -E`, `passwd -l`, et changer l'interpréteur pour `/usr/sbin/nologin` : quatre méthodes, quatre effets différents. Laquelle bloque quoi ? Laquelle empêche encore une connexion par **clé SSH** ? La réponse détermine ta procédure EX-22.

---

## 8. Bonus

- **B-01** - Quotas disque sur `/srv` : limiter `g_exploitation` à 500 Mo. Documente pourquoi cela impose une option de montage supplémentaire.
- **B-02** - Politique de robustesse des mots de passe via PAM : longueur minimale, classes de caractères, refus des mots de passe trop proches du précédent.
- **B-03** - Personnaliser `/etc/skel` pour que tout nouveau salarié hérite d'un `.bashrc` avec un `umask` adapté et un raccourci vers son répertoire de service.
- **B-04** - Un script d'audit qui liste les comptes dont le mot de passe expire dans moins de 15 jours.

---

## 9. Livrables

```
02-cloisonnement-donnees/
├── README.md
├── JOURNAL.md
├── docs/
│   ├── mise-en-oeuvre.md          Procédure reproductible
│   ├── matrice-habilitations.md   Organigramme, comptes, groupes, droits
│   ├── procedure-depart.md        Procédure de départ, testée
│   ├── recherches.md
│   └── validation.md              Sorties de commandes, en texte
└── conf/
    ├── login.defs
    ├── skel-bashrc
    └── <ce que tu as modifié>
```

### La matrice d'habilitations

C'est le livrable qui distingue ce projet. Format attendu :

| Répertoire | `g_direction` | `g_exploitation` | `g_commercial` | `g_comptabilite` | Autres |
|---|---|---|---|---|---|
| `/srv/meridian/direction` | rwx | - | - | r-x | - |
| `/srv/meridian/exploitation` | | | | | |
| `/srv/meridian/commercial` | | | | | |
| `/srv/meridian/comptabilite` | | | | | |
| `/srv/meridian/commun` | | | | | |

Complète-la, puis vérifie que chaque case correspond à un test de la section 6. Une case sans test est une affirmation non prouvée.

---

## 10. Fiche portfolio

Rédigée après validation.

```markdown
### Cloisonnement des données par service - Groupe MERIDIAN (projet personnel)

**Problème** - Organiser les données partagées de 4 services aux besoins
contradictoires : cloisonnement strict entre services, accès transverse en
lecture seule pour la comptabilité, sans intervention de l'administrateur à
chaque création de fichier.

**Solution** - Un groupe Unix par service et des répertoires sous /srv/meridian
en 2770 : le bit setgid donne à chaque nouveau fichier le groupe du service.
Sticky bit sur le répertoire commun. ACL d'accès et ACL par défaut pour
donner à la comptabilité une lecture seule, héritée par les nouveaux fichiers.
Comptes créés par un script Bash avec expiration des mots de passe.

**Compétences** - Linux · permissions POSIX · ACL · gestion des identités

**Résultat mesurable** - 13 comptes et 5 groupes créés par script, 5 répertoires
cloisonnés, tests d'accès consignés en texte. Procédure de départ exécutée sur
un compte de test : connexion SSH et su refusés, fichiers conservés et lisibles
par le service.
```

---

## 11. Definition of Done

- [x] Les 22 exigences sont satisfaites
- [x] Tous les tests de la section 6 passent, sorties consignées **en texte** (6.8 sans sortie consignée)
- [x] La matrice d'habilitations est complète et chaque case est adossée à un test
- [x] La procédure de départ a été exécutée sur un compte de test
- [x] Les 6 questions de recherche ont une réponse rédigée
- [x] `JOURNAL.md` contient les incidents réellement rencontrés
- [ ] Un commit par étape, poussé sur GitHub

---

*Cahier des charges - Parcours Linux Admin Système & Réseau - Projet 02/12*
