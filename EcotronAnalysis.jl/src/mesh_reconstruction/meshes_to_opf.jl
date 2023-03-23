function meshes_to_opf(leaves_files, spear_files, bulb_file, pot_file)

    # Empty reference meshes:
    refmeshes = PlantGeom.RefMeshes(RefMesh[])

    # Create the base of the MTG (plant scale + Pot + first stipe):
    opf = MultiScaleTreeGraph.Node(1, NodeMTG("/", "Plant", 1, 0), Dict())

    # Add the pot:
    mesh = readply(pot_file[1])
    # We need to translate the pot to the origin, and scale it to be in cm instead of m (because of OPF...):
    pot_center = Meshes.centroid(mesh)
    z_min = Meshes.coordinates(Meshes.boundingbox(mesh).min)[3]
    translationxyz = [-p for p in Meshes.coordinates(pot_center)]
    translationxyz[3] = -z_min

    mesh_tri =
        push!(
            refmeshes.meshes,
            PlantGeom.RefMesh(
                "Pot",
                Meshes.simplexify(mesh |> Meshes.Translate(translationxyz...) |> Meshes.Stretch(100.0)) # Triangulated quad mesh
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
                CoordinateTransformations.IdentityTransformation(),
                1,
                1,
                nothing,
            )
        )
    )

    # Adding the bulb:
    mesh = readply(bulb_file[1]) |> Meshes.Translate(translationxyz...) |> Meshes.Stretch(100.0)
    mesh_tri =
        push!(
            refmeshes.meshes,
            PlantGeom.RefMesh(
                "Bulb",
                Meshes.simplexify(mesh) # Triangulated quad mesh
            )
        )
    # Add the Pot to the OPF:
    prev_stipe = MultiScaleTreeGraph.Node(
        3,
        prev_node,
        NodeMTG("<", "Bulb", 1, 2),
        Dict{Symbol,Any}(
            :geometry => PlantGeom.geometry(
                refmeshes.meshes[end],
                length(refmeshes.meshes),
                CoordinateTransformations.IdentityTransformation(),
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
        mesh = readply(i) |> Meshes.Translate(translationxyz...) |> Meshes.Stretch(100.0)
        mesh_tri = Meshes.simplexify(mesh) # Triangulate the quad mesh for Archimed
        id_leaf = parse(Int, replace(basename(i), ".ply" => "", r"Plant_[0-9]_[0-9][0-9]_[0-9][0-9]_[0-9]{4}_R" => "")) # Get the leaf number
        # Add stipe (no mesh but we want a goof MTG):
        prev_stipe = MultiScaleTreeGraph.Node(id[1], prev_stipe, NodeMTG("<", "Stipe", 1, 3), Dict())
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
                    CoordinateTransformations.IdentityTransformation(),
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
        prev_stipe = MultiScaleTreeGraph.Node(id[1], prev_stipe, NodeMTG("<", "Stipe", 1, 3), Dict())
        id[1] += 1
        mesh = readply(spear_files[1]) |> Meshes.Translate(translationxyz...) |> Meshes.Stretch(100.0)
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
                    CoordinateTransformations.IdentityTransformation(),
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