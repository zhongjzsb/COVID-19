library(DT)

wide_data <- dcast(data, ...~Type, value.var = 'Num')
latest_data <- wide_data[Date==max(Date) & confirmed!=0]

data_DT <- datatable(latest_data[, .(
    `Country/Region`,
    `Province/State`,
    Date,
    confirmed,
    current,
    death,
    recovered
)][order(-current)])

htmlwidgets::saveWidget(
    data_DT,
    here::here(
        "static",
        "images",
        'covid-19-DT.html'),
    selfcontained = FALSE,
    libdir = 'r_js')
