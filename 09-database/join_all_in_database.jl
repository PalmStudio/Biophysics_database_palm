# Aim: join all data from the experiment into a single database file

using CSV, DataFrames
using CodecBzip2, Tar
using Dates

# Load the data
climate = CSV.read("1-climate/climate_mic3_5min.csv", DataFrame)
leaf_temperature = open(Bzip2DecompressorStream, "4-thermal_camera_measurements/leaf_temperature.csv.bz2") do io
    CSV.read(io, DataFrame)
end
transpiration = open(Bzip2DecompressorStream, "5-transpiration/transpiration.csv.bz2") do io
    CSV.read(io, DataFrame)
end
CO2 = CSV.read("3-CO2/CO2_fluxes.csv", DataFrame)

# Importing the scenario sequence:
sequence = CSV.read("0-data/scenario_sequence/SequencePlanteMicro3.csv", DataFrame)
transform!(
    sequence,
    :hour_start => ByRow(x -> DateTime(x[1:end-1], dateformat"dd/mm/yyyy HH:MM:SS")) => :hour_start,
    :hour_end => ByRow(x -> DateTime(x[1:end-1], dateformat"dd/mm/yyyy HH:MM:SS")) => :hour_end,
)

# Join the data together:
#! add the sequence to the climate data before

full_df = outerjoin(leaf_temperature, climate, on=:DateTime)
full_df = outerjoin(full_df, transpiration, on=:DateTime)
full_df = outerjoin(full_df, CO2, on=:DateTime)


using CairoMakie
using AlgebraOfGraphics

df_plot = stack(full_df, [:Ta_measurement, :Tl_mean, :weight, :flux_umol_s], [:DateTime, :plant])
transform!(
    groupby(skipmissing(df_plot), :variable),
    :value => (x -> (x .- minimum(x)) ./ (maximum(x) .- minimum(x))) => :value_norm
)

data(df_plot) *
mapping(:DateTime, :value_norm => "Normalized value", color=:variable) *
visual(Scatter) |>
draw

data(df_plot) *
mapping(:DateTime, :value_norm => "Normalized value", layout=:variable, color=:plant) *
visual(Scatter) |>
draw

p_clim =
    data(climate) *
    mapping(:DateTime, :Ta_measurement => (x -> (x - min_Ta) / (max_Ta - min_Ta)) => "Ta_measurement") *
    visual(Scatter)

min_Tl = minimum(leaf_temperature.Tl_mean)
max_Tl = maximum(leaf_temperature.Tl_mean)
p_Tl =
    data(leaf_temperature) *
    mapping(:DateTime, :Tl_mean => (x -> (x - min_Tl) / (max_Tl - min_Tl)) => "Tl_mean") *
    visual(Scatter, color=:red)

min_transp = minimum(transpiration.weight)
max_transp = maximum(transpiration.weight)
p_transp =
    data(transpiration) *
    mapping(:DateTime, :weight => (x -> (x - min_transp) / (max_transp - min_transp)) => "weight") *
    visual(Scatter, color=:blue)

min_CO2 = minimum(CO2.flux_umol_s)
max_CO2 = maximum(CO2.flux_umol_s)
p_CO2 =
    data(CO2) *
    mapping(:DateTime, :flux_umol_s => (x -> (x - min_CO2) / (max_CO2 - min_CO2)) => "CO2_flux") *
    visual(Scatter, color=:green)

p_clim + p_Tl + p_transp + p_CO2 |> draw
