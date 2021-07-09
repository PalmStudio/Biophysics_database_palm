using Dates:parse
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

using Revise

includet("1-code/4-thermal_camera/functions.jl")

img_file = "D:/Cirad/PalmStudio - Manip EcoTron 2021/stageRValentin/thermal_camera_photos/valentin/P1-S4-S5-S6-20210330_152159-20210331_103918/1/20210330_152159_R.jpg"
mask_file = "D:/Cirad/PalmStudio - Manip EcoTron 2021/Ecotron2021/0-data/0-raw/thermal_camera_roi_coordinates/P1F3-S4-S5-S6-20210330_142758-20210331_103918_XY_Coordinates_V2.csv"

# Read the climate only once:
climate_mic3 = CSV.read("0-data/1-climate/climate_mic3.csv", DataFrame, dateformat = "y-m-d H:M:S")

extract_temperature(img_file, mask_file, climate_mic3) # 1.659 per image, compared to 2.30 in R

# emissivity of 0.95 -> 37.66 °C in average; emmissivity of 0.98 -> 36.19

plot_mask(img_file, mask_file)

# Apply the mask on the whole set of images:
images = readdir("D:/Cirad/PalmStudio - Manip EcoTron 2021/stageRValentin/thermal_camera_photos/valentin/P1-S4-S5-S6-20210330_152159-20210331_103918/1", join = true)
leaf = "P1F3-S4-S5-S6"
mask = CSV.read(mask_file, DataFrame)

df_temp = DataFrame(:id => String[], :DateTime => DateTime[], :mean => Float64[], :min => Float64[], :max => Float64[], :std => Float64[], :n_pixels => Int[])
for (i, path) in enumerate(images)
    temps = extract_temperature(path, mask, climate_mic3)
    push!(df_temp, (temps..., id = leaf))
end

scatter(df_temp.DateTime,df_temp.min, label = "")
xlabel!("Time")
ylabel!("Leaf temperature (°C)")
title!(leaf)

CSV.write("D:/Cirad/PalmStudio - Manip EcoTron 2021/stageRValentin/thermal_camera_photos/valentin/P1F3-S4-S5-S6-20210330_142758-20210331_103918.csv", df_temp)

# Read the masks and make a table out of it to see which images have which mask applied onto it
# This is done like this because opening an image is expensive in compute time so we prefer to
# open it once and apply the mask once too.

mask_files = readdir("D:/Cirad/PalmStudio - Manip EcoTron 2021/Ecotron2021/0-data/0-raw/thermal_camera_roi_coordinates", join = true)
mask_files = filter(x -> occursin(r".csv$", x), mask_files)

image_files = readdir("E:\\Backups Manip Ecotron\\thermal_camera\\images", join = true)
image_files = image_files[348:400]

df_all = compute_all_images(image_files, mask_files, climate_mic3)

CSV.write("D:/Cirad/PalmStudio - Manip EcoTron 2021/0-data/4-thermal_camera_measurements/leaf_temperature.csv", df_all)

# image_files = [joinpath.(realpath(root), files) for (root, dirs, files) in walkdir("E:/Backups Manip Ecotron/thermal_camera/images")]
# image_files = collect(Iterators.flatten(image_files))
# mv.(image_files, joinpath.("E:\\Backups Manip Ecotron\\thermal_camera\\images", basename.(image_files)))

floor.(length(image_files) ./ (1:12))

function distrib_compute(n)

    mask_files = readdir("D:/Cirad/PalmStudio - Manip EcoTron 2021/Ecotron2021/0-data/0-raw/thermal_camera_roi_coordinates", join = true)
    mask_files = filter(x -> occursin(r".csv$", x), mask_files)

    image_files = readdir("E:\\Backups Manip Ecotron\\thermal_camera\\images", join = true)

    image_files = image_files[n]

    df_all = compute_all_images(image_files, mask_files, climate_mic3)
    CSV.write("D:/Cirad/PalmStudio - Manip EcoTron 2021/Ecotron2021/0-data/4-thermal_camera_measurements/leaf_temperature_$(n[1])-$(n[2]).csv", df_all)
end
