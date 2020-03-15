

# top 20 countries ranking by total cases
top20_countries <- data[
    , .(TotalCase=max(Num)), `Country/Region`
    ][order(-TotalCase)]$`Country/Region`[1:20]

top20_data <- country_data[
    order(match(`Country/Region`, top20_countries))
    ][Type!='confirmed' & `Country/Region` %in% top20_countries]

# set order from largest to smallest
top20_data[, `Country/Region`:=factor(`Country/Region`, levels = top20_countries)]

ggplot(top20_data) + geom_col(
    aes(x = Date, y = Num, fill=Type),
    position = position_stack(reverse = TRUE)
    ) + 
    theme_gray(base_size = 20) +
    theme(legend.position = 'top') +
    facet_wrap(. ~ `Country/Region`, nrow = 4, scales = "free_y") + 
    labs(title = 'Top 20 Countries')

ggsave(
    here::here('static', 'images', 'top20countries.png'),
    width = 20, height = 12, dpi = 300, units = "in"
) 
