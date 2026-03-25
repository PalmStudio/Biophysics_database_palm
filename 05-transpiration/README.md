# Transpiration computation

The transpiration was measured in five phases due to changes in the measurement setup, see the [README]([00-data/scale_weight/README.md](https://github.com/PalmStudio/Biophysics_database_palm/blob/main/00-data/scale_weight/README.md)) here for more details.

Computing the transpiration is quite tricky because we had three different computers in use, with different delay from UTC.
To be sure to get the same time for all the data, we used the time of the thermal camera, which we know have a constant delay of 3512s compared to UTC. The method is to use the thermal images to see when there is a change of plant, because its wait goes down to 0 at this time, with a maximum error of 60s as the images where taken each minute.

We use the `match_scale_camera_time.csv` file to synchronize correctly the timestamps.
