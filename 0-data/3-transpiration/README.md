# Transpiration computation

The transpiration was measured in five phases due to changes in the measurement setup, see the [README](0-data/0-raw/scale_weight/README.md) here for more details.

Computing the transpiration is quite tricky because we had three different computers in use, with different delay from UTC.
To be sure to get the same time for all the data, we used the time of the thermal camera, which we know have a constant delay of 3512s compared to UTC. The method is to use the thermal images to see when there is a change of plant, because its wait goes down to 0 at this time, with a maximum error of 60s as the images where taken each minute.

The `correspondance_scale_camera_time.csv` file is a table that gives the time of the thermal camera for each noticeable measurement of the scale. The time of the thermal camera is given as it is given in the image file name (so with the delay, not UTC).

The columns are:

- `phase`: the phase of measurement
- `scale`: the last time the scale measured the weight of the plant (before going down close to 0) for plant in, or the first time the scale measured the weight of the plant (after going up from 0) for plant out
- `thermal_camera`: the last time the thermal camera took an image with a plant for the plant in, or the first time the thermal camera took an image of the plant for the plant out