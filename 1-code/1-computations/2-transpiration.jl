# Aim: compute transpiration from the weight of the potted plants. The pot and soil were 
# isolated using a plastic bag. The weight of the pot and soil was measured before entering
# the chamber, and then continuously measured during the experiment using a connected 
# precision scale. There are five phases of measurement due to changes in the measurement 
# setup, see 0-data/0-raw/scale_weight/README.md for more details.


using Dates
using DataFrames, CSV

ref_thermal_camera = DateTime("2021-04-13T14:48:27") - Dates.Second(3512)
ref_weight = DateTime("2021-04-12T13:02:43")
cor_phase_4 = Second(thermal_camera - weight)

# Which is:
Dates.canonicalize(Second(thermal_camera - weight))


# Import the sequences of the measurement sessions for each plant:
MicPlant = CSV.read("0-data/0-raw/scenario_sequence/SequencePlanteMicro3.csv", DataFrame)

transform!(
    MicPlant,
    :hour_start => ByRow(x -> DateTime(x[1:end-1], dateformat"dd/mm/yyyy HH:MM:SS")) => :hour_start,
    :hour_end => ByRow(x -> DateTime(x[1:end-1], dateformat"dd/mm/yyyy HH:MM:SS")) => :hour_end,
)

# Phase 0 of the measurements:
df_phase_0 = CSV.read("0-data/0-raw/scale_weight/weights_1.txt", DataFrame, header=["DateTime", "weight"])
# Phase 0 is at UTC+1, so we need to correct the time:
df_phase_0.DateTime = df_phase_0.DateTime - Dates.Hour(1)

# Phase 1 of the measurements, measured at UTC-4min:
df_phase_1 = CSV.read("0-data/0-raw/scale_weight/weightsPhase1.txt", DataFrame, header=["DateTime", "weight"])
df_phase_1.DateTime = df_phase_1.DateTime + Dates.Minute(4)

# Phase 1 of the measurements, measured at UTC (check if it was UTC or UTC-4min here):
df_phase_2 = CSV.read("0-data/0-raw/scale_weight/weightsPhase2.txt", DataFrame, header=["DateTime", "weight"])

Plant1_removed =
    transform!(
        tr_raw1,
        :DateTime => (x -> Date.(x)) => :Date,
        :DateTime => (x -> Time.(x)) => :Time,
    )

# date at which the plant was still in the chamber:
date_weight = DateTime("2021-03-15T12:26:19")

ref_thermal_camera_p1 = DateTime("2021-03-15T13:31:12") - Dates.Second(3512)
ref_weight_p1 = DateTime("2021-03-15T12:26:19")
cor_phase_1 = Second(ref_thermal_camera_p1 - ref_weight_p1)
canonicalize(cor_phase_1)


ref_thermal_camera_p1 = DateTime("2021-03-15T15:46:03") - Dates.Second(3512)
ref_weight_p1 = DateTime("2021-03-15T14:43:59")
cor_phase_1 = Second(ref_thermal_camera_p1 - ref_weight_p1)
canonicalize(cor_phase_1)