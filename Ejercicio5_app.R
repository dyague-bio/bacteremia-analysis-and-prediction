
library(shiny)
library(dplyr)
library(ggplot2)

bacteremia_clean <- readRDS("data/bacteremia_clean.rds")

ui <- fluidPage(
  titlePanel("Conjunto de datos Bacteriemia"),
  sidebarLayout(
    sidebarPanel(
      selectInput("variable", "Selecciona el indicador:", 
                  choices = c("Glóbulos Blancos (WBC)" = "WBC", 
                              "Proteína C Reactiva (CRP)" = "CRP", 
                              "Transaminasa (ALAT)" = "ALAT", 
                              "Creatinina (CREA)" = "CREA", 
                              "Plaquetas (PLT)" = "PLT",
                              "Neutrófilos %" = "NEUR",
                              "Linfocitos %" = "LYMR",
                              "Glucosa" = "GLU",
                              "Edad" = "AGE",
                              "Sexo" = "SEX")),
      
      # Checkbox para dist. logaritmica
      checkboxInput("aplicar_log", "Aplicar Escala Logarítmica (log(x))", value = FALSE)
    ),
    mainPanel(
      # 3 paneles con diferentes visualizaciones e informaciones:
      tabsetPanel(
        tabPanel("Análisis Clínico", plotOutput("plot_indicador")),
        tabPanel("Resumen Estadístico", verbatimTextOutput("resumen_datos"))
      )
    )
  )
)

server <- function(input, output) {
  output$plot_indicador <- renderPlot({
    
    if (is.numeric(bacteremia_clean[[input$variable]])) {
      if (input$aplicar_log) {
        # si log activo
        ggplot(bacteremia_clean, aes(x = BloodCulture, y = log(.data[[input$variable]] + 1), fill = BloodCulture)) +
          geom_boxplot(alpha = 0.7) +
          labs(title = paste("Distribución Logarítmica de", input$variable), y = "log(valor + 1)") +
          theme_minimal()
      } else {
        # Gráfico con los datos sin log
        ggplot(bacteremia_clean, aes(x = BloodCulture, y =  .data[[input$variable]], fill = BloodCulture)) +
          geom_boxplot(alpha = 0.7) +
          labs(title = paste("Distribución Original de", input$variable), y = "valor real") +
          theme_minimal()
      }
    } else {
      # Gráfico de barras - proporciones
      ggplot(bacteremia_clean, aes(x = .data[[input$variable]], fill = BloodCulture)) + 
        geom_bar(position = "fill") + 
        theme_minimal() +
        labs(title = "Proporción de bacteriemia", x = "Sexo", y = "proporción")
    }
  })
  
  # Resumen estadístico
  output$resumen_datos <- renderPrint({
    particion <- split(bacteremia_clean[[input$variable]], bacteremia_clean$BloodCulture)
    lapply(particion, summary)
  })
}

# Iniciar aplicación:
shinyApp(ui = ui, server = server)
