using Core:println

"""
    parse_mask_name(mask_name)

Parse a mask file name into a Dictionary with plant name, leaf name, scenario, first and last
images dates.
"""
function parse_mask_name(mask_name)
    # println(mask_name)
    file_name = splitext(basename(mask_name))[1]
    split_file_name = split(file_name, "-")
    plant, leaf = parse.(Int, split(popfirst!(split_file_name)[2:end], "F"))

    info = Dict(:plant => plant, :leaf => leaf, :scenario => [])

    # There may be a list of scenarios in the name:
    i = 0
    while true
        i += 1
        if occursin(r"^[A-Z]", split_file_name[1])
            # This is a scenario name
            push!(info[:scenario], popfirst!(split_file_name))
        else
            break
        end
    end

    # This is the date
    push!(info, :date_first_image => DateTime(popfirst!(split_file_name), DateFormat("yyyymmdd_HHMMSS")))
    push!(info, :date_last_image => DateTime(split(popfirst!(split_file_name), r"_[A-Z\s]")[1], DateFormat("yyyymmdd_HHMMSS")))
    info
end

"""
    distrib_compute(n, mask_dir, img_dir, csv_dir)

Apply `compute_all_images` over a range of images given by `n`.
"""
function distrib_compute(n, mask_dir, img_dir, csv_dir)

    mask_files = readdir(mask_dir, join = true)
    mask_files = filter(x -> occursin(r".csv$", x), mask_files)

    image_files = readdir(img_dir, join = true)

    image_files = image_files[n]

    df_all = compute_all_images(image_files, mask_files, climate_mic3)
    CSV.write(joinpath(csv_dir, "leaf_temperature_$(n[1])-$(n[end]).csv"), df_all)
end

"""
    extract_temperature(img_file, mask_file, climate_file)

Return a summary of the temperature data of the mask(s) in `mask_file` for the `img_file` thermal image.
The computation of the temperature is corrected by the chamber air temperature and relative humidity
measured at the same time.
"""
function extract_temperature(img_file, mask, climate)
    # Importing the chamber temperature and humidity:
    DateTime_img = DateTime(ZonedDateTime(CSV.File(`exiftool -FileModifyDate -n -csv $img_file`).FileModifyDate[1], DateFormat("yyyy:mm:dd HH:MM:SSzzzz")))
    DateTime_img -= Dates.Second(3512) # There was a delay of 58m32s in the camera clock
    DateTime_img = round(DateTime_img, Dates.Second(30)) # round at 30s as for the climate data
    climate_img = filter(:DateTime => ==(DateTime_img), climate)  # Extract climate at that time
    climate_img = select(climate_img, [:Rh_measurement, :Ta_measurement]) # Extract Tair and Rh

    temp_mat = compute_temperature(img_file, climate_img.Ta_measurement[1], climate_img.Rh_measurement[1]) # 1.067s for each image
    # temp_mat = compute_temperature(img_file, 22.0, 0.6)

    (mask_temperature(temp_mat, mask)..., DateTime = DateTime_img)
end

function extract_temperature(img_file, mask::T, mask_info, climate) where T <: Dict{String,DataFrame}
    # Importing the chamber temperature and humidity:
    DateTime_img = DateTime(ZonedDateTime(CSV.File(`exiftool -FileModifyDate -n -csv $img_file`).FileModifyDate[1], DateFormat("yyyy:mm:dd HH:MM:SSzzzz")))
    DateTime_img -= Dates.Second(3512) # There was a delay of 58m32s in the camera clock
    DateTime_img = round(DateTime_img, Dates.Second(30)) # round at 30s as for the climate data
     # Extract climate at that time, and if not found, extract climate at max one minute near it:
    climate_img = filter(:DateTime => x -> x == DateTime_img || x <= DateTime_img + Minute(1) && x >= DateTime_img - Minute(1), climate)

    if size(climate_img, 1) > 1
        climate_img = climate_img[[findmin(abs.(climate_img.DateTime .- DateTime_img))[2]],:]
    elseif size(climate_img, 1) == 0
        # Not meteo time-step found near the image, return an empty DataFrame
        df_temp =  DataFrame(:plant => Int[], :leaf => Int[], :DateTime => DateTime[],
                        :Tl_mean => Float64[], :Tl_min => Float64[], :Tl_max => Float64[],
                        :Tl_std => Float64[], :n_pixel => Int[], :mask =>  String[]
                        )
        println("No climate found near image $(basename(img_file)). Skipping this image.")
        return df_temp
    end

    climate_img = select(climate_img, [:Rh_measurement, :Ta_measurement]) # Extract Tair and Rh

    temp_mat = compute_temperature(img_file, climate_img.Ta_measurement[1], climate_img.Rh_measurement[1]) # 1.067s for each image
    # temp_mat = compute_temperature(img_file, 22.0, 0.6)

    # Import the masks
    df_temp = DataFrame(:plant => Int[], :leaf => Int[], :DateTime => DateTime[],
                        :Tl_mean => Float64[], :Tl_min => Float64[], :Tl_max => Float64[],
                        :Tl_std => Float64[], :n_pixel => Int[], :mask =>  String[]
                        )

    for (k, v) in mask
        mask_info_i = filter(:path => ==(k), mask_info)
        push!(
            df_temp,
            (mask_temperature(temp_mat, v)...,
            DateTime = DateTime_img,
            leaf = mask_info_i.leaf[1],
            plant = mask_info_i.plant[1],
            mask = basename(k))
        )
    end

    return df_temp
end

function compute_all_images(image_files, mask_files, climate)

    mask_df = DataFrame(parse_mask_name.(mask_files))
    mask_df[!,:path] = mask_files
    sort!(mask_df, :date_first_image)

    # Import all masks in-memory for efficiency:
    masks = Dict{String,DataFrame}()
    for i in 1:size(mask_df, 1)
        push!(masks, mask_df[i,:path] => CSV.read(mask_df[i,:path], DataFrame))
    end
    d_format = DateFormat("yyyymmdd_HHMMSS\\_\\R\\.\\j\\p\\g")
    image_dates = DateTime.(basename.(image_files), d_format)
    img_df = DataFrame(path = image_files, date = image_dates)

    df_temp = DataFrame(:plant => Int[], :leaf => Int[], :DateTime => DateTime[],
                        :Tl_mean => Float64[], :Tl_min => Float64[], :Tl_max => Float64[],
                        :Tl_std => Float64[], :n_pixel => Int[], :mask =>  String[]
                        )

    p = Progress(size(img_df, 1), 1)
    for i in 1:size(img_df, 1)
        next!(p)
        img_date = img_df[i,:date]
        masks_img_i = filter([:date_first_image,:date_last_image] => (x, y) -> x <= img_date && y >= img_date, mask_df)

        if size(masks_img_i, 1) > 0
            # We have at least one mask for this image
            i_temp =
            try
                extract_temperature(
                    img_df[i,:path],
                    filter(x -> x.first in masks_img_i.path, masks), # use only the filters we need
                    masks_img_i,
                    climate
                )
            catch
                println("Issue with image $(img_df[i,:path])")
            end
            append!(df_temp, i_temp)
        end
    end
    return df_temp
end


"""
    plot_mask(image, mask)

Plot the image and the mask.

"""
function plot_mask(img_file, mask_file)
    img = load(img_file)
    mask = CSV.read(mask_file, DataFrame)
    draw!(img, Polygon([Point(round(i.X), round(i.Y)) for i in eachrow(mask)]), colorant"red")
end

"""
    mask_temperature(temp_mat, mask)

Extract the temperature of the pixels inside the mask and compute statistics, i.e. mean,
minimum, maximum and std.
"""
function mask_temperature(temp_mat, mask)
    vector_mask = [Array(mask[i,:]) for i in 1:size(mask)[1]]
    push!(vector_mask, vector_mask[1]) # Close the polygon by adding the first point as the last point

    buffer = []
    push!(vector_mask, vector_mask[1]) # Close the polygon by adding the first point as the last point
    [if inpolygon([x, y], vector_mask) != 0 push!(buffer, temp_mat[x,y]) end for x in collect(1:size(temp_mat)[1]), y in collect(1:size(temp_mat)[2])];

    mean_t = mean(buffer)
    min_t = minimum(buffer)
    max_t = maximum(buffer)
    sd_t = std(buffer)

    (Tl_mean = mean(buffer), Tl_min = minimum(buffer), Tl_max = maximum(buffer), Tl_std = std(buffer), n_pixel = length(buffer))
end

function standardize(mat)
    tmin, tmax = extrema(mat)
    tmax_tmin = (tmax - tmin)
    (mat .- tmin) ./ tmax_tmin
end

function standardize(mat, tmin, tmax)
    tmax_tmin = (tmax - tmin)
    (mat .- tmin) ./ tmax_tmin
end

function load_FLIR(file)
    RawThermalImageType = CSV.File(`exiftool -RawThermalImageType -n -csv $file`).RawThermalImageType[1]

    if RawThermalImageType != "TIFF"
        error("Image format not compatible yet")
    end

    # Extract the binary data:
    rawTIFF = read(`exiftool -b $file`)

    # Find the magick numbers at the begining of the file
    TIFF = findfirst([0x54, 0x49, 0x46, 0x46, 0x49, 0x49], rawTIFF)[1]
    rawTIFF = rawTIFF[(TIFF + 4):end]

    # Write the binary data to a file and re-import using GDAL.
    # ?NOTE: there must be a better way to do that but GDAL needs a file as input...
    img = mktemp() do path, io
        write(io, rawTIFF)
        ArchGDAL.readraster(path) do img
            collect(img)
        end
    end

    # Convert to integers and reshape as a matrix:
    img = reshape(convert.(Int, img), size(img)[1:2])

    return img
end


# @btime ArchGDAL.readraster(tempfile)
# @btime convert.(Int64, reinterpret(UInt16, load(tempfile)))
# @btime reinterpret(UInt16, load(tempfile))
"""
    compute_temperature(file, Tair, Rh, emmissivity = 0.98)

Computes the temperature from a FLIR camera image. The `file` argument is the path to the
image. `Tair` is in °C, `Rh` in %. The default `emmissivity` is 0.98 as taken from López et
al. (2012).

# References

López, A., F. D. Molina-Aiz, D. L. Valera, et A. Peña. 2012. « Determining the Emissivity of
the Leaves of Nine Horticultural Crops by Means of Infrared Thermography ». Scientia
Horticulturae 137 (avril): 49‑58. https://doi.org/10.1016/j.scienta.2012.01.022.
"""
function compute_temperature(file, Tair, Rh, emmissivity = 0.98)
            image = load_FLIR(file) # NB: takes ~700ms for an image, compared to 1.8s in R

            vars =
    [
        # "Emissivity", # Measured emissivity - should be ~0.95 or 0.96
        "DateTimeOriginal", # Date of the creation of the file
        "FileModificationDateTime", # date of last file modification
        # Planck constants for camera:
        "PlanckR1",
        "PlanckB",
        "PlanckF",
        "PlanckO",
        "PlanckR2",
        "AtmosphericTransAlpha1", # Atmospheric Transmittance Alpha 1
        "AtmosphericTransAlpha2",
        "AtmosphericTransBeta1",
        "AtmosphericTransBeta2",
        "AtmosphericTransX",     # Atmospheric Transmittance X
        "ObjectDistance", # object distance in metres
        "FocusDistance", # focus distance in metres
        # "ReflectedApparentTemperature",
        # "AtmosphericTemperature", # Atmospheric temperature, should be corrected by measurement
        "IRWindowTemperature",
        "IRWindowTransmission", # IR Window transparency
        # "RelativeHumidity", # Atmospheric Relative Humidity, should be corrected by measurement
        "RawThermalImageHeight", # sensor height (i.e. image height)
        "RawThermalImageWidth"   # sensor width (i.e. image width)
    ]
    #  Original work: R package `Thermimage`.

            parsed_vars = "-" .* vars
    # Read the image metadata:
            mdata = CSV.File(`exiftool $parsed_vars -n -csv $file`)
    # -n means no print conversion
    # -csv means return result in csv format

            temperature(
        image,
        emmissivity, # López et al. (2012), see below for full ref
        # mdata.Emissivity[1], # If you want to use the one from the camera
        mdata.ObjectDistance[1],
        # mdata.ReflectedApparentTemperature[1], # This one we don't know so we take it at Tair
        Tair,
        # mdata.AtmosphericTemperature[1],
        Tair,
        mdata.IRWindowTemperature[1],
        mdata.IRWindowTransmission[1],
        # mdata.RelativeHumidity[1] * 100,
        Rh,
        mdata.PlanckR1[1],
        mdata.PlanckB[1],
        mdata.PlanckF[1],
        mdata.PlanckO[1],
        mdata.PlanckR2[1],
        mdata.AtmosphericTransAlpha1[1],
        mdata.AtmosphericTransAlpha2[1],
        mdata.AtmosphericTransBeta1[1],
        mdata.AtmosphericTransBeta2[1],
        mdata.AtmosphericTransX[1]
)
        end

        """
    temperature(
        raw, E = 1, OD = 1, RTemp = 20, ATemp = RTemp, IRWTemp = RTemp, IRT = 1,
        RH = 50, PR1 = 21106.77, PB = 1501, PF = 1, PO = -7340, PR2 = 0.012545258,
        ATA1=0.006569, ATA2=0.01262, ATB1=-0.002276, ATB2=-0.00667, ATX=1.9
    )


Converts raw thermal data into temperature (°C).

## Arguments

- `raw`: A/D bit signal from FLIR file. FLIR .seq files and .fcf files store data in a 16-bit
encoded value. This means it can range from 0 up to 65535. This is referred to as the raw
value. The raw value is actually what the sensor detects which is related to the radiance
hitting the sensor. At the factory, each sensor has been calibrated against a blackbody
radiation source so calibration values to convert the raw signal into the expected
temperature of a blackbody radiator are provided. Since the sensors do not pick up all
wavelengths of light, the calibration can be estimated using a limited version of Planck's
law. But the blackbody calibration is still critical to this.

- `E`: Emissivity - default 1, should be ~0.95 to 0.97 depending on object of interest.
Determined by user.
- `OD`: Object distance from thermal camera in metres
- `RTemp`: Apparent reflected temperature (oC) of the enrivonment impinging on the object of
interest - one value from FLIR file (oC), default 20C.
- `ATemp`: Atmospheric temperature (oC) for infrared transmission loss - one value from FLIR
file (oC) - default value is set to be equal to the reflected temperature. Transmission loss
is a function of absolute humidity in the air.
- `IRWTemp`: Infrared Window Temperature (oC). Default is set to be equivalent to reflected
temp (oC).
- `IRT`: Infrared Window transmission - default is set to 1.0. Likely ~0.95-0.97. Should be
empirically determined. Germanium windows with anti-reflective coating typically have IRTs ~0.95-0.97.
- `RH`: Relative humidity expressed as percent. Default value is 50.
- `PR1`: PlanckR1 - a calibration constant for FLIR cameras
- `PB`: PlanckB - a calibration constant for FLIR cameras
- `PF`: PlanckF - a calibration constant for FLIR cameras
- `PO`: PlanckO - a calibration constant for FLIR cameras
- `PR2`: PlanckR2 - a calibration constant for FLIR cameras
- `ATA1`: ATA1 - an atmospheric attenuation constant to calculate atmospheric tau
- `ATA2`: ATA2 - an atmospheric attenuation constant to calculate atmospheric tau
- `ATB1`: ATB1 - an atmospheric attenuation constant to calculate atmospheric tau
- `ATB2`: ATB2 - an atmospheric attenuation constant to calculate atmospheric tau
- `ATX`: ATX - an atmospheric attenuation constant to calculate atmospheric tau

## Details

Note: PR1, PR2, PB, PF, and PO are specific to each camera and result from the calibration
at factory of the camera's Raw data signal recording from a blackbody radiation source.

## Value

Returns numeric value in Celsius degrees. Can handle vector or matrix objects.

## Original author ([`Thermimage`](https://github.com/gtatters/Thermimage) R package):

Glenn J. Tattersall

## References

1. http://130.15.24.88/exiftool/forum/index.php/topic,4898.60.html

2. Minkina, W. and Dudzik, S. 2009. Infrared Thermography: Errors and Uncertainties. Wiley Press, 192 pp.
"""
        function temperature(
        raw,
        E = 1, OD = 1, RTemp = 20, ATemp = RTemp, IRWTemp = RTemp,
        IRT = 1, RH = 50, PR1 = 21106.77, PB = 1501, PF = 1, PO = -7340,
        PR2 = 0.012545258, ATA1 = 0.006569, ATA2 = 0.01262, ATB1 = -0.002276,
        ATB2 = -0.00667, ATX = 1.9
    )

            emissivity_wind = 1 - IRT
    reflectivity_wind = 0
            h2o = (RH / 100) * exp(1.5587 + 0.06939 * ATemp - 0.00027816 * ATemp^2 + 6.8455e-07 * ATemp^3)
            tau1 = ATX * exp(-sqrt(OD / 2) * (ATA1 + ATB1 * sqrt(h2o))) +
        (1 - ATX) * exp(-sqrt(OD / 2) * (ATA2 + ATB2 * sqrt(h2o)))
            tau2 = ATX * exp(-sqrt(OD / 2) * (ATA1 + ATB1 * sqrt(h2o))) +
        (1 - ATX) * exp(-sqrt(OD / 2) * (ATA2 + ATB2 * sqrt(h2o)))
            raw_refl1 = PR1 / (PR2 * (exp(PB / (RTemp + 273.15)) - PF)) - PO
            raw_refl1_attn = (1 - E) / E * raw_refl1
            raw_atm1 = PR1 / (PR2 * (exp(PB / (ATemp + 273.15)) - PF)) - PO
            raw_atm1_attn = (1 - tau1) / E / tau1 * raw_atm1
            raw_wind = PR1 / (PR2 * (exp(PB / (IRWTemp + 273.15)) - PF)) - PO
            raw_wind_attn = emissivity_wind / E / tau1 / IRT * raw_wind
            raw_refl2 = PR1 / (PR2 * (exp(PB / (RTemp + 273.15)) - PF)) - PO
            raw_refl2_attn = reflectivity_wind / E / tau1 / IRT * raw_refl2
            raw_atm2 = PR1 / (PR2 * (exp(PB / (ATemp + 273.15)) - PF)) - PO
            raw_atm2_attn = (1 - tau2) / E / tau1 / IRT / tau2 * raw_atm2
            raw_obj = (raw / E / tau1 / IRT / tau2 .- raw_atm1_attn .- raw_atm2_attn .-
        raw_wind_attn .- raw_refl1_attn .- raw_refl2_attn)
            temp_C = PB ./ log.(PR1 ./ (PR2 * (raw_obj .+ PO)) .+ PF) .- 273.15

            return temp_C
        end
