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

# Plot parameters -----
plot_breaks <- c(1, 10, 100, 1000, 10000)
plot_labels <- c('1', '10', '100', '1000', '10000')

plot_regions <- c('china', 'world')
plot_types <- c('confirmed', 'current')
plot_titles <- c(
    'Number of Cumulative Confirmed Cases',
    'Number of Current Remaining Cases'
)

plot_matrix <- as.data.table(expand.grid(
    Region=plot_regions, 
    Type=plot_types
))
for (i in c(1:length(plot_types))) {
    plot_matrix[Type==plot_types[i], Title:=plot_titles[i]]
}
plot_matrix[, FigName:=paste(Region, Type, sep='_')]

# -------------------
# Plot Cases

for (i_plot in c(1:dim(plot_matrix)[1])) {
    
    plot_region <- plot_matrix$Region[i_plot]
    plot_title <- plot_matrix$Title[i_plot]
    plot_type <- plot_matrix$Type[i_plot]
    plot_figname <- plot_matrix$FigName[i_plot]
    
    if (plot_region != 'world') {
        plot_data <- data[
            toupper(`Country/Region`)==toupper(plot_region) & Type==plot_type, 
        ]
    } else {
        plot_data <- data[Type==plot_type, ]
    }
    
    setorder(plot_data, Date, `Country/Region`, `Province/State`)
    
    if (plot_region %in% c('china', 'world')) {
        region_names <- regionNames(plot_region)
        map_dt <- data.frame(region_names,
                             value=length(region_names))
        map <- leafletGeo(plot_region, map_dt)
        map_sf <- st_as_sf(map)
    } else if (plot_region == 'us') {
        map_sf <- st_as_sf(map('state', plot = FALSE, fill = TRUE))    
    } else {
        map_sf <- st_as_sf(map(as.character(plot_region), plot = FALSE, fill = TRUE))
    }

    p_ggplot <- ggplot(data = map_sf) +
        geom_sf() +
        geom_point(aes(x = Long, y = Lat, size = Num),
                   data = plot_data,
                   colour = 'red', alpha = .5
        ) +
        scale_size_continuous(
            range = c(0, 30),
            breaks = plot_breaks, 
            labels = plot_labels,
            trans = "log"
        ) + 
        theme(
            plot.title=element_text(size = 40, face = "bold"),
            legend.title=element_text(size = 30), 
            legend.text=element_text(size = 30)) + 
        transition_time(Date) +
        labs(title = paste0(plot_title, ' on {frame_time}'))
    
    animate <- animate(
        p_ggplot, 
        width = 1500,
        height = 1500,
        fps = 2,
        nframes=length(unique(plot_data$Date))
    )
    anim_save(here::here(
        "figures", 
        paste0(plot_figname,".gif")
    ), animate)
}

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


## plotly ----------

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
