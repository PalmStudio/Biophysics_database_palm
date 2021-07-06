# Extract temperatures from thermal images, then use masks to extract the
# temperatures from each visible leaves in the image. 

library(Thermimage)
library(fields)
source("1-code/4-thermal_camera/functions.R")
library(sp)
library(raster)
library(viridis)
library(tidyverse)
library(data.table)
library(lubridate)

climate_file = "0-data/1-climate/climate_mic3.csv"
image_file = "D:/Cirad/PalmStudio - Manip EcoTron 2021/stageRValentin/thermal_camera_photos/valentin/P1-S4-S5-S6-20210330_152159-20210331_103918/1/20210330_152159_R.jpg"
mask_file = "D:/Cirad/PalmStudio - Manip EcoTron 2021/Ecotron2021/0-data/0-raw/thermal_camera_roi_coordinates/P1F3-S4-S5-S6-20210330_142758-20210331_103918_XY_Coordinates_V2.csv"

climate_mic3 = 
  fread(climate_file, data.table = FALSE)%>%
  mutate(DateTime = as.POSIXct(DateTime))

# Carefull!!!! The function does not work the mask is not properly oriented
extract_temperature(image_file,mask_file,climate_mic3)
