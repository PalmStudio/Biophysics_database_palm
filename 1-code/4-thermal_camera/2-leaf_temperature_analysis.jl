# Purpose: analyse leaf temperatures from thermal images regarding their environment

using CSV
using DataFrames
using Plots

# Read the leaf temperature data:
tleaf_df = CSV.read("D:/Cirad/PalmStudio - Manip EcoTron 2021/stageRValentin/thermal_camera_photos/valentin/P1F3-S4-S5-S6-20210330_142758-20210331_103918.csv", DataFrame)

# Read the climate:
climate_mic3 = CSV.read("0-data/1-climate/climate_mic3.csv", DataFrame, dateformat = "y-m-d H:M:S")

# Join the data together:
full_df = leftjoin(tleaf_df, climate_mic3, on = :DateTime)

# Plots:
scatter(full_df.Ta_measurement, full_df.mean, label = "")
Plots.abline!(1,0, label = "identity", line = :dash, legend = :bottomright)
xlabel!("Air temperature (°C)")
ylabel!("Leaf temperature (°C)")
