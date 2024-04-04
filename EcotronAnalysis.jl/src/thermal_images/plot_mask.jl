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

begin
    using CSV
    using DataFrames
    using CairoMakie
    using AlgebraOfGraphics
    using CodecBzip2
    using Colors
	using Images
	using Makie.GeometryBasics
end
# img_file = "./EcotronAnalysis.jl/test/test_data/20210308_180009_R.jpg"
# mask_file1 = "./EcotronAnalysis.jl/test/test_data/P3F3-S1-S2-S3-20210308_174136-20210309_140728_XY_Coordinates.csv"
# mask_file2 = "./EcotronAnalysis.jl/test/test_data/P3F5-S1-S2-S3-20210308_174136-20210309_140728_XY_Coordinates.csv"
# mask_file3 = "./EcotronAnalysis.jl/test/test_data/P3F6-S1-S2-S3-20210308_174136-20210309_140728_XY_Coordinates.csv"
# mask_file4 = "./EcotronAnalysis.jl/test/test_data/P3F7-S1-S2-S3-20210308_174136-20210309_140728_XY_Coordinates.csv"
img_file = "./EcotronAnalysis.jl/test/test_data/20210318_080105_R.jpg"
mask_file1 = "./EcotronAnalysis.jl/test/test_data/P1F3-S1-S2-S3-20210315_162104-20210318_173106_XY_Coordinates_V11.csv"
mask_file2 = "./EcotronAnalysis.jl/test/test_data/P1F4-S1-S2-S3-20210315_162104-20210318_173106_XY_Coordinates_V11.csv"
mask_file3 = "./EcotronAnalysis.jl/test/test_data/P1F6-S1-S2-S3-20210315_162104-20210318_173106_XY_Coordinates_V11.csv"
mask_file4 = "./EcotronAnalysis.jl/test/test_data/P1F7-S1-S2-S3-20210315_162104-20210318_173106_XY_Coordinates_V11.csv"
mask_file5 = "./EcotronAnalysis.jl/test/test_data/P1F8-S1-S2-S3-20210315_162104-20210318_173106_XY_Coordinates_V11.csv"

mask1 = CSV.read(mask_file1, DataFrame)
mask2 = CSV.read(mask_file2, DataFrame)
mask3 = CSV.read(mask_file3, DataFrame)
mask4 = CSV.read(mask_file4, DataFrame)
mask5 = CSV.read(mask_file5, DataFrame)
	f = Figure()
	image(
		f[1, 1], 
		Images.load(img_file)',
	    axis = (
			aspect = DataAspect(), 
			yreversed = true,
	        # title = "Mask for leaf 3 from plant 1", 
			# subtitle = "Applicable from 17:41 on the 08/03/2021 to 14:07 on the 09/03/2021",
            # title="Masks for plant 3",
            # subtitle = "from 08/03/2021 to 09/03/2021",
			title="Masks for plant 1",
            subtitle = "from 15/03/2021 to 18/03/2021",
		)
	)

	poly!(
		f[1, 1], 
		Polygon([Point(round(i.X), round(i.Y)) for i in eachrow(mask1)]), 
		color = "#fee5d9"
	)
    poly!(
		f[1, 1], 
		Polygon([Point(round(i.X), round(i.Y)) for i in eachrow(mask2)]), 
		color = "#fcae91"
	)
    poly!(
		f[1, 1], 
		Polygon([Point(round(i.X), round(i.Y)) for i in eachrow(mask3)]), 
		color = "#fb6a4a"
	)
    poly!(
		f[1, 1], 
		Polygon([Point(round(i.X), round(i.Y)) for i in eachrow(mask4)]), 
		color = "#de2d26"
	)
	poly!(
		f[1, 1], 
		Polygon([Point(round(i.X), round(i.Y)) for i in eachrow(mask5)]), 
		color = "#a50f15"
	)
	f


### scenario Hot
img_file = "./EcotronAnalysis.jl/test/test_data/20210406_065534_R.jpg"
mask_file1 = "./EcotronAnalysis.jl/test/test_data/P5F2-S4-S5-S6-S7-S8-20210402_152208-20210408_080421_XY_Coordinates_V1.csv"
mask_file2 = "./EcotronAnalysis.jl/test/test_data/P5F4-S4-S5-S6-S7-S8-20210402_152208-20210408_080421_XY_Coordinates_V1.csv"
mask_file3 = "./EcotronAnalysis.jl/test/test_data/P5F6-S4-S5-S6-S7-S8-20210402_152208-20210408_080421_XY_Coordinates_V1.csv"
mask_file4 = "./EcotronAnalysis.jl/test/test_data/P5F7-S4-S5-S6-S7-S8-20210402_152208-20210408_080421_XY_Coordinates_V1.csv"
mask_file5 = "./EcotronAnalysis.jl/test/test_data/P5F8-S4-S5-S6-S7-S8-20210402_152208-20210408_080421_XY_Coordinates_V1.csv"
mask_file6 = "./EcotronAnalysis.jl/test/test_data/P5F9-S4-S5-S6-S7-S8-20210402_152208-20210408_080421_XY_Coordinates_V1.csv"
mask_file7 = "./EcotronAnalysis.jl/test/test_data/P5F10-S4-S5-S6-S7-S8-20210402_152208-20210408_080421_XY_Coordinates_V1.csv"

mask1 = CSV.read(mask_file1, DataFrame)
mask2 = CSV.read(mask_file2, DataFrame)
mask3 = CSV.read(mask_file3, DataFrame)
mask4 = CSV.read(mask_file4, DataFrame)
mask5 = CSV.read(mask_file5, DataFrame)
mask6 = CSV.read(mask_file6, DataFrame)
mask7 = CSV.read(mask_file7, DataFrame)
	f = Figure()
	image(
		f[1, 1], 
		Images.load(img_file)',
	    axis = (
			aspect = DataAspect(), 
			yreversed = true,
			title="Masks for plant 4",
            subtitle = "from 02/04/2021 to 08/04/2021",
		)
	)

	poly!(
		f[1, 1], 
		Polygon([Point(round(i.X), round(i.Y)) for i in eachrow(mask1)]), 
		color = "#fee5d9"
	)
    poly!(
		f[1, 1], 
		Polygon([Point(round(i.X), round(i.Y)) for i in eachrow(mask2)]), 
		color = "#fcae91"
	)
    poly!(
		f[1, 1], 
		Polygon([Point(round(i.X), round(i.Y)) for i in eachrow(mask3)]), 
		color = "#fb6a4a"
	)
    poly!(
		f[1, 1], 
		Polygon([Point(round(i.X), round(i.Y)) for i in eachrow(mask4)]), 
		color = "#de2d26"
	)
	poly!(
		f[1, 1], 
		Polygon([Point(round(i.X), round(i.Y)) for i in eachrow(mask5)]), 
		color = "#a50f15"
	)
	f
