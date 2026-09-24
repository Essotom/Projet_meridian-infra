# Journal du Projet

---

## Objectif

L'objectif de ce journal est de documenter toutes les avancées sur ce projet, mais aussi de préciser les difficultés que j'ai rencontrées dans le cadre de ce projet.

---

## 15/09/2026 : Date de début du projet

**Actions réalisées :**

- Lecture du projet et définition de la marche à adopter
- Création de la structure template du projet
- Définition du cahier des charges
- Téléchargement de l'image ISO de Debian 13

**Ce que je ne connais pas encore**

- Pour l'instant je ne maîtrise pas encore le partitionnement des disques sous Linux
- Je ne maîtrise pas complètement certains aspects de la configuration SSH

---

## 18/09/2026

Le projet a beaucoup avancé aujourd'hui, j'ai appris comment durcir et enregistrer les commandes sudo dans un fichier, et comment éditer sudoers en toute sécurité avec visudo.

**Ce que j'ai appris**

Pour accorder des privilèges à un compte utilisateur, comme j'ai eu à le faire au début de ce projet, j'avais pour habitude d'éditer directement le fichier /etc/sudoers, ce qui n'est pas une pratique recommandée : si une erreur est commise dans ce fichier, la commande sudo pourrait mal fonctionner ou être bloquée. C'est pourquoi il est recommandé d'utiliser visudo, qui est un outil spécialement conçu pour modifier ce fichier : **il vérifie la syntaxe du fichier sudoers avant de valider les modifications**.

De plus, j'ai appris que bien que sudo dispose d'un mécanisme interne de journalisation, il est recommandé d'utiliser un emplacement externe comme /var/log/sudo.log pour des raisons de bonnes pratiques sous Linux.

La configuration est détaillée dans [installation.md](docs/installation.md), partie 6, étape 3.

---

## 24/09/2026 : Relecture et correction des écarts

Le projet était marqué comme terminé, mais une relecture a relevé des écarts entre le cahier des charges, le serveur et la documentation. Une partie concerne la configuration du serveur, l'autre la façon dont j'ai mené la recette.

**Écarts relevés**

- `/tmp` était monté sans `noexec` alors que EX-09 l'exige. La capture `findmnt` de validation.md le montrait, et je l'avais quand même notée conforme.
- Le pare-feu utilisait une table `ip`, qui ne filtre que l'IPv4. Le trafic IPv6 entrant n'était pas filtré du tout.
- Dans installation.md, les règles étaient créées à chaud avec `nft add`. Elles ne correspondaient pas exactement au fichier conf/nftables.conf, et ce fichier ne commençait pas par `flush ruleset`.
- `X11Forwarding` était à `yes` sur un serveur qui n'a pas d'interface graphique.
- Le test T-02 avait été lancé avec le compte `esstom` au lieu de `essotom`.
- Le test T-03 avait été lancé depuis mon poste vers 10.0.2.15, une adresse que mon poste ne peut pas joindre.

**Cause de la perte de noexec**

Toujours incertaine

**Actions réalisées :**

- Ajout de `noexec` sur la ligne `/tmp` de /etc/fstab
- Réécriture de /etc/nftables.conf : `flush ruleset` en tête, table `inet`, et autorisation de la découverte de voisins IPv6
- Passage de `X11Forwarding` à `no`
- Mise à jour de conf/, de installation.md et de validation.md
- Contre-recette faite : nouvelles captures pour `/tmp`, le pare-feu, T-02, T-03 et `sshd -T`

**Ce que j'ai appris**

Une table `ip` dans nftables ne voit que l'IPv4. Avec une table `inet`, les mêmes règles s'appliquent à l'IPv4 et à l'IPv6. Par contre, la politique `drop` bloque alors aussi les messages ICMPv6 dont IPv6 a besoin pour fonctionner. Sans `nd-neighbor-solicit` et `nd-neighbor-advert`, le serveur ne peut plus trouver l'adresse MAC de ses voisins (c'est le rôle que joue ARP en IPv4). `nd-router-advert` lui permet de recevoir les annonces des routeurs, qui servent à la configuration automatique des adresses IPv6.

Le `flush ruleset` en tête du fichier vide toutes les règles avant de charger les nouvelles. Sans lui, chaque `nft -f` ajoute les règles à celles déjà en place et on se retrouve avec des doublons. Les règles ajoutées à chaud avec `nft add`, elles, disparaissent au redémarrage si elles ne sont pas écrites dans /etc/nftables.conf. C'est le fichier qui compte, pas ce qui tourne en mémoire à un instant donné.

Pour T-03, le « Connection timed out » obtenu depuis mon poste ne prouvait rien. 10.0.2.15 est l'adresse que VirtualBox donne à la VM sur son réseau NAT, et mon poste ne peut pas la joindre, que sshd écoute dessus ou non. Depuis le serveur, une connexion vers 10.0.2.15 passe par l'interface de bouclage, que le pare-feu laisse passer. Si la réponse est « Connection refused », c'est que rien n'écoute sur le port 22 de cette adresse, et c'est exactement ce que le test doit montrer.

Sur la recette en général, je retiens deux choses : relire chaque capture avant d'écrire « conforme », et vérifier qu'un test qui échoue échoue pour la bonne raison. T-02 échouait parce que le compte `esstom` n'existe pas, ce qui ne disait rien sur le compte `essotom`.
