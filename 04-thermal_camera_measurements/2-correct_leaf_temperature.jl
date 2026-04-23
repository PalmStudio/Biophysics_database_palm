# Aim: correct the systematic thermal-camera leaf temperature offset.
#
# At night, leaf temperature should be very close to chamber air temperature.
# This script estimates the thermal-camera bias as the average
# Tl_mean - Ta_measurement during lights-off periods, using all days and all
# leaves, then subtracts that bias from every leaf temperature measurement.

using CSV
using CodecBzip2
using DataFrames
using Dates
using Printf
using Statistics
using AlgebraOfGraphics, CairoMakie

const LEAF_TEMPERATURE_FILE = joinpath(@__DIR__, "leaf_temperature.csv.bz2")
const CLIMATE_FILE = normpath(joinpath(@__DIR__, "..", "01-climate", "climate_mic3.csv"))
const OUTPUT_FILE = joinpath(@__DIR__, "leaf_temperature.csv.bz2")
const CORRECTION_FILE = joinpath(@__DIR__, "leaf_temperature_correction.csv")
const plot_file = joinpath(@__DIR__, "leaf_temperature_correction_effect.png")

# Night is defined from the measured chamber radiation. Increase this threshold
# slightly if low non-zero sensor values should still be treated as lights-off.
const NIGHT_RADIATION_MAX = 1.0

# The quantile of the leaf temperature distribution to use for the bias estimation.
const CORRECTION_QUANTILE = 0.25

# A constant temperature correction shifts location statistics, but not spread.
const TEMPERATURE_COLUMNS_TO_CORRECT = [:Tl_mean, :Tl_min, :Tl_max]

function read_bzip2_csv(path)
    open(Bzip2DecompressorStream, path) do stream
        CSV.read(stream, DataFrame)
    end
end

function write_bzip2_csv(path, df)
    open(Bzip2CompressorStream, path, "w") do stream
        CSV.write(stream, df)
    end
end

function require_columns(df, cols, path)
    missing_cols = setdiff(cols, propertynames(df))
    if !isempty(missing_cols)
        error("Missing required column(s) in $(path): $(join(string.(missing_cols), ", "))")
    end
end

leaf_temperature = read_bzip2_csv(LEAF_TEMPERATURE_FILE)
climate = CSV.read(CLIMATE_FILE, DataFrame)

require_columns(
    leaf_temperature,
    [:DateTime; TEMPERATURE_COLUMNS_TO_CORRECT],
    LEAF_TEMPERATURE_FILE,
)
require_columns(climate, [:DateTime, :Ta_measurement, :R_measurement], CLIMATE_FILE)

climate_temperature = select(climate, :DateTime, :Ta_measurement, :R_measurement)
temperature_with_climate = leftjoin(leaf_temperature, climate_temperature, on=:DateTime)

night_temperature = dropmissing(
    temperature_with_climate,
    [:Tl_mean, :Ta_measurement, :R_measurement],
)
filter!(row -> row.R_measurement <= NIGHT_RADIATION_MAX, night_temperature)

if nrow(night_temperature) == 0
    error(
        "No night measurements found with R_measurement <= $(NIGHT_RADIATION_MAX). " *
        "Increase NIGHT_RADIATION_MAX or check the climate data."
    )
end

# thermal_bias = mean(night_temperature.Tl_mean .- night_temperature.Ta_measurement)
thermal_bias = quantile(
    night_temperature.Tl_mean .- night_temperature.Ta_measurement,
    CORRECTION_QUANTILE,
)
temperature_correction = -thermal_bias

# Visualize the night bias:
data(dropmissing(night_temperature, :Ta_measurement)) *
mapping(
    :DateTime => (x -> Time(x) .+ Second(0)) => "Hour (UTC)",
    :Ta_measurement => "Air temperature (°C)",
    layout=:DateTime => Date => "Day",
) *
visual(Scatter, color=:red, markersize=1) +
AlgebraOfGraphics.data(dropmissing(night_temperature, :Ta_measurement)) *
mapping(
    :DateTime => Time => "Hour (UTC)",
    :Tl_mean => "Leaf temperature (°C)",
    color=:plant => string => "Plant",
    layout=:DateTime => Date => "Day",
) *
visual(Scatter, markersize=3) |>
draw(figure=(; size=(1080, 3000)), scales(Layout=(; palette=wrapped(cols=3))))

for column in TEMPERATURE_COLUMNS_TO_CORRECT
    leaf_temperature[!, string(column, "_corrected")] .= leaf_temperature[!, string(column)] .+ temperature_correction
end

# Visualize the effect of the correction on the leaf temperature distribution:
leaf_temperature.Time = Time.(leaf_temperature.DateTime)
leaf_temperature.Day = Date.(leaf_temperature.DateTime)

# Gather the original and corrected temperatures in a long format for visualization:
fig = data(sort(leaf_temperature, :Time)) *
      mapping(:Time => "Hour (UTC)", :Tl_mean => "Leaf temperature (°C)", group=:leaf, layout=:Day) *
      visual(Lines, color=:red, alpha=0.3, label="Original") +
      data(sort(leaf_temperature, :Time)) *
      mapping(:Time => "Hour (UTC)", :Tl_mean_corrected => "Corrected leaf temperature (°C)", group=:leaf, layout=:Day) *
      visual(Lines, color=:blue, alpha=0.3, label="Corrected") +
      AlgebraOfGraphics.data(temperature_with_climate) *
      mapping(:DateTime => Time => "Hour (UTC)", :Ta_measurement => "Air temperature (°C)", layout=:DateTime => Date => "Day") *
      visual(Lines, color=:black, label="Air temperature") |>
      draw(figure=(; size=(2000, 1500)))

save(plot_file, fig)

write_bzip2_csv(OUTPUT_FILE, select(leaf_temperature, Not(:Day, :Time)))

correction_summary = DataFrame(
    created_at_utc=[string(now(UTC))],
    input_file=[basename(LEAF_TEMPERATURE_FILE)],
    climate_file=[relpath(CLIMATE_FILE, @__DIR__)],
    output_file=[basename(OUTPUT_FILE)],
    night_definition=["R_measurement <= $(NIGHT_RADIATION_MAX)"],
    corrected_columns=[join(string.(TEMPERATURE_COLUMNS_TO_CORRECT), ", ")],
    n_leaf_temperature_records=[nrow(leaf_temperature)],
    n_records_with_climate=[count(!ismissing, temperature_with_climate.Ta_measurement)],
    n_night_records=[nrow(night_temperature)],
    mean_tleaf_minus_tair_night=[thermal_bias],
    median_tleaf_minus_tair_night=[
        median(night_temperature.Tl_mean .- night_temperature.Ta_measurement)
    ],
    correction_applied=[temperature_correction],
)

CSV.write(CORRECTION_FILE, correction_summary)

@printf(
    "Estimated night thermal bias: %.3f deg C from %d records (%s)\n",
    thermal_bias,
    nrow(night_temperature),
    correction_summary.night_definition[1],
)
@printf("Applied correction to %s: %.3f deg C\n", join(string.(TEMPERATURE_COLUMNS_TO_CORRECT), ", "), temperature_correction)
println("Wrote corrected leaf temperatures to $(OUTPUT_FILE)")
println("Wrote correction summary to $(CORRECTION_FILE)")
