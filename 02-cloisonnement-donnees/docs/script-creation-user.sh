#!/bin/bash

# Nous créons d'abord un groupe commun MERIDIAN pour tous les utilisateurs
if ! getent group g_meridian &>/dev/null; then
    groupadd g_meridian
fi

# Ensuite, dans la boucle while nous lisons le fichier user.txt ligne par ligne en précisant separateur '|' et nous créons les utilisateurs et leurs groupes de service respectifs
while IFS='|' read -r utilisateur service
do
    echo "Utilisateur : $utilisateur"
    echo "Service : $service"

    groupe="g_$service"
    echo "Groupe : $groupe"

    # On fait un premier contrôle pour vérifier si l'utilisateur existe déjà
    if ! id "$utilisateur" &>/dev/null; then

        # On vérifie ensuite si le groupe de service existe déjà, sinon on le crée
        if ! getent group "$groupe" &>/dev/null; then
            groupadd "$groupe" || {
                echo "Erreur : impossible de creer le groupe $groupe"
                continue
            }
        fi

        # On crée ensuite l'utilisateur avec son groupe de service et on lui attribue un shell bash
        useradd -m -s /bin/bash -g "$groupe" "$utilisateur" || {
            echo "Erreur : impossible de creer l'utilisateur $utilisateur"
            continue
        }

        # On configure l'expiration du mot de passe à 90 jours et l'avertissement à 7 jours avant expiration
        chage -M 90 -W 7 "$utilisateur" || {
            echo "Erreur : impossible de configurer la politique d'expiration du mot de passe de $utilisateur"
            continue
        }

        # Nous ajoutons maintenant l'utilisateur au groupe secondaire commun MERIDIAN
        usermod -aG g_meridian "$utilisateur" || {
            echo "Erreur : impossible d'ajouter $utilisateur au groupe g_meridian"
            continue
        }

        # Pour finir, nous traitons le cas particulier de l'utilisateur ext.comptable pour définir une date d'expiration spécifique
        if [ "$utilisateur" = "ext.comptable" ]; then
            chage -E 2026-12-31 "$utilisateur" || {
                echo "Erreur : impossible de definir la date d'expiration de $utilisateur"
                continue
            }
        fi

        echo "Utilisateur $utilisateur cree avec succes"

    else
        echo "L'utilisateur $utilisateur existe deja"
    fi

    echo

done < user.txt