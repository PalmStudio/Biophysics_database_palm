extract_temperature = function(img_file, mask_file, climate){
  
  img = read_image(image_file)
  
  DateTime_img = 
    round_date(as.POSIXct(img$settings$Dates$FileModificationDateTime, tz = "UTC") - 3510, "30 second")
  # There was a delay of 58m32s in the camera clock
  
  climate_img = 
    climate_mic3%>%
    filter(.data$DateTime == DateTime_img)%>%
    select(Rh_measurement, Ta_measurement)
  
  temperature = get_temperature(img$img,
                                img$settings,
                                Tair = climate_img$Ta_measurement,
                                Rh = climate_img$Rh_measurement)
  
  # plotTherm(temperature, h = img$settings$h, w = img$settings$w, 
  #           minrangeset = 30, 
  #           maxrangeset = 42,
  #           trans="rotate270.matrix")
  
  mask = 
    fread(mask_file, data.table = FALSE)%>%
    mutate_all(round)
  
  mask_polygon = sp::SpatialPolygons(list(sp::Polygons(list(sp::Polygon(mask)), ID = "A")))
  
  temp_raster = raster(temperature, xmn = 0, xmx = ncol(temperature), ymn = 0, 
                       ymx = nrow(temperature))
  
  temp_P1F3_S4 = raster::extract(temp_raster,mask_polygon)
  # plot(temp_raster, col = viridis(50))
  # plot(mask_polygon, add = TRUE)
  list(mean = mean(temp_P1F3_S4[[1]]), min = min(temp_P1F3_S4[[1]]),
       max = max(temp_P1F3_S4[[1]]), sd = sd(temp_P1F3_S4[[1]]))
}


#' Read thermal image
#'
#' @param image_file The path to a thermal image
#'
#' @return A list of two: the image, and the settings extracted from the image file
#' @export
#'
read_image = function(image_file){
  img = Thermimage::readflirJPG(imagefile = image_file, exiftoolpath = "installed")
  cams = Thermimage::flirsettings(imagefile = image_file, exiftoolpath="installed", camvals="")
  list(img = img, settings = cams)
}

#' Get temperature for each pixel of an image 
#'
#' @param image A thermal image as a matrix
#' @param Tair  Air temperature
#' @param Rh    Air relative humidity
#'
#' @details You need to install exiftool before using this function. it also needs 
#' to be in your PATH.
#' 
#' @return A matrix of temperatures
#' @export
#'
get_temperature = function(image, settings, Tair = NULL, Rh = NULL){
  
  if(is.null(Tair)){
    Tair = settings$Info$AtmosphericTemperature        # Atmospheric temperature
  }

  if(is.null(Rh)){
    Rh = settings$Info$RelativeHumidity              # Relative Humidity
  }
  
  Thermimage::raw2temp(raw = image, 
                       E = settings$Info$Emissivity, # Image Saved Emissivity - should be ~0.95 or 0.96
                       OD = settings$Info$ObjectDistance, # object distance in metres 
                       RTemp = settings$Info$ReflectedApparentTemperature,  # Reflected apparent temperature 
                       ATemp = Tair, 
                       IRWTemp = settings$Info$IRWindowTemperature,  # IR Window Temperature
                       IRT = settings$Info$IRWindowTransmission, # IR Window transparency
                       RH = Rh,
                       PR1 = settings$Info$PlanckR1, # Planck R1 constant for camera
                       PB = settings$Info$PlanckB,  # Planck B constant for camera
                       PF = settings$Info$PlanckF,  # Planck F constant for camera
                       PO = settings$Info$PlanckO,  # Planck O constant for camera
                       PR2 = settings$Info$PlanckR2, # Planck R2 constant for camera
                       ATA1 = settings$Info$AtmosphericTransAlpha1, # Atmospheric Transmittance Alpha 1
                       ATA2 = settings$Info$AtmosphericTransAlpha2, # Atmospheric Transmittance Alpha 2
                       ATB1 = settings$Info$AtmosphericTransBeta1, # Atmospheric Transmittance Beta 1
                       ATB2 = settings$Info$AtmosphericTransBeta2, # Atmospheric Transmittance Beta 2
                       ATX = settings$Info$AtmosphericTransX # Atmospheric Transmittance X
  )
}