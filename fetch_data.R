# Author: Jingyu Bao
# Email: zhongjzsb@gmail.com

library(lubridate)
library(data.table)
library(googlesheets4)
library(stringr)

Sys.setlocale(category="LC_ALL",locale="chinese")
# library(magick)
# jhu_url <- "https://docs.google.com/spreadsheets/d/169AP3oaJZSMTquxtrkgFYMSp4gTApLTTWqo25qCpjL0/htmlview?usp=sharing&sle=true#"
sheets_auth('zhongjzsb@gmail.com')
jhu_url <- 'https://docs.google.com/spreadsheets/d/1yZv9w9zRKwrGTaR-YzmAqMefw4wMlaXocejdxZaTs6w/htmlview?usp=sharing&sle=true#'
jhu_allsheets <- sheets_get(jhu_url)
jhu_sheetnames <- jhu_allsheets$sheets$name

jhu_data_list <- list()
jhu_data_list
for (i_name in jhu_sheetnames) {
    i_sheet <- as.data.table(read_sheet(jhu_url, sheet = i_name))
    setnames(i_sheet, 'Country', 'Country/Region', skip_absent = TRUE)
    setnames(i_sheet, 'Date last updated', 'Last Update', skip_absent = TRUE)
    
    if (i_name == 'Jan25_12pm') {
        i_name = 'Jan25_06pm'
    }
    i_string <- strsplit(i_name, '_')[[1]]
    i_day <- regmatches(i_string[1], gregexpr('[0-9]+', i_string[1]))[[1]]
    i_month <- regmatches(i_string[1], gregexpr('[a-zA-Z]+', i_string[1]))[[1]]
    i_time <- regmatches(i_string[2], gregexpr('[0-9]+', i_string[2]))[[1]]
    i_am <- regmatches(i_string[2], gregexpr('[a-z]+', i_string[2]))[[1]]
    
    if (nchar(i_time) >= 3){
        i_datetime <- mdy_hm(paste0(i_month, ' ', i_day, ' 2020, ', str_sub(i_time, end = 1), ':', str_sub(i_time, start= -2)), tz='EST')
    } else  {
        i_datetime <- mdy_hm(paste0(i_month, ' ', i_day, ' 2020, ', i_time, ':00'), tz = 'EST')
    }
    if (i_am == 'pm') {
        i_datetime <- i_datetime + hours(12)
    }
    
    i_sheet[, DateTime:=i_datetime]
    jhu_data_list[[i_name]] <- i_sheet    
    
}

jhu_data <- rbindlist(jhu_data_list, fill = TRUE)
head(jhu_data)
jhu_data[, Date:=as.Date(DateTime)]
jhu_data[is.na(Confirmed), Confirmed:=0]
jhu_data[is.na(Deaths), Deaths:=0]
jhu_data[is.na(Recovered), Recovered:=0]
jhu_data[is.na(Suspected), Suspected:=0]
jhu_data[`Country/Region`=='Mainland China', `Country/Region`:='China']
jhu_data[`Province/State` %in% c('Hong Kong', 'Macau', 'Taiwan'), `Country/Region`:='China']
jhu_data[`Country/Region`=='US', `Country/Region`:='United States']
jhu_data[, .(.N),`Country/Region`]
jhu_data[, lapply(.SD, sum), c('Date', 'Country/Region'), .SDcols=c('Confirmed', 'Deaths', 'Recovered', 'Suspected')]

setorder(jhu_data, Date, `Country/Region`, `Province/State`)

# Here we use max number in the day, it's not ideal but reasonable.
jhu_daily_data <- jhu_data[, lapply(.SD, max), by=c('Date', 'Country/Region', 'Province/State'),.SDcols=c('Confirmed', 'Deaths', 'Recovered', 'Suspected')]

fwrite(jhu_daily_data, './data/jhu_daily_data.csv')


# Ref: [1] http://boazsobrado.com/blog/2019/01/13/where-i-was-in-2018/
