# Transpiration computation

The `correspondance_scale_camera_time.csv` file is a table that gives the time of the thermal camera for each noticeable measurement of the scale, compared to the reference UTC time given by the database about opening and closing of the chamber door. The time of the thermal camera is given as it is given in the image file name, so it includes its delay.

The columns in the file are:

- `phase`: the phase of measurement
- `scale`: the last time the scale measured the weight of the plant (before going down close to 0) for plant in, or the first time the scale measured the weight of the plant (after going up from 0) for plant out
- `thermal_camera`: the last time the thermal camera took an image with a plant for the plant in, or the first time the thermal camera took an image of the plant for the plant out
- `door_opening`: the timestamp of when the door was opened or closed. This time is in UTC, and is synchronized between all equipments in the Ecotron, including the CO2 fluxes.
- `plant`: the plant identifier
- `note`: a note about the data point