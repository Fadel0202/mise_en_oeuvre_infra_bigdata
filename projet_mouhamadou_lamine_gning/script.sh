#!/bin/bash

# Clé d'API OpenWeatherMap (remplacez par votre clé)
api_key="7105ffeae6a39ceb11ad5822a265deca"

# La date et l'heure au format spécifié
date=$(date +"%Y-%m-%d_%H:%M:%S")

# Nom du fichier avec date et heure
filename="weather_data_${date}.json"

# Données de la ville de Paris
city="Paris"
url="http://api.openweathermap.org/data/2.5/weather?q=${city}&appid=${api_key}"

# Répertoire dédié pour le stockage
current_directory="${PWD}"
directory="${current_directory}/data_weather/${filename}"

# Télécharger les données météorologiques de l'API OpenWeatherMap
wget -O "${directory}" ${url}

# Afficher un message de confirmation
echo "Données météorologiques téléchargées avec succès dans le fichier : $filename"
