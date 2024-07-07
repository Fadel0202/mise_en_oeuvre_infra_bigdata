# Importer les bibliothèques nécessaires
import pandas as pd
import matplotlib.pyplot as plt
from pymongo import MongoClient
import numpy as np
from PIL import Image

# Se connecter à la base de données MongoDB et récupérer les données de la collection video
client = MongoClient("mongodb://127.0.0.1:27017/")
db = client["test"]
collection = db["video"]
data = list(collection.find())

# Créer un DataFrame pandas à partir des données, en sélectionnant les colonnes statistics et insertion_date
df = pd.DataFrame(data)[["statistics", "insertion_date"]]

# Convertir les valeurs de statistics en nombres et ajouter les colonnes pour le nombre de likes, de commentaires et de favoris
df['viewCount'] = df['statistics'].apply(lambda x: int(x['viewCount']))
df['likeCount'] = df['statistics'].apply(lambda x: int(x.get('likeCount', 0)))
df['commentCount'] = df['statistics'].apply(lambda x: int(x.get('commentCount', 0)))
df['favoriteCount'] = df['statistics'].apply(lambda x: int(x.get('favoriteCount', 0)))

# Supprimer la colonne 'statistics' si nécessaire
df.drop(columns=['statistics'], inplace=True)

# Convertir les colonnes 'insertion_date' et les colonnes de données en tableaux numpy
dates = df['insertion_date'].to_numpy()
view_counts = df['viewCount'].to_numpy()
like_counts = df['likeCount'].to_numpy()
comment_counts = df['commentCount'].to_numpy()
favorite_counts = df['favoriteCount'].to_numpy()

# Tracer le graphique
plt.figure(figsize=(10, 6))
plt.plot(dates, view_counts, label='View Count')
plt.plot(dates, like_counts, label='Like Count')
plt.plot(dates, comment_counts, label='Comment Count')
plt.plot(dates, favorite_counts, label='Favorite Count')
plt.xlabel('Date')
plt.ylabel('Count')
plt.title('Evolution des statistiques de la vidéo au fil du temps')
plt.legend()

# Sauvegarder le graphique en PNG
plt.savefig('graphique_statistiques.png')

# Ouvrir le PNG et le convertir en mode RVB
img = Image.open('graphique_statistiques.png').convert('RGB')

# Sauvegarder l'image convertie en PDF
img.save('graphique_statistiques.pdf', 'PDF', resolution=100.0)

# Afficher le graphique
plt.show()
