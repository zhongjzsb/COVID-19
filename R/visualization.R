# Author: Jingyu Bao
# Email: zhongjzsb@gmail.com

library(ggplot2)
library(leafletCN)
library(ggthemes)
library(mapdata)
library(data.table)
library(gganimate)
library(sf)

jhu_daily_data <- fread('./data/jhu_daily_data.csv')
jhu_daily_data[, Date:=as.Date(Date)]

world_cities <- fread('./data/worldcities.csv')
world_cities[city %in% c('Hong Kong', 'Macau', 'Taipei'), `:=`(country='China', capital='admin', admin_name=city)]
world_cities[city=='Taipei', admin_name:='Taiwan']
world_cities[country=='Korea, South', country:='South Korea']
world_cities[country=='United Kingdom', country:='UK']
# Singapore no admin name
world_cities[country=='Singapore', admin_name:='Singapore']
# Sri Lanka wrong capital, Ontario has two cities in primary and admin, Ivory Coast has two capitals!
world_cities <- world_cities[!(city %in% c('Colombo', 'Ottawa', 'Delhi', 'Abidjan'))]



# world_cities[, .SD[1], by=.(country, admin_name)]

# -------------------
# Plot Cases in China

china_cities <- world_cities[country=='China' & (capital=='primary' | capital=='admin'), ]

head(china_cities)

jhu_daily_data_china <- jhu_daily_data[`Country/Region`=='China', ][china_cities, on=.(`Province/State`=admin_name)]
jhu_daily_data_china[, .N, by=.(`Province/State`, Date)]
setorder(jhu_daily_data_china, Date, `Country/Region`, `Province/State`)

china_map_dt = data.frame(regionNames("china"),
                          value=c(1:34))
china_map = leafletGeo("china", china_map_dt)
china_map_sf <- st_as_sf(china_map)
jhu_china_ggplot <- ggplot(data = china_map_sf) +
    geom_sf() +
    geom_point(aes(x = lng, y = lat, size=Confirmed),
               data = jhu_daily_data_china,
               colour = 'purple', alpha = .5
    ) +
    scale_size_continuous(range = c(0, 60)) + 
    theme(
        plot.title=element_text(size = 40, face = "bold"),
        legend.title=element_text(size = 30), 
        legend.text=element_text(size = 30)) + 
    transition_time(Date) +
    labs(title = 'Day: {frame_time}')

jhu_animate_china <- animate(
    jhu_china_ggplot, 
    width = 1500,
    height = 1500,
    fps = 1,
    nframes=length(unique(jhu_daily_data_china$Date))
    # nframes=24
)
anim_save("./figures/jhu_animate_china.gif", jhu_animate_china)

# map fill plot 
# inspired from [3]
ChineseProvinceNames <- fread('./data/ChineseProvinceNames.csv', encoding = 'UTF-8')

setkey(ChineseProvinceNames, pinyin)
setkey(jhu_daily_data_china, 'Province/State')

china_map_polygon_list <- list()
for (i_date in unique(jhu_daily_data_china$Date)){
    i_table <- jhu_daily_data_china[Date==i_date, ]
    # i_map <- china_map_sf
    # i_map$Date <- i_date
    i_map <- i_table[ChineseProvinceNames, on=.(`Province/State`=pinyin)]
    i_map[is.na(Confirmed), Confirmed:=0]
    i_map[is.na(Deaths), Deaths:=0]
    i_map[is.na(Recovered), Recovered:=0]
    i_map[is.na(Suspected), Suspected:=0]
    i_map <- merge(china_map_sf, i_map, by='label', all.x=TRUE)
    i_map$Date <- as.Date(i_date, origin = '1970-01-01')
    china_map_polygon_list[[as.character(i_date)]] <- i_map
}
china_map_polygon <- do.call("rbind", china_map_polygon_list)

jhu_china_polygon <- ggplot() +
    geom_sf(aes(fill=Confirmed + 1), data = china_map_polygon) + 
    scale_fill_gradient2(
        low = "white", 
        mid = "red",
        high = "black",
        midpoint = 2,
        trans = "log10", 
        breaks = c(1,10,100,1000), 
        labels = c(1,10,100,1000)) + 
    # scale_fill_gradientn(colors = terrain.colors(20)) + 
    transition_time(Date) +
    theme(
        plot.title=element_text(size = 40, face = "bold"),
        legend.title=element_text(size = 20), 
        legend.text=element_text(size = 20),
        ) +
    labs(title = 'Day: {frame_time}', fill = 'Confirmed')
jhu_china_polygon_animate <- animate(
    jhu_china_polygon, 
    width = 2000,
    height = 1500,
    fps = 2,
    # nframes=length(unique(jhu_daily_data_china$Date))
    nframes=24
)
anim_save("./figures/jhu_china_polygon_animate.gif", jhu_china_polygon_animate)


# -----------------------
# Plot Cases in the world

world_captitals <- jhu_daily_data[world_cities[capital=='primary'], on=.(`Country/Region`=country)][`Province/State`==''][, .(Date, `Country/Region`, `Province/State`, capital, admin_name, city, lng, lat)][capital=='primary', .N, by=.(`Country/Region`, admin_name, city)]

jhu_daily_data[`Province/State`=='', `Province/State`:=world_captitals[jhu_daily_data[`Province/State`=='',], on=.(`Country/Region`)]$admin_name]

jhu_daily_data_world <- world_cities[capital=='primary' | capital=='admin'][jhu_daily_data, on=.(admin_name=`Province/State`, country=`Country/Region`)]

# Check consistency
# jhu_daily_data_world[, .N, country][order(country)]
# jhu_daily_data[, .N, `Country/Region`][order(`Country/Region`)]
# dim(jhu_daily_data)
# dim(jhu_daily_data_world)
# jhu_daily_data_world[country=='India']
# jhu_daily_data[`Country/Region`=='India']

jhu_daily_data_world[, Confirmed_Group := (cut(
    Confirmed, 
    breaks = c(0, 3, 10, 100, 1000), 
    labels = c('(0, 3)', '(3, 10)', '(10, 100)', '(100, Inf)')
))]
jhu_daily_data_world[, Confirmed_Value := as.numeric(Confirmed_Group)]
jhu_daily_data_world <- jhu_daily_data_world[!is.na(Confirmed_Group)]

# colSums(is.na(jhu_daily_data_world))
# jhu_daily_data_world[is.na(city)]
# jhu_daily_data_world[country=='Ivory Coast']

world_map_dt = data.frame(regionNames("world"),
                          value=c(1:length(regionNames("world"))))
world_map = leafletGeo("world", world_map_dt)
world_map_sf <- st_as_sf(world_map)
jhu_world_ggplot <- ggplot(data = world_map_sf) +
    geom_sf() +
    geom_point(aes(x = lng, y = lat, size=Confirmed_Value),
               data = jhu_daily_data_world,
               color='red', alpha = .5
    ) +
    scale_size_continuous(
        name = "Confirmed",
        range = c(5, 12), 
        breaks = c(1:4), 
        labels = c('(0, 3)', '(3, 10)', '(10, 100)', '(100, Inf)')) + 
    theme(
        plot.title=element_text(size = 40, face = "bold"),
        legend.title=element_text(size = 30),
        legend.text=element_text(size = 30),
        legend.position = 'right') + 
    transition_time(Date) +
    labs(title = 'Day: {frame_time}')

jhu_animate_world <- animate(
    jhu_world_ggplot, 
    width = 1500,
    height = 1500,
    fps = 1,
    nframes=length(unique(jhu_daily_data_world$Date))
    # nframes=24
)
anim_save("./figures/jhu_animate_world.gif", jhu_animate_world)

