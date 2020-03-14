# some analysis

head(data)

data[, sum(Num),`Country/Region`][order(`Country/Region`)]
data[, sum(Num),`Province/State`][order(`Province/State`)]
china_data <- data[`Country/Region`=='China', .(TotalNum=sum(Num)), .(Time, Type)]
china_data[Type=='death', .(TotalNum)] / china_data[Type=='confirmed', .(TotalNum)]
sum_data <- dcast(china_data, Time~Type, value.var='TotalNum')
sum_data[, DeathRatio:=death/confirmed]