from pymongo import MongoClient
import pandas as pd
import matplotlib.pyplot as plt
from datetime import datetime, timedelta

# Connexion à MongoDB
client = MongoClient("mongodb://localhost:27017/")
db = client["test"]
collection = db["weather_data"]

# Récupérer toutes les données
data = list(collection.find())

# Convertir les données en DataFrame Pandas
df = pd.DataFrame(data)

# Convertir la colonne de timestamp en format datetime
df['timestamp'] = pd.to_datetime(df['timestamp'])

# Convertir les colonnes timestamp et average_temperature en listes
timestamps = df['timestamp'].tolist()
temperatures = df['average_temperature'].tolist()

# Analyse des données (exemple : calcul de la température moyenne)
mean_temperature = df["average_temperature"].mean()

# Générer un graphique et sauvegarder en PDF
plt.plot(timestamps, temperatures)
plt.title("Moyenne quotidienne de température")
plt.xlabel("Jour")
plt.ylabel("Température (°C)")
plt.xticks(rotation=45)
plt.savefig("data_weather_analyser/evolution_journaliere_temperature.pdf")

# Enregistrer les données dans un fichier CSV
df.to_csv('data.csv', index=False)

# Fermer la connexion MongoDB
client.close()
