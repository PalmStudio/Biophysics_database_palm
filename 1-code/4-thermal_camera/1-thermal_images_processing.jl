# Purpose: extract leaf temperatures from thermal images using hand-drawn masks

# Cite: https://www.sciencedirect.com/science/article/pii/S0168192316303434?via%3Dihub
# See [here](https://github.com/yakir12/TrackRoots.jl/search?q=exiftool) for an example of
# packing directly exiftool with a package.
# See [this discussion](https://discourse.julialang.org/t/to-not-shell-out/8929/10) for an efficient implementation.


# The thermal camera group the images into folders for each hour. This is few lines of code
# to move the images all in the same folder before computations:
# img_dir = "E:/Backups Manip Ecotron/thermal_camera/images"
# image_files = [joinpath.(realpath(root), files) for (root, dirs, files) in walkdir(img_dir)]
# image_files = collect(Iterators.flatten(image_files))
# mv.(image_files, joinpath.(img_dir, basename.(image_files)))

# COmputing the images in parrallel:
using Distributed
using ProgressMeter
using CSV, ArchGDAL, DataFrames, Dates, TimeZones, PolygonOps, Images, Statistics
# addprocs(6)
addprocs(exeflags="--project")
@everywhere using CSV, ArchGDAL, DataFrames, Dates, TimeZones, PolygonOps, Images, Statistics
@everywhere include("1-code/4-thermal_camera/0-functions.jl")
@everywhere climate_mic3 = CSV.read("0-data/1-climate/climate_mic3.csv", DataFrame, dateformat="y-m-d H:M:S")
@everywhere steps = floor(Int, 78289 / 12)
@everywhere mask_dir = abspath("0-data/0-raw/thermal_camera_roi_coordinates")
@everywhere img_dir = "E:\\Backups Manip Ecotron\\thermal_camera\\images"
@everywhere csv_dir = abspath("0-data/4-thermal_camera_measurements/")

@showprogress @distributed for i in 1:12
    current_step = (steps*(i-1)+1):(steps*i)
    if i == 12
        current_step = current_step[1]:(current_step[end]+1)
    end
    distrib_compute(current_step, mask_dir, img_dir, csv_dir)
end


plot_mask("E:/Backups Manip Ecotron/thermal_camera/images/20210308_180009_R.jpg", "D:/Cirad/PalmStudio - Manip EcoTron 2021/Ecotron2021/0-data/4-thermal_camera_measurements/leaf_temperature_1-6524.csv")
