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