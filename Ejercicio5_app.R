
library(shiny)
library(dplyr)
library(ggplot2)

bacteremia_clean <- readRDS("data/bacteremia_clean.rds")
bacteremia_clean$Rango_Edad <- cut(bacteremia_clean$AGE, 
                        breaks = c(0,30, 60, 100),
                        labels = c("Joven (0-30)", "Adulto (30-60)", "3a edad (>=60)"), include.lowest = TRUE)

ui <- fluidPage(
  titlePanel("Conjunto de datos Bacteriemia"),
  sidebarLayout(
    sidebarPanel(
      width = 3,
      selectInput("rango_edad", "Rango de edad:",
                  choices = c("Joven (0-30)", "Adulto (30-60)", "3a edad (>=60)" = "Joven (0-30)", "Adulto (30-60)", "3a edad (>=60)"),
                  selected = "Joven (0-30)"
                  ),
      selectInput("sex", "Sexo:",
                  choices = c("Masculino" = 1,
                              "Femenino" = 2)
                  ),
      selectInput("biomarcador", "Selecciona el biomarcador:", 
                  choices = c("Glóbulos Blancos (WBC)" = "WBC", 
                              "Proteína C Reactiva (CRP)" = "CRP", 
                              "Transaminasa (ALAT)" = "ALAT", 
                              "Creatinina (CREA)" = "CREA", 
                              "Plaquetas (PLT)" = "PLT",
                              "Neutrófilos %" = "NEUR",
                              "Linfocitos %" = "LYMR",
                              "Glucosa" = "GLU")
                  ),
      
      # Checkbox para dist. logaritmica
      checkboxInput("aplicar_log", "Aplicar Escala Logarítmica (log(x))", value = FALSE)
    ),
    mainPanel(
      # 3 paneles:
      tabsetPanel(
        tabPanel(title = "Análisis Clínico", 
                 br(),
                 layout_column_wrap(
                   width = 1/3, # Fuerza 3 columnas de igual tamaño (1/3 cada una)
                   value_box(
                     title = " Pacientes Filtrados", 
                     value = textOutput("kpi_total"),
                   ),
                   value_box(
                     title = "Prevalencia Bacteriemia", 
                     value = textOutput("kpi_prev")
                   ),
                   value_box(
                     title = "Edad Media", 
                     value = textOutput("kpi_edad")
                   )
                 ),
                 layout_columns(
                   col_widths = c(6, 6),
                   card(card_header("Distribución del Biomarcador"),
                        plotlyOutput("plot_distribucion", height = "380px")
                        ),
                   card(plotOutput("plot_indicador"))
                   )
                 ),
        tabPanel("Resumen Estadístico", verbatimTextOutput("resumen_datos"))
      )
    )
  )
)

server <- function(input, output) {
  output$plot_indicador <- renderPlot({
    
    if (is.numeric(bacteremia_clean[[input$biomarcador]])) {
      if (input$aplicar_log) {
        # si log activo
        ggplot(bacteremia_clean, aes(x = BloodCulture, y = log(.data[[input$biomarcador]] + 1), fill = BloodCulture)) +
          geom_boxplot(alpha = 0.7) +
          labs(title = paste("Distribución Logarítmica de", input$biomarcador), y = "log(valor + 1)") +
          theme_minimal()
      } else {
        # Gráfico con los datos sin log
        ggplot(bacteremia_clean, aes(x = BloodCulture, y =  .data[[input$biomarcador]], fill = BloodCulture)) +
          geom_boxplot(alpha = 0.7) +
          labs(title = paste("Distribución Original de", input$biomarcador), y = "valor real") +
          theme_minimal()
      }
    } else {
      # Gráfico de barras - proporciones
      ggplot(bacteremia_clean, aes(x = .data[[input$biomarcador]], fill = BloodCulture)) + 
        geom_bar(position = "fill") + 
        theme_minimal() +
        labs(title = "Proporción de bacteriemia", x = "Sexo", y = "proporción")
    }
  })
  
  # Resumen estadístico
  output$resumen_datos <- renderPrint({
    particion <- split(bacteremia_clean[[input$biomarcador]], bacteremia_clean$BloodCulture)
    lapply(particion, summary)
  })
}

# Iniciar aplicación:
shinyApp(ui = ui, server = server)
