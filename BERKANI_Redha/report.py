
from pymongo import MongoClient
from datetime import datetime, timedelta
import matplotlib.pyplot as plt
import pandas as pd

# Connexion à MongoDB
client = MongoClient('mongodb://localhost:27017/')
db = client['earthquakes']  # Spécifiez le nom de la base de données ici
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

# Conversion de la colonne 'time' en datetime
df['time'] = pd.to_datetime(df['time'])

# Ajout d'une colonne 'date' pour regrouper par jour
df['date'] = df['time'].dt.date

# Calcul du nombre de tremblements de terre par jour
daily_counts = df.groupby('date').size()





plt.figure(figsize=(10, 6))
daily_counts.plot(kind='bar')
plt.title('Nombre de tremblements de terre par jour')
plt.xlabel('Jour')
plt.ylabel('Nombre de tremblements de terre')
plt.xticks(rotation=45)
plt.tight_layout()
plt.savefig(f"/home/reda/Desktop/BERKANI_Redha/earthquakes_per_day_{first_day_last_month.strftime('%Y_%m')}.png")
plt.show()


from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas

c = canvas.Canvas(f"./earthquakes_report{first_day_last_month.strftime('%Y_%m')}.pdf", pagesize=letter)
c.drawImage(f"./earthquakes_per_day_{first_day_last_month.strftime('%Y_%m')}.png", 50, 400, width=500, height=300)
c.save()




