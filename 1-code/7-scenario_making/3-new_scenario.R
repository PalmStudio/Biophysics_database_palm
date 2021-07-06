# -------------------------------------------------------------------------###
### script to make Ecotron Scenario from SMSE climate data
# -------------------------------------------------------------------------###

# Load packages -----------------------------------------------------------

packs <- c("lubridate", "ggplot2",'dplyr',"tidyr","bigleaf","stringr")
InstIfNec<-function (pack) {
  if (!do.call(require,as.list(pack))) {
    do.call(install.packages,as.list(pack))  }
  do.call(require,as.list(pack)) }
lapply(packs, InstIfNec)

# Source functions

source("1-code/7-scenario_making/2-gaussian_helper_scenario.R")

# Import meteo data -------------------------------------------------------------

# Conversion factor J.cm-2 --> W.m-2
conv0 = 10000/3600
# Conversion factor W m-2 h-1 --> umol m-2 s-1 of PAR
conv1 = 0.48*4.6

don =
  data.table::fread(file = './0-data/0-raw/smse/Meteo_hour_SMSE.csv',sep=';',dec='.')%>%
  mutate(
    Date = dmy(Date),
    Time = as.POSIXct(x = Time, format = '%H:%M'),
    Year = year(Date),
    Month = as.factor(month.abb[month(Date)]),
    VPD = bigleaf::rH.to.VPD(HR / 100 ,Temp,"Allen_1998"),
    RG_Wm2 = `RG_J.cm-2` * conv0,
    PAR = RG_Wm2 * conv1)

levels(don$Month)=list("Jan"="Jan","Feb"="Feb","Mar"='Mar','Apr'="Apr",'May'='May',
                       'Jun'='Jun','Jul'='Jul','Aug'='Aug','Sep'='Sep','Oct'='Oct',
                       'Nov'='Nov','Dec'='Dec')

# Remove errors recorded

don =
  don%>%
  filter(!(Month %in% c('Dec') & Year==2014) & 
           !(Month %in% c('Jan','Feb','Mar','Apr','May','Dec') & Year==2015) &
           !(Month %in% c('Jan','Feb','Mar','Apr','May','Jun','Jul') & Year==2016))%>%
  select(Date,Time,Temp,HR,PAR,VPD)

# Select a particularly cloudy day (take the day with minimum of daily max value for PAR):

PAR_day_cloudy=
  don%>%
  group_by(Date)%>%
  summarise(PAR = max(PAR))%>%
  filter(PAR == min(PAR))%>%
  pull(PAR)

# Select a standard day (using the median radiation):

days_median=
  don%>%
  group_by(Date)%>%
  summarise(PAR_max = max(PAR))%>%
  filter(PAR_max == median(PAR_max))%>%
  pull(Date)

day_median = 
  don%>%
  filter(Date %in% days_median)%>%
  group_by(Time)%>%
  summarise_if(is.numeric,median)

# Plotting for all days_median days the values of their variables, and the median value again (in red):

day_median_plot = 
  don%>%
  filter(Date %in% days_median)%>%
  gather(key = 'var',value='value',Temp,HR,PAR,VPD)%>%
  ggplot(aes(x = Time, y = value))+
  facet_wrap(.~var, scales = "free_y")+
  geom_line(aes(group = Date, color = Date))+
  geom_line(data = day_median %>% gather(key = 'var',value='value',Temp,HR,PAR,VPD), color = "red", lwd = 2)

day_median_plot

# Adjusting a dynamic using a gaussian on daily hours only:

pic_value = 13 # Hour at which we get pic value 

sigmas = 
  day_median%>%
  mutate(Hour = hour(Time))%>%
  filter(Hour>=6 & Hour<=18)%>%
  {
    param_Temp = summary(fit_gaussian(.$Hour,.$Temp,pic_value,k = max(.$Temp)))$parameters[,"Estimate"]
    param_PAR = summary(fit_gaussian(.$Hour,.$PAR,11,k = max(.$PAR)))$parameters[,"Estimate"]
    param_VPD = summary(fit_gaussian(.$Hour,.$VPD,pic_value,k = max(.$VPD)))$parameters[,"Estimate"]
    param_HR = summary(fit_gaussian(.$Hour,.$HR,pic_value,k = max(.$HR)))$parameters[,"Estimate"]
    list(Temp = param_Temp, PAR = param_PAR, VPD = param_VPD, HR = param_HR)
  }

ref_day = 
  day_median%>%
  mutate(Hour = hour(Time))%>%
  # filter(Hour>=6 & Hour<=20)%>%
  mutate(Temp = gaussian_fn(x = Hour, mu = pic_value, sigma = sigmas$Temp, k = max(Temp)),
         PAR = gaussian_fn(x = Hour, mu = pic_value, sigma = sigmas$PAR, k = max(PAR)),
         VPD = gaussian_fn(x = Hour, mu = pic_value, sigma = sigmas$VPD, k = max(VPD)),
         HR = bigleaf::VPD.to.rH(VPD,Temp,"Allen_1998")*100)

# Plotting the result (proposed points in green):
day_median_plot + 
  geom_line(data = ref_day %>% gather(key = 'var',value='value',Temp,HR,PAR,VPD), color = "green", lwd = 2)

# NB: note that we shift the max value of PAR at pic_value instead of ~11h because it is more
# practical (we can start later in the morning). We also used the same dynamic for all 
# variables to get the extreme values at the same time.

# Adjusting variables to more practical values ---------------------------------

# RH: we want to avoid dew formation in the chamber.
any(ref_day$Temp - bigleaf::dew.point(Tair = ref_day$Temp, ref_day$VPD) <= 0.0)
# FALSE here, but we saw due formation in the chamber... Still avoiding high RH:

max_RH_chamber = 85 # In %

# Updating the new RH by removing highest values:

ref_day$HR[ref_day$HR > max_RH_chamber] = max_RH_chamber

# Tair: we don't want values below the median measurement:
ref_day$Temp[ref_day$Temp < min(day_median$Temp)] = min(day_median$Temp)

# Recompute VPD accordingly:
ref_day$VPD = bigleaf::rH.to.VPD(ref_day$HR/100, ref_day$Temp, Esat.formula = "Allen_1998")

# Plotting the result (proposed points in green):
day_median_plot + 
  geom_line(data = ref_day %>% gather(key = 'var',value='value',Temp,HR,PAR,VPD), color = "green", lwd = 2)

# Adjusting maximum PAR to chamber max available --------------------------

max_PAR_chamber = 730 # in umol m-2 s-1
min_PAR_chamber = 30   # in umol m-2 s-1

# Remove lower points because chamber will lit too much at these (and we need dark):
ref_day$PAR[ref_day$PAR <= min_PAR_chamber] = 0.0

# Two methods: we either replace all high values by the maximum allowed, or we 
# use a different sigma for smoother transitions.

# First method:
ref_day$PAR[ref_day$PAR > max_PAR_chamber] = max_PAR_chamber

# Second method:
# (Re)computing the SIGMA of the PAR from the reference values:
# 
sigma_PAR =
  day_median%>%
  mutate(Hour = hour(Time))%>%
  filter(Hour>=6 & Hour<=20)%>%
  {summary(fit_gaussian(.$Hour,.$PAR,pic_value,k = max(.$PAR)))$parameters[,"Estimate"]}

# Updating the new PAR with same parameters, but updating the maximum value:
# ref_day =
#   ref_day%>%
#   mutate(PAR = gaussian_fn(x = Hour, mu = pic_value, sigma = sigma_PAR, k = max_PAR_chamber))
# NB: We could also use the one before and put a max at max_PAR_chamber

# Plotting the result (proposed points in green):
day_median_plot + 
  geom_line(data = ref_day %>% gather(key = 'var',value='value',Temp,HR,PAR,VPD), color = "green", lwd = 2)


# Add first point ---------------------------------------------------------

ref_day_1 = ref_day[1,]
ref_day_1$Time = ymd_hms(date(ref_day_1$Time), truncated = 3)
ref_day_1$Hour = 0
ref_day = dplyr::bind_rows(ref_day_1,ref_day) 

# Make the scenarios ------------------------------------------------------

dev = 0.3 # % of deviation of a variable from ref value

ref =
  ref_day%>%
  mutate(scenario = 'reference')

hot =
  ref_day%>%
  mutate(scenario='hot', Temp = Temp * (1 + dev),
         VPD = rH.to.VPD(HR/100, Temp, Esat.formula = "Allen_1998"))

dry_hot =
  hot%>%
  mutate(scenario='dry_hot', HR = HR * (1 - dev),
         VPD = rH.to.VPD(HR/100, Temp, Esat.formula = "Allen_1998"))

cold =
  ref_day%>%
  mutate(scenario='cold', Temp = Temp * (1 - dev),
         VPD = rH.to.VPD(HR/100, Temp, Esat.formula = "Allen_1998"))

dry_cold =
  cold%>%
  mutate(scenario='dry_cold', HR = HR * (1 - dev),
         VPD = rH.to.VPD(HR/100, Temp, Esat.formula = "Allen_1998"))


cloudy =
  ref_day%>%
  mutate(PAR = gaussian_fn(x = Hour, mu = pic_value, sigma = sigma_PAR, k = PAR_day_cloudy))%>%
  mutate(scenario='cloudy')



# All scenarios -----------------------------------------------------------

scenar = dplyr::bind_rows(ref,cold,hot,dry_hot,dry_cold,cloudy)

graph_scenar =
  scenar%>%
  gather(key = 'var',value='value',Temp,HR,PAR,VPD)%>%
  ggplot(aes(x = Hour,y = value, col = scenario))+
  geom_line()+
  facet_grid(var~scenario,scale='free_y')

don_space=
  scenar%>%
  group_by(scenario, Hour)%>%
  summarize(HR = round(mean(HR, na.rm = TRUE)),
            PAR = round(mean(PAR, na.rm = TRUE)),
            Temp = round(mean(Temp, na.rm = TRUE),1))%>%
  mutate(PAR = ifelse(PAR<5, 0, PAR))%>%
  select(PAR, HR, Temp)%>%
  ungroup()

# plot(don_space[,c('PAR','HR','Temp')])

# extract conditions ------------------------------------------------------
ref_time = c('00:00:00','02:00:00','04:00:00','06:00:00','08:00:00','10:00:00','12:00:00',
             '14:00:00','16:00:00','18:00:00',"20:00:00",'22:00:00')

table =
  scenar%>%
  mutate(hour = str_sub(string = Time, start = 12, end = 19))%>%
  filter(hour %in% ref_time)%>%
  group_by(scenario, hour)%>%
  summarize(HR = round(mean(HR, na.rm = TRUE)),
            PAR = round(mean(PAR, na.rm = TRUE)),
            Temp = round(mean(Temp, na.rm = TRUE), 1))%>%
  mutate(PAR = ifelse(PAR<5, 0, PAR))

colnames(table) = c('Scenario', 'Hour', 'HR (%)', 'PAR (micr.mol.m-2.s-1)', 'Temp (deg C)')

data.table::fwrite(table, "0-data/7-scenarios/new_scenario_output.csv")

