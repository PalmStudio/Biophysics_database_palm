# Purpose: extract leaf temperatures from thermal images using hand-drawn masks

"""
    compute_jpg_temperature_batch(current_step, mask_dir, img_dir, csv_dir, climate; delay::Dates.TimePeriod=Dates.Second(3512))

Compute in parrallel the temperature of the leaves from the thermal images using the masks, considering
the air temperature and the relative humidity.

# Arguments

- `current_step`: the current step of the computation
- `mask_dir`: the directory containing the masks
- `img_dir`: the directory containing the images
- `csv_dir`: the directory where the results will be saved
- `climate`: the DataFrame containing the climate data
- `delay`: the delay in the camera clock (default: 3512 seconds as for our experiment)
- `img_dateformat=DateFormat("yyyymmdd_HHMMSS\\_\\R\\.\\j\\p\\g")`: the date format from the images file name

The `climate` DataFrame is used to correct the temperature measurements with the air temperature and relative humidity.
It should have the following columns:
- DateTime: the date and time of the measurement
- Ta_measurement: the air temperature in °C
- Rh_measurement: the relative humidity in %

# Examples
    
```julia
using EcotronAnalysis, DataFrames, CSV, Distributed
img_dir = "../00-data/0-raw/thermal_camera_images/sample"
mask_dir = "../00-data/0-raw/thermal_camera_roi_coordinates/coordinates"
out_dir = "tmp"
climate = CSV.read("../00-data/02-climate/climate_mic3.csv", DataFrame, dateformat="y-m-d H:M:S")

# Running the computation in parrallel:
addprocs(exeflags="--project")
@everywhere using EcotronAnalysis
compute_jpg_temperature_distributed(img_dir, mask_dir, out_dir, climate)
rmprocs()
```
"""
function compute_jpg_temperature_distributed(
    img_dir, mask_dir, out_dir, climate;
    delay::Dates.TimePeriod=Dates.Second(3512),
    img_dateformat=DateFormat("yyyymmdd_HHMMSS\\_\\R\\.\\j\\p\\g")
)
    nprocessors = Distributed.nprocs() # available processors
    if nprocessors == 1 && Sys.CPU_THREADS > 1
        error(
            "Julia uses only one processor.",
            " Please restart Julia with several processors using `julia -p numcores`.",
            " You have $(Sys.CPU_THREADS) available on your machine."
        )
    end

    # Test if the folders exist
    if !isdir(img_dir)
        error("The image directory does not exist.")
    end

    if !isdir(mask_dir)
        error("The mask directory does not exist.")
    end

    if !isdir(out_dir)
        error("The output directory does not exist.")
    end

    image_files = filter(x -> !startswith(basename(x), ".") && endswith(basename(x), ".jpg"), readdir(img_dir))
    partitions = equal_partition(length(image_files), nprocessors)

    ProgressMeter.@showprogress @distributed for i in partitions
        compute_jpg_temperature_batch(i, mask_dir, img_dir, out_dir, climate; delay=delay, img_dateformat=img_dateformat)
    end
end

"""
    equal_partition(n, parts)

Divide `n` into n equal `parts`. Used for dividing the data into chunks for parallel computing.
Source: https://discourse.julialang.org/t/split-vector-into-n-potentially-unequal-length-subvectors/73548/6?u=rvezy
"""
function equal_partition(n, parts)
    if n < parts
        return [x:x for x in 1:n]
    end
    starts = push!(Int64.(round.(1:n/parts:n)), n + 1)
    return [starts[i]:starts[i+1]-1 for i in 1:length(starts)-1]
end
