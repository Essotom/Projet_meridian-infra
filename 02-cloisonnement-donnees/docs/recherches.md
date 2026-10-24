# Recherches

Réponses aux six questions de la section 7 du cahier des charges.

---

## 1. La norme d'arborescence

La norme est le **FHS** (Filesystem Hierarchy Standard), version 3.0, publiée par la Linux Foundation. Debian la suit.

| Répertoire | Rôle selon le FHS |
|---|---|
| `/srv` | Données servies par la machine : site web, dépôt, partage de fichiers. |
| `/opt` | Logiciels supplémentaires installés en bloc, en dehors du gestionnaire de paquets. |
| `/usr/local` | Programmes installés par l'administrateur lui-même (compilés à la main, scripts maison). |
| `/var/lib` | Données d'état gérées par les programmes eux-mêmes (base des paquets, bases de données). |

Pour `/srv`, le FHS dit qu'il contient les données propres au site, servies par le système. Il ne fixe pas l'organisation à l'intérieur : c'est à l'administrateur de la choisir. Ici, un sous-dossier par entreprise puis un par service : `/srv/meridian/<service>`.

**Pourquoi pas `/home`** : `/home` contient les répertoires personnels. Sur Debian 13, chacun est en `700` et n'est lisible que par son propriétaire. Des données d'équipe rangées dans le dossier d'un salarié deviendraient inaccessibles à son départ, ce qu'EX-21 interdit.

**Pourquoi pas `/opt`** : `/opt` est fait pour des logiciels, pas pour des documents de travail.

**Pourquoi pas `/var/lib`** : ce répertoire appartient aux programmes. Les utilisateurs n'y déposent pas de fichiers eux-mêmes.

---

## 2. Le bit setgid

**Sur un fichier exécutable** : le programme s'exécute avec les droits du groupe propriétaire du fichier, et non avec ceux du groupe de la personne qui le lance. Cela permet à un outil d'accéder à une ressource réservée à un groupe sans donner ce groupe à l'utilisateur.

**Sur un répertoire** : tout fichier ou sous-dossier créé dedans prend le groupe du répertoire, et non le groupe principal de son créateur. Les sous-dossiers reçoivent aussi le bit, donc la règle se propage.

EX-13 utilise le deuxième comportement. On le reconnaît au `s` à la place du `x` du groupe : `drwxrws---`. En octal, setgid vaut `2000`, d'où `chmod 2770`.

Preuve dans notre test de départ : `test.depart`, dont le groupe principal est `g_commercial`, a créé `note-test-depart.txt` dans `commun`. Le fichier a pris le groupe `g_meridian`, celui du répertoire.

---

## 3. umask

La valeur par défaut sur Debian 13 est `022`. Elle retire des droits aux fichiers et dossiers créés :

| Objet | Droits de départ | Après umask 022 |
|---|---|---|
| Fichier | `666` (`rw-rw-rw-`) | `644` (`rw-r--r--`) |
| Dossier | `777` (`rwxrwxrwx`) | `755` (`rwxr-xr-x`) |

Avec `644`, le groupe peut lire mais pas écrire. Un collègue du même service ne peut donc pas modifier le fichier d'un autre : EX-14 échoue. Pour du travail en équipe, il faut `007` (fichiers en `660`, dossiers en `770`).

La valeur se règle durablement dans `/etc/login.defs` (directive `UMASK`) pour tous les comptes, ou dans les fichiers de démarrage du shell (`/etc/profile`, `~/.bashrc`). Attention : `sudo -u` n'ouvre pas de session et ne lit pas `.bashrc`, donc les tests faits avec `sudo -u` ne voient pas un umask réglé dans `.bashrc`.

Ce que nous avons observé : dans un répertoire qui porte une ACL par défaut, l'umask n'est pas utilisé. Les droits viennent de l'ACL par défaut. C'est pour ça que `devis-2026.txt` est en `rw-rw----` dans `commercial` alors que l'umask est `022`. Dans `commun`, qui n'avait pas encore d'ACL par défaut, `note-A.txt` était en lecture seule pour les autres. Une ACL par défaut `g::rwx` a ensuite été ajoutée sur `commun` et `comptabilite` pour corriger ça.

---

## 4. Le masque ACL

La ligne `mask` est le plafond des droits accordés à tout ce qui n'est ni le propriétaire ni "les autres" : le groupe propriétaire, les groupes nommés et les utilisateurs nommés. Le droit réel est le droit demandé limité par le masque. `getfacl` l'affiche avec `#effective`.

Exemple tiré de `nouveau.txt` :

```text
group:g_comptabilite:r-x        #effective:r--
mask::rw-
```

La comptabilité a `r-x` sur le papier, mais le masque n'autorise pas `x` : son droit réel est `r--`.

Quand on lance `chmod g-w` sur un fichier qui porte des ACL, ce n'est pas la ligne `group::` qui change, c'est le masque. Tous les groupes et utilisateurs nommés perdent l'écriture en même temps.

Le piège : sur un fichier avec ACL, `ls -l` affiche le masque à la place des droits du groupe. On croit modifier un seul groupe et on coupe des droits à plusieurs. Il faut toujours vérifier avec `getfacl` et regarder les `#effective`.

---

## 5. ACL d'accès et ACL par défaut

- **ACL d'accès** : elle contrôle l'accès au fichier ou au dossier sur lequel elle est posée, tout de suite.
- **ACL par défaut** : elle se pose uniquement sur un dossier. Elle ne sert pas à contrôler l'accès au dossier lui-même. Elle est copiée sur chaque fichier ou sous-dossier créé ensuite à l'intérieur.

Aucune des deux ne s'applique aux fichiers qui existent déjà au moment où on la pose. L'ACL par défaut n'agit que sur les créations futures.

Conséquences pour l'ordre des opérations :

1. Il faut les deux : l'ACL d'accès pour que la comptabilité puisse entrer dans le dossier, l'ACL par défaut pour qu'elle puisse lire les nouveaux fichiers (EX-17).
2. Il vaut mieux poser les ACL sur des dossiers vides, avant que les salariés y déposent des fichiers. C'était notre cas.
3. Si des fichiers existent déjà, il faut aussi les traiter avec `setfacl -R -m ...`.

---

## 6. Désactiver un compte

| Méthode | Ce qu'elle fait | Mot de passe bloqué | Clé SSH bloquée | `su` bloqué |
|---|---|---|---|---|
| `passwd -l` ou `usermod -L` | Ajoute un `!` devant le mot de passe dans `/etc/shadow` | Oui | Non | Oui depuis un compte normal, non pour root |
| `chage -E` ou `usermod -e` | Fixe une date d'expiration du compte | Oui | Oui | Oui, même pour root |
| Shell `/usr/sbin/nologin` | Refuse l'ouverture d'un shell interactif | L'authentification passe, mais la session se ferme aussitôt | Pareil | Pareil |

`passwd -l` et `usermod -L` font la même chose.

Le verrouillage du mot de passe ne bloque pas une clé SSH : sur Debian, `sshd` utilise PAM (`UsePAM yes`) et ne regarde pas le `!` du mot de passe quand on s'authentifie par clé. L'expiration du compte, elle, est vérifiée par PAM pour toutes les méthodes. C'est la seule des quatre qui bloque une connexion par clé.

Notre procédure combine donc les quatre : mot de passe verrouillé, compte expiré, shell `nologin` et clés SSH mises de côté. Le test l'a confirmé : après la procédure, `sudo su - test.depart` répond "Votre compte a expiré".
