using EcotronAnalysis
using GLMakie
using CSV, DataFrames, Dates
using CodecBzip2, Tar # For the extraction of the tar.bz2
using Meshes, Rotations
using PlantGeom, MultiScaleTreeGraph
using Unitful

# Extract the reconstructions from the tar.bz2 file:
!isdir("00-data/lidar/reconstructions") && open(Bzip2DecompressorStream, "00-data/lidar/reconstructions.tar.bz2") do io
    Tar.extract(io, "00-data/lidar/reconstructions")
end

# Extract the lidar point clouds from the tar.bz2 file:
!isdir("00-data/lidar/lidar") && open(Bzip2DecompressorStream, "00-data/lidar/lidar.tar.bz2") do io
    Tar.extract(io, "00-data/lidar/lidar")
end

# List the folders containing the meshes:
reconstruction_folders = filter(x -> startswith(basename(x), "Plant_"), readdir("00-data/lidar/reconstructions", join=true))

# List the lidar sessions:
LiDAR_sessions = filter(x -> startswith(basename(x), "SESSION"), readdir("00-data/lidar/lidar", join=true))

# Reconstruct the OPF for each plant from the set of meshes:
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
    write_opf("10-reconstruction/reconstructions/$(basename(i)).opf", opf)
end

# Save the translations, not that we remove the units for writing:
CSV.write("10-reconstruction/translations.csv", transform(translations, [:x, :y, :z] .=> (x -> ustrip.(x)) .=> [:x, :y, :z]))

# Compress the reconstructions:
begin
    tar_bz = open("10-reconstruction/reconstructions.tar.bz2", write=true)
    tar = Bzip2CompressorStream(tar_bz)
    Tar.create("10-reconstruction/reconstructions", tar)
    close(tar)
end

# Visualize the reconstructions and the lidar point-clouds:
# Choose a plant (1, 2, 3 or 4):
plant = 1

OPFs = readdir("10-reconstruction/reconstructions", join=true)
# Checking that our OPF matches its lidar point-cloud:
sessions = begin
    files_plant = OPFs[findall(x -> startswith(x, "Plant_$(plant)"), basename.(OPFs))]
    folders_dates = replace.(basename.(files_plant), "Plant_$(plant)_" => "", ".opf" => "")
    Date.(folders_dates, dateformat"yyyy_mm_dd")
end

session = sessions[1]

opf = read_opf(files_plant[findfirst(x -> x == session, sessions)])
transform!(opf, refmesh_to_mesh!)
transform!(opf, :geometry => (x -> [coords(i).z for i in x.mesh.vertices]) => :z, ignore_nothing=true)

transl = filter(x -> x.plant == plant && x.date_reconstruction == session, CSV.read("10-reconstruction/translations.csv", DataFrame))

lidar = let
    # 1. Find the lidar session corresponding to the reconstruction:
    folder_session = LiDAR_sessions[findfirst(x -> occursin(Dates.format(session, dateformat"dd_mm_yyyy"), basename(x)), LiDAR_sessions)]
    # Grep the plant in the session:
    session_files = readdir(folder_session, join=true)
    plant_file = session_files[findfirst(x -> "Plant$(plant).txt" == basename(x), session_files)]
    df_ = CSV.read(plant_file, DataFrame, header=["X", "Y", "Z", "Reflectance"], skipto=2)
    LiDAR_points = Meshes.Point[]
    LiDAR_reflectance = Float64[]
    for row in eachrow(df_)
        p = Meshes.Point.(row.X, row.Y, row.Z) |> Meshes.Translate(transl.x[1], transl.y[1], transl.z[1]) |> Meshes.Rotate(rot)
        push!(LiDAR_points, p)
        push!(LiDAR_reflectance, row.Reflectance)
    end
    DataFrame(points=LiDAR_points, Reflectance=LiDAR_reflectance)
end

begin
    # set_theme!(backgroundcolor="#F7F7F7")
    fig = Figure(size=(2400, 1200))
    ax = LScene(fig[1, 1])
    viz!(ax, lidar.points, color=lidar.Reflectance, markersize=5, alpha=0.5)
    viz!(ax, opf, color=:z, showfacets=true, color_vertex=true, alpha=0.5)
    # GLMakie.save("11-outputs/Reconstruction_Plant_$(plant)_$(session).png", fig)
    fig
end


function plot_opf_and_lidar!(ax, plant, session)
    sessions = get_sessions(plant)
    opf_file = files_plant[findfirst(x -> x == session, sessions)]
    opf = read_opf(opf_file)
    transform!(opf, refmesh_to_mesh!)
    transform!(opf, :geometry => (x -> [coords(i).z for i in x.mesh.vertices]) => :z, ignore_nothing=true)

    transl = filter(x -> x.plant == plant && x.date_reconstruction == session, CSV.read("10-reconstruction/translations.csv", DataFrame))

    lidar = let
        # 1. Find the lidar session corresponding to the reconstruction:
        folder_session = LiDAR_sessions[findfirst(x -> occursin(Dates.format(session, dateformat"dd_mm_yyyy"), basename(x)), LiDAR_sessions)]
        # Grep the plant in the session:
        session_files = readdir(folder_session, join=true)
        plant_file = session_files[findfirst(x -> occursin("Plant$(plant).txt", basename(x)), session_files)]
        df_ = CSV.read(plant_file, DataFrame, header=["X", "Y", "Z", "Reflectance"], skipto=2)
        LiDAR_points = Meshes.Point[]
        LiDAR_reflectance = Float64[]
        for row in eachrow(df_)
            p = Meshes.Point.(row.X, row.Y, row.Z) |> Meshes.Translate(transl.x[1], transl.y[1], transl.z[1]) |> Meshes.Rotate(rot)
            push!(LiDAR_points, p)
            push!(LiDAR_reflectance, row.Reflectance)
        end
        DataFrame(points=LiDAR_points, Reflectance=LiDAR_reflectance)
    end

    viz!(ax, lidar.points, color=lidar.Reflectance, markersize=0.1, alpha=0.1)
    viz!(ax, opf, color=:z, showfacets=true, color_vertex=true, alpha=0.5)
end


# Checking that our OPF matches its lidar point-cloud:
function get_sessions(plant; OPFs=readdir("10-reconstruction/reconstructions", join=true))
    files_plant = OPFs[findall(x -> startswith(x, "Plant_$(plant)"), basename.(OPFs))]
    folders_dates = replace.(basename.(files_plant), "Plant_$(plant)_" => "", ".opf" => "")
    Date.(folders_dates, dateformat"yyyy_mm_dd")
end


plant = 1
# set_theme!(backgroundcolor="#F7F7F7")
fig = Figure(size=(2400, 1200))
for (i, session) in enumerate(sessions) # i = 1
    ax = Axis3(fig[1, i], title="Plant $plant session $(Dates.format(session, dateformat"dd/mm/yyyy"))", aspect=:data)
    plot_opf_and_lidar!(ax, plant, session)
end
fig


# Over all plants:

# set_theme!(backgroundcolor="#F7F7F7")
fig = Figure(size=(800, 1200))
for p in [1, 2, 3, 5]
    if p == 5
        p = 4
    end
    sessions = get_sessions(plant)
    for (i, session) in enumerate(sessions) # i = 1
        plant_title = i == 1 ? "Plant $p\n" : "\n"
        title = string(plant_title, "session $(Dates.format(session, dateformat"dd/mm/yyyy"))")
        ax = Axis3(fig[p, i], title=title, aspect=:data, xticklabelsize=8, yticklabelsize=8, zticklabelsize=8, xlabel="", ylabel="", zlabel="")
        plot_opf_and_lidar!(ax, plant, session)
    end
end
fig

save("11-outputs/Reconstructions_LiDAR_all.png", fig)