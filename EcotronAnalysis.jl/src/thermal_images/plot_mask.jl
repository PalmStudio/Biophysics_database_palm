#NB: this script is not included in the package, but you still can use it.
"""
    plot_mask(image, mask)

Plot the image and the mask.

# Examples

```julia
using EcotronAnalysis, Images, CSV, Plots, DataFrames
img_file = joinpath(dirname(dirname(pathof(EcotronAnalysis))), "test", "test_data", "20210308_180009_R.jpg")
mask_file = joinpath(dirname(dirname(pathof(EcotronAnalysis))), "test", "test_data", "P1F3-20210427_154213-20210428_080428_XY_Coordinates_V1.csv")

plot_mask(img_file, mask_file)
````
"""

# function plot_mask(img_file, mask_file)

#     img = load(img_file)
#     mask = CSV.read(mask_file, DataFrame)
#     draw!(img, Polygon([Point(round(i.X), round(i.Y)) for i in eachrow(mask)]), colorant"red")
# end

using EcotronAnalysis
img_file = "./EcotronAnalysis.jl/test/test_data/20210308_180009_R.jpg"
mask_file1 = "./EcotronAnalysis.jl/test/test_data/P3F3-S1-S2-S3-20210308_174136-20210309_140728_XY_Coordinates.csv"
mask_file2 = "./EcotronAnalysis.jl/test/test_data/P3F5-S1-S2-S3-20210308_174136-20210309_140728_XY_Coordinates.csv"
mask_file3 = "./EcotronAnalysis.jl/test/test_data/P3F6-S1-S2-S3-20210308_174136-20210309_140728_XY_Coordinates.csv"
mask_file4 = "./EcotronAnalysis.jl/test/test_data/P3F7-S1-S2-S3-20210308_174136-20210309_140728_XY_Coordinates.csv"
	mask1 = CSV.read(mask_file1, DataFrame)
    mask2 = CSV.read(mask_file2, DataFrame)
    mask3 = CSV.read(mask_file3, DataFrame)
    mask4 = CSV.read(mask_file4, DataFrame)
	f = Figure()
	image(
		f[1, 1], 
		Images.load(img_file)',
	    axis = (
			aspect = DataAspect(), 
			yreversed = true,
	        # title = "Mask for leaf 3 from plant 1", 
			# subtitle = "Applicable from 17:41 on the 08/03/2021 to 14:07 on the 09/03/2021",
            title="Masks for plant 3",
            subtitle = "from 08/03/2021 to 09/03/2021",
		)
	)

	poly!(
		f[1, 1], 
		Polygon([Point(round(i.X), round(i.Y)) for i in eachrow(mask1)]), 
		color = "#fef0d9"
	)
    poly!(
		f[1, 1], 
		Polygon([Point(round(i.X), round(i.Y)) for i in eachrow(mask2)]), 
		color = "#fdcc8a"
	)
    poly!(
		f[1, 1], 
		Polygon([Point(round(i.X), round(i.Y)) for i in eachrow(mask3)]), 
		color = "#fc8d59"
	)
    poly!(
		f[1, 1], 
		Polygon([Point(round(i.X), round(i.Y)) for i in eachrow(mask4)]), 
		color = "#d7301f"
	)
	f