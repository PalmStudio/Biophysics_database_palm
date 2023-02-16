"""
    compute_jpg_temperature_batch(n, mask_dir, img_dir, csv_dir, climate; delay::Dates.TimePeriod,img_dateformat)

Apply `compute_all_images` over a range of images given by `n` (easier for distributed processing).

# Arguments

- `n`: the range of images to process (e.g. `1:100` takes the first 100 images in the folder)
- `mask_dir`: the directory containing the masks
- `img_dir`: the directory containing the images
- `csv_dir`: the directory where the results will be saved
- `climate`: the DataFrame containing the climate data (see below)
- `delay=Dates.Second(3512)`: the delay in the camera clock (default: 3512 seconds as for our experiment)
- `img_dateformat=DateFormat("yyyymmdd_HHMMSS\\_\\R\\.\\j\\p\\g")`: the date format of the images

The `climate` DataFrame is used to correct the temperature measurements with the air temperature
and relative humidity. It should have the following columns:
- DateTime: the date and time of the measurement
- Ta_measurement: the air temperature in °C
- Rh_measurement: the relative humidity in %
"""
function compute_jpg_temperature_batch(
    n, mask_dir, img_dir, csv_dir, climate;
    delay::Dates.TimePeriod=Dates.Second(3512),
    img_dateformat=DateFormat("yyyymmdd_HHMMSS\\_\\R\\.\\j\\p\\g")
)
    # n = partitions[7]
    mask_files = readdir(mask_dir, join=true)
    mask_files = filter(x -> occursin(r".csv$", x), mask_files)

    image_files = readdir(img_dir, join=true)

    image_files = image_files[n]

    df_all = compute_all_images(image_files, mask_files, climate; delay=delay, img_dateformat=img_dateformat)
    CSV.write(joinpath(csv_dir, "leaf_temperature_$(n[1])-$(n[end]).csv"), df_all)
end

"""
    compute_all_images(image_files, mask_files, climate; delay::Dates.TimePeriod, img_dateformat)

Compute the temperature of all leaves in all images given by `image_files` using the masks
given by `mask_files`. The `climate` DataFrame is used to correct the temperature measurements
with the air temperature and relative humidity.

# Arguments

- `image_files`: a vector of paths to the images
- `mask_files`: a vector of paths to the masks
- `climate`: the DataFrame containing the climate data
- `delay`: the delay in the camera clock (default: 3512 seconds as for our experiment)
- `img_dateformat`: the date format of the images (default: `DateFormat("yyyymmdd_HHMMSS\\_\\R\\.\\j\\p\\g")`)

"""
function compute_all_images(
    image_files, mask_files, climate;
    delay::Dates.TimePeriod=Dates.Second(3512),
    img_dateformat=DateFormat("yyyymmdd_HHMMSS\\_\\R\\.\\j\\p\\g")
)

    mask_df = DataFrame(parse_mask_name.(mask_files))
    mask_df[!, :path] = mask_files
    sort!(mask_df, :date_first_image)

    # Import all masks in-memory for efficiency:
    masks = Dict{String,DataFrame}()
    for i in 1:size(mask_df, 1)
        push!(masks, mask_df[i, :path] => CSV.read(mask_df[i, :path], DataFrame))
    end

    image_dates = DateTime.(basename.(image_files), img_dateformat)
    img_df = DataFrame(path=image_files, date=image_dates)

    df_temp = DataFrame(:plant => Int[], :leaf => Int[], :DateTime => DateTime[],
        :Tl_mean => Float64[], :Tl_min => Float64[], :Tl_max => Float64[],
        :Tl_std => Float64[], :n_pixel => Int[], :mask => String[]
    )

    p = Progress(size(img_df, 1), 1)
    for i in 1:nrow(img_df)
        next!(p)
        img_date = img_df[i, :date]
        masks_img_i = filter([:date_first_image, :date_last_image] => (x, y) -> x <= img_date && y >= img_date, mask_df)

        if size(masks_img_i, 1) > 0
            # We have at least one mask for this image
            i_temp =
                try
                    temperature_in_mask(
                        img_df[i, :path],
                        filter(x -> x.first in masks_img_i.path, masks), # use only the filters we need
                        masks_img_i,
                        climate;
                        delay=delay,
                        img_dateformat=img_dateformat
                    )
                catch
                    @info "Issue with image $(img_df[i,:path])"
                end
            if size(i_temp, 1) > 0
                append!(df_temp, i_temp)
            end
        end
    end
    return df_temp
end