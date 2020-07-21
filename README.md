# Backup-SQL-via-Powershell
Simple Backup complet des BDD MSSQL via Powershell avec suivi de versions et envoi d'email
Ce script est destiné à une application sur des petits serveurs en entreprise

#Fonctionnement
Ce script powershell permet de faire une sauvegarde complète simple d'une base de donnée MSSQL.
- Renomme les sauvegardes précédentes avec la date du jour de création de celles-ci (pour que le nom des fichiers correspondent au nom de la base et la date du jour de la sauvegarde)
- Supprime les sauvegardes qui datent de plus de X jours
- Lance la sauvegardes des bases de données via une commande SQL (en ingnorant les bases de données par défaut)
- Check dans l'observateur d'événements Windows si la sauvegarde s'est bien passée ou pas et envoi un mail  en fonction du résultat
Les sauvegardes sont stockées sous la forme d'un fichier .BAK dans le répertoire de destination choisi. Elle en sont pas compressées ou modifiées d'une quelconque façon.

#Utilisation
Les variables en début de scripts servent à choisir :
- La destination de sauvegarde (chemin Windows classique)
- Déclarer le nom des bases de données sauvegardées (ces variables servent au suivi de version et à l'envoi d'email), il faut ajouter autant de variables que de bases de données à sauvegarder
- Déclarer le nom du serveur SQL
- Indiquer le nombre de jours de versionning voulu

La première partie du script qui renomme les fichiers doit être copiée pour chaque base de donnée qui doit être sauvegardée et de même pour l'envoi d'email (partie succès et echec).
Il faut indiquer le chemin de destination des sauvegardes dans la variable $sql.
Dans la section #préparation mail il faut simplement remplir les variables communes d'envoi d'email.
Le script doit ensuite être lancé via le plannificateur des tâches de Windows avec les droits d'administrateur.
