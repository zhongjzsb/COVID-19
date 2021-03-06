# Author: Jingyu Bao
# Email: zhongjzsb@gmail.com

library(lubridate)
library(data.table)
library(stringr)
library(RCurl)

# -----------

site_link <- paste0("https://raw.githubusercontent.com/",
    "CSSEGISandData/COVID-19/",
    "master/csse_covid_19_data/",
    "csse_covid_19_time_series/"
)
# confirmed_data <- fread(getURL(paste0(site_link, "time_series_19-covid-Confirmed.csv")))
# recovered_data <- fread(getURL(paste0(site_link, "time_series_19-covid-Recovered.csv")))
# death_data <- fread(getURL(paste0(site_link, "time_series_19-covid-Deaths.csv")))
confirmed_data <- fread(getURL(paste0(site_link, "time_series_covid19_confirmed_global.csv")))
recovered_data <- fread(getURL(paste0(site_link, "time_series_covid19_recovered_global.csv")))
death_data <- fread(getURL(paste0(site_link, "time_series_covid19_deaths_global.csv")))

# remove columns with NA's
confirmed_data <- confirmed_data[
    , colSums(!is.na(confirmed_data)) == nrow(confirmed_data), with=FALSE]
recovered_data <- recovered_data[
    , colSums(!is.na(confirmed_data)) == nrow(confirmed_data), with=FALSE]
death_data <- death_data[
    , colSums(!is.na(confirmed_data)) == nrow(confirmed_data), with=FALSE]

cols <- names(recovered_data)[5:dim(recovered_data)[2]]
recovered_data[, (cols) := lapply(.SD, as.integer), .SDcols = cols]

confirmed <- melt(
    confirmed_data,
    id=1:4,
    measure=colnames(confirmed_data)[5:dim(confirmed_data)[2]],
    value.factor=TRUE,
    variable.name = "Date",
    value.name = "Num"
)
recovered <- melt(
    recovered_data,
    id=1:4,
    measure=colnames(recovered_data)[5:dim(recovered_data)[2]],
    value.factor=TRUE,
    variable.name = "Date",
    value.name = "Num"
)
death <- melt(
    death_data,
    id=1:4,
    measure=colnames(death_data)[5:dim(death_data)[2]],
    value.factor=TRUE,
    variable.name = "Date",
    value.name = "Num"
)

confirmed[, Type:='confirmed']
recovered[, Type:='recovered']
death[, Type:='death']

total_data <- rbindlist(list(confirmed, recovered, death), fill = TRUE)
total_data[is.na(Num), Num:=0]
total_data[, Date:=mdy(Date)]

total_data[`Country/Region`=='Taiwan*', `Province/State`:='Taiwan']
total_data[`Country/Region` %in% c('Mainland China', 'Taiwan*'), `Country/Region`:='China']
total_data[`Province/State` %in% c('Hong Kong', 'Macau'), `Country/Region`:='China']

# calculate current case: confirmed - death - recovered
current <- dcast(total_data, ...~Type, value.var = 'Num')
current[is.na(confirmed), confirmed := 0]
current[is.na(death), death := 0]
current[is.na(recovered), recovered := 0]
current[, `:=`(
    current=confirmed - death - recovered,
    Type='current'
)]

data <- melt(current, id=1:5, measure=6:9, variable.name = 'Type', value.name = 'Num')
data <- data[!is.na(Num) & !(`Province/State` %in% c("Recovered", "Diamond Princess"))]

# country-wise data
country_data <- data[, .(Num=sum(Num)), by=.(Type, `Country/Region`, Date)]

saveRDS(data, here::here(
    "static",
    "images",
    'covid-19-data.RDS'))
# fwrite(data, './data/data.csv')
