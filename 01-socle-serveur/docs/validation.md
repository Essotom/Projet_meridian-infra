# Validation -`srv-meridian-01`

|                             |                                         |
| --------------------------- | --------------------------------------- |
| **Date de recette**         | 2026-09-17                              |
| **Opérateur**               | Essotom                                 |
| **Système testé**           | Debian 13.x, noyau 6.12.105+deb13-amd64 |
| **Version de la procédure** | `installation.md` v1.0                  |
| **Résultat global**         | Conforme     |

---

## 1. Matrice de traçabilité

| Test                         | Exigences couvertes | Résultat |
| ---------------------------- | ------------------- | -------- |
| 6.1 Partitionnement          | EX-05 → EX-09       | OK       |
| 6.2 Réseau                   | EX-10 → EX-13       | OK       |
| 6.3 Accès SSH                | EX-17 → EX-20       | OK       |
| 6.4 Privilèges               | EX-14 → EX-16       | OK       |
| 6.5 Pare-feu et mises à jour | EX-21, EX-22        | OK       |
| 6.6 Résilience               | EX-23               | OK       |
| 6.7 Reconstruction           | O-08                | OK       |

---

## 2. Partitionnement

### `lsblk`

![alt text](img/image-28.png)

### `sudo vgs`

![alt text](img/image-29.png)

**Vérification** - `VFree` ≥ 2,00g → oui (EX-08)

### `sudo lvs`

![alt text](img/image-30.png)

### `df -h`

![alt text](img/image-31.png)

### `findmnt --real -o TARGET,SOURCE,FSTYPE,OPTIONS`

![alt text](img/image-32.png)

**Vérification** - options `nodev,nosuid,noexec` présentes sur `/tmp`

### Test `noexec` sur `/tmp` *(attendu : échec)*

![alt text](img/image-47.png)

**Verdict** : OK

---

## 3. Réseau

### `ip -brief address show`

![alt text](img/image-33.png)

### `ping -c3 deb.debian.org`

![alt text](img/image-34.png)

### `getent hosts srv-meridian-01.meridian.lan`

![alt text](img/image-35.png)

### `hostnamectl`

![alt text](img/image-36.png)

---

## 4. Accès SSH

> Les trois premiers tests doivent **échouer**. Un échec attendu est un test réussi : c'est le message d'erreur qui constitue la preuve, pas son absence.

### T-01 - Connexion root refusée *(attendu : échec)*

![alt text](img/image-37.png)

**Verdict** : Accès refusé

### T-02 - Authentification par mot de passe refusée *(attendu : échec)*

Test refait avec le compte `essotom`.

![alt text](img/image-48.png)

**Verdict** : OK

### T-03 - Pas d'écoute sur l'interface NAT *(attendu : échec)*

![alt text](img/image-49.png)

**Verdict** : OK

### T-04 - Connexion par clé *(attendu : succès, sans mot de passe)*

![alt text](img/image-40.png)

**Verdict** : conforme (EX-17, EX-20)

### `ss -tlnp | grep :22`

![alt text](img/image-41.png)

**Vérification** - écoute limitée à `192.168.56.10:22` → conforme (EX-19)

### `sudo sshd -T`

![alt text](img/image-50.png)

**Vérification** - `permitrootlogin no`, `passwordauthentication no`, `x11forwarding no`, `listenaddress 192.168.56.10` → OK (EX-18, EX-19)

---

## 5. Privilèges

### `sudo -l`

![alt text](img/image-42.png)


### `sudo tail -n5 /var/log/sudo.log`

![alt text](img/image-43.png)

**Vérification** - la commande précédente figure bien dans le journal → conforme (EX-15)

---

## 6. Pare-feu et mises à jour

### `sudo nft list ruleset`

![alt text](img/image-51.png)

**Vérification** - table `inet meridian`, politique `drop` en entrée, loopback autorisé, SSH limité à `192.168.56.0/24`, connexions établies acceptées, ICMPv6 `nd-neighbor-solicit`, `nd-neighbor-advert`, `nd-router-advert` acceptés → OK

### `systemctl is-enabled unattended-upgrades`

![alt text](img/image-45.png)

---

## 7. Résilience au redémarrage


### `systemctl --failed`

![alt text](img/image-46.png)


---
