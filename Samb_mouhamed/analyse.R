# Charger les packages
library(shiny)
library(mongolite)

# Connexion à la base de données MongoDB
mongo_url <- "mongodb://localhost:27017/"
mongo_db <- "test"
mongo_collection <- "video"
video_data <- mongo(collection = mongo_collection, db = mongo_db, url = mongo_url)

# Interface utilisateur de l'application web
ui <- fluidPage(
  titlePanel("Évolution des statistiques vidéo"),
  sidebarLayout(
    sidebarPanel(
      h4("Statistiques récapitulatives"),
      verbatimTextOutput("summary")
    ),
    mainPanel(
      plotOutput("viewCountPlot"),
      plotOutput("likeCountPlot"),
      plotOutput("commentCountPlot"),
      plotOutput("favoriteCountPlot")
    )
  )
)

# Fonction pour extraire les statistiques et effectuer les calculs
getSummaryStats <- function(data) {
  # Extraction des statistiques
  stats_df <- data$statistics
  
  # Vérification des noms de colonnes et des premières lignes
  print("Affichage des noms de colonnes...")
  print(names(stats_df))
  print("Affichage des 5 premières lignes du dataframe...")
  print(head(stats_df))
  
  # Calcul de la variation entre le début et la fin pour chaque statistique
  print("Variation entre le début et la fin pour chaque statistique:")
  variation <- sapply(stats_df, function(x) as.numeric(x[length(x)]) - as.numeric(x[1]))
  print(variation)
  
  # Calcul de la moyenne pour chaque statistique
  print("Moyenne pour chaque statistique:")
  mean_stats <- sapply(stats_df, function(x) mean(as.numeric(x)))
  print(mean_stats)
  
  # Retourne la variation et la moyenne
  return(list(variation = variation, mean_stats = mean_stats))
}

# Fonction pour générer un graphique
generatePlot <- function(data, x_column, y_column, color) {
  plot(data$insertion_date, data[[y_column]], type = "l", col = color,
       xlab = "Date", ylab = y_column,
       main = paste("Évolution du nombre de", y_column, "de la vidéo au fil du temps"))
}

# Fonctions de génération de graphique pour chaque série de données
server <- function(input, output) {
  
  # Résumé des statistiques
  output$summary <- renderPrint({
    data <- video_data$find()
    df <- as.data.frame(data)
    summary <- getSummaryStats(df)
    if (!is.null(summary)) {
      summary
    } else {
      print("Certaines colonnes de statistiques sont manquantes.")
    }
  })
  
  # Graphique pour le nombre de vues
  output$viewCountPlot <- renderPlot({
    data <- video_data$find()
    df <- as.data.frame(data)
    generatePlot(df, "insertion_date", "statistics$viewCount", "blue")
  })
  
  # Graphique pour le nombre de likes
  output$likeCountPlot <- renderPlot({
    data <- video_data$find()
    df <- as.data.frame(data)
    generatePlot(df, "insertion_date", "statistics$likeCount", "red")
  })
  
  # Graphique pour le nombre de commentaires
  output$commentCountPlot <- renderPlot({
    data <- video_data$find()
    df <- as.data.frame(data)
    generatePlot(df, "insertion_date", "statistics$commentCount", "green")
  })
  
  # Graphique pour le nombre de favoris
  output$favoriteCountPlot <- renderPlot({
    data <- video_data$find()
    df <- as.data.frame(data)
    generatePlot(df, "insertion_date", "statistics$favoriteCount", "orange")
  })
}

# Exécuter l'application web Shiny
shinyApp(ui = ui, server = server)
