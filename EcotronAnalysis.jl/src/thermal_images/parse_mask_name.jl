"""
    parse_mask_name(mask_name)

Parse a mask file name into a Dictionary with plant name, leaf name, scenario, first and last
images dates.

# Arguments

- `mask_name::String`: The mask file name.

# Examples

```julia
file = joinpath(dirname(dirname(pathof(EcotronAnalysis))), "test", "test_data", "P3F3-S1-S2-S3-20210308_174136-20210309_140728_XY_Coordinates.csv")
parse_mask_name(file)
```
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