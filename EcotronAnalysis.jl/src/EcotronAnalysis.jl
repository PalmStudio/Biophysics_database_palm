module EcotronAnalysis

# This is a Julia package for the computation and analysis of data from the Ecotron
# in Montpellier, France.

# Thermal images analysis:
import Distributed
import Distributed: @distributed, @everywhere
using ProgressMeter
using CSV, ArchGDAL, DataFrames, Dates, TimeZones, PolygonOps, Images, Statistics

# Mesh reconstruction:
using PlantGeom
import PlyIO: load_ply
import Meshes
import CoordinateTransformations
using MultiScaleTreeGraph
import ReferenceFrameRotations

include("thermal_images/read_FLIR.jl")
include("thermal_images/parse_mask_name.jl")
include("thermal_images/temperature_from_jpg.jl")
include("thermal_images/temperature_in_mask.jl")
include("thermal_images/compute_all_images.jl")
include("thermal_images/compute_jpg_temperature_distributed.jl")

include("mesh_reconstruction/readply.jl")
include("mesh_reconstruction/meshes_to_opf.jl")


# Thermal images:
export read_FLIR, compute_jpg_temperature_distributed
export meshes_to_opf, readply
end
