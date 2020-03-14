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

# fetch data ---------
source(here::here('R', '01-fetch-data.R'))

# -------------------
# Plot Cases in China

china_data <- data[`Country/Region`=='China' & Type=='confirmed', ]
# china_data[, .N, by=.(`Province/State`, Date)]
setorder(china_data, Date, `Country/Region`, `Province/State`)

china_map_dt = data.frame(regionNames("china"),
                          value=c(1:34))
china_map = leafletGeo("china", china_map_dt)
china_map_sf <- st_as_sf(china_map)
china_ggplot <- ggplot(data = china_map_sf) +
    geom_sf() +
    geom_point(aes(x = Long, y = Lat, size=Num),
               data = china_data,
               colour = 'purple', alpha = .5
    ) +
    scale_size_continuous(range = c(0, 60)) + 
    theme(
        plot.title=element_text(size = 40, face = "bold"),
        legend.title=element_text(size = 30), 
        legend.text=element_text(size = 30)) + 
    transition_time(Date) +
    labs(title = 'Number of Cumulative Confirmed Case on {frame_time}')

animate_china <- animate(
    china_ggplot, 
    width = 1500,
    height = 1500,
    fps = 2,
    nframes=length(unique(china_data$Date))
    # nframes=24
)
anim_save(here::here("figures", "animate_china.gif"), animate_china)

# -----------------------
# Plot Cases in the world

world_data <- data[Type=='confirmed', ]
world_data[, Confirmed_Group := (cut(
    Num, 
    breaks = c(0, 10, 100, 1000, 10000), 
    labels = c('(0, 10)', '(10, 100)', '(100, 1000)', '(1000, Inf)')
))]
world_data[, Confirmed_Value := as.numeric(Confirmed_Group)]

world_map_dt = data.frame(regionNames("world"),
                          value=c(1:length(regionNames("world"))))
world_map = leafletGeo("world", world_map_dt)
world_map_sf <- st_as_sf(world_map)
world_ggplot <- ggplot(data = world_map_sf) +
    geom_sf() +
    geom_point(aes(x = Long, y = Lat, size=Confirmed_Value),
               data = world_data,
               color='red', alpha = .5
    ) +
    scale_size_continuous(
        name = "Confirmed",
        range = c(5, 12), 
        breaks = c(1: 4), 
        labels = c('(0, 10)', '(10, 100)', '(100, 1000)', '(1000, Inf)')) + 
    theme(
        plot.title=element_text(size = 40, face = "bold"),
        legend.title=element_text(size = 30),
        legend.text=element_text(size = 30),
        legend.position = 'right') + 
    transition_time(Date) +
    labs(title = 'Number of Cumulative Confirmed Case on {frame_time}')

animate_world <- animate(
    world_ggplot, 
    width = 1500,
    height = 1500,
    fps = 2,
    nframes=length(unique(world_data$Date))
    # nframes=24
)
anim_save(here::here("figures", "animate_world.gif"), animate_world)


# map fill plot 
ChineseProvinceNames <- fread(here::here('data', 'ChineseProvinceNames.csv'), encoding = 'UTF-8')

china_map_polygon_list <- list()
for (i_date in unique(china_data$Date)){
    i_table <- china_data[Date==i_date, ]
    # i_map <- china_map_sf
    # i_map$Date <- i_date
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
    # scale_fill_gradientn(colors = terrain.colors(20)) + 
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
    # nframes=24
)
anim_save(here("figures", "china_polygon_animate.gif"), china_polygon_animate)


## plotly

# library(plotly)
# gg <- ggplot(china_data, aes(Long, Lat, color = 'red', frame = Date, ids = `Province/State`)) +
#     geom_point(aes(size = Num))
# ggplotly(gg)
# 
# china_ggplotly <- ggplot(data = china_map_sf, frame=Date) +
#     geom_sf() +
#     geom_point(aes(x = Long, y = Lat, size=Num),
#                data = china_data,
#                colour = 'purple', alpha = .5
#     )
# ggplotly(china_ggplot)
