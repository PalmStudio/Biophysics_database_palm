# Aim: compute the leaf temperature from thermal images (FLIR camera)
# and masks named after the plant, leaf, session and duration of 
# its validity (sometimes the leaves has moved and we need a new mask).
# This computation is done in parrallel, and needs access to the thermal 
# images (JPEG), which takes 60Go of disk space roughly. Please make this 
# computation only if you have to because it takes time and disk space.

using EcotronAnalysis
using DataFrames, CSV # For the climate data
using Distributed     # For the parrallel computation
using Dates           # For the delay in the camera clock
using CodecBzip2, Tar # For the extraction of the images from the tar.bz2 file

# Requirements: you need to install exiftool on your machine first, and add it to your PATH.
# This is needed to read the metadata from the thermal images.
# You can refer to this page for installation: https://exiftool.org/install.html
# Or if you use a package manager:
# `brew install exiftool` # On MacOS
# `choco install exiftool` # On Windows
# `sudo apt install libimage-exiftool-perl` # On Linux

# Extract the images from the tar.bz2 file. This can take a while, and the
# images are 60Go of disk space, so make sure you really need to make this.
open(Bzip2DecompressorStream, "00-data/thermal_camera_images/images.tar.bz2") do io
    Tar.extract(io, "00-data/thermal_camera_images/images")
end

# Extract the masks from the tar.bz2 file:
open(Bzip2DecompressorStream, "00-data/thermal_camera_images/coordinates.tar.bz2") do io
    Tar.extract(io, "00-data/thermal_camera_images/coordinates")
end

# Setting up the paths and climate data:
img_dir = "00-data/thermal_camera_images/images/images"
mask_dir = "00-data/thermal_camera_roi_coordinates/coordinates"
out_dir = @__DIR__

# Climate data (for correcting the leaf temperature from air temperature and humidity):
climate = CSV.read("02-climate/climate_mic3.csv", DataFrame)
# There was a delay in the camera clock of -59m32s (name of the file VS UTC)::
delay_df = CSV.read("03-time-synchronization/time_synchronization.csv", DataFrame)
delay = Second(filter(x -> x.type == "thermal camera", delay_df).delay_seconds[1])

# Date format of the image file names:
img_dateformat = DateFormat("yyyymmdd_HHMMSS\\_\\R\\.\\j\\p\\g")

# img = readdir(img_dir)
# img = filter(x -> !startswith(basename(x), ".") && endswith(basename(x), ".jpg"), img)
# image_dates = DateTime.(basename.(img), img_dateformat)
# img_df = DataFrame(path=img, date=image_dates)

# Running the computation in parrallel:
addprocs(exeflags="--project")
@everywhere using EcotronAnalysis
@time compute_jpg_temperature_distributed(img_dir, mask_dir, out_dir, climate, delay=delay, img_dateformat=img_dateformat)
rmprocs()
# The results are saved in the out_dir folder, in CSV files named after the images index that were computed in this batch.


# Making a one-file output from this:

# Get all csv files in the output directory, and read them:
all_data = CSV.read(joinpath.(out_dir, filter(x -> occursin(r"\.csv$", x), readdir(out_dir))), DataFrame)

# Saving the data in a compressed csv file:
open(Bzip2CompressorStream, joinpath(out_dir, "leaf_temperature.csv.bz2"), "w") do stream
    CSV.write(stream, all_data)
end

# If you need to check which images were not computed due to a lack of climate measurement in the chamber, you can use this code:
all_dates = DateTime.(filter(x -> occursin(r"^2021.*\.jpg$", x), readdir(img_dir)), img_dateformat) .+ delay
all_dates_round_30s = round.(all_dates, Dates.Second(30))
computed_dates = unique(all_data.DateTime)
not_computed_timesteps = setdiff(all_dates_round_30s, computed_dates)
not_computed_hours = unique(round.(not_computed_timesteps, Dates.Hour(1)))

# Cleaning up the output directory:
rm.(filter(x -> occursin(r"\.csv$", basename(x)), readdir(out_dir, join=true)), force=true)

# Cleaning up the input directory:
rm(dirname(img_dir), force=true, recursive=true)