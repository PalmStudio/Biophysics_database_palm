"""
    meshes_to_opf(leaves_files, spear_files, bulb_file, pot_file; rot=Rotations.AngleAxis(π, 0, 0, 1), scale=100.0)

Make an OPF from the meshes of the leaves, spears, bulb and pot.

# Arguments

* `leaves_files`: list of paths to the leaves meshes for a plant.
* `spear_files`: list of paths to the spears meshes for a plant.
* `bulb_file`: path to the bulb mesh for a plant.
* `pot_file`: path to the pot mesh for a plant.
* `rot`: rotation to apply to the meshes, by default, a rotation of 180° around the z axis.
* `scale`: scale to apply to the meshes, by default, a scale of 100 to transform from meters to centimeters (required for the OPF).

# Returns

* `opf`: the OPF of the plant.
* `translationxyz`: the translation that was applied to the mesh to put the center of the pot at the origin.
"""
function meshes_to_opf(leaves_files, spear_files, bulb_file, pot_file; rot=Rotations.AngleAxis(π, 0, 0, 1), scale=100.0)

    # Empty reference meshes:
    refmeshes = PlantGeom.RefMeshes(RefMesh[])

    # Create the base of the MTG (plant scale + Pot + first stipe):
    opf = MultiScaleTreeGraph.Node(1, NodeMTG("/", "Plant", 1, 0), Dict{Symbol,Any}())

    # Add the pot:
    mesh = readply(pot_file[1])
    # We need to translate the pot to the origin, and scale it to be in cm instead of m (because of OPF...):
    pot_center = Meshes.centroid(mesh)
    z_min = Meshes.coords(Meshes.boundingbox(mesh).min).z
    translationxyz = [-p for p in Meshes.to(pot_center)]
    translationxyz[3] = -z_min

    mesh_tri =
        push!(
            refmeshes.meshes,
            PlantGeom.RefMesh(
                "Pot",
                # Triangulated quad mesh:
                Meshes.simplexify(mesh |> Meshes.Translate(translationxyz...) |> Meshes.Stretch(scale) |> Meshes.Rotate(rot))
            )
        )
    # Add the Pot to the OPF:
    prev_node = MultiScaleTreeGraph.Node(
        2,
        opf,
        NodeMTG("/", "Pot", 1, 2),
        Dict{Symbol,Any}(
            :geometry => PlantGeom.geometry(
                refmeshes.meshes[end],
                length(refmeshes.meshes),
                TransformsBase.Identity(),
                1,
                1,
                nothing,
            )
        )
    )

    # Adding the bulb:
    mesh = readply(bulb_file[1]) |> Meshes.Translate(translationxyz...) |> Meshes.Stretch(scale) |> Meshes.Rotate(rot)
    mesh_tri =
        push!(
            refmeshes.meshes,
            PlantGeom.RefMesh(
                "Bulb",
                Meshes.simplexify(mesh) # Triangulated quad mesh
            )
        )

    prev_stipe = MultiScaleTreeGraph.Node(
        3,
        prev_node,
        NodeMTG("<", "Bulb", 1, 2),
        Dict{Symbol,Any}(
            :geometry => PlantGeom.geometry(
                refmeshes.meshes[end],
                length(refmeshes.meshes),
                TransformsBase.Identity(),
                1,
                1,
                nothing,
            )
        )
    )

    # First ID starts at 4 (we already created 3 MTG nodes):
    id = [4]

    # Import each leaf mesh, triangulate it and add it as a leaf node after a stipe node
    for i in leaves_files
        # i = leaves_files[1]
        mesh = readply(i) |> Meshes.Translate(translationxyz...) |> Meshes.Stretch(scale) |> Meshes.Rotate(rot)
        mesh_tri = Meshes.simplexify(mesh) # Triangulate the quad mesh for Archimed
        id_leaf = parse(Int, replace(basename(i), ".ply" => "", r"Plant_[0-9]_[0-9][0-9]_[0-9][0-9]_[0-9]{4}_R" => "")) # Get the leaf number
        # Add stipe (no mesh but we want a goof MTG):
        prev_stipe = MultiScaleTreeGraph.Node(id[1], prev_stipe, NodeMTG("<", "Stipe", 1, 3), Dict{Symbol,Any}())
        push!(
            refmeshes.meshes,
            PlantGeom.RefMesh(
                "Rank_$id_leaf",
                mesh_tri
                # , Colors.RGB(1.0, 1.0, 1.0)
            )
        )
        # viz(mesh_tri)
        # Add leaf:
        id[1] += 1
        MultiScaleTreeGraph.Node(
            id[1],
            prev_stipe,
            NodeMTG("+", "Leaf", id_leaf, 3),
            Dict{Symbol,Any}(
                :geometry => PlantGeom.geometry(
                    refmeshes.meshes[end],
                    length(refmeshes.meshes),
                    TransformsBase.Identity(),
                    1,
                    1,
                    nothing
                )
            ) # add geometry here
        )
        # opf[:ref_meshes] = refmeshes; viz(opf)
        id[1] += 1
    end

    # Add the spear if any:
    if length(spear_files) > 0
        prev_stipe = MultiScaleTreeGraph.Node(id[1], prev_stipe, NodeMTG("<", "Stipe", 1, 3), Dict{Symbol,Any}())
        id[1] += 1
        mesh = readply(spear_files[1]) |> Meshes.Translate(translationxyz...) |> Meshes.Stretch(scale) |> Meshes.Rotate(rot)
        mesh_tri = Meshes.simplexify(mesh) # Triangulate the quad mesh for Archimed
        push!(
            refmeshes.meshes,
            PlantGeom.RefMesh(
                "Spear",
                mesh_tri
                # , Colors.RGB(1.0, 1.0, 1.0)
            )
        )
        MultiScaleTreeGraph.Node(
            id[1],
            prev_stipe,
            NodeMTG("+", "Spear", 1, 3),
            Dict{Symbol,Any}(
                :geometry => PlantGeom.geometry(
                    refmeshes.meshes[end],
                    length(refmeshes.meshes),
                    TransformsBase.Identity(),
                    1,
                    1,
                    nothing
                )
            ) # add geometry here
        )
    end

    append!(opf, Dict(:ref_meshes => refmeshes))

    return opf, translationxyz
end