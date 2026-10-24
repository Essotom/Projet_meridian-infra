# Journal de bord - Projet 02

## 30/09/2026 : début du travail

Avant de commencer, j'ai lu le cahier des charges pour bien comprendre ce qui était demandé. Mon premier objectif était de pouvoir expliquer le besoin avec mes propres mots.

J'ai ensuite listé les 22 exigences et je les ai regroupées en étapes (comptes, arborescence, ACL, départ) pour valider au fur et à mesure.

## 01/10/2026

Révision du Bash pour écrire un script qui crée les comptes et les groupes à partir d'un fichier texte.

## 02/10/2026

Script terminé et testé sur quelques comptes de test avant de le lancer sur les 13 comptes.

## 17/10/2026 : création des comptes et de l'arborescence

**Groupes parasites.** Après l'exécution du script, `getent group` montre deux groupes en trop : `g_groupe` (GID 1002) et `g_` (GID 1003). `g_` vient des lignes vides à la fin de `user.txt` : le script lit une ligne vide, le service est vide, il crée donc `g_`. `g_groupe` vient sans doute d'un essai précédent du script. Les deux étaient vides, je les ai supprimés le 24/10/2026 avec `groupdel`. À retenir : un script qui lit un fichier doit ignorer les lignes vides.

**Répertoire exploitation oublié.** J'ai créé `direction`, `commercial`, `comptabilite` et `commun`, mais j'ai oublié `exploitation`. Je l'ai créé à 15h01 avec le même groupe et les mêmes droits (`2770`). Les captures prises avant ne le montrent pas.

**Faute de frappe.** `sudo .\script-creation-user.sh` répond "commande introuvable" : j'avais tapé un antislash Windows au lieu de `./`.

## 20/10/2026 : tests de collaboration et du sticky bit

`devis-2026.txt`, créé par `laura.mercier` dans `commercial`, est en `rw-rw----` alors que l'umask est `022`, qui donnerait `rw-r--r--`. La raison : dans un répertoire qui a une ACL par défaut, ce sont les droits de l'ACL qui s'appliquent, pas l'umask.

Dans `commun`, qui n'a pas d'ACL par défaut, `rm` demande une confirmation parce que `note-A.txt` est "protégé en écriture". Là, c'est bien l'umask `022` qui s'applique. Les collègues peuvent lire les fichiers de `commun` mais pas les modifier. Ça n'empêche pas le test du sticky bit, mais c'est une limite à corriger.

## 22/10/2026 : préparation du test de départ

Création du compte `test.depart` dans le service commercial, avec une clé SSH. Connexion SSH réussie depuis le poste Windows.

Le test `su - test.depart` depuis `essotom` a échoué ("Échec de l'authentification") alors que le compte était actif, sans doute à cause d'une erreur de saisie du mot de passe. J'ai utilisé `sudo su - test.depart` comme test de référence.

## 24/10/2026 : exécution de la procédure de départ

**`lastlog` introuvable.** La procédure prévoyait `lastlog -u` à l'étape 0. La commande n'existe plus sur Debian 13. Les connexions passées se retrouvent avec `journalctl -u ssh`.

**Groupe principal impossible à retirer.** Après `gpasswd -d test.depart g_meridian`, `id` affiche encore `g_commercial`. C'est normal : c'est son groupe principal, `gpasswd` ne peut pas le retirer. La procédure attendait "son groupe personnel", ce qui ne correspond pas à notre organisation. J'ai corrigé le contrôle de l'étape 8.

**Archive impossible à créer.** `tar` répondait "open impossible: Aucun fichier ou dossier de ce nom". En listant `/srv/archives/`, j'ai vu que j'avais créé le dossier `départs` avec un accent, alors que `tar` écrivait dans `departs`. J'ai supprimé le mauvais dossier avec `rmdir`, créé le bon, et relancé l'archivage. À retenir : pas d'accent dans les noms de fichiers sur un serveur, et un chemin utilisé plusieurs fois doit être mis dans une variable.

**Journal SSH.** La tentative de connexion refusée apparaît sous le nom `sshd-session` et non `sshd`. Sur Debian 13, le filtre `_COMM=sshd` prévu à l'étape 20 ne trouve donc rien. Je l'ai remplacé par `journalctl -u ssh`.

**Résultat.** Après la procédure, la connexion SSH par clé est refusée, `su` répond "Votre compte a expiré", et `laura.mercier` lit toujours le devis laissé par `test.depart`.

## 24/10/2026 : correction d'EX-14

Les fichiers créés dans `comptabilite` et `commun` suivaient l'umask `022` : un collègue ne pouvait pas les modifier. J'ai ajouté une ACL par défaut qui donne `rwx` au groupe propriétaire (`setfacl -d -m g::rwx`). Test : `david.ostermann` a ajouté une ligne au fichier créé par `nathalie.roux`.

## Persistance

La VM a été redémarrée plusieurs fois au cours du projet et les comportements testés sont restés identiques. Aucune série de commandes n'a été consignée spécialement après un redémarrage. Les permissions, le setgid, le sticky bit et les ACL sont enregistrés dans le système de fichiers ; ils ne dépendent d'aucun service à relancer.
