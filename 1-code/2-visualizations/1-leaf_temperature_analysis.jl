# Purpose: analyse leaf temperatures from thermal images taken with the FLIR camera
# The data is stored in the `0-data/4-thermal_camera_measurements/leaf_temperature.csv.bz2`
# that waw computed by the `1-code/1-computations/1-leaf_temperature.jl` script

# Load packages:
using CSV
using DataFrames
using CairoMakie
using AlgebraOfGraphics
using CodecBzip2
using Colors

# Read the leaf temperature data:
tleaf_df = open(Bzip2DecompressorStream, "0-data/4-thermal_camera_measurements/backup/leaf_temperature.csv.bz2") do io
    CSV.read(io, DataFrame)
end

# Plot the results:
begin
    abline = mapping([0], [1]) * visual(ABLines, color=:grey, linestyle=:dash)
    p =
        abline +
        data(dropmissing(tleaf_df, :Ta_measurement)) *
        mapping(
            :Ta_measurement => "Air temperature (°C)",
            :Tl_mean => "Leaf temperature (°C)",
            color=:leaf => "Leaf Number",
            layout=:plant => string => "Plant",
            markersize=3,
            # alpha=0.5
        ) *
        visual(Scatter, alpha=0.5)

    draw(p)
end

