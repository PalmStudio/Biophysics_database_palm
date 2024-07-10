"""
    read_FLIR(file)

Read a FLIR image file and return the image as a matrix of integers.

# Arguments

- `file`: path to the image file.

# Example

```julia
file = 
file = "path/to/file.jpg"
img = read_FLIR(file)
```
"""
function read_FLIR(file)
    isfile(file) || error("File does not exist: $file")
    RawThermalImageType = try
        CSV.File(`exiftool -RawThermalImageType -n -csv $file`).RawThermalImageType[1]
    catch e
        println("Make sure you installed `exiftool` first on your computer, and put it in the PATH.")
        println("Original error: $e")
        return nothing
    end

    if RawThermalImageType != "TIFF"
        error("Image format not compatible, need a TIFF file.")
    end

    # Extract the binary data:
    img = read(`exiftool -b $file`) # Raw tiff

    # Find the magick numbers at the begining of the file
    TIFF = findfirst([0x54, 0x49, 0x46, 0x46, 0x49, 0x49], img)[1]
    img = img[(TIFF+4):end]

    # Write the binary data to a file and re-import using GDAL.
    # ?NOTE: there must be a better way to do that but GDAL needs a file as input...
    img = mktemp() do path, io
        write(io, img)
        ArchGDAL.readraster(path) do img
            collect(img)
        end
    end
    # Convert to integers and reshape as a matrix:
    img = reshape(convert(Array{Int64,3}, img), size(img)[1:2])

    return img
end