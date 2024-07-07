import json
from datetime import datetime
from pymongo import MongoClient
import os


# Paramètres de connexion MongoDB
mongo_url = "mongodb://localhost:27017/"
mongo_db = "test"
mongo_collection = "earthquakes_log"

# Se connecter à MongoDB
client = MongoClient(mongo_url)
db = client[mongo_db]
collection = db[mongo_collection]



def get_last_files_sorted(directory, n=4):
    """
    Récupère les n derniers fichiers d'un dossier triés par ordre alphabétique.

    :param directory: Chemin du dossier à analyser.
    :param n: Nombre de fichiers à récupérer.
    :return: Liste des n derniers fichiers triés par ordre alphabétique.
    """
    # Liste tous les fichiers du dossier
    all_files = [f for f in os.listdir(directory) if os.path.isfile(os.path.join(directory, f))]
    
    # Trie les fichiers par ordre alphabétique
    sorted_files = sorted(all_files)
    
    # Récupère les n derniers fichiers
    last_files = sorted_files[-n:]
    
    return last_files

# Exemple d'utilisation
directory = './downloads/'
last_files = get_last_files_sorted(directory, n=4)

last_files_with_path = [os.path.join('./downloads/', file) for file in last_files]


def summarize_and_store_earthquake_data(file_path):
    # Charger les données JSON
    with open(file_path, 'r') as file:
        data = json.load(file)

    events = []
    for event in data['features']:
        mag = event['properties']['mag']
        place = event['properties']['place']
        time = event['properties']['time']
        # Conversion du timestamp UNIX en format lisible
        time_readable = datetime.utcfromtimestamp(time / 1000).strftime('%Y-%m-%d %H:%M:%S UTC')
        
        # Préparation de l'objet à insérer
        event_data = {
            'magnitude': mag,
            'place': place,
            'time': time_readable
        }
        events.append(event_data)
    
    # Insertion des données dans MongoDB
    if events:
        collection.insert_many(events)
        print(f"{len(events)} événements insérés dans MongoDB pour le fichier {file_path}")
    
    # Suppression du fichier
    os.remove(file_path)
    print(f"Fichier {file_path} supprimé.")

# Itération sur chaque fichier et exécution de la fonction
for path in last_files_with_path:
    summarize_and_store_earthquake_data(path)

