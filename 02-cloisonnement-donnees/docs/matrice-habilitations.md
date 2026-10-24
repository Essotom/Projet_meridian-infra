# Matrice d'habilitations - Groupe MERIDIAN

Serveur : `srv-meridian-01`. Dernière mise à jour : 24/10/2026.

## 1. Organigramme et comptes

Convention de nommage : `prenom.nom`, en minuscules, sans accents, avec un tiret pour les noms composés. Seule exception, le compte `ext.comptable`, dont le nom est imposé par le cahier des charges.

| Service | Compte | UID | Groupe principal | Groupe secondaire |
|---|---|---|---|---|
| Direction | `philippe.marchand` | 1001 | `g_direction` | `g_meridian` |
| Direction | `sylvie.ferrand` | 1002 | `g_direction` | `g_meridian` |
| Exploitation | `karim.benali` | 1003 | `g_exploitation` | `g_meridian` |
| Exploitation | `marc.dubois` | 1004 | `g_exploitation` | `g_meridian` |
| Exploitation | `marie.dubois` | 1005 | `g_exploitation` | `g_meridian` |
| Exploitation | `anne-sophie.lefevre-brun` | 1006 | `g_exploitation` | `g_meridian` |
| Exploitation | `youssef.tahiri` | 1007 | `g_exploitation` | `g_meridian` |
| Commercial | `laura.mercier` | 1008 | `g_commercial` | `g_meridian` |
| Commercial | `thomas.nguyen` | 1009 | `g_commercial` | `g_meridian` |
| Commercial | `ines.vasquez` | 1010 | `g_commercial` | `g_meridian` |
| Comptabilité | `nathalie.roux` | 1011 | `g_comptabilite` | `g_meridian` |
| Comptabilité | `david.ostermann` | 1012 | `g_comptabilite` | `g_meridian` |
| Prestataire | `ext.comptable` | 1013 | `g_comptabilite` | `g_meridian` |

Tous les comptes : shell `/bin/bash`, mot de passe valable 90 jours, avertissement 7 jours avant. `ext.comptable` expire le 31/12/2026.

`ext.comptable` est dans `g_comptabilite` : il a exactement les mêmes droits que la comptabilité interne.

Compte d'administration : `essotom`, seul membre du groupe `sudo`. Aucun salarié n'a de droit d'administration.

Comptes partis :

| Compte | Service | Date de départ | Remarque |
|---|---|---|---|
| `test.depart` (UID 1014) | Commercial | 24/10/2026 | Compte de test de la procédure de départ, bloqué et en rétention |

## 2. Groupes

| Groupe | GID | Membres |
|---|---|---|
| `g_meridian` | 1001 | Les 13 comptes (groupe secondaire) |
| `g_direction` | 1004 | 2 comptes (groupe principal) |
| `g_exploitation` | 1005 | 5 comptes (groupe principal) |
| `g_commercial` | 1006 | 3 comptes (groupe principal), plus `test.depart` bloqué |
| `g_comptabilite` | 1007 | 3 comptes (groupe principal) |

## 3. Droits sur les répertoires

| Répertoire | Mode | `g_direction` | `g_exploitation` | `g_commercial` | `g_comptabilite` | Autres |
|---|---|:---:|:---:|:---:|:---:|:---:|
| `/srv/meridian/direction` | `2770` + ACL | `rwx` | `---` | `---` | `r-x` | `---` |
| `/srv/meridian/exploitation` | `2770` + ACL | `---` | `rwx` | `---` | `r-x` | `---` |
| `/srv/meridian/commercial` | `2770` + ACL | `---` | `---` | `rwx` | `r-x` | `---` |
| `/srv/meridian/comptabilite` | `2770` + ACL | `---` | `---` | `---` | `rwx` | `---` |
| `/srv/meridian/commun` | `3770` + ACL | `rwx` | `rwx` | `rwx` | `rwx` | `---` |

Pour lire ce tableau :

- Tous les répertoires appartiennent à `root`. Le groupe propriétaire est le groupe du service, ou `g_meridian` pour `commun`.
- Le `2` de `2770` est le bit setgid : un nouveau fichier prend le groupe du répertoire.
- Le `3` de `3770` ajoute le sticky bit : dans `commun`, on ne peut supprimer que ses propres fichiers.
- Le `r-x` de la comptabilité vient d'une ACL d'accès et d'une ACL par défaut. Sur les fichiers, son droit réel est `r--` : lecture seule.
- Sur `comptabilite` et `commun`, une ACL par défaut donne `rw-` au groupe sur chaque nouveau fichier : les collègues peuvent modifier les fichiers des autres.
- "Autres" désigne tout compte qui n'est pas dans le groupe concerné.

## 4. Preuves

Chaque case renvoie à un test de [validation.md](validation.md).

| Case | Test | Résultat |
|---|---|---|
| Modes et groupes des 5 répertoires | 6.2 : `ls -ld` et `stat` | Conforme |
| Commercial `rwx` sur `commercial` | 6.4 : `laura.mercier` crée, `thomas.nguyen` modifie | Réussi |
| Commercial `---` sur `direction` | 6.3 : `ls` et `touch` par `laura.mercier` | Refusé |
| Exploitation `---` sur `comptabilite` | 6.3 : `cat` par `youssef.tahiri` | Refusé |
| Comptabilité `rwx` sur `comptabilite` | 6.3 : `nathalie.roux` crée `Bilan-2026` | Réussi |
| Comptabilité : modifier le fichier d'un collègue | 6.4, complément : `david.ostermann` écrit dans le fichier de `nathalie.roux` | Réussi |
| Comptabilité `r-x` sur `commercial` | 6.5 : lecture de deux fichiers, `touch` refusé, ACL héritée | Conforme |
| Comptabilité `r-x` sur `direction` et `exploitation` | Même ACL que `commercial` (`getfacl`, captures image-11 et image-12) | Conforme |
| Tous `rwx` sur `commun`, sticky bit | 6.6 : création par un compte, suppression refusée à un autre | Conforme |
| Direction `rwx` sur `direction`, exploitation `rwx` sur `exploitation` | Même mode et même ACL que `commercial` (6.2) | Configuration identique, non rejouée compte par compte |
