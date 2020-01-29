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
    geom_sf(aes(fill=log(Confirmed + 1)), data = china_map_polygon) + 
    scale_fill_gradient2(low = "white", high = "red") + 
    # scale_fill_gradientn(colors = terrain.colors(20)) + 
    transition_time(Date) +
    theme(
        plot.title=element_text(size = 40, face = "bold"),
        legend.title=element_text(size = 30), 
        legend.text=element_text(size = 30)) +
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


# Ref: 
# [1] http://boazsobrado.com/blog/2019/01/13/where-i-was-in-2018/
# [2] https://stackoverflow.com/questions/48288183/changing-ggplot-geom-sf-choropleth-fill-colors
# [3] https://github.com/globalcitizen/2019-wuhan-coronavirus-data/
# [4] https://www.r-spatial.org/r/2018/10/25/ggplot2-sf.html
# [5] https://simplemaps.com/data/cn-cities