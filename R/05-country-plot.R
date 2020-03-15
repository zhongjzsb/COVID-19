

top20_countries <- data[
    , .(TotalCase=max(Num)), `Country/Region`
][order(-TotalCase)]$`Country/Region`[1:20]

top20_data <- country_data[
    order(match(`Country/Region`, top20_countries))
][Type!='confirmed' & `Country/Region` %in% top20_countries]

# set order from largest to smallest
top20_data[, `Country/Region`:=factor(`Country/Region`, levels = top20_countries)]

ggplot(
    top20_data, 
    aes(x = Date, y = Num, fill=Type)
) + geom_col(position = position_stack(reverse = TRUE)) + 
    theme(legend.position = 'top') +
    facet_wrap(. ~ `Country/Region`, nrow = 4, scales = "free_y") + 
    labs(title = 'Top 20 Countries')

ggsave(
    here::here('static', 'images', 'top20counties.png'),
    width = 20, height = 12, dpi = 300, units = "in"
) 
