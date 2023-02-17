using CSV, DataFrames
using Dates
using Statistics

df_cor = CSV.read("0-data/3-transpiration/correspondance_scale_camera_time.csv", DataFrame)
df_cor.thermal_camera = DateTime.(df_cor.thermal_camera, dateformat"yyyymmdd_HHMMSS_R")
df_cor.door_opening = [ismissing(i) ? missing : DateTime.(i, dateformat"yyyy-mm-dd HH:MM:SS") for i in df_cor.door_opening]

# Thermal camera

df_thermal = transform(
    df_cor,
    [:door_opening, :thermal_camera] => ByRow((x, y) -> ismissing(x) || ismissing(y) ? missing : canonicalize(x - y)) => :thermal_camera_to_door_cmp,
    [:door_opening, :thermal_camera] => ((x, y) -> x - y) => :thermal_camera_to_door,
)

delay_camera = Second(round(minimum([i.value for i in skipmissing(df_thermal.thermal_camera_to_door)]) * 1e-3, digits=0))
# NB: we take the minimum because the camera takes a picture every 1 min, so the delay is the
# minimum observed delay between the camera and the door opening.
# This value (3565 seconds) is close to the real observation of 3512 seconds.

df_cor.thermal_camera = df_cor.thermal_camera .+ delay_camera
# Transpiration

# Phase 0 measurements:

# We have no measurements that could help us know match the measurements because we don't 
# have any weight close to 0...
# It is written in the report that the computer was writting with UTC+1 though. To check.

# Phase 1 measurements
df_phase1 = transform(
    dropmissing(df_cor, :scale),
    [:scale, :thermal_camera] => ((x, y) -> x - y) => :scale_to_thermal_camera,
    [:scale, :door_opening] => ((x, y) -> x - y) => :scale_to_door,
)

# We have to measurement points, one when the door opens to remove the P5 plant, and one when
# we put the P1 plant inside the chamber. We have the picture of the change at one minute time-scale.
# We can thus compute the delay between the scale and the camera.

# Both the camera and the door opening match so it's a good news. Unfortunately, the scale
# measurements are weird because there is a two minute difference between the difference on 
# the two measurement points (-4m27s and -2m36s compared to the door). 

# If we compare the period of time between the two measurement points, we see that the scale
# has a 2h16h39s period, and the two others have ~2h14m50s:
canonicalize(df_phase1.scale[2] - df_phase1.scale[1])
canonicalize(df_phase1.thermal_camera[2] - df_phase1.thermal_camera[1])
canonicalize(df_phase1.door_opening[2] - df_phase1.door_opening[1])

# We take the minimum delay between the scale and the door opening then:
delay_scale_p1 = Second(round(minimum([i.value for i in df_phase1.scale_to_door]) * 1e-3, digits=0))
# The delay is -267 seconds (so its not a delay but a lead)

# Phase 2 measurements

