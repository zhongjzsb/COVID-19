# Author: Jingyu Bao
# Email: zhongjzsb@gmail.com

# load packages ---- 
library(ggplot2)
library(plotly)

# ggplotly ----
data[, IsChina:=as.factor(ifelse(`Country/Region`=='China', 'China', 'OutsideChina'))]
regional_data <- data[, .(TotalNum=sum(Num)), by=.(Type, IsChina, Date)]

p.bar <- ggplot(
    regional_data[Type!='confirmed'], 
    aes(x = Date, y = TotalNum, fill=Type)) +
    geom_col(position = position_stack(reverse = TRUE)) + 
    theme(legend.position = 'top') +
    # theme_gray(base_size = 13) +
    facet_grid(. ~ IsChina) + 
    labs(title = 'China vs Outside')
p.line.plotly <- ggplotly(p.bar)
htmlwidgets::saveWidget(
    p.line.plotly,
    here::here("static",
               "images", 
               'china-vs-outside.html'),
    background = 'grey',
    title='China vs Outside',
    selfcontained = FALSE,
    libdir = 'r_js')
