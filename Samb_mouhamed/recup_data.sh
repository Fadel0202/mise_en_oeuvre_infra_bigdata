#!/bin/bash

# Votre clé API YouTube Data API v3
API_KEY="AIzaSyBJ1pdHkJSDmbG4gci5QU6TF4tS4PpynEU"

# URL de la vidéo YouTube
VIDEO_URL="https://www.youtube.com/watch?v=XUFLq6dKQok"

DATE=$(date +"%Y-%m-%d_%H:%M:%S")

# Extraire l'ID de la vidéo à partir de l'URL
VIDEO_ID=$(echo $VIDEO_URL | awk -F'=' '{print $NF}')

# Utiliser l'API YouTube Data API v3 pour obtenir les statistiques de la vidéo
wget -qO- "https://www.googleapis.com/youtube/v3/videos?id=${VIDEO_ID}&key=${API_KEY}&part=statistics" | jq '.' > video_stats_${VIDEO_ID}_${DATE}.json

# Imprimer un message de confirmation
echo "Statistiques de la vidéo YouTube (ID: ${VIDEO_ID}) téléchargées avec succès dans video_stats_${VIDEO_ID}_${DATE}.json"



