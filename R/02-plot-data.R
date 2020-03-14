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
        width = 1600,
        height = 900,
        fps = 2,
        nframes=length(unique(plot_data$Date))
    )
    anim_save(here::here(
        "static",
        "images", 
        paste0(plot_figname,".gif")
    ), animate)
}


