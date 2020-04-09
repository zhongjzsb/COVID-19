library(DT)
library(countrycode)

wide_data <- dcast(
    country_data[Date==max(Date),], ...~Type, value.var = 'Num'
)[order(-current)]
latest_data <- dcast(
    country_data[Date==max(Date),], ...~Type, value.var = 'Num'
)[, `:=`(
    Ctry=countrycode(
        `Country/Region`, 'country.name', 'iso3c', warn=FALSE, nomatch = NULL
    ),
    Cur=current,
    D=death,
    Rec=recovered
)][, .(
    Ctry,
    Cur,
    D,
    Rec
)][order(-Cur)]

latest_data_DT_mobile <- datatable(
    latest_data,
    width = 250,
    height = 400,
    rownames = FALSE,
    options = list(pageLength=5)
)

latest_data_DT <- datatable(
    wide_data,
    width = 800,
    height = 400,
    rownames = FALSE,
    options = list(pageLength=10)
)

htmlwidgets::saveWidget(
    latest_data_DT,
    here::here(
        "static",
        "images",
        'covid-19-DT.html'),
    selfcontained = FALSE,
    libdir = 'r_js')

htmlwidgets::saveWidget(
    latest_data_DT_mobile,
    here::here(
        "static",
        "images",
        'covid-19-DT-mobile.html'),
    selfcontained = FALSE,
    libdir = 'r_js')

saveRDS(
    latest_data_DT,
    here::here(
        "static",
        "images",
        'covid-19-DT.RDS'))
# writeLines(format_table(latest_data[1:20], format = 'html'),
#            here::here(
#                "static",
#                "images",
#                'covid-19-DT.txt'))


