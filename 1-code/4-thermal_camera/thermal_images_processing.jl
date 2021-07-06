# Purpose: extract leaf temperatures from thermal images and hand-drawn masks

# Cite: https://www.sciencedirect.com/science/article/pii/S0168192316303434?via%3Dihub
# See [here](https://github.com/yakir12/TrackRoots.jl/search?q=exiftool) for an example of
# packing directly exiftool with a package.
# See [this discussion](https://discourse.julialang.org/t/to-not-shell-out/8929/10) for an efficient implementation.

using CSV
using Plots
using ArchGDAL
using DataFrames
using Dates
using TimeZones
using PolygonOps # To compute a polygon from the mask edge points
using Images
using Statistics
using ImageDraw

include("1-code/4-thermal_camera/functions.jl")

img_file = "D:/Cirad/PalmStudio - Manip EcoTron 2021/stageRValentin/thermal_camera_photos/valentin/P1-S4-S5-S6-20210330_152159-20210331_103918/1/20210330_152159_R.jpg"
mask_file = "D:/Cirad/PalmStudio - Manip EcoTron 2021/Ecotron2021/0-data/0-raw/thermal_camera_roi_coordinates/P1F3-S4-S5-S6-20210330_142758-20210331_103918_XY_Coordinates_V2.csv"

# Read the climate only once:
climate_mic3 = CSV.read("0-data/1-climate/climate_mic3.csv", DataFrame, dateformat = "y-m-d H:M:S")

extract_temperature(img_file, mask_file, climate_mic3) # 1.659 per image, compared to 2.30 in R

# plot_mask(img_file, mask_file)
