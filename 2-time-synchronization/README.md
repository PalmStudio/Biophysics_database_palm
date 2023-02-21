# Time synchronization

The timestamps of the different sensors and equipments used in the experiment can deviate from each other. This is a problem when we want to merge all measurements into the same database, and compare them alongside.

The equipments include:

- the climate database, which is at UTC
- the CO2 fluxes (UTC)
- the scale data (logged differently along the experiment)
- the thermal camera

The `correspondance_scale_camera_time.csv` file is a table that gives the time of the thermal camera for each noticeable measurement of the scale, compared to the reference UTC time given by the database about opening and closing of the chamber door. The time of the thermal camera is given as it is given in the image file name, so it includes its delay.

The columns in the file are:

- `phase`: the phase of measurement
- `scale`: the last time the scale measured the weight of the plant (before going down close to 0) for plant in, or the first time the scale measured the weight of the plant (after going up from 0) for plant out
- `thermal_camera`: the last time the thermal camera took an image with a plant for the plant in, or the first time the thermal camera took an image of the plant for the plant out
- `door_opening`: the timestamp of when the door was opened or closed. This time is in UTC, and is synchronized between all equipments in the Ecotron, including the CO2 fluxes.
- `plant`: the plant identifier
- `note`: a note about the data point


The file `time_synchronization_notebook.jl` is a Pluto.jl notebook that can be used to visualize the different delays, and compute the corrections to apply. It also generates the output file `time_synchronization.csv`.

You can run the notebook like so:

```julia
using Pluto
Pluto.run()
```

Then open the notebook `time_synchronization_notebook.jl` in Pluto.

Or more directly using:

```julia
using Pluto
Pluto.run(notebook="./2-time-synchronization/time_synchronization_notebook.jl")
```