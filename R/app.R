# load packages ----
library(shiny)
library(lubridate)
library(data.table)
library(stringr)
library(RCurl)
library(ggplot2)
# -----------
source('01-fetch-data.R')

# all countries ranking by total cases
all_countries <- data[
    , .(TotalCase=max(Num)), `Country/Region`
    ][order(-TotalCase)]$`Country/Region`

# 
ui <- fluidPage(
    
    titlePanel("COVID-19 Country-wise Data"),
    
    sidebarLayout(
        sidebarPanel(
            selectInput(
                'country',
                'Country/Region', 
                choices = all_countries),
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
            ggplot(
                country_data[`Country/Region`==input$country, ]
            ) + geom_line(aes(x = Date, y = Num, col=Type), size = 2) + 
                theme_gray(base_size = 20) +
                theme(legend.position = 'top') +
                facet_wrap(. ~ `Country/Region`, nrow = 4, scales = "free_y") + 
                labs(title = str_to_title(input$country))
        } else {
            ggplot(
                country_data[`Country/Region`==input$country & Type==input$type, ]
            ) + geom_col(
                aes(x = Date, y = Num),
                fill='red',
                position = position_stack(reverse = TRUE)) + 
                theme_gray(base_size = 20) +
                theme(legend.position = 'top') +
                labs(title = str_to_title(input$country))
        }
    })
    output$country_plot <- renderPlot(p())
    
}

# Run the application 
shinyApp(ui = ui, server = server)