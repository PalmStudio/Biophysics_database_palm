### A Pluto.jl notebook ###
# v0.19.42

#> [frontmatter]
#> title = "Plant visualisation"
#> layout = "layout.jlhtml"
#> tags = ["visualisation"]
#> description = "Plant visualisation"

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ a19e5cb1-9154-4f34-ab14-a28e7f0124d5
begin
    using CairoMakie, Meshes, PlantGeom, Rotations
    using Dates, Colors
    using PlutoUI, CSV, DataFrames
	using CodecBzip2, Tar
	using Unitful
	using Pkg
	Pkg.develop(path="../EcotronAnalysis.jl")
	using EcotronAnalysis
end

# ╔═╡ 7c4f9c36-78a0-4a69-8f2d-f28c9de2e1aa
begin
    using JSServe
    Page()
end

# ╔═╡ 54f3d030-c985-11ed-30b9-41f0bdfdae8a
md"""
# Plants visualization

Plants were reconstructed from 3D point clouds using Blender where each leaf was reconstructed independently. Then, each mesh was used to build a 3D plant for its geometry and topology.

In this notebook, we visualize both the reconstruction of the plants and the original point cloud, colored by reflectance. The reflectance helps us identify the reflective tape marking the plant number on the pot. The pot was always put into the chamber with the tape facing forward relative to the door.
"""

# ╔═╡ 27fc581f-68cf-4f9b-a318-69d9bcb51811
md"""
## Dependencies
"""

# ╔═╡ 9de34a24-daad-49d2-8a94-5711b7f46518
md"""
Extract the reconstructions from the tar.bz2 file and get directories for all plants and all sessions.
"""

# ╔═╡ a8262ba2-81e3-4dcf-89b5-8b19ccec328a
reconstruction_folders = let
	!isdir("../00-data/lidar/reconstructions") && open(Bzip2DecompressorStream, "../00-data/lidar/reconstructions.tar.bz2") do io
    	Tar.extract(io, "../00-data/lidar/reconstructions")
	end
	filter(x -> startswith(basename(x), "Plant"), readdir("../00-data/lidar/reconstructions", join=true))
end

# ╔═╡ 882db50c-bc35-4f2b-9d7a-771ddfd1535b
md"""
Extract the lidar point clouds from the tar.bz2 file and get directories for all plants and all sessions.
"""

# ╔═╡ 7d404317-640e-4cc6-b513-5ff9864238a1
lidar_sessions = let
	!isdir("../00-data/lidar/lidar") && open(Bzip2DecompressorStream, "../00-data/lidar/lidar.tar.bz2") do io
    	Tar.extract(io, "../00-data/lidar/lidar")
	end
	filter(x -> startswith(basename(x), "SESSION"), readdir("../00-data/lidar/lidar", join=true))
end

# ╔═╡ 4b962830-26a0-41db-a9e9-3d43de1787d4
md"""
Finaly we reconstruct the OPF for each plant from the set of meshes:
"""

# ╔═╡ 9aacc6ca-39bb-4fc5-ac2d-d2b79df422e7
begin
	rot = Rotations.AngleAxis(π, 0, 0, 1) # Rotate the meshes by 180° around the z-axis
	translations = DataFrame(plant=Int[], date_reconstruction=Date[], x=Any[], y=Any[], z=Any[])
	for i in reconstruction_folders # i = reconstruction_folders[3]
    	println("Processing $(basename(i))")
    	files = readdir(i, join=true)
    	leaves_files = files[findall(x -> occursin(r"^Plant.*R\d+.ply$", basename(x)), files)]
    	sort!(leaves_files, by=x -> parse(Int, match(r"\d+$", splitext(basename(x))[1]).match))
    	spear_files = files[findall(x -> occursin(r"^Plant.*S\d+.ply$", basename(x)), files)]
    	bulb_file = files[findall(x -> occursin(r"^Plant.*bulb.ply$", basename(x)), files)]
    	pot_file = files[findall(x -> occursin(r"^Plant.*pot.ply$", basename(x)), files)]

    	opf, translationxyz = meshes_to_opf(leaves_files, spear_files, bulb_file, pot_file, rot=rot)

    	date_reconstruction = Date(replace(basename(i), r"Plant_[0-9]_" => ""), dateformat"yyyy_mm_dd")
    	plant = parse(Int, replace(basename(i), r"Plant_" => "")[1])
    	df_ = DataFrame(
        	plant=plant,
        	date_reconstruction=date_reconstruction,
        	x=translationxyz[1],
        	y=translationxyz[2],
        	z=translationxyz[3]
    	)

    	append!(translations, df_)
    	write_opf("./reconstructions/$(basename(i)).opf", opf)
	end
	# Save the translations, not that we remove the units for writing:
	CSV.write("./translations.csv", transform(translations, [:x, :y, :z] .=> (x -> ustrip.(x)) .=> [:x, :y, :z]))
	
end

# ╔═╡ c501796d-335c-4625-b44a-136efcfb971d
begin
	reconstruction_dir = "./reconstructions"
    if !isdir(reconstruction_dir)
        open(Bzip2DecompressorStream, "./reconstructions.tar.bz2") do io
            Tar.extract(io, reconstruction_dir)
        end
    end
	OPFs = readdir(reconstruction_dir, join=true)
end

# ╔═╡ 46ecd169-e3dd-4c79-a505-cf87beecddf0
md"""
## Plotting

"""

# ╔═╡ 353e6b49-a886-43b0-bf76-3e1173bd66f0
md"""
Choose the plant:
$(@bind plant_number Select([1,2,3,4]))
"""

# ╔═╡ 57107cea-8ee8-44d9-9885-bf0cc55b194b
sessions = begin
    files_plant = OPFs[findall(x -> startswith(x, "Plant_$(plant_number)"), basename.(OPFs))]
    folders_dates = replace.(basename.(files_plant), "Plant_$(plant_number)_" => "", ".opf" => "")
    Date.(folders_dates, dateformat"yyyy_mm_dd")
end

# ╔═╡ ba76d91a-122b-4062-b69c-6615a9cf2dce
md"""
Select the LiDAR measurement session: $(@bind session Select(sessions))
"""

# ╔═╡ 6a66bfda-c3a9-44fa-81b8-d199d8a5ba88
opf = read_opf(files_plant[findfirst(x -> x == session, sessions)])

# ╔═╡ a85e9e05-4e3b-429e-b5a9-57f03183c954
transl = let
    f = "./translations.csv"
    !isfile(f) && error("File `translations.csv` not found. please run the `build_opfs.jl` script before running this notebook.")
    filter(x -> x.plant == plant_number && x.date_reconstruction == session, CSV.read(f, DataFrame))
end

# ╔═╡ ed81cdbc-6a4b-48d8-be2f-e2f78862d598
lidar = let
    # 1. Find the LiDAR session corresponding to the reconstruction:
    folder_session = lidar_sessions[findfirst(x -> occursin(Dates.format(session, dateformat"dd_mm_yyyy"), basename(x)), lidar_sessions)]

    # Grep the plant in the session:
    session_files = readdir(folder_session, join=true)
    plant_file = session_files[findfirst(x -> "Plant$(plant_number).txt" == basename(x), session_files)]
    df = CSV.read(plant_file, DataFrame, header=["X", "Y", "Z", "Reflectance"], skipto=2)

    rot = Rotations.AngleAxis(π, 0, 0, 1)

    LiDAR_points = Meshes.Point[]
    LiDAR_reflectance = Float64[]
    for row in eachrow(df)
        p = Meshes.Point.(row.X, row.Y, row.Z) |> Meshes.Translate(transl.x[1], transl.y[1], transl.z[1]) |> Meshes.Scale(100.0) |> Meshes.Rotate(rot)
        push!(LiDAR_points, p)
        push!(LiDAR_reflectance, row.Reflectance)
    end
    DataFrame(points=LiDAR_points, reflectance=LiDAR_reflectance)
end

# ╔═╡ 8fd804a5-17bc-43d1-a1b1-c72eccdc4bc8
let
    fig = Figure(size=(2400, 1200))
    ax = LScene(fig[1, 1])
    viz!(ax, lidar.points, color=lidar.reflectance, markersize=5, alpha=0.5)
    viz!(ax, opf, showfacets=true, color_vertex=true, alpha=0.5)
    fig
end

# ╔═╡ 8f3550e7-e8ee-4349-849d-c1aa96470735
let
    fig = Figure(size=(2400, 1200))
    ax = LScene(fig[1, 1])
    viz!(ax, lidar.points, color=lidar.reflectance, markersize=5, alpha=0.5)
    ax2 = LScene(fig[1, 2])
    viz!(ax2, lidar.points, color=lidar.reflectance, markersize=5, alpha=0.5)
    viz!(ax2, opf, showfacets=true, color_vertex=true, alpha=0.5)
    ax3 = LScene(fig[1, 3])
    viz!(ax3, opf, showfacets=true, color_vertex=true, alpha=0.5)
    fig
end

# ╔═╡ Cell order:
# ╠═7c4f9c36-78a0-4a69-8f2d-f28c9de2e1aa
# ╟─54f3d030-c985-11ed-30b9-41f0bdfdae8a
# ╟─27fc581f-68cf-4f9b-a318-69d9bcb51811
# ╠═a19e5cb1-9154-4f34-ab14-a28e7f0124d5
# ╟─9de34a24-daad-49d2-8a94-5711b7f46518
# ╠═a8262ba2-81e3-4dcf-89b5-8b19ccec328a
# ╟─882db50c-bc35-4f2b-9d7a-771ddfd1535b
# ╠═7d404317-640e-4cc6-b513-5ff9864238a1
# ╟─4b962830-26a0-41db-a9e9-3d43de1787d4
# ╠═9aacc6ca-39bb-4fc5-ac2d-d2b79df422e7
# ╠═c501796d-335c-4625-b44a-136efcfb971d
# ╟─46ecd169-e3dd-4c79-a505-cf87beecddf0
# ╟─353e6b49-a886-43b0-bf76-3e1173bd66f0
# ╟─57107cea-8ee8-44d9-9885-bf0cc55b194b
# ╟─ba76d91a-122b-4062-b69c-6615a9cf2dce
# ╠═8fd804a5-17bc-43d1-a1b1-c72eccdc4bc8
# ╠═8f3550e7-e8ee-4349-849d-c1aa96470735
# ╟─6a66bfda-c3a9-44fa-81b8-d199d8a5ba88
# ╠═a85e9e05-4e3b-429e-b5a9-57f03183c954
# ╠═ed81cdbc-6a4b-48d8-be2f-e2f78862d598
