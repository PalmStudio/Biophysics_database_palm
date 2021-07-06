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

climate_mic3 = 
  fread("0-data/1-climate/climate_mic3.csv", data.table = FALSE)%>%
  mutate(DateTime = as.POSIXct(DateTime))

image_file = "D:/Cirad/PalmStudio - Manip EcoTron 2021/stageRValentin/thermal_camera_photos/valentin/P1-S4-S5-S6-20210330_152159-20210331_103918/1/20210330_152159_R.jpg"

img = read_image(image_file)

DateTime_img = as.POSIXct(img$settings$Dates$FileModificationDateTime, tz = "UTC")

climate_img = 
  climate_mic3%>%
  filter(.data$DateTime == DateTime_img)%>%
  select(Rh_measurement, Ta_measurement)

temperature = get_temperature(img$img,
                              img$settings,
                              Tair = climate_img$Ta_measurement,
                              Rh = climate_img$Rh_measurement)

plotTherm(temperature, h = img$settings$h, w = img$settings$w, 
          minrangeset = 30, 
          maxrangeset = 42,
          trans="rotate270.matrix")


mask = 
  fread("D:/Cirad/PalmStudio - Manip EcoTron 2021/Ecotron2021/0-data/0-raw/thermal_camera_roi_coordinates/P1F3-S4-S5-S6-20210330_142758-20210331_103918_XY_Coordinates_V2.csv", 
        data.table = FALSE)%>%
  mutate_all(round)

# mask_polygon = sp::Polygon(mask)

mask_polygon = sp::SpatialPolygons(list(sp::Polygons(list(sp::Polygon(mask)), ID = "A")))

temp_raster = raster(temperature, xmn = 0, xmx = ncol(temperature), ymn = 0, 
                     ymx = nrow(temperature))

temp_P1F3_S4 = raster::extract(temp_raster,mask_polygon)

plot(temp_raster, col = viridis(50))
plot(mask_polygon, add = TRUE)
