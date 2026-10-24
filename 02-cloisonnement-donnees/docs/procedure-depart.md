# Procédure de départ d'un collaborateur

| | |
|---|---|
| Entreprise | Groupe MERIDIAN |
| Serveur concerné | `srv-meridian-01` (Debian 13, `192.168.56.10`) |
| Version | 1.1 |
| Auteur | Essotom |
| Dernière révision | 24/10/2026 |

Convention : `[HOTE]` = poste Windows, `[SRV]` = serveur. `$` = utilisateur standard, `#` = root (après `sudo -i`).

Cette procédure a été exécutée sur le compte de test `test.depart` le 24/10/2026. Les sorties sont dans [validation.md](validation.md), section "Départ d'un collaborateur".

## 1. Objet

Couper tous les accès d'un salarié qui quitte MERIDIAN, garder les fichiers qu'il a déposés dans les répertoires partagés, archiver son répertoire personnel, puis supprimer le compte après un délai de rétention.

Hors périmètre : changement de service, comptes techniques, accès hors serveur (messagerie, logiciels métier).

## 2. Règles

1. On bloque d'abord, on supprime ensuite. Un compte bloqué se réactive en une minute, un compte supprimé demande une restauration.
2. Rien n'est supprimé avant que l'archive soit faite et vérifiée.
3. Chaque étape a un contrôle. Une étape sans contrôle n'est pas terminée.
4. L'archive est gardée 30 jours avant la suppression définitive du compte.

## 3. Qui fait quoi

| Rôle | Qui | Action |
|------|-----|--------|
| Demandeur | Gérant ou responsable de service | Donne la date de départ et le nom du successeur |
| Exécutant | Administrateur (`essotom`) | Applique la procédure et remplit le registre |
| Successeur | Collègue du même service | Récupère la propriété des fichiers partagés |

## 4. Fiche de départ

Exemple rempli avec le compte de test :

| Élément | Valeur |
|---------|--------|
| Compte | `test.depart` |
| UID / GID (à garder pour un retour arrière) | `1014 / 1006` |
| Groupe principal | `g_commercial` |
| Groupes secondaires | `g_meridian` |
| Répertoire du service | `/srv/meridian/commercial` |
| Successeur | `laura.mercier` |
| Date de départ | 24/10/2026 |

Les comptes et groupes de MERIDIAN sont listés dans [matrice-habilitations.md](matrice-habilitations.md).

## 5. Étape 0 : état des lieux

Avant de toucher au compte :

```text
[SRV] $ sudo -i
[SRV] # U=test.depart
[SRV] # id $U                          # UID, GID, groupes
[SRV] # chage -l $U                    # expiration actuelle
[SRV] # loginctl list-sessions         # sessions ouvertes
[SRV] # ps -u $U                       # processus en cours
[SRV] # crontab -l -u $U               # tâches planifiées
[SRV] # du -sh /home/$U                # taille à archiver
[SRV] # journalctl -u ssh | grep "Accepted.*$U"    # dernières connexions SSH
```

`lastlog` n'existe plus sur Debian 13. Les connexions passées se lisent dans le journal du service `ssh`.

Reporter l'UID, le GID et les groupes dans la fiche de départ.

## 6. Étapes

### 6.1 Le jour du départ : couper l'accès

| # | Action | Commande | Contrôle |
|---|--------|----------|----------|
| 1 | Verrouiller le mot de passe | `usermod -L $U` | `passwd -S $U` affiche `L` |
| 2 | Faire expirer le compte | `usermod -e 1 $U` | `chage -l $U` : "Le compte expire : janv. 02, 1970" |
| 3 | Retirer le shell | `usermod -s /usr/sbin/nologin $U` | `getent passwd $U` se termine par `/usr/sbin/nologin` |
| 4 | Mettre de côté les clés SSH | `mv /home/$U/.ssh/authorized_keys /home/$U/.ssh/authorized_keys.depart` | Le fichier `authorized_keys` n'existe plus |
| 5 | Fermer les sessions | `loginctl terminate-user $U` | `ps -u $U` ne renvoie rien. Si le compte n'a pas de session, la commande répond "not logged in", c'est normal |
| 6 | Sauvegarder puis supprimer ses tâches planifiées | `crontab -l -u $U > /root/cron-$U.bak` puis `crontab -r -u $U` | `crontab -l -u $U` : "no crontab" |
| 7 | Désactiver le lingering | `loginctl disable-linger $U` | Pas de message d'erreur |

Pourquoi plusieurs blocages : verrouiller le mot de passe (étape 1) n'empêche pas une connexion par clé SSH. C'est l'expiration du compte (étape 2) et le retrait des clés (étape 4) qui bloquent la clé. L'expiration bloque aussi `su`, même lancé par root.

Test depuis le poste :

```text
[HOTE] $ ssh test.depart@192.168.56.10
```

Résultat attendu : `Permission denied (publickey).`

### 6.2 Groupes

| # | Action | Commande | Contrôle |
|---|--------|----------|----------|
| 8 | Retirer le compte de ses groupes secondaires | `gpasswd -d $U g_meridian` | `id $U` n'affiche plus que le groupe principal |
| 9 | Vérifier qu'il n'a aucun droit sudo | `grep -r "$U" /etc/sudoers /etc/sudoers.d/` | Aucune ligne. Aucun salarié n'est dans `sudo` (EX-05) |
| 10 | Mettre à jour la matrice | Édition de `docs/matrice-habilitations.md` | Le compte est marqué "parti le JJ/MM/AAAA" |

Le groupe principal (le groupe de service, par exemple `g_commercial`) ne peut pas être retiré avec `gpasswd`. Il disparaît avec le compte à l'étape 17. En attendant, il ne donne aucun accès puisque le compte ne peut plus se connecter.

### 6.3 Données

| # | Action | Commande | Contrôle |
|---|--------|----------|----------|
| 11 | Créer le dossier d'archives (une seule fois) | `install -d -m 700 -o root -g root /srv/archives/departs` | `ls -ld` affiche `drwx------ root root` |
| 12 | Archiver le répertoire personnel | `A=/srv/archives/departs/$U-$(date +%Y%m%d).tar.gz` puis `tar --numeric-owner --acls --xattrs -czpf $A -C /home $U` | Pas d'erreur |
| 13 | Protéger l'archive et noter son empreinte | `chmod 600 $A` puis `sha256sum $A` | `tar -tzf $A` liste le contenu. L'empreinte est notée dans le registre |
| 14 | Lister ses fichiers dans les partages | `find /srv/meridian -user $U -ls` | Liste enregistrée |
| 15 | Donner ces fichiers au successeur | `find /srv/meridian -user $U -exec chown -h laura.mercier {} +` | Le `find` de l'étape 14 ne renvoie plus rien |
| 16 | Vérifier que le groupe n'a pas changé | `find /srv/meridian/commercial -user laura.mercier ! -group g_commercial -ls` | Aucune ligne |

Seul le propriétaire change. Le groupe reste celui du répertoire, donc le service garde l'accès aux fichiers.

Attention aux accents : le dossier s'appelle `departs`, sans accent. Un `install -d` avec `départs` crée un autre dossier et l'archivage échoue (incident du 24/10/2026, voir `JOURNAL.md`).

### 6.4 Suppression définitive (après 30 jours)

À faire seulement si le service n'a rien réclamé et si l'empreinte de l'archive est identique à celle du registre.

| # | Action | Commande | Contrôle |
|---|--------|----------|----------|
| 17 | Supprimer le compte et son répertoire | `userdel -r $U` | `getent passwd $U` ne renvoie rien |
| 18 | Chercher les fichiers sans propriétaire | `for m in $(findmnt -rn -t ext4 -o TARGET); do find "$m" -xdev \( -nouser -o -nogroup \) -ls; done` | Aucune ligne |
| 19 | Vérifier les restes | `ls /var/spool/cron/crontabs/ /var/mail/` | Rien au nom du compte |
| 20 | Vérifier qu'il n'y a pas eu de connexion après le départ | `journalctl -u ssh --since AAAA-MM-JJ \| grep $U` | Aucune ligne "Accepted" |

Sur Debian 13, les connexions SSH sont journalisées par le processus `sshd-session`. Filtrer sur l'unité (`-u ssh`) les trouve toutes, filtrer sur `_COMM=sshd` les manque.

## 7. Vérification finale

- [ ] Accès coupé le jour du départ (étapes 1 à 7)
- [ ] Connexion SSH refusée depuis le poste
- [ ] Plus de groupe secondaire, aucun droit sudo
- [ ] Archive créée, protégée, empreinte notée
- [ ] Fichiers partagés transférés au successeur, groupe inchangé
- [ ] Matrice et registre à jour
- [ ] Après 30 jours : compte supprimé, aucun fichier orphelin

## 8. Retour arrière

Tant que le compte existe (avant l'étape 17) :

```text
[SRV] # usermod -U $U
[SRV] # usermod -e '' $U
[SRV] # usermod -s /bin/bash $U
[SRV] # mv /home/$U/.ssh/authorized_keys.depart /home/$U/.ssh/authorized_keys
[SRV] # gpasswd -a $U g_meridian
[SRV] # crontab -u $U /root/cron-$U.bak        # seulement si une sauvegarde existe
```

Après l'étape 17 : recréer le compte avec son UID et son groupe d'origine (`useradd -m -u <UID> -g <groupe> -G g_meridian -s /bin/bash <compte>`), puis restaurer l'archive avec `tar -xzpf <archive> -C /home`.

## 9. Registre des départs

| Date | Compte | Exécutant | Motif | Étapes 1 à 16 | Étape 17 | Empreinte de l'archive | Remarques |
|------|--------|-----------|-------|---------------|----------|------------------------|-----------|
| 24/10/2026 | `test.depart` | essotom | Test EX-21 / EX-22 | Faites | Non faite (rétention jusqu'au 23/11/2026) | `5eac03810311ae689b3de11c730dd099bcfac2a5e178baa70920a71c83ea318f` | Compte de test, successeur `laura.mercier` |

## 10. Cas particuliers

- Départ en urgence (licenciement, incident de sécurité) : faire tout de suite les étapes 2, 4 et 5, qui prennent moins d'une minute, puis le reste dans la journée.
- Fichiers que personne ne peut reprendre : garder le compte bloqué plus longtemps et noter la raison dans le registre.
