import json
import os
from datetime import datetime
from pathlib import Path
from pymongo import MongoClient

# Paramètres de connexion MongoDB
mongo_url = "mongodb://localhost:27017/"
mongo_db = "test"
mongo_collection = "video"

# Se connecter à MongoDB
myclient = MongoClient(mongo_url)
db = myclient[mongo_db]
collection = db[mongo_collection]

def traite_json(file):
    try:
        # Extraire la date et l'heure du nom de fichier
        filename = os.path.basename(file)
        parts = filename.split("_")
        file_date = parts[-2]  # Date dans le nom du fichier
        file_time = parts[-1].split(".")[0]  # Heure dans le nom du fichier
        
        with open(file, 'r') as f:
            data = json.load(f)

        if 'items' in data and len(data['items']) > 0:
            video_data = data['items'][0]
            video_data["insertion_date"] = datetime.strptime(f"{file_date}_{file_time}", "%Y-%m-%d_%H:%M:%S")  # Convertir en datetime
            collection.insert_one(video_data)
            print(f"Les données de la vidéo avec l'ID {video_data['id']} ont été insérées avec succès.")
            
            # Supprimer le fichier après l'insertion
            os.unlink(file)
            print(f"Le fichier {file} a été supprimé.")
        else:
            print(f"Le fichier {file} ne contient pas de données valides pour une vidéo YouTube.")
    
    except Exception as e:
        print(f"Erreur lors du traitement du fichier {file}: {e}")

directory = os.getcwd()

for path in Path(directory).iterdir():
    if path.suffix == '.json':
        traite_json(path)