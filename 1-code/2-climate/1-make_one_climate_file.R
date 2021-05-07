# Aim: read all separate climate files and make a new global one.
# Authors: V. Torrelli & R. Perez & R. Vezy
# Date: 07/05/2021

# Script set-up -----------------------------------------------------------

library(tidyverse)
library(lubridate)


# Reading all files -------------------------------------------------------

mic3_all_files = list.files("0-data/0-raw/climate", 
                            pattern = "^Mic3_data_clim_[0-9]+\\.csv$", 
                            full.names = TRUE)
mic4_all_files = list.files("0-data/0-raw/climate", 
                            pattern = "^Mic4_data_clim_[0-9]+\\.csv$", 
                            full.names = TRUE)

df_mic3 = 
  lapply(mic3_all_files, function(x){
    data.table::fread(x, data.table = FALSE)
  })%>%
  dplyr::bind_rows()

duplicated_rows = duplicated(df_mic3$DateTime)

# Number of duplicated rows:
n_dupl = length(df_mic3$DateTime[duplicated_rows])
n_dupl

# Removing duplicated rows from the data.frame:
df_mic3 = df_mic3[!duplicated_rows,]


df_mic4 = 
  lapply(mic4_all_files, function(x){
    data.table::fread(x, data.table = FALSE)
  })%>%
  dplyr::bind_rows()

df_mic4 = df_mic4[!duplicated(df_mic4$DateTime),]


# Cleaning the columns ----------------------------------------------------

df_mic3 = 
  df_mic3%>%
  select(-V1)%>%
  rename(Ta_instruction = "consigne T°C", Ta_measurement = "mesure T°C",
         Rh_instruction = "consigne HR", Rh_measurement = "mesure HR",
         R_instruction = "consigne Rayo", R_measurement = "mesure Rayo",
         CO2_ppm = "mesures [CO2]", CO2_flux = "mesure debit CO2",
  )

df_mic4 = 
  df_mic4%>%
  select(-V1)%>%
  rename(Ta_instruction = "consigne T°C", Ta_measurement = "mesure T°C",
         Rh_instruction = "consigne HR", Rh_measurement = "mesure HR",
         R_instruction = "consigne Rayo", R_measurement = "mesure Rayo",
         CO2_ppm = "mesures [CO2]")

# Save the new databases --------------------------------------------------

data.table::fwrite(df_mic3, "0-data/1-climate/climate_mic3.csv")
data.table::fwrite(df_mic4, "0-data/1-climate/climate_mic4.csv")

