# load packages ----
library(shiny)
library(lubridate)
library(data.table)
library(stringr)
library(RCurl)
library(ggplot2)
# -----------
source(here::here('R', '01-fetch-data.R'))

country_data <- data[, .(Num=sum(Num)), .(`Country/Region`, Date, Type)]
top10_countries <- data[, .(TotalCase=max(Num)), `Country/Region`][order(-TotalCase)]$`Country/Region`[1:10]
# Define UI for application that draws a histogram
ui <- fluidPage(
    
    # Application title
    titlePanel("Old Faithful Geyser Data"),
    
    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
            selectInput('country',
                        'Top 10 Countries', 
                        choices = top10_countries),
            selectInput('type',
                        'Type', 
                        choices = c('All', unique(country_data$Type)))
        ),
        
        # Show a plot of the generated distribution
        mainPanel(
            plotOutput("distPlot")
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
    
    p <- reactive({
        if (input$type == 'All') {
            ggplot(country_data[`Country/Region`==input$country, ]) +
                geom_line(aes(x=Date, y=Num, col=Type))
        } else {
            ggplot(country_data[`Country/Region`==input$country & Type==input$type, ]) +
                geom_line(aes(x=Date, y=Num))
        }
    })
    output$distPlot <- renderPlot(p())
    
}

# Run the application 
shinyApp(ui = ui, server = server)