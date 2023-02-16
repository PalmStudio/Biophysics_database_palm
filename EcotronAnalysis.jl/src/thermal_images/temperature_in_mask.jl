"""
    temperature_in_mask(img_file, mask_file, climate; delay::Dates.TimePeriod=Dates.Second(3512))
    temperature_in_mask(img_file, mask::T, mask_info, climate; delay::Dates.TimePeriod=Dates.Second(3512)) where {T<:Dict{String,DataFrame}}

Return a summary of the temperature data in the image within the mask(s) in `mask_file`. The computation of the temperature is corrected by the chamber air temperature and relative humidity
measured at the same time.

The `img_file` is a JPG file from a FLIR camera with the thermal image.

The first method takes a single mask file. The second method takes a dictionary of masks information `mask_info`, 
and a DataFrame `mask` with the mask coordinates. The latter method finds the mask that corresponds to the image
date and time automatically.

The `climate` is a DataFrame file with the following columns:
- DateTime: the date and time of the measurement
- Ta_measurement: the air temperature in °C
- Rh_measurement: the relative humidity in %

The `mask_file` is a CSV file with the following columns:
- plant: the plant number
- leaf: the leaf number
- mask: the path to the mask file

The `delay` is the delay in the camera clock (default: 3512 seconds as for our experiment).

# Examples

```julia
using EcotronAnalysis, DataFrames, CSV, Dates
img_file = joinpath(dirname(dirname(pathof(EcotronAnalysis))), "test", "test_data", "20210308_180009_R.jpg")
mask_file = joinpath(dirname(dirname(pathof(EcotronAnalysis))), "test", "test_data", "P1F3-20210427_154213-20210428_080428_XY_Coordinates_V1.csv")
mask = CSV.read(mask_file, DataFrame)
climate = DataFrame(DateTime=DateTime("2023-02-15T13:07:30"), Ta_measurement=25.0, Rh_measurement=0.3)

temperature_in_mask(img_file, mask, climate)
"""
function temperature_in_mask(img_file, mask, climate; delay::Dates.TimePeriod=Dates.Second(3512))
    # Importing the chamber temperature and humidity:
    DateTime_img = DateTime(basename(img_file), dateformat"yyyymmdd_HHMMSS\\_\\R\\.\\j\\p\\g")
    DateTime_img -= delay
    DateTime_img = round(DateTime_img, Dates.Second(30)) # round at 30s as for the climate data
    climate_img = filter(:DateTime => ==(DateTime_img), climate)  # Extract climate at that time
    climate_img = select(climate_img, [:Rh_measurement, :Ta_measurement]) # Extract Tair and Rh

    temp_mat = temperature_from_jpg(img_file, climate_img.Ta_measurement[1], climate_img.Rh_measurement[1]) # 1.067s for each image

    return (; mask_temperature(temp_mat, mask)..., DateTime=DateTime_img)
end

function temperature_in_mask(img_file, mask::T, mask_info, climate; delay::Dates.TimePeriod=Dates.Second(3512)) where {T<:Dict{String,DataFrame}}
    # Importing the chamber temperature and humidity:
    DateTime_img = DateTime(ZonedDateTime(String(CSV.File(`exiftool -FileModifyDate -n -csv $img_file`).FileModifyDate[1]), DateFormat("yyyy:mm:dd HH:MM:SSzzzz")))
    DateTime_img -= delay # There was a delay of 58m32s in the camera clock
    DateTime_img = round(DateTime_img, Dates.Second(30)) # round at 30s as for the climate data
    # Extract climate at that time, and if not found, extract climate at max one minute near it:
    climate_img = filter(:DateTime => x -> x == DateTime_img || x <= DateTime_img + Minute(1) && x >= DateTime_img - Minute(1), climate)

    if size(climate_img, 1) > 1
        climate_img = climate_img[[findmin(abs.(climate_img.DateTime .- DateTime_img))[2]], :]
    elseif size(climate_img, 1) == 0
        # Not meteo time-step found near the image, return an empty DataFrame
        df_temp = DataFrame(:plant => Int[], :leaf => Int[], :DateTime => DateTime[],
            :Tl_mean => Float64[], :Tl_min => Float64[], :Tl_max => Float64[],
            :Tl_std => Float64[], :n_pixel => Int[], :mask => String[]
        )
        println("No climate found near image $(basename(img_file)). Skipping this image.")
        return df_temp
    end

    climate_img = select(climate_img, [:Rh_measurement, :Ta_measurement]) # Extract Tair and Rh

    temp_mat = temperature_from_jpg(img_file, climate_img.Ta_measurement[1], climate_img.Rh_measurement[1]) # 1.067s for each image
    # temp_mat = temperature_from_jpg(img_file, 22.0, 0.6)

    # Import the masks
    df_temp = DataFrame(:plant => Int[], :leaf => Int[], :DateTime => DateTime[],
        :Tl_mean => Float64[], :Tl_min => Float64[], :Tl_max => Float64[],
        :Tl_std => Float64[], :n_pixel => Int[], :mask => String[]
    )

    for (k, v) in mask
        mask_info_i = filter(:path => ==(k), mask_info)
        push!(
            df_temp,
            (mask_temperature(temp_mat, v)...,
                DateTime=DateTime_img,
                leaf=mask_info_i.leaf[1],
                plant=mask_info_i.plant[1],
                mask=basename(k))
        )
    end

    return df_temp
end


"""
    mask_temperature(temp_mat, mask)

Extract the temperature of the pixels inside the mask and compute statistics, i.e. mean,
minimum, maximum and std.
"""
function mask_temperature(temp_mat, mask)
    vector_mask = [Array(mask[i, :]) for i in 1:size(mask)[1]]
    push!(vector_mask, vector_mask[1]) # Close the polygon by adding the first point as the last point

    buffer = []
    push!(vector_mask, vector_mask[1]) # Close the polygon by adding the first point as the last point
    [
        if inpolygon([x, y], vector_mask) != 0
            push!(buffer, temp_mat[x, y])
        end for x in collect(1:size(temp_mat)[1]), y in collect(1:size(temp_mat)[2])
    ]

    (Tl_mean=mean(buffer), Tl_min=minimum(buffer), Tl_max=maximum(buffer), Tl_std=std(buffer), n_pixel=length(buffer))
end