#!/bin/bash


# Définit le dossier de destination où le fichier JSON sera sauvegardé
DESTINATION_FOLDER="downloads"

# Crée un nom de fichier avec la date et l'heure actuelles pour éviter les écrasements
FILENAME="data_$(date +'%Y%m%d_%H%M%S').json"

# URL de l'API pour télécharger les données
URL="https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_hour.geojson"

# Utilise curl pour télécharger les données de l'URL et les enregistrer dans le fichier spécifié
curl "$URL" -o "$DESTINATION_FOLDER/$FILENAME"

# Affiche un message confirmant où les données ont été sauvegardées
echo "Données sauvegardées dans $DESTINATION_FOLDER/$FILENAME"

