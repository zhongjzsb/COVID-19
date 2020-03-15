# load packages ----
library(shiny)
library(lubridate)
library(data.table)
library(stringr)
library(RCurl)
library(ggplot2)
# -----------
source(here::here('R', '01-fetch-data.R'))

top20_countries <- data[
    , .(TotalCase=max(Num)), `Country/Region`
    ][order(-TotalCase)]$`Country/Region`[1:20]
# 
ui <- fluidPage(
    
    titlePanel("COVID-19 Country-wise Data"),
    
    sidebarLayout(
        sidebarPanel(
            selectInput(
                'country',
                'Top 20 Country/Region', 
                choices = top20_countries),
            selectInput(
                'type',
                'Type', 
                choices = c('All', unique(country_data$Type)))
        ),
        
        mainPanel(
            plotOutput("country_plot")
        )
    )
)


# 
server <- function(input, output) {
    
    p <- reactive({
        if (input$type == 'All') {
            ggplot(country_data[`Country/Region`==input$country, ]) +
                geom_col(aes(x=Date, y=Num, col=Type))
        } else {
            ggplot(country_data[`Country/Region`==input$country & Type==input$type, ]) +
                geom_col(aes(x=Date, y=Num))
        }
    })
    output$country_plot <- renderPlot(p())
    
}

# Run the application 
shinyApp(ui = ui, server = server)