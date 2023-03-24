using EcotronAnalysis
using PlantGeom, MultiScaleTreeGraph
using GLMakie, Colors
using CSV, DataFrames, Dates
using CodecBzip2, Tar # For the extraction of the tar.bz2

# Extract the reconstructions from the tar.bz2 file:
open(Bzip2DecompressorStream, "00-data/LiDAR/reconstructions.tar.bz2") do io
    Tar.extract(io, "00-data/LiDAR/reconstructions")
end

# Extract the LiDAR point clouds from the tar.bz2 file:
open(Bzip2DecompressorStream, "00-data/LiDAR/LiDAR_data.tar.bz2") do io
    Tar.extract(io, "00-data/LiDAR/LiDAR_data")
end

# List the folders containing the meshes:
reconstruction_folders = filter(x -> startswith(basename(x), "Plant_"), readdir("00-data/LiDAR/reconstructions", join=true))

# List the LiDAR sessions:
LiDAR_sessions = filter(x -> startswith(basename(x), "SESSION"), readdir("00-data/LiDAR/LiDAR_data", join=true))

# Reconstruct the OPF for each plant from the set of meshes:
translations = DataFrame(plant=Int[], date_reconstruction=Date[], x=Float64[], y=Float64[], z=Float64[])
for i in reconstruction_folders
    println("Processing $(basename(i))")
    files = readdir(i, join=true)
    leaves_files = files[findall(x -> occursin(r"^Plant.*R[1-9].ply$", basename(x)), files)]
    spear_files = files[findall(x -> occursin(r"^Plant.*S[1-9].ply$", basename(x)), files)]
    bulb_file = files[findall(x -> occursin(r"^Plant.*bulb.ply$", basename(x)), files)]
    pot_file = files[findall(x -> occursin(r"^Plant.*pot.ply$", basename(x)), files)]

    opf, translationxyz = meshes_to_opf(leaves_files, spear_files, bulb_file, pot_file)

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
end

# Save the translations:
CSV.write("10-reconstruction/translations.csv", translations)

# Compress the reconstructions:
begin
    tar_bz = open("10-reconstruction/reconstructions.tar.bz2", write=true)
    tar = Bzip2CompressorStream(tar_bz)
    Tar.create("10-reconstruction/reconstructions", tar)
    close(tar)
end

# Visualize the reconstructions and the LiDAR point-clouds:
# Choose a plant (1, 2, 3 or 5):
plant = 1

OPFs = readdir("10-reconstruction/reconstructions", join=true)
# Checking that our OPF matches its LiDAR point-cloud:
sessions = begin
    files_plant = OPFs[findall(x -> startswith(x, "Plant_$(plant)"), basename.(OPFs))]
    folders_dates = replace.(basename.(files_plant), "Plant_$(plant)_" => "", ".opf" => "")
    Date.(folders_dates, dateformat"yyyy_mm_dd")
end

session = sessions[1]

opf = read_opf(files_plant[findfirst(x -> x == session, sessions)])
transform!(opf, refmesh_to_mesh!)
transform!(opf, :geometry => (x -> [i.coords[3] for i in x.mesh.vertices]) => :z, ignore_nothing=true)

transl = filter(x -> x.plant == plant && x.date_reconstruction == session, CSV.read("10-reconstruction/translations.csv", DataFrame))

lidar = let
    # 1. Find the LiDAR session corresponding to the reconstruction:
    folder_session = LiDAR_sessions[findfirst(x -> occursin(Dates.format(session, dateformat"dd_mm_yyyy"), basename(x)), LiDAR_sessions)]
    # Grep the plant in the session:
    session_files = readdir(folder_session, join=true)
    plant_file = session_files[findfirst(x -> occursin("Plant$(plant).txt", basename(x)), session_files)]
    df_ = CSV.read(plant_file, DataFrame, header=["X", "Y", "Z", "Reflectance"], skipto=2)
    transform!(df_, :X => (x -> (x .+ transl.x[1]) .* 100) => :X, :Y => (x -> (x .+ transl.y[1]) .* 100) => :Y, :Z => (x -> (x .+ transl.z[1]) .* 100) => :Z)
    df_
end

# Make the figure:
set_theme!(backgroundcolor="#F7F7F7")
fig = Figure(resolution=(2400, 1200))
ax = LScene(fig[1, 1])
scatter!(ax, lidar.X, lidar.Y, lidar.Z, color=lidar.Reflectance, markersize=5, alpha=0.5)
ax2 = LScene(fig[1, 2])
scatter!(ax2, lidar.X, lidar.Y, lidar.Z, color=lidar.Reflectance, markersize=5, alpha=0.5)
viz!(ax2, opf, color=:z, showfacets=true, color_vertex=true, alpha=0.5)
ax3 = LScene(fig[1, 3])
viz!(ax3, opf, color=:z, showfacets=true, color_vertex=true, alpha=0.5)
GLMakie.save("12-outputs/Reconstruction_Plant_$(plant)_$(session).png", fig)