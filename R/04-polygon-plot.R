# Author: Jingyu Bao
# Email: zhongjzsb@gmail.com

# load packages ---- 
library(ggplot2)
library(leafletCN)
library(ggthemes)
library(mapdata)
library(data.table)
library(gganimate)
library(sf)
library(here)
library(stringr)

# fetch data ---------
source(here::here('R', '01-fetch-data.R'))

# Alternative plots ------------
# map fill plot 
china_data <- data[
    `Country/Region`=='China' & Type=='confirmed', 
    ]
region_names <- regionNames('china')
map_dt <- data.frame(region_names,
                     value=length(region_names))
china_map <- leafletGeo('china', map_dt)
china_map_sf <- st_as_sf(china_map)

ChineseProvinceNames <- fread(here::here('data', 'ChineseProvinceNames.csv'), encoding = 'UTF-8')

china_map_polygon_list <- list()
for (i_date in unique(china_data$Date)){
    i_table <- china_data[Date==i_date, ]
    i_map <- i_table[ChineseProvinceNames, on=.(`Province/State`=pinyin)]
    i_map <- merge(china_map_sf, i_map, by='label', all.x=TRUE)
    i_map$Date <- as.Date(i_date, origin = '1970-01-01')
    china_map_polygon_list[[as.character(i_date)]] <- i_map
}
china_map_polygon <- do.call("rbind", china_map_polygon_list)

china_polygon <- ggplot() +
    geom_sf(aes(fill=Num + 1), data = china_map_polygon) + 
    scale_fill_gradient2(
        low = "white", 
        mid = "red",
        high = "black",
        midpoint = 2,
        trans = "log10", 
        breaks = c(1,10,100,1000, 10000), 
        labels = c(1,10,100,1000, 10000)) + 
    transition_time(Date) +
    theme(
        plot.title=element_text(size = 40, face = "bold"),
        legend.title=element_text(size = 20), 
        legend.text=element_text(size = 20),
    ) +
    labs(title = 'Number of Cumulative Confirmed Case on {frame_time}', fill = 'Confirmed')
china_polygon_animate <- animate(
    china_polygon, 
    width = 2000,
    height = 1500,
    fps = 2,
    nframes=length(unique(china_data$Date))
)
anim_save(here::here("figures", "china_polygon_confirmed.gif"), china_polygon_animate)