# meridian-infra

Infrastructure Linux d'une PME fictive, construite progressivement à travers 12 projets d'administration système et réseau. Parcours en cours - chaque projet est spécifié, réalisé et documenté.

**Groupe MERIDIAN** est une PME de transport et logistique imaginaire : 12 salariés au départ, 80 à l'arrivée. Chaque projet répond à un besoin réel de cette croissance, et s'appuie sur l'infrastructure montée dans les précédents. Les décisions prises au projet 01 conditionnent le projet 12.

> Projet personnel de formation. L'entreprise, ses salariés et ses données sont fictifs ; l'infrastructure, elle, est réellement déployée et testée.

---

## Avancement

| # | Projet | Compétences | Statut |
|---|---|---|---|
| 01 | [Socle serveur](01-socle-serveur/) | Debian, LVM, SSH, nftables, systemd | Terminé |
| 02 | Utilisateurs, groupes et ACL | Permissions POSIX, ACL, quotas, setgid | Planifié |
| 03 | Scripts et tâches planifiées | Bash, timers systemd, journalisation | Planifié |
| 04 | Stockage et partage de fichiers | LVM avancé, Samba, rsync | Planifié |
| 05 | Services réseau internes | DNS, DHCP, NTP | Planifié |
| 06 | Serveur web et reverse proxy | Nginx, vhosts, TLS | Planifié |
| 07 | Segmentation réseau | Routage Linux, VLAN, nftables, NAT | Planifié |
| 08 | Authentification centralisée | LDAP | Planifié |
| 09 | Accès distant sécurisé | WireGuard | Planifié |
| 10 | Supervision et journaux | Prometheus, Grafana, centralisation | Planifié |
| 11 | Sauvegarde et restauration | Stratégie 3-2-1, test de restauration | Planifié |
| 12 | Industrialisation | Ansible, haute disponibilité | Planifié |

---

## Structure d'un projet

Chaque projet suit la même organisation :

```
NN-nom-du-projet/
├── README.md          Cahier des charges et résultat
├── JOURNAL.md         Incidents rencontrés et décisions prises
├── docs/
│   ├── installation.md    Procédure reproductible
│   ├── validation.md      Procès-verbal de recette
│   ├── recherches.md      Notions étudiées
│   └── <spécifique>.md
└── conf/              Fichiers de configuration versionnés
```

## Principes de travail

Chaque projet est cadré par un **cahier des charges** avant d'être réalisé : contexte, exigences numérotées, critères de validation exécutables.

La validation ne repose pas sur « ça marche » mais sur une **recette** : des commandes dont la sortie est consignée et rattachée à une exigence.

Chaque procédure d'installation est **testée par reconstruction** : la machine est détruite et remontée en suivant uniquement la documentation produite.

Le **journal de bord** consigne les erreurs et la façon dont elles ont été diagnostiquées - c'est souvent le document le plus instructif d'un projet.

---

## À propos

Parcours mené par **Tom Blakime**, élève-ingénieur en réseaux et cybersécurité, dans le cadre d'une montée en compétences vers l'administration système et infrastructure.

[LinkedIn](www.linkedin.com/in/hugues-essotom-blakime)
