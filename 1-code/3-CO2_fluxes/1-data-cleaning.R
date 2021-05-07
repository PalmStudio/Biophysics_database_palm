# Aim: Cleaning the raw data to keep only the points without door opening.
# Authors: V. Torrelli & R. Perez & R. Vezy
# Date: 07/05/2021


# Script set-up -----------------------------------------------------------

library(tidyverse)
library(lubridate)
source("1-code/0-functions/functions.R") # Functions of this project

# Importing the CO2 flux data ---------------------------------------------

df_CO2 = 
  data.table::fread("0-data/0-raw/picarro_flux/data_mean_flux.csv", 
                    data.table = FALSE)%>%
  mutate(DateTime = lubridate::dmy_hm(MPV1_time),
         DateTime_30min = lubridate::round_date(DateTime, "30minute"))

# Importing the data to know when the chamber was opened ------------------

df_open = 
  data.table::fread("0-data/0-raw/opening_door/Mic3_ouverture_porte.csv", 
                    data.table = FALSE)%>%
  rename(door = ouverture_porte)%>%
  mutate(DateTime = floor_date(lubridate::ymd_hms(DateTime), 
                               unit = "minute"),
         DateTime_30min = lubridate::round_date(DateTime, "30minute"))
# 0: the door of the chamber is closed, 1: it is open


# Importing the chamber climate -------------------------------------------
# NB: this database is computed in the script "1-code/2-climate/2-make-5min-timestep-climate.R"
# This file is integrated at a 5min time-step

df_climate_5min = 
  data.table::fread("0-data/1-climate/mic3_climate_5min.csv", 
                    data.table = FALSE)%>%
  mutate(DateTime = floor_date(lubridate::ymd_hms(DateTime_start), 
                               unit = "minute"))

# Joining the data --------------------------------------------------------

# Both df_CO2 and df_climate_5min share the same time-steps because the latter 
# was computing using the former. Joining them together:
df = left_join(df_CO2, df_climate_5min, by = "DateTime")

# Joining the door data at 30min resolution (because if finner resolution, can 
# happen at a time where we don't measure CO2):
df = 
  left_join(df, df_open, by = "DateTime_30min",suffix = c("_CO2", "_open"))%>%
  mutate(door = if_else(is.na(door),0,1))


# Plotting the moment when the door was opened:
p =
  df%>%
  ggplot(aes(x = DateTime_CO2))+
  geom_point(aes(y = CO2_dry_MPV2, color = as.factor(door)))

plotly::ggplotly(p)

# Filter-out the periods around when the door was opened

points_before = 1 # Number of points to filter-out before the opening of the door
points_after = 9  # Number of points to filter-out after the opening of the door

# Flag time-steps that match points_before and points_after around a door opening:
df$around_opening = is_val_around(df$door,1,points_after,points_before)

df_filtered= df%>%filter(around_opening != 1)

# Plotting the moment when the door was opened:
p_filt =
  df_filtered%>%
  ggplot(aes(x = DateTime_CO2))+
  geom_point(aes(y = flux_umol_s, color = as.factor(door)))

plotly::ggplotly(p_filt)


# Filter points around CO2 instruction change -----------------------------

p_filt =
  df_filtered%>%
  ggplot(aes(x = DateTime_CO2))+
  geom_point(aes(y = flux_umol_s, color = CO2_change))

plotly::ggplotly(p_filt)

df_filtered_change = df_filtered%>%filter(CO2_change != "change")

p_filt_change =
  df_filtered_change%>%
  ggplot(aes(x = DateTime_CO2))+
  geom_point(aes(y = CO2_dry_MPV2, color = CO2_change))

plotly::ggplotly(p_filt_change)


# Saving the new cleaned database -----------------------------------------

data.table::fwrite(df_filtered_change, "0-data/2-CO2/CO2_fluxes.csv")

