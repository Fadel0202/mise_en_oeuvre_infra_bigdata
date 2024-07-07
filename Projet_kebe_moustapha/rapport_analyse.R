library(shiny)
library(mongolite)
library(leaflet)
library(ggplot2)

# Paramètres de connexion MongoDB
mongo_url <- "mongodb://localhost:27017/test"
mongo_collection <- "projet" 

# Définir l'interface utilisateur
ui <- fluidPage(
  titlePanel("Analyse de la qualité de l'air"),
  sidebarLayout(
    sidebarPanel(
      helpText("Affichage de la carte de l'indice de qualité de l'air pour Paris")
    ),
    mainPanel(
      leafletOutput("map"),
      br(),
      h4("Concentrations de polluants à Paris :"),
      tableOutput("pollutants_table"),
      br(),
      h4("Indice de qualité de l'air à Paris :"),
      verbatimTextOutput("aqi_output"),
      br(),
      h4("Histogramme de l'Indice de Qualité de l'Air :"),
      plotOutput("aqi_histogram"),
      br(),
      h4("Histogramme de Concentration de Polluants Atmosphériques :"),
      plotOutput("pollutants_histogram")
    )
  )
)

# Définir le serveur
server <- function(input, output) {
  # Se connecter à MongoDB
  conn <- mongo(collection = mongo_collection, url = mongo_url)
  
  # Récupérer les données de MongoDB pour la ville de Paris
  data <- conn$find('{"coord.lon": 2.3488, "coord.lat": 48.8534}')
  
  # Créer la carte avec Leaflet
  output$map <- renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      setView(lng = 2.3488, lat = 48.8534, zoom = 10) %>%
      addMarkers(lng = 2.3488, lat = 48.8534, popup = "Paris")
  })
  
  # Calculer les concentrations de polluants et l'indice de qualité de l'air
  output$pollutants_table <- renderTable({
    pollutants <- data$list[[1]]$components
    pollutants_df <- data.frame(
      Pollutant = names(pollutants),
      Concentration = unlist(pollutants)
    )
    pollutants_df
  })
  
  output$aqi_output <- renderText({
    aqi <- unique(sapply(data, function(x) x$list[[1]]$main$aqi))
    paste("Indice de qualité de l'air (AQI) :", aqi)
  })
  
  # Extraire les indices AQI
  aqi_values <- sapply(data, function(x) x$list[[1]]$main$aqi)
  
  # Créer l'histogramme de l'indice de qualité de l'air
  output$aqi_histogram <- renderPlot({
    ggplot(data.frame(AQI = as.factor(aqi_values)), aes(x = AQI)) +
      geom_bar(fill = "blue") +
      labs(x = "Indice de Qualité de l'Air (AQI)", y = "Nombre d'occurrences", 
           title = "Histogramme de l'Indice de Qualité de l'Air")
  })
  
  
  # Histogramme de Concentration de Polluants Atmosphériques
  output$pollutants_histogram <- renderPlot({
    pollutants <- data$list[[1]]$components
    pollutants_df <- data.frame(
      Pollutant = names(pollutants),
      Concentration = unlist(pollutants)
    )
    ggplot(pollutants_df, aes(x = Pollutant, y = Concentration, fill = Pollutant)) +
      geom_bar(stat = "identity") +
      labs(x = "Polluant Atmosphérique", y = "Concentration", title = "Histogramme de Concentration de Polluants Atmosphériques") +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  })
}

# Lancer l'application Shiny
shinyApp(ui = ui, server = server)
