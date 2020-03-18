library(leaflet)
library(dplyr)
library(leafpop)
library(sf)
library(ggplot2)
library(htmltools)
library(leaflet.extras)

wide_data <- dcast(data, ...~Type, value.var = 'Num')
latest_data <- wide_data[Date==max(Date)]

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
            sprintf("#Confirmed: %s   ", i_record$confirmed), 
            sprintf("#Current: %s", i_record$current), '\n',
            sprintf("#Death: %s   ", i_record$death),
            sprintf("#Recovered: %s", i_record$recovered)
        ))
}

# data_sf <- st_as_sf(latest_data, coords = c('Long', 'Lat'))
# Create the map
leaflet_map <- latest_data %>%
    leaflet() %>%
    addTiles(
        urlTemplate = "//{s}.tiles.mapbox.com/v3/jcheng.map-5ebohr46/{z}/{x}/{y}.png",
        attribution = 'Maps by <a href="http://www.mapbox.com/">Mapbox</a>'
    ) %>%
    addMarkers(
        ~Long, 
        ~Lat, 
        group = "covid-19",
        # popup = popupTable(
        #     data_sf,
        #     zcol = c('Province/State', 'Country/Region', 'confirmed', 
        #              'current', 'death', 'recovered'))
    ) %>%
    addLogo(
        "https://i.imgur.com/N3jsUbD.png", 
        url = 'https://i.imgur.com/N3jsUbD.png',
        position = "bottomleft",
        offset.x = 5,
        offset.y = 40,
        width = 100,
        height = 100
    ) %>% 
    addPopupGraphs(popup_plots, group = 'covid-19') %>%
    addFullscreenControl() %>%
    addHomeButton(extent(c(-170, 170, -70, 70)), 'Home') %>%
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
