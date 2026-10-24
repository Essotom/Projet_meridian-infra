# conf

Aucun fichier de `/etc` n'a été modifié pour ce projet. Ce dossier ne contient donc pas de copie de configuration.

Le cahier des charges prévoyait `login.defs` et `skel-bashrc` pour régler l'umask. Le problème a été traité autrement : une ACL par défaut sur les répertoires partagés (`setfacl -d -m g::rwx`, voir [mise-en-oeuvre.md](../docs/mise-en-oeuvre.md), sections 3.4 et 3.5).

Raisons de ce choix :

- L'ACL par défaut est portée par le répertoire. Elle s'applique à tout fichier créé dedans, quel que soit le compte, le shell ou la façon de lancer la commande, y compris `sudo -u`, qui ne lit pas `.bashrc`.
- La directive `UMASK` de `/etc/login.defs` est globale : elle changerait les droits des fichiers créés par tous les comptes, y compris en dehors de `/srv/meridian`.

Conséquence : les droits d'un nouveau fichier dépendent du répertoire où il est créé, pas de l'utilisateur. Un répertoire ajouté plus tard sous `/srv/meridian` devra recevoir sa propre ACL par défaut.

La politique d'expiration des mots de passe est appliquée compte par compte avec `chage` par le script de création, et non par `/etc/login.defs`.
