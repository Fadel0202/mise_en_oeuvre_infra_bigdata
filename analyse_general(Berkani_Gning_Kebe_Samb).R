library(shiny)
library(mongolite)
library(leaflet)
library(ggplot2)

# Paramètres de connexion MongoDB
mongo_url <- "mongodb://localhost:27017/"

# Définir l'interface utilisateur
ui <- fluidPage(
  titlePanel("Rapport Analyse generale"),
  tabsetPanel(
    tabPanel("Statistiques vidéo",
             sidebarLayout(
               sidebarPanel(
                 h4("Statistiques récapitulatives"),
                 verbatimTextOutput("video_summary")
               ),
               mainPanel(
                 plotOutput("viewCountPlot"),
                 plotOutput("likeCountPlot"),
                 plotOutput("commentCountPlot"),
                 plotOutput("favoriteCountPlot")
               )
             )
    ),
    tabPanel("Température météo",
             plotOutput("weatherPlot")
    ),
    tabPanel("Analyse de la qualité de l'air",
             leafletOutput("map"),
             br(),
             h4("Concentrations de polluants à Paris :"),
             tableOutput("pollutants_table"),
             br(),
             h4("Indice de qualité de l'air à Paris :"),
             verbatimTextOutput("aqi_output"),
             br(),
             h4("Histogramme de Concentration de Polluants Atmosphériques :"),
             plotOutput("pollutants_histogram"),
             h4("Histogramme de l'Indice de Qualité de l'Air :"),
             plotOutput("aqi_histogram"),
             br()
             
    ),
    tabPanel("Tremblements de terre",
             plotOutput("earthquake_histogram")
    )
  )
)


# Définir le serveur
server <- function(input, output) {
  # Se connecter à MongoDB pour les statistiques vidéo
  video_conn <- mongo(collection = "video", url = mongo_url)
  video_data <- video_conn$find()
  
  # Se connecter à MongoDB pour la température météo
  weather_conn <- mongo(collection = "weather_data", url = mongo_url)
  weather_data <- weather_conn$find()
  
  # Se connecter à MongoDB pour l'analyse de la qualité de l'air
  air_quality_conn <- mongo(collection = "projet", url = mongo_url)
  air_quality_data <- air_quality_conn$find('{"coord.lon": 2.3488, "coord.lat": 48.8534}')
  
  # Se connecter à MongoDB pour les tremblements de terre
  earthquake_conn <- mongo(collection = "earthquakes_log", url = mongo_url)
  earthquakes_data <- earthquake_conn$find()
  
  # Fonction pour extraire les statistiques et effectuer les calculs
  getSummaryStats <- function(data) {
    # Extraction des statistiques
    stats_df <- data$statistics
    
    # Calcul de la variation entre le début et la fin pour chaque statistique
    variation <- sapply(stats_df, function(x) as.numeric(x[length(x)]) - as.numeric(x[1]))
    
    # Calcul de la moyenne pour chaque statistique
    mean_stats <- sapply(stats_df, function(x) mean(as.numeric(x)))
    
    # Retourne la variation et la moyenne
    return(list(variation = variation, mean_stats = mean_stats))
  }
  

  # Fonction pour extraire les données de température
  getWeatherData <- function(data) {
    # Extraction des données de température
    return(data$average_temperature)
  }
  
  generateTemperaturePlot <- function(timestamps, temperatures, color) {
    plot(timestamps, temperatures, type = "l", col = color,
         xlab = "Date", ylab = "Température (°C)",
         main = "Évolution de la température météo au fil du temps")
  }
  
  
  # Fonction pour générer un graphique de statistiques vidéo
  generateVideoStatsPlot <- function(data, x_column, y_column, color) {
    plot(data[[x_column]], data[[y_column]], type = "l", col = color,
         xlab = "Date", ylab = y_column,
         main = paste("Évolution du nombre de", y_column, "de la vidéo au fil du temps"))
  }
  
  # Fonction pour extraire les données de tremblements de terre et compter par jour
  getEarthquakesCountByDay <- function(data) {
    # Convertir le champ 'time' en format de date
    data$time <- as.Date(data$time)
    # Compter le nombre de tremblements de terre par jour
    earthquakes_count <- table(data$time)
    return(as.data.frame(earthquakes_count))
  }
  
  # Résumé des statistiques vidéo
  output$video_summary <- renderPrint({
    summary <- getSummaryStats(video_data)
    if (!is.null(summary)) {
      summary
    } else {
      print("Certaines colonnes de statistiques sont manquantes.")
    }
  })
  
  # Graphique pour le nombre de vues
  output$viewCountPlot <- renderPlot({
    generateVideoStatsPlot(video_data, "insertion_date", "statistics$viewCount", "blue")
  })
  
  # Graphique pour le nombre de likes
  output$likeCountPlot <- renderPlot({
    generateVideoStatsPlot(video_data, "insertion_date", "statistics$likeCount", "red")
  })
  
  # Graphique pour le nombre de commentaires
  output$commentCountPlot <- renderPlot({
    generateVideoStatsPlot(video_data, "insertion_date", "statistics$commentCount", "green")
  })
  
  # Graphique pour le nombre de favoris
  output$favoriteCountPlot <- renderPlot({
    generateVideoStatsPlot(video_data, "insertion_date", "statistics$favoriteCount", "orange")
  })
  
  # Graphique pour la température météo

  
  output$weatherPlot <- renderPlot({
    temperatures <- getWeatherData(weather_data)
    timestamps <- weather_data$timestamp
    generateTemperaturePlot(timestamps, temperatures, "blue")
  })
  
  
  # Carte pour l'analyse de la qualité de l'air
  output$map <- renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      setView(lng = 2.3488, lat = 48.8534, zoom = 10) %>%
      addMarkers(lng = 2.3488, lat = 48.8534, popup = "Paris")
  })
  
  # Tableau des concentrations de polluants
  output$pollutants_table <- renderTable({
    pollutants <- air_quality_data$list[[1]]$components
    pollutants_df <- data.frame(
      Pollutant = names(pollutants),
      Concentration = unlist(pollutants)
    )
    pollutants_df
  })
  
  output$aqi_output <- renderText({
    # Récupérer la dernière entrée de la liste
    latest_entry <- tail(air_quality_data, n = 1)
    # Extraire la date de la dernière entrée
    dt <- as.POSIXct(latest_entry$dt, origin = "1970-01-01", tz = "UTC")
    # Extraire l'AQI de la dernière entrée
    aqi_value <- latest_entry$list[[1]]$main$aqi
    # Vérifier si l'AQI est disponible
    if (!is.null(aqi_value) && !is.na(aqi_value)) {
      paste("Date:", date(), " - Indice de qualité de l'air (AQI):", aqi_value)
    } else {
      "Aucune donnée d'indice de qualité de l'air disponible."
    }
  })
  
  
  
  
  # Récupérer les données sur la qualité de l'air
  air_quality_data <- air_quality_conn$find()
  
  # Créer un histogramme de la distribution de la qualité de l'air en fonction des valeurs AQI
  output$aqi_histogram <- renderPlot({
    # Extraire les valeurs de l'indice de qualité de l'air (AQI)
    aqi_values <- unlist(lapply(air_quality_data$list, function(x) x$main$aqi))
    
    # Filtrer les valeurs NULL et NA
    aqi_values <- aqi_values[!is.null(aqi_values) & !is.na(aqi_values)]
    
    # Vérifier si des données sont disponibles
    if (length(aqi_values) > 0) {
      # Créer un data frame contenant les valeurs AQI et leur nombre d'occurrences
      aqi_data <- data.frame(AQI = as.factor(aqi_values))
      aqi_counts <- table(aqi_data$AQI)
      aqi_df <- data.frame(AQI = names(aqi_counts), Count = as.numeric(aqi_counts))
      
      # Créer un histogramme avec une barre pour chaque valeur AQI différente
      ggplot(aqi_df, aes(x = AQI, y = Count, fill = AQI)) +
        geom_bar(stat = "identity") +
        scale_fill_manual(values = rainbow(length(unique(aqi_values)))) + # Utiliser une palette de couleurs
        labs(x = "Indice de Qualité de l'Air (AQI)", y = "Nombre d'occurrences", 
             title = "Distribution de la Qualité de l'Air en fonction de l'Indice de Qualité de l'Air (AQI)")
    } else {
      # Afficher un message si aucune donnée n'est disponible
      ggplot() + 
        annotate("text", x = 1, y = 1, label = "Aucune donnée d'indice de qualité de l'air disponible.", size = 5)
    }
  })

  
  
  
  
  # Histogramme de Concentration de Polluants Atmosphériques
  output$pollutants_histogram <- renderPlot({
    pollutants <- air_quality_data$list[[1]]$components
    pollutants_df <- data.frame(
      Pollutant = names(pollutants),
      Concentration = unlist(pollutants)
    )
    ggplot(pollutants_df, aes(x = Pollutant, y = Concentration, fill = Pollutant)) +
      geom_bar(stat = "identity") +
      labs(x = "Polluant Atmosphérique", y = "Concentration", title = "Histogramme de Concentration de Polluants Atmosphériques") +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  })
  
  # Histogramme pour le nombre de tremblements de terre par jour
  output$earthquake_histogram <- renderPlot({
    earthquakes_count <- getEarthquakesCountByDay(earthquakes_data)
    ggplot(earthquakes_count, aes(x = Var1, y = Freq)) +
      geom_bar(stat = "identity", fill = "blue") +
      labs(x = "Date", y = "Nombre de tremblements de terre", title = "Histogramme du nombre de tremblements de terre par jour")
  })
  
}

# Lancer l'application Shiny
shinyApp(ui = ui, server = server)
