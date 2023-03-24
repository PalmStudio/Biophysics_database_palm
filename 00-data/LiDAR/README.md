# LiDAR Data

The archive `LiDAR_data.zip` contains the LiDAR data for the four plants. 

Each folder inside the archive is a measurement session were we scanned all four plants with a Riegl VZ400. The data here are the point clouds extracted from the raw data. The raw data are not included here for disk space reasons (44 Go). The raw data can be sent upon request.

The archive `reconstructions.zip` contains the meshes reconstructed from the point clouds. There are four folders for each plant, corresponding to the scan of the plant near a sequence of measurement. In each folder, there are several `.ply` files, *e.g.* for the first date of the first plant: 

- `Plant_1_15_03_2021_bulb.ply`: the mesh of the bulb
- `Plant_1_15_03_2021_bulb.ply`: the mesh of the bulb
- `Plant_1_15_03_2021_R<leaf number>.ply`: the mesh of the leaf number `<leaf number>`, one being the first leaf emitted ever
- `Plant_1_15_03_2021_S<leaf number>.ply`: the mesh of a leaf number `<leaf number>` at the stage of spear
- `Plant_1_15_03_2021_whole.ply`: the complete mesh of the plant

There are also three other files:

- `RecapEcotronSelectionDate.xlsx`: the dates of the LiDAR scans (on which the meshes were reconstructed) and dates of the scenarios
- `EvoArea.csv`: the evolution of the area of the plant at each reconstrucion, computed from the reconstructed meshes
- `surface.csv`: the evolution of the surface of each leaf in the plant over time, computed from the the two previous files