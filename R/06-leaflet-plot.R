library(leaflet)
library(dplyr)
library(leafpop)
library(sf)
library(ggplot2)
library(htmltools)
library(leafem)
library(leaflet.extras)
library(raster)
library(mapview)

# glyphicon: glyphicon glyphicon-asterisk glyphicon glyphicon-globe

popup_icons <- awesomeIconList(
    lvl1 = makeAwesomeIcon(icon='stats', library='glyphicon', markerColor = 'lightblue'),
    lvl2 = makeAwesomeIcon(icon='stats', library='glyphicon', markerColor = 'orange'),
    lvl3 = makeAwesomeIcon(icon='stats', library='glyphicon', markerColor = 'red'),
    lvl4 = makeAwesomeIcon(icon='stats', library='glyphicon', markerColor = 'black')
)

wide_data <- dcast(data, ...~Type, value.var = 'Num')
latest_data <- wide_data[Date==max(Date) & confirmed!=0]
latest_data[, icon_group:=cut(
    latest_data$current, 
    breaks=c(-1, 10, 100, 1000, 1000000), 
    labels=c('lvl1', 'lvl2', 'lvl3', 'lvl4')
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
            i_record$`Country/Region`, '   ---', i_record$`Province/State`, '\n',
            sprintf("Date: %s", i_record$Date), '\n',
            sprintf("#Confirmed: %s   ", i_record$confirmed),
            sprintf("#Current: %s", i_record$current), '\n',
            sprintf("#Death: %s   ", i_record$death),
            sprintf("#Recovered: %s", i_record$recovered)
        ))
}

# Create the map
leaflet_map <- latest_data %>%
    leaflet() %>%
    addTiles(
        urlTemplate = "//{s}.tiles.mapbox.com/v3/jcheng.map-5ebohr46/{z}/{x}/{y}.png",
        attribution = 'Maps by <a href="http://www.mapbox.com/">Mapbox</a>'
    ) %>%
    addAwesomeMarkers(
        ~Long,
        ~Lat,
        group = "covid-19",
        label = ~`Country/Region`,
        icon = ~popup_icons[icon_group]
    ) %>%
    addPopupGraphs(popup_plots, group = 'covid-19') %>%
    addFullscreenControl(position = "topleft") %>%
    leafem::addHomeButton(extent(c(-130, 130, -50, 50)), 'Home', position = 'topleft') %>%
    setView(lng = 0, lat = 40, zoom = 2)
leaflet_map
htmlwidgets::saveWidget(
    leaflet_map,
    here::here(
        "static",
        "images",
        'leaflet-plot.html'),
    selfcontained = FALSE,
    libdir = 'r_js')
