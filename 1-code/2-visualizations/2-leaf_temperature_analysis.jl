# Purpose: analyse leaf temperatures from thermal images regarding their environment

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

# Plots:
begin
    f = Figure(resolution=(800, 600))
    ax = Axis(f[1, 1], xlabel="Air temperature (°C)", ylabel="Leaf temperature (°C)")
    ablines!(ax, 0, 1, label="identity", linestyle=:dash, color="grey")
    scatter!(
        ax, tleaf_df.Ta_measurement, tleaf_df.Tl_mean,
        markersize=5, color=colorant"#F5505020",
        strokecolor=colorant"#F5505040", strokewidth=0.5
    )
    f
end

begin
    p =
        data(tleaf_df) *
        mapping(
            :Ta_measurement => "Air temperature (°C)",
            :Tl_mean => "Leaf temperature (°C)",
            color=:leaf,
            row=:plant
        )
    draw(p)
end