# Aim: integrate the global climate files at 10min time-steps.
# Authors: V. Torrelli & R. Perez & R. Vezy
# Date: 07/05/2021
# Details: the climate file is at 30s time-step, but the CO2 fluxes are measured
# for 5 minutes every 10 minutes (5min input / 5min output), so we need the 
# climate data integrated at 5min time-step when there is a measurement of CO2
# flux.


# Script set-up -----------------------------------------------------------

library(tidyverse)
library(lubridate)


# Importing the climate data ----------------------------------------------

mic3_climate = 
  data.table::fread("0-data/1-climate/climate_mic3.csv", 
                    data.table = FALSE)%>%
  mutate(DateTime = lubridate::ymd_hms(DateTime))

# Importing the CO2 flux data ---------------------------------------------

Period_needed = 
  data.table::fread("0-data/0-raw/picarro_flux/data_mean_flux.csv", 
                    data.table = FALSE)%>%
  transmute(DateTime_start = lubridate::dmy_hm(MPV1_time),
         DateTime_end = lubridate::dmy_hm(MPV2_time))



# Computing corresponding periods -----------------------------------------

mic3_climate$DateTime_start = NA
mic3_climate$DateTime_end = NA

for (i in 1:nrow(Period_needed)) {
  all_in_period_i = mic3_climate$DateTime >= Period_needed$DateTime_start[i] & mic3_climate$DateTime <= Period_needed$DateTime_end[i]
  mic3_climate$DateTime_start[all_in_period_i] = Period_needed$DateTime_start[i]
  mic3_climate$DateTime_end[all_in_period_i] = Period_needed$DateTime_end[i]
}

mic3_climate_int = 
  mic3_climate%>%
  filter(!is.na(DateTime_start))%>%
  group_by(DateTime_start)%>%
  summarise_if(is.numeric,mean)%>%
  mutate(DateTime_start = lubridate::as_datetime(DateTime_start),
         DateTime_end = lubridate::as_datetime(DateTime_end))


# Saving the integrated database ------------------------------------------

data.table::fwrite(mic3_climate_int, "0-data/1-climate/mic3_climate_5min.csv")
