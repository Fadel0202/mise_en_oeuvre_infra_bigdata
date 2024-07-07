import numpy as np
import pandas as pd
import cairosvg
import folium
import matplotlib.pyplot as plt
from fpdf import FPDF
from prettytable import PrettyTable
from datetime import datetime, timedelta
import pymongo

# Paramètres de connexion MongoDB
mongo_url = "mongodb://localhost:27017/"  # Modifiez l'URL de connexion en conséquence

# Se connecter à MongoDB
client = pymongo.MongoClient(mongo_url)
db = client["test"]
collection = db["projet"]
#J'ai pas beaucoup de données, donc je récupére toutes les données stockées dans ma base de données
cursor=collection.find()
data=list(cursor)
documents = []
for document in data:
	document_data = {
                "_id": document["_id"],
            	"lon": document["coord"]["lon"],
            	"lat": document["coord"]["lat"],
            	"aqi": document["list"][0]["main"]["aqi"],
            	"co": document["list"][0]["components"]["co"],
            	"no": document["list"][0]["components"]["no"],
            	"no2": document["list"][0]["components"]["no2"],
            	"o3": document["list"][0]["components"]["o3"],
            	"so2": document["list"][0]["components"]["so2"],
            	"pm2_5": document["list"][0]["components"]["pm2_5"],
            	"pm10": document["list"][0]["components"]["pm10"],
            	"nh3": document["list"][0]["components"]["nh3"],
            	"dt": document["list"][0]["dt"]
	}
	documents.append(document_data)
df = pd.DataFrame(documents)
df.to_csv(f"data_{datetime.now()}.csv",index=False)
mean_aqi = df["aqi"].mean()

max_aqi_date = datetime.fromtimestamp(df.loc[df["aqi"].idxmax(), "dt"])
max_aqi =df.loc[df["aqi"].idxmax(),"aqi"]
aqi_now=df.loc[df["dt"].idxmax(), "aqi"]
#Les CONCENTRATIONS OBTENUS AVEC LES DONNEES LES PLUS RECENTES ENREGISTREES DANS LA BASE DE DONNEES.
co_now = df.loc[df["dt"].idxmax(), "co"]
no_now = df.loc[df["dt"].idxmax(), "no"]
no2_now = df.loc[df["dt"].idxmax(), "no2"]
o3_now = df.loc[df["dt"].idxmax(), "o3"]
so2_now = df.loc[df["dt"].idxmax(), "so2"]
pm2_5_now = df.loc[df["dt"].idxmax(), "pm2_5"]
pm10_now = df.loc[df["dt"].idxmax(), "pm10"]
nh3_now = df.loc[df["dt"].idxmax(), "nh3"]
pollutant_series = pd.Series({
    'CO': co_now,
    'NO': no_now,
    'NO2': no2_now,
    'O3': o3_now,
    'SO2': so2_now,
    'PM2_5': pm2_5_now,
    'PM10': pm10_now,
    'NH3': nh3_now
}).sort_values(ascending=False)
#Faire un pretty table.
x = PrettyTable()
x.field_names = ["Polluants", "Valeur"]
for index, value in pollutant_series.items():
    x.add_row([index, value])
# Sauvegarder la table jolie dans un fichier texte
with open("pollutant_table.txt", "w") as f:
    f.write(x.get_string())

#2
colors = plt.cm.RdYlGn(np.linspace(0, 1, 7))
# Créer le diagramme à barres horizontal
plt.figure(figsize=(7, 6))
plt.barh(pollutant_series.index, pollutant_series.values, color=colors)
# Ajouter les annotations sur les barres
for i, v in enumerate(pollutant_series.values):
    plt.text(v + 10, i - 0.1, str(v), fontsize=12)
# Ajouter les titres et les labels
plt.title(f"Concentrations de polluants atmosphériques : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
plt.xlabel('Concentration (µg/m3)')
plt.ylabel('Polluants')
plt.savefig("Concentration_polluants.png")
plt.close()

value=df["aqi"].value_counts()
#plt.plot(df["dt"], df["co"], label="AQI")
col = ['skyblue', 'lightgreen', 'lightcoral', 'orange']
value.plot(kind="bar",label="AQI",color=col)
plt.xlabel("AQI")
plt.ylabel("Count AQI")
plt.title("Distribution de l'indice de la qualité de l'air")
#plt.legend()
plt.savefig("dist_air_quality_plot.png")
plt.close()

#3
# Création de la carte de l'endroit que j'ai choisit par exemple "Paris" en utilisant la longitude et la latitude.
m = folium.Map(location=[48.8566, 2.3522], zoom_start=12)
# Ajout d'un marqueur à une position spécifique
folium.Marker(location=[48.8566, 2.3522], popup='Paris').add_to(m)
# Sauvegarde la carte dans un fichier HTML
m.save('map.html')

#4
#Créer un rapport PDF
pdf = FPDF()
pdf.add_page()
pdf.set_font("Arial", size=12)
pdf.cell(200, 6, "KEBE MOUSTAPHA", ln=1)
pdf.cell(200, 5, f"Moyenne de l'indice de qualité de l'air (AQI): {mean_aqi:.2f}", ln=1)
pdf.cell(200, 5, f"L'indice de la qualité de l'air {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} est :{aqi_now}", ln=1)
pdf.cell(200, 5, f"Date avec le plus haut AQI: {max_aqi_date.strftime('%Y-%m-%d %H:%M:%S')},AQI={max_aqi}", ln=1)
pdf.image("Concentration_polluants.png", x=10, y=50, w=180)
pdf.add_page()
pdf.cell(200, 6, f"Table des concentrations de polluants atmosphériques:{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}", ln=1)
with open("pollutant_table.txt", "r") as f:
    for line in f:
        pdf.cell(200, 8, txt=line, ln=1)
pdf.image("dist_air_quality_plot.png", x=10, y=pdf.get_y() + 10, w=180)
pdf.add_page()
pdf.cell(200, 6, "Champs dans la réponse de l'API", ln=1)
pdf.image("image.png", x=10, y=50,w=180)
pdf.output("air_quality_analysis_report.pdf")
