# Aim: join all data from the experiment into a single database file

using CSV, DataFrames
using CodecBzip2, Tar

# Load the data
climate = CSV.read("1-climate/climate_mic3.csv", DataFrame)
leaf_temperature = open(Bzip2DecompressorStream, "4-thermal_camera_measurements/leaf_temperature.csv.bz2") do io
    CSV.read(io, DataFrame)
end
transpiration = open(Bzip2DecompressorStream, "5-transpiration/transpiration.csv.bz2") do io
    CSV.read(io, DataFrame)
end

# Join the data together (climate and leaf temperature):
full_df = leftjoin(leaf_temperature, climate, on=:DateTime)
leftjoin!(full_df, transpiration, on=:DateTime)
