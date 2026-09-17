# Journal du Projet

--- 

## Objectif 

L'objectif de ce journal est de documenter toutes les avancées sur ce projet, mais aussi de préciser les difficultés que j'ai rencontrées dans le cadre de ce projet.

---

## 25/08/2026 - Date de début du projet

**Actions réalisées :**

- Lecture du projet et définition de la marche à adopter
- Création de la structure template du projet
- Définition du cahier des charges
- Téléchargement de l'image ISO de Debian 13

**Ce que je ne connais pas encore**

- Pour l'instant je ne maîtrise pas encore le partitionnement des disques sous Linux
- Je ne maîtrise pas complètement certains aspects de la configuration SSH

---

## 28/08/2026 

Le projet a beaucoup avancé aujourd'hui, j'ai appris comment durcir et enregistrer les commandes sudo dans un fichier, et comment éditer sudoers en toute sécurité avec visudo.

**Ce que j'ai appris**

Pour accorder des privilèges à un compte utilisateur, comme j'ai eu à le faire au début de ce projet, j'avais pour habitude d'éditer directement le fichier /etc/sudoers, ce qui n'est pas une pratique recommandée : si une erreur est commise dans ce fichier, la commande sudo pourrait mal fonctionner ou être bloquée. C'est pourquoi il est recommandé d'utiliser visudo, qui est un outil spécialement conçu pour modifier ce fichier : **il vérifie la syntaxe du fichier sudoers avant de valider les modifications**.

De plus, j'ai appris que bien que sudo dispose d'un mécanisme interne de journalisation, il est recommandé d'utiliser un emplacement externe comme /var/log/sudo.log pour des raisons de bonnes pratiques sous Linux.

Alors comment faire cette config ? --> voir [installation.md](docs/installation.md)
