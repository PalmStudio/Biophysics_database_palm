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
open(Bzip2DecompressorStream, "0-data/thermal_camera_images/images.tar.bz2") do io
    Tar.extract(io, "0-data/thermal_camera_images/images")
end

# Setting up the paths and climate data:
img_dir = "0-data/thermal_camera_images/images/images"
mask_dir = "0-data/thermal_camera_roi_coordinates/coordinates"
out_dir = @__DIR__

# Climate data (for correcting the leaf temperature from air temperature and humidity):
climate = CSV.read("1-climate/climate_mic3.csv", DataFrame)
# There was a delay in the camera clock of -59m32s (name of the file VS UTC)::
delay_df = CSV.read("2-time-synchronization/time_synchronization.csv", DataFrame)
delay = Second(filter(x -> x.type == "thermal camera", delay_df).delay_seconds[1])

# Date format of the image file names:
img_dateformat = DateFormat("yyyymmdd_HHMMSS_R.jpg")

# Running the computation in parrallel:
addprocs(exeflags="--project")
@everywhere using EcotronAnalysis
@time compute_jpg_temperature_distributed(img_dir, mask_dir, out_dir, climate, delay=delay, img_dateformat=img_dateformat)
rmprocs()

# The results are saved in the out_dir folder, in CSV files named after the images index that were computed in this batch.
# Making a one-file output from this:
out_dir = "0-data/4-thermal_camera_measurements/backup"

# Get all csv files in the output directory, and read them:
all_data = CSV.read(joinpath.(out_dir, filter(x -> occursin(r"\.csv$", x), readdir(out_dir))), DataFrame)

# Join the data together (climate and leaf temperature):
full_df = leftjoin(all_data, climate, on=:DateTime)

# Saving the data in a compressed csv file:
open(Bzip2CompressorStream, joinpath(out_dir, "leaf_temperature.csv.bz2"), "w") do stream
    CSV.write(stream, full_df)
end

