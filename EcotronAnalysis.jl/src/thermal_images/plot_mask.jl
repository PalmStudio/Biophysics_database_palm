#NB: this script is not included in the package, but you still can use it.
"""
    plot_mask(image, mask)

Plot the image and the mask.

# Examples

```julia
using Images, CSV, Plot
img_file = joinpath(dirname(dirname(pathof(EcotronAnalysis))), "test", "test_data", "20210308_180009_R.jpg")
mask_file = joinpath(dirname(dirname(pathof(EcotronAnalysis))), "test", "test_data", "P1F3-20210427_154213-20210428_080428_XY_Coordinates_V1.csv")

plot_mask(img_file, mask_file)
````
"""
function plot_mask(img_file, mask_file)
    img = load(img_file)
    mask = CSV.read(mask_file, DataFrame)
    draw!(img, Polygon([Point(round(i.X), round(i.Y)) for i in eachrow(mask)]), colorant"red")
end