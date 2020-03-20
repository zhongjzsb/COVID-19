library(mapview)
library(leaflet)
library(dplyr)
library(leafpop)
library(sf)
library(ggplot2)
library(htmltools)
library(leafem)
library(leaflet.extras)
library(raster)

# Ref: https://stackoverflow.com/questions/47064921/leaflet-legend-for-addawesomemarkers-function-with-icons
markerLegendHTML <- function(IconSet) {
    # container div:
    legendHtml <- "<div style='padding: 10px; padding-bottom: 10px;'><h4 style='padding-top:0; padding-bottom:10px; margin: 0;'> #Current </h4>"
    
    n <- 1
    # add each icon for font-awesome icons icons:
    for (Icon in IconSet) {
        if (Icon[["library"]] == "glyphicon") {
            legendHtml<- paste0(
                legendHtml, 
                "<div style='width: auto; height: 45px'>",
                "<div style='position: relative; display: inline-block; width: 36px; height: 45px' class='awesome-marker awesome-marker-icon-",
                Icon[["markerColor"]],
                "'>",
                "<i style='margin-left: 4px; margin-top: 11px; color: ",
                Icon[["iconColor"]],
                "' class= 'glyphicon glyphicon-",
                Icon[["icon"]],
                "'></i>",
                "</div>",
                "<p style='position: relative; top: 10px; left: 2px; display: inline-block; ' >", 
                names(IconSet)[n] ,
                "</p>",
                "</div>")    
        }
        n<- n + 1
    }
    paste0(legendHtml, "</div>")
}

popup_icons <- awesomeIconList(
    '1-10' = makeAwesomeIcon(icon='stats', library='glyphicon', markerColor = 'lightblue'),
    '11-100' = makeAwesomeIcon(icon='stats', library='glyphicon', markerColor = 'orange'),
    '101-1000' = makeAwesomeIcon(icon='stats', library='glyphicon', markerColor = 'red'),
    '1001-10000' = makeAwesomeIcon(icon='stats', library='glyphicon', markerColor = 'black'),
    '10000-' = makeAwesomeIcon(icon='stats', library='glyphicon', markerColor = 'black', iconColor = 'darkred')
)

wide_data <- dcast(data, ...~Type, value.var = 'Num')
latest_data <- wide_data[Date==max(Date) & confirmed!=0]
latest_data[, `:=`(
    icon_group=cut(
        latest_data$current, 
        breaks=c(-1, 10, 100, 1000, 10000, 1000000), 
        labels=c('1-10', '11-100', '101-1000', '1001-10000', '10000-')),
    region_label=paste0(
        `Country/Region`, ', ', `Province/State`, 
        ' <br> #Current: ', current,
        ' <br> #Death: ', death,
        ' <br> #Recovered: ', recovered
    )
)]

popup_plots <- list()
for (i_row in c(1:nrow(latest_data))) {
    i_record <- latest_data[i_row]
    popup_plots[[i_row]] <- ggplot(data[
        `Country/Region`==i_record$`Country/Region` &
        `Province/State`==i_record$`Province/State` &
        Type != 'confirmed'
    ]) + geom_col(aes(x = Date, y = Num, fill=Type)) +
        labs(title = paste0(
            i_record$`Country/Region`, '  --- ', i_record$`Province/State`, '\n',
            sprintf("Date: %s", i_record$Date), '\n',
            sprintf("#Confirmed: %s   ", i_record$confirmed),
            sprintf("#Current: %s", i_record$current), '\n',
            sprintf("#Death: %s   ", i_record$death),
            sprintf("#Recovered: %s", i_record$recovered)
        )) +
        theme_gray(base_size = 12) +
        theme(legend.text=element_text(size=15))
}

# Create the map
leaflet_map <- latest_data %>%
    leaflet(options = leafletOptions(minZoom = 2, maxZoom = 8)) %>%
    addTiles(
        urlTemplate = "//{s}.tiles.mapbox.com/v3/jcheng.map-5ebohr46/{z}/{x}/{y}.png",
        attribution = 'Maps by <a href="http://www.mapbox.com/">Mapbox</a>',
        options = providerTileOptions(noWrap = TRUE)
    ) %>%
    addAwesomeMarkers(
        ~Long,
        ~Lat,
        group = "covid-19",
        label = ~lapply(latest_data$region_label, htmltools::HTML),
        icon = ~popup_icons[icon_group]
    ) %>%
    addPopupGraphs(popup_plots, group = 'covid-19', width = 300, height = 300) %>%
    addFullscreenControl(position = "topleft") %>%
    addControl(html = markerLegendHTML(popup_icons), position = "bottomright") %>%
    leafem::addHomeButton(extent(c(-130, 130, -50, 50)), 'Home', position = 'topleft') %>%
    setView(lng = 0, lat = 40, zoom = 4) %>%
    setMaxBounds(lng1 = -200, lat1 = -90, lng2 = 200, lat2 = 90)

htmlwidgets::saveWidget(
    leaflet_map,
    here::here(
        "static",
        "images",
        'leaflet-plot.html'),
    title = 'zhongjzsb\'s COVID-19 leaflet plot',
    selfcontained = FALSE,
    libdir = 'r_js')

