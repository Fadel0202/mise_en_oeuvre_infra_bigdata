import json
from pymongo import MongoClient
from datetime import datetime
import os


mongo_url = "mongodb://localhost:27017/"
mongo_db = "test"

# Connexion à MongoDB
client = MongoClient(mongo_url)
db = client[mongo_db]
collection = db["weather_data"]

# Répertoire contenant les fichiers JSON (chemin relatif ou absolu)
repertoire_donnees = "data_weather"

# Fonction pour résumer les données
def summarize_data(data):
    # Exemple: Calcul de la moyenne des températures
    if "main" in data and "temp" in data["main"]:
        return {"average_temperature": data["main"]["temp"]}
    else:
        return {"average_temperature": None}

# Résumer les données toutes les heures
for fichier in os.listdir(repertoire_donnees):
    if fichier.endswith(".json"):
        chemin_absolu = os.path.join(repertoire_donnees, fichier)
        
        # Charger les données JSON depuis le fichier
        with open(chemin_absolu, "r") as file:
            data = json.load(file)

        # Résumer les données
        summary = summarize_data(data)

        # Ajouter une horodatage
        summary["timestamp"] = datetime.now()

        # Insérer dans la base de données MongoDB
        collection.insert_one(summary)

        # Supprimer le fichier résumé
        os.remove(chemin_absolu)

# Fermer la connexion MongoDB
client.close()
