# Mise en Œuvre de l'Infrastructure Big Data pour Tableaux de Bord Temps Réel

## Introduction
Ce projet vise à mettre en œuvre une infrastructure Big Data pour la collecte, le traitement et l'analyse de données en temps réel. Ce travail collectif permet de construire des tableaux de bord représentant l'activité quotidienne sur différentes zones et thématiques.

Dans le cadre de notre projet, nous avons été mandatés pour concevoir un tableau de bord temps réel qui présente diverses activités quotidiennes. Notre objectif principal est de mettre en place la partie extraction et stockage des données, mais aussi d'assurer l'analyse et la visualisation à travers une application Shiny.

## Structure du Projet
Le projet est divisé en plusieurs sous-répertoires, chacun correspondant à une composante spécifique développée par un membre du groupe :

- **BERKANI_Redha** : Contient les scripts pour télécharger et analyser les données d'activité sismique à travers le monde.
- **projet_mouhamadou_lamine_gning** : Répertoire dédié à l'analyse de la température de la ville de Paris.
- **Projet_kebe_moustapha** : Répertoire dédié à l'analyse de la pollution de l'air à Paris.
- **Samb_mouhamed** : Répertoire contenant les scripts pour collecter et analyser les statistiques de la vidéo YouTube "FORMATION DEEP LEARNING COMPLETE (2021)".
- **rsconnect** : Contient des documents de connexion pour l'application Shiny.

## Prérequis
Pour exécuter ce projet, vous devez avoir les éléments suivants installés :

1. **Python 3.x**
2. **MongoDB**
3. **Anaconda** (optionnel mais recommandé pour gérer les environnements Python)
4. **Bash** (pour exécuter les scripts shell)

## Installation

### Configuration de l'environnement

1. Clonez ce dépôt :
   ```bash
   git clone https://github.com/votre-utilisateur/votre-depot.git
   cd votre-depot
   ```

2. Créez un environnement virtuel (optionnel mais recommandé) :
   ```bash
   conda create -n bigdata-env python=3.8
   conda activate bigdata-env
   ```

3. Installez les dépendances Python :
   ```bash
   pip install pymongo matplotlib pandas reportlab
   ```

4. Assurez-vous que MongoDB est en cours d'exécution :
   ```bash
   systemctl status mongodb
   # Si MongoDB n'est pas en cours d'exécution :
   systemctl start mongodb
   ```

5. Créez le dossier de téléchargement s'il n'existe pas :
   ```bash
   mkdir -p downloads
   ```

## Composants du Système

## Sources de Données du Projet

### 1. Activité Sismique à travers le monde (BERKANI_Redha)

Le sujet de ce programme est l'analyse des données sur les tremblements de terre recueillies sur le site de l'USGS. L'objectif est d'exploiter ces données pour mieux comprendre la fréquence et la distribution des tremblements de terre au cours d'une période donnée, par jour dans un mois.

Les données sont fournies au format GeoJSON, un format standardisé pour encoder des structures de données géospatiales. Un fichier GeoJSON typique de l'USGS contient :
- Type : Indique qu'il s'agit d'un FeatureCollection (ensemble d'éléments sismiques)
- Metadata : Informations générales sur la requête
- Features : Tableau d'éléments où chaque élément représente un tremblement de terre spécifique

Pour cette étude, 4 champs ont été retenus : ID, Magnitude, Place et Time.

### 2. Température de la ville de Paris (GNING Mouhamadou Lamine)

Cette partie consiste à étudier l'évolution journalière des températures à Paris. Les données sont téléchargées depuis OpenWeatherMap chaque heure, puis agrégées pour obtenir la moyenne des températures journalières.

### 3. Pollution de l'Air à Paris (KÉBÉ Moustapha)

Cette composante analyse la qualité de l'air à Paris en collectant des données via l'API Air Pollution d'OpenWeatherMap. L'API fournit des données actuelles, prévisionnelles et historiques sur la pollution atmosphérique incluant l'indice de qualité de l'air et les indices de CO, NO, NO2, O3, SO2, NH3, PM2.5, et PM10.

### 4. Statistiques d'une vidéo YouTube (SAMB Mouhamed)

Cette partie collecte et analyse les statistiques de la vidéo "FORMATION DEEP LEARNING COMPLETE (2021)" de la chaîne Machine Learning Mastery à l'aide de l'API YouTube Data v3. Les données collectées incluent le nombre de vues, de likes, de commentaires et d'ajouts aux favoris.

## Composants du Système

### 1. Collecte de Données

Chaque composant du projet utilise un script de téléchargement spécifique. Pour l'activité sismique, le script `download.sh` télécharge les données depuis l'API USGS et les enregistre dans un fichier JSON horodaté.

```bash
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
```

Pour exécuter le script de téléchargement :
```bash
chmod +x download.sh
./download.sh
```

### 2. Traitement et Stockage des Données

Le script `resume.py` traite les fichiers JSON téléchargés, extrait les informations pertinentes, les insère dans MongoDB, et supprime les fichiers traités.

```python
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
    # Récupère les n derniers fichiers d'un dossier triés par ordre alphabétique.
    all_files = [f for f in os.listdir(directory) if os.path.isfile(os.path.join(directory, f))]
    sorted_files = sorted(all_files)
    return sorted_files[-n:]

# Exemple d'utilisation
directory = './downloads/'
last_files = get_last_files_sorted(directory, n=4)
last_files_with_path = [os.path.join('./downloads/', file) for file in last_files]

def summarize_and_store_earthquake_data(file_path):
    with open(file_path, 'r') as file:
        data = json.load(file)
    events = []
    for event in data['features']:
        mag = event['properties']['mag']
        place = event['properties']['place']
        time = event['properties']['time']
        time_readable = datetime.utcfromtimestamp(time / 1000).strftime('%Y-%m-%d %H:%M:%S UTC')
        event_data = {'magnitude': mag, 'place': place, 'time': time_readable}
        events.append(event_data)
    if events:
        collection.insert_many(events)
        print(f"{len(events)} événements insérés dans MongoDB pour le fichier {file_path}")
    os.remove(file_path)
    print(f"Fichier {file_path} supprimé.")

for path in last_files_with_path:
    summarize_and_store_earthquake_data(path)
```

Pour exécuter le script de traitement :
```bash
python resume.py
```

### 3. Génération de Rapports et Visualisation

Le script `report.py` génère un rapport sous forme de graphique et de fichier PDF des tremblements de terre enregistrés au cours du mois précédent.

```python
from pymongo import MongoClient
from datetime import datetime, timedelta
import matplotlib.pyplot as plt
import pandas as pd
from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas

# Connexion à MongoDB
client = MongoClient('mongodb://localhost:27017/')
db = client['earthquakes']
collection = db['earthquakes_log']

# Calcul de la date de début pour le dernier mois
today = datetime.today()
first_day_last_month = (today.replace(day=1) - timedelta(days=1)).replace(day=1)

# Récupération des enregistrements du dernier mois
last_month_earthquakes = collection.find({
    'time': {
        '$gte': first_day_last_month,
        '$lt': today
    }
})

# Création d'un DataFrame à partir des données récupérées
df = pd.DataFrame(list(last_month_earthquakes))
df['time'] = pd.to_datetime(df['time'])
df['date'] = df['time'].dt.date
daily_counts = df.groupby('date').size()

plt.figure(figsize=(10, 6))
daily_counts.plot(kind='bar')
plt.title('Nombre de tremblements de terre par jour')
plt.xlabel('Jour')
plt.ylabel('Nombre de tremblements de terre')
plt.xticks(rotation=45)
plt.tight_layout()
plt.savefig(f"./earthquakes_per_day_{first_day_last_month.strftime('%Y_%m')}.png")
plt.show()

c = canvas.Canvas(f"./earthquakes_report{first_day_last_month.strftime('%Y_%m')}.pdf", pagesize=letter)
c.drawImage(f"./earthquakes_per_day_{first_day_last_month.strftime('%Y_%m')}.png", 50, 400, width=500, height=300)
c.save()
```

Pour exécuter le script de rapport :
```bash
python report.py
```

## Automatisation avec Cron

Vous pouvez automatiser la collecte de données et la génération de rapports en utilisant cron. Voici un exemple de configuration cron pour chaque composant :

### Données sismiques (USGS)
```bash
# Télécharger les données toutes les heures
0 * * * * /chemin/vers/votre/projet/BERKANI_Redha/download.sh

# Traiter et stocker les données toutes les heures à 5 minutes
5 * * * * /usr/bin/python3 /chemin/vers/votre/projet/BERKANI_Redha/resume.py

# Générer un rapport une fois par jour à minuit
0 0 * * * /usr/bin/python3 /chemin/vers/votre/projet/BERKANI_Redha/report.py
```

### Données de température (Paris)
```bash
# Télécharger les données toutes les heures
0 * * * * /chemin/vers/votre/projet/projet_mouhamadou_lamine_gning/download.sh

# Traiter les données et les stocker dans MongoDB
5 * * * * /usr/bin/python3 /chemin/vers/votre/projet/projet_mouhamadou_lamine_gning/summarize.py
```

### Données de pollution de l'air (Paris)
```bash
# Télécharger les données toutes les heures
0 * * * * /chemin/vers/votre/projet/Projet_kebe_moustapha/download.sh

# Traiter les données et les stocker
5 * * * * /usr/bin/python3 /chemin/vers/votre/projet/Projet_kebe_moustapha/summarize.py
```

### Statistiques YouTube
```bash
# Télécharger les données toutes les heures
0 * * * * /chemin/vers/votre/projet/Samb_mouhamed/download.sh

# Traiter les données et les stocker
5 * * * * /usr/bin/python3 /chemin/vers/votre/projet/Samb_mouhamed/process_data.py
```

### Mise à jour de l'application Shiny
```bash
# Mettre à jour l'application Shiny une fois par jour
0 0 * * * Rscript -e "source('/chemin/vers/votre/projet/analyse_generale.R')"
```

Pour ajouter ces tâches à cron :
```bash
crontab -e
# Ajoutez les lignes ci-dessus et enregistrez
```

## Schéma de la Base de Données

La base de données MongoDB utilisée dans ce projet est organisée en plusieurs collections pour stocker les différents types de données :

### Collection pour les données sismiques
- **Base de données**: `earthquakes` (ou `test` selon la configuration)
- **Collection**: `earthquakes_log`
- **Structure du document**:
  ```json
  {
    "_id": ObjectId("..."),
    "magnitude": 3.5,
    "place": "10km NE of City, Country",
    "time": "2023-03-15 14:30:45 UTC"
  }
  ```

### Collection pour les données de température
- **Base de données**: `test`
- **Collection**: `temperature_data`
- **Structure du document**:
  ```json
  {
    "_id": ObjectId("..."),
    "temperature": 15.7,
    "date": "2023-03-15",
    "time": "14:30:45 UTC"
  }
  ```

### Collection pour les données de pollution
- **Base de données**: `test`
- **Collection**: `air_pollution`
- **Structure du document**:
  ```json
  {
    "_id": ObjectId("..."),
    "aqi": 2,
    "co": 1.93,
    "no": 0.02,
    "no2": 16.59,
    "o3": 29.33,
    "so2": 1.64,
    "pm2_5": 4.08,
    "pm10": 7.32,
    "nh3": 1.22,
    "date": "2023-03-15 14:30:45 UTC"
  }
  ```

### Collection pour les statistiques YouTube
- **Base de données**: `test`
- **Collection**: `youtube_stats`
- **Structure du document**:
  ```json
  {
    "_id": ObjectId("..."),
    "videoId": "video_id",
    "viewCount": 12345,
    "likeCount": 987,
    "commentCount": 56,
    "favoriteCount": 0,
    "timestamp": "2023-03-15 14:30:45 UTC"
  }
  ```

## Application de Visualisation

Le projet comprend une application Shiny (fichier `analyse_generale.R`) qui regroupe toutes les analyses et visualisations dans un tableau de bord interactif. Cette application offre une vue d'ensemble complète de l'activité quotidienne dans les différentes zones d'étude:

- Statistiques des vidéos YouTube : évolution du nombre de vues, likes et commentaires au fil du temps
- Température à Paris : graphique d'évolution journalière
- Analyse de la qualité de l'air : concentrations des polluants à Paris, indices de qualité de l'air et visualisation cartographique
- Tremblements de terre : histogramme du nombre de tremblements de terre par jour

Pour lancer l'application, utilisez la commande:
```r
library(shiny)
runApp("analyse_generale.R")
```

## Importation des Données

Pour importer des données et tester l'application, exécutez cette commande:
```bash
mongorestore projet_linux
```

Les données sont également accessibles dans le répertoire `test` au format JSON.

## Résolution des Problèmes Courants

1. **MongoDB n'est pas accessible**:
   - Vérifiez que le service MongoDB est en cours d'exécution : `systemctl status mongodb`
   - Vérifiez les logs MongoDB : `journalctl -u mongodb`

2. **Erreurs de téléchargement**:
   - Vérifiez votre connexion Internet
   - Assurez-vous que les URLs des différentes APIs sont correctes et accessibles
   - Vérifiez que vos clés API sont valides (pour OpenWeatherMap et YouTube API)

3. **Erreurs de traitement des fichiers JSON**:
   - Vérifiez le format des fichiers JSON téléchargés
   - Assurez-vous que les dossiers de téléchargement existent et sont accessibles en écriture

## Contribution au Projet

Les contributions sont les bienvenues. Veuillez suivre ces étapes pour contribuer :

1. Forkez le dépôt
2. Créez une branche pour votre fonctionnalité (`git checkout -b feature/amazing-feature`)
3. Committez vos changements (`git commit -m 'Add some amazing feature'`)
4. Poussez vers la branche (`git push origin feature/amazing-feature`)
5. Ouvrez une Pull Request

## License

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

## Outils Utilisés

Les principaux outils utilisés dans ce projet comprennent :

- **MongoDB** : Base de données NoSQL pour le stockage des données
- **Python** : Langage de programmation pour le traitement des données et génération de rapports
- **Bash** : Scripts shell pour l'automatisation des téléchargements
- **R et Shiny** : Développement de l'application de tableau de bord interactif
- **APIs tierces** :
  - API USGS pour les données sismiques
  - OpenWeatherMap API pour les données météorologiques et de pollution
  - YouTube Data API v3 pour les statistiques de vidéos

## Auteurs

Ce projet a été réalisé par :
- **BERKANI Redha** : Développement du système de collecte et d'analyse des données sismiques
- **GNING Mouhamadou Lamine** : Développement du système de collecte et d'analyse des données de température
- **KÉBÉ Moustapha** : Développement du système de collecte et d'analyse des données de pollution de l'air
- **SAMB Mouhamed** : Développement du système de collecte et d'analyse des statistiques YouTube

## Remerciements

- USGS pour la fourniture des données sismiques via leur API
- OpenWeatherMap pour l'accès aux données météorologiques et de pollution
- YouTube Data API pour l'accès aux statistiques des vidéos
- Tous les contributeurs qui ont participé à ce projet
