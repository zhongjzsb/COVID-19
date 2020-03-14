# Author: Jingyu Bao
# Email: zhongjzsb@gmail.com

# load packages ---- 
library(ggplot2)
library(plotly)

# ggplotly ----
data[, IsChina:=as.factor(ifelse(`Country/Region`=='China', 'China', 'OutsideChina'))]

regional_data <- data[, .(TotalNum=sum(Num)), by=.(Type, IsChina, Date)]
p.line <- ggplot(regional_data, aes(x = Date, y = TotalNum, col=Type)) +
    geom_line() + facet_grid(. ~ IsChina)
p.line.plotly <- ggplotly(p.line)
htmlwidgets::saveWidget(
    p.line.plotly,
    here::here('figures', 'china-vs-outside.html'),
    selfcontained = TRUE,
    background = 'grey',
    title='China vs Outside')



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
