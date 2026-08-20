
library(shiny)
library(dplyr)
library(ggplot2)

bacteremia_clean <- readRDS("data/bacteremia_clean.rds")
bacteremia_clean$Rango_Edad <- cut(bacteremia_clean$AGE, 
                        breaks = c(0,30, 60, 100),
                        labels = c("Joven", "Adulto", "3a Edad"), include.lowest = TRUE)

ui <- fluidPage(
  titlePanel("Conjunto de datos Bacteriemia"),
  sidebarLayout(
    sidebarPanel(
      width = 3,
      selectInput("rango_edad", "Rango de edad:",
                  choices = c("Joven (0-30)" = "Joven",
                              "Adulto (30-60)" = "Adulto",
                              "3a edad (>=60)" = "3a Edad",
                              "Todas las edades" = "all"
                              ),
                  selected = "all"
                  ),
      selectInput("sex", "Sexo:",
                  choices = c("Masculino" = "male",
                              "Femenino" = "female",
                              "Todos" = "all"),
                  selected = "all"
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
                 
                 # KPIs
                 layout_column_wrap(
                   width = 1/3, # Fuerza 3 columnas de igual tamaño (1/3 cada una)
                   value_box(
                     title = " Pacientes Filtrados", 
                     value = textOutput("kpi_total")
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
                 
                 # Graphs
                 layout_columns(
                   col_widths = c(6, 6),
                   card(textOutput("header1"),
                        plotOutput("plot_hist", height = "380px")
                        ),
                   card(textOutput("header2"),
                        plotOutput("plot_box")
                        )
                   )
                 ),
        tabPanel("Resumen Estadístico", verbatimTextOutput("resumen_datos"))
      )
    )
  )
)

server <- function(input, output) {
  data_filter <- reactive({
    df <- bacteremia_clean
    
    # Filtrar rango edad:
    if (input$rango_edad != "all") {
      df <- df[df$Rango_Edad == input$rango_edad, ]
    }
    
    # Filtrar sexo
    if (input$sex != "all") {
      df <- df[df$SEX == input$sex, ]
    }
    
    return(df)
  })
  
  # KPIs
  output$kpi_total <- renderText({
    nrow(data_filter())
  })
  
  output$kpi_prev <- renderText({
    val <- mean(data_filter()$BloodCulture == "yes") * 100
    paste0(round(val, 2), "%")
  })

  output$kpi_edad <- renderText({
    round(mean(data_filter()$AGE))
  })
  
  # Graphs
  output$header1 <- renderText({paste0("Histograma de: ", input$biomarcador)})
  output$header2 <- renderText({paste0("Distribución de ", input$biomarcador ," según hemocultivo:")})
  
  output$plot_hist <- renderPlot({
    if (input$aplicar_log) {
      #log
      ggplot(data_filter(), aes(x = log(.data[[input$biomarcador]] + 1))) +
        geom_histogram(fill="#69c3a2", color="#e9ecdf", alpha=0.9) +
        labs(x = "log(valor + 1)") +
        theme_minimal()
    } else {
      #no log
      ggplot(data_filter(), aes(x = .data[[input$biomarcador]])) +
        geom_histogram(fill="#69c3a2", color="#e9ecdf", alpha=0.9) +
        labs(x = "log(valor + 1)") +
        theme_minimal()
    }
  })
  
  output$plot_box <- renderPlot({
    if (input$aplicar_log) {
      # si log activo
      ggplot(data_filter(), aes(x = BloodCulture, y = log(.data[[input$biomarcador]] + 1), fill = BloodCulture)) +
        geom_boxplot(alpha = 0.7) +
        labs(y = "log(valor + 1)") +
        theme_minimal()
    } else {
      # Gráfico con los datos sin log
      ggplot(data_filter(), aes(x = BloodCulture, y =  .data[[input$biomarcador]], fill = BloodCulture)) +
        geom_boxplot(alpha = 0.7) +
        labs(y = "valor real") +
        theme_minimal()
    }
  })
  
  # Resumen estadístico
  output$header3 <- renderText({paste0("Resumen estadístico de: ", input$biomarcador)})
  output$resumen_datos <- renderPrint({
    particion <- split(data_filter()[[input$biomarcador]], data_filter()$BloodCulture)
    lapply(particion, summary)
  })
}

# Iniciar aplicación:
shinyApp(ui = ui, server = server)
