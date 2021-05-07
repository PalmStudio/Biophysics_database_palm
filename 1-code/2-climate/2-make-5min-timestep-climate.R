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
source("1-code/0-functions/functions.R") # Functions of this project

# Importing the climate data ----------------------------------------------
# NB: this database is computed in the script "1-code/2-climate/1-make_one_climate_file.R"

mic3_climate = 
  data.table::fread("0-data/1-climate/climate_mic3.csv", 
                    data.table = FALSE)%>%
  mutate(DateTime = lubridate::ymd_hms(DateTime))%>%
  mutate(CO2_instruction = 0.0)

# p =
#   mic3_climate%>%
#   filter(DateTime>=as.POSIXct("2021-03-27T00:00:00") & DateTime<as.POSIXct("2021-03-29T00:00:00"))%>%
#   ggplot(aes(x = DateTime))+
#   geom_point(aes(y = CO2_flux))
# plotly::ggplotly(p)

# Recomputing the CO2 forcing in the chamber from the input flux, which is itself
# quite noisy:

mic3_climate$CO2_instruction[mic3_climate$CO2_flux>=30 &
                               mic3_climate$CO2_flux <= 45] = 400.0

mic3_climate$CO2_instruction[mic3_climate$CO2_flux>=45 &
                               mic3_climate$CO2_flux <= 55] = 600.0

mic3_climate$CO2_instruction[mic3_climate$CO2_flux>=55] = 800.0

# NB: 800 to 400ppm is fast

# Computing a variable to flag the change in CO2 forcing:

mic3_climate = 
  mic3_climate%>%
  mutate(CO2_change = ifelse(CO2_instruction != lag(CO2_instruction,default = 0),
                             "change","no_change"))

mic3_climate$CO2_change[mic3_climate$CO2_instruction == 0] = "change"


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
  group_by(DateTime_start)

mic3_climate_int_num = 
  mic3_climate_int%>%
  summarise_if(is.numeric,mean)%>%
  mutate(DateTime_start = lubridate::as_datetime(DateTime_start),
         DateTime_end = lubridate::as_datetime(DateTime_end))

mic3_climate_int_char = 
  mic3_climate_int%>%
  summarise(CO2_change = if_else(any(CO2_change=="change"),"change","no_change"))

# Flag values just before or after a change as change to be large:
mic3_climate_int_char$CO2_change = 
  is_val_around(mic3_climate_int_char$CO2_change,"change",
                points_after = 2,
                points_before = 1)

mic3_climate_int = mic3_climate_int_num
mic3_climate_int$CO2_change = mic3_climate_int_char$CO2_change

# Saving the integrated database ------------------------------------------

data.table::fwrite(mic3_climate_int, "0-data/1-climate/mic3_climate_5min.csv")
