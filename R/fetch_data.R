# Author: Jingyu Bao
# Email: zhongjzsb@gmail.com

library(lubridate)
library(data.table)
library(googlesheets4)
library(stringr)
library(RCurl)

Sys.setlocale(category="LC_ALL",locale="chinese")

# ----------
# This google sheet no longer updates
# 
# sheets_auth('zhongjzsb@gmail.com')
# jhu_url <- 'https://docs.google.com/spreadsheets/d/1UF2pSkFTURko2OvfHWWlFpDFAr1UxCBA4JLwlSP6KFo/edit#gid=0'
# jhu_allsheets <- sheets_get(jhu_url)
# jhu_sheetnames <- jhu_allsheets$sheets$name
# 
# confirmed_data <- as.data.table(read_sheet(jhu_url, sheet = 'Confirmed'))
# recovered_data <- as.data.table(read_sheet(jhu_url, sheet = 'Recovered'))
# death_data <- as.data.table(read_sheet(jhu_url, sheet = 'Death'))
# death_data[, `1/21/2020 10:00 PM`:=as.numeric(`1/21/2020 10:00 PM`)]
# death_data[, `1/22/2020 12:00 PM`:=as.numeric(`1/22/2020 12:00 PM`)]
# death_data[, `1/23/2020 12:00 PM`:=as.numeric(`1/23/2020 12:00 PM`)]
# setnames(confirmed_data, 'First confirmed date in country (Est.)', 'First confirmed date in country')
# -----------

confirmed_data <- fread(getURL("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_19-covid-Confirmed.csv"))
recovered_data <- fread(getURL("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_19-covid-Recovered.csv"))
death_data <- fread(getURL("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_19-covid-Deaths.csv"))

# Ref: https://stackoverflow.com/questions/32940580/convert-some-column-classes-in-data-table
cols <- names(recovered_data)[5:dim(recovered_data)[2]]
recovered_data[, (cols) := lapply(.SD, as.integer), .SDcols = cols]

# for (col in cols) set(dat, j = col, value = as.integer(dat[[col]]))
# for (col in cols) dat[, (col) := as.integer(dat[[col]])]

# head(confirmed_data)
confirmed <- melt(confirmed_data, id=1:4, measure=colnames(confirmed_data)[5:dim(confirmed_data)[2]], value.factor=TRUE, variable.name = "Date", value.name = "Num")
recovered <- melt(recovered_data, id=1:4, measure=colnames(recovered_data)[5:dim(recovered_data)[2]], value.factor=TRUE, variable.name = "Date", value.name = "Num")
death <- melt(death_data, id=1:4, measure=colnames(death_data)[5:dim(death_data)[2]], value.factor=TRUE, variable.name = "Date", value.name = "Num")

confirmed[, Type:='confirmed']
recovered[, Type:='recovered']
death[, Type:='death']

data <- rbindlist(list(confirmed, recovered, death), fill = TRUE)
data[is.na(Num), Num:=0]
# data[, Time:=mdy_hm(Time)]
data[, Date:=mdy(Date)]

data[`Country/Region`=='Mainland China', `Country/Region`:='China']
data[`Province/State` %in% c('Hong Kong', 'Macau', 'Taiwan'), `Country/Region`:='China']

# Here we use max number in the day, it's not ideal but reasonable.
# daily_data <- data[, .(Num=max(Num)), by=c('Date', 'Type', 'Country/Region', 'Province/State')]

saveRDS(data, './data/data.RDS')
fwrite(data, './data/data.csv')
# saveRDS(daily_data, './data/daily_data.RDS')
# fwrite(daily_data, './data/daily_data.csv')

# Ref: [1] http://boazsobrado.com/blog/2019/01/13/where-i-was-in-2018/

# some analysis

head(data)

data[, sum(Num),`Country/Region`][order(`Country/Region`)]
data[, sum(Num),`Province/State`][order(`Province/State`)]
china_data <- data[`Country/Region`=='China', .(TotalNum=sum(Num)), .(Time, Type)]
china_data[Type=='death', .(TotalNum)] / china_data[Type=='confirmed', .(TotalNum)]
sum_data <- dcast(china_data, Time~Type, value.var='TotalNum')
sum_data[, DeathRatio:=death/confirmed]

