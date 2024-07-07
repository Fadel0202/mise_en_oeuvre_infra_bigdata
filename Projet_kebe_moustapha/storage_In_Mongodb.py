import os
import json
from pymongo import MongoClient

# Paramètres de connexion MongoDB
mongo_url = "mongodb://localhost:27017/"
mongo_db = "test"
mongo_collection = "projet" 

# Se connecter à MongoDB
myclient = MongoClient(mongo_url)
db = myclient[mongo_db]
collection = db[mongo_collection]

# Chemin du répertoire courant
chemin = os.getcwd()

# Parcourir les fichiers du répertoire
for filename in os.listdir(chemin):
    if filename.endswith(".json"):
        filepath = os.path.join(chemin, filename)
        with open(filepath, 'r') as file:
            data = json.load(file)
        collection.insert_one(data)
        os.remove(filepath)

# Fermer la connexion à MongoDB
myclient.close()
