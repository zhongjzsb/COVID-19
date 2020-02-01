library(plotly)
library(MASS)

covmat <- matrix(c(0.8, 0.4, 0.3, 0.8), nrow = 2, byrow = T)
df <- mvrnorm(n = 10000, c(0,0), Sigma = covmat)
df <- as.data.frame(df)

colnames(df) <- c("x", "y")
p <- plot_ly(df, x = ~x, y = ~y, alpha = 0.3) %>%
    add_markers(marker = list(line = list(color = "black", width = 1))) %>%
    layout(
        title = "Drop down menus - Plot type",
        xaxis = list(domain = c(0.1, 1)),
        yaxis = list(title = "y"),
        updatemenus = list(
            list(
                y = 0.8,
                buttons = list(
                    list(method = "restyle",
                         args = list("type", "scatter"),
                         label = "Scatter"),
                    
                    list(method = "restyle",
                         args = list("type", "histogram2d"),
                         label = "2D Histogram")))
        ))

p


require(plotly)
df <- data.frame(x = runif(200), y = runif(200), z = runif(200))
p <- plot_ly(df, x = ~x, y = ~y, mode = "markers", name = "A", visible = T) %>%
    layout(
        title = "Drop down menus - Styling",
        xaxis = list(domain = c(0.1, 1)),
        yaxis = list(title = "y"),
        updatemenus = list(
            list(
                y = 0.7,
                buttons = list(
                    list(method = "restyle",
                         args = list("y", list(df$y)),  # put it in a list
                         label = "Show A"),
                    list(method = "restyle",
                         args = list("y", list(df$z)),  # put it in a list
                         label = "Show B")))
        ))
p

