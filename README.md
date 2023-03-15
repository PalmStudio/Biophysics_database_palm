# Ecotron 2021

The Ecotron is a controlled environment facility for plants located in Montpellier, France. In this work, we made an experiment that consisted in investigating the behavior of oil palm (*Elaeis guineensis*) in response to different environmental conditions. The conditions were defined based on an average daily variation from Libo, Indonesia, *i.e.* a day without rain, not too cold, not too hot. This base condition was then modified by adding more CO2, less radiation, more or less temperature, and more or less vapor pressure deficit. 

The height resulting conditions were the following:

- 400ppm: the base condition
- 600ppm: 50% more CO2
- 800ppm: 100% more CO2
- Cloudy: the same as base condition but with the PAR values based on the most cloudy day of our database from Sumatra. The dynamic of the PAR is kept as in the base condition though. The maximum PPFD was 130 µmol m² s⁻¹ at 51cm from the lamps, compared to 300 in the reference scenario.
- Cold: -30% °C compared to the base condition
- Hot: +30% °C
- DryCold: -30% relative humidity and -30% °C
- DryHot: -30% relative humidity and +30% °C
 
Two microcosms where used during 2 months to measure each of four plants with each condition. The two microcosms are 114cm (Width) x 113cm (Depth) x 152cm (Height) chambers with a radiation and climate control system that can precisely control the temperature, humidity, and CO2 concentration. The first microcosm was used to store the plants, always following the base conditions, and the second one was used to perform the experiment on different conditions. 

Measurements included: 

- CO2 fluxes with a Picarro G2101-i, measuring the CO2 concentration in the chamber for 5 minutes, and input CO2 concentration for 5 minutes
- H2O fluxes with a precision scale, considering that any change in the weight of the potted plant is due to loss of H2O fluxes by transpiration, as the pot was seeled with a plastic film during the experiment in the second microcosm. The code to control the scale is available [here](https://github.com/ARCHIMED-platform/Precision_scale-Raspberry_Pi)
- Leaf temperature, measured with a thermal camera
- LiDAR scans of the plants each week, using a Riegl VZ400. Each plant was extracted from the co-registered point clouds using Riegl RiSCAN Pro. The plants were then reconstructed using Blender.
- Biomass and surface measurements of all organs of the plants were also performed at the end of the experiment.
- SPAD measurements of each leaf of the plants
- A-Cᵢ and Gs-A/(Cₐ√Dₗ) response curves using a portable gas analyzer (Walz GFS-3000) for model calibration

This repository does not contain the raw thermal images and the raw LiDAR data taken during the experiment, because they are too large to be stored on Git (images: 60Go, 24Go when compressed). The data is available on a dedicated repository in Zenodo.

## Folder structure

```
This folder
├── 0-data                         --> Contains raw, unprocessed data
│   ├── LiDAR                      --> LiDAR data for the 3D reconstruction of the plants
│   │   ├── LiDAR_data.zip         --> LiDAR point clouds for each plant and session
│   │   ├── README.md              --> Instructions on how to use the LiDAR data
│   │   └── reconstructions.zip    --> 3D reconstructions of the plants
│   ├── climate                    --> Climatic data from the growth chamber
│   │   ├── README.md   
│   │   └── climate.zip            --> Climatic data archive
│   ├── door_opening               --> Door opening data (when the door of the chamber was opened / closed)
│   │   ├── Mic3_door_opening.csv  --> Door opening data for the Mic3 chamber (Mic means microcosm)
│   │   └── Mic4_door_opening.csv  --> Door opening data for the Mic4 chamber
│   ├── morphology_and_biomass     --> Morphological and biomass data from desctruction at the end (weight, height, etc.)
│   │   ├── bulbs_weight.csv       --> Bulb weight data
│   │   ├── leaves_weight.csv      --> Leaves weight data
│   │   └── roots_weight.csv       --> Roots weight data
│   ├── picarro_flux               --> CO2 flux data from the Picarro
│   │   ├── data_mean_flux.csv     --> Mean CO2 flux data
│   │   └── outliers.csv           --> Outliers data identified by hand
│   ├── scale_weight               --> Weight data from the scale
│   │   ├── README.md          
│   │   └── weights.tar.bz2        --> Weight data archive
│   ├── scenario_sequence          --> Sequence of the scenarios
│   │   ├── SequencePlanteMicro3.csv  --> Sequence of measurement in Mic3 for the plants
│   │   └── SequenceScenarioMicro3.csv --> Sequence of the scenarios in Mic3 for each day
│   ├── smse                       --> Reference meteorological data from Sumatra 2008-2018
│   │   └── Meteo_hour_SMSE.csv    
│   ├── spad                       --> SPAD measurement data
│   │   ├── SPAD.csv               --> measured for all leaves in the plant of interest, dynamically throughout experiment.
│   │   └── SPAD_all_plants.csv    --> measured on all leaves of all plants on the same date, repeated twice (2021-02-16, 2021-02-23).
│   ├── thermal_camera_images      --> Thermal camera images
│   │   ├── README.md 
│   │   └── images.tar.bz2         --> Thermal camera images archive (see Zenodo archive to get it)
│   ├── thermal_camera_roi_coordinates --> Coordinates of the ROI (Region of Interest) for the thermal camera images
│   │   ├── README.md
│   │   ├── ROI.zip                --> ROI coordinates archive
│   │   └── coordinates.tar.bz2    --> ROI coordinates as X and Y coordinates in CSV
│   └── walz                       --> Walz GFS-3000 portable gas analyzer data
│       ├── README.md
│       └── walz.tar.bz2           --> Walz data archive
├── 2-climate                      --> Contains processed climatic data
│   ├── climate_mic3.csv           --> Climatic data for Mic3
│   ├── climate_mic3_10min.csv     --> Climatic data for Mic3, aggregated to 10 minutes matching CO2 inut/output measurement cycle
│   ├── climate_mic3_5min.csv      --> Climatic data for Mic3, aggregated to 5 minutes matching CO2 output measurement
│   ├── climate_mic4.csv           --> Climatic data for Mic4
│   └── climate_notebook.jl        --> Notebook to process climatic data
├── 3-time-synchronization         --> Computation of the data to synchronize all sensors to UTC time
│   ├── README.md
│   ├── correspondance_scale_camera_time.csv --> Correspondance between the scale and the thermal camera
│   ├── time_synchronization.csv             --> Time synchronization data
│   └── time_synchronization_notebook.jl     --> Notebook to compute time synchronization data
├── 4-CO2                          --> Processed CO2 data
│   ├── CO2_fluxes.csv             --> CO2 fluxes data
│   └── CO2_notebook.jl            --> Notebook to process CO2 data
├── 5-thermal_camera_measurements  --> Processed thermal camera data
│   ├── 1-compute_leaf_temperature.jl --> Script to compute leaf temperature (careful, it takes several hours to process)
│   ├── 2-vizualise_temperature.jl --> Notebook to vizualise processed leaf temperature
│   └── leaf_temperature.csv.bz2   --> Leaf temperature data (at 1min time-scale, but with information to match with CO2 fluxes)
├── 6-transpiration                --> Processed plant transpiration data
│   ├── README.md
│   ├── plant_sequence_delayed_corrected.csv --> Plant sequence with corrected delay
│   ├── transpiration_10min.csv.bz2 --> Plant transpiration data aggregated to match the 10 minutes CO2 measurement
│   ├── transpiration_first_5min.csv.bz2 --> Plant transpiration data aggregated to match the 5min output CO2 measurement
│   └── transpiration_notebook.jl  --> Notebook to process plant transpiration data 
├── 7-walz                         --> Processed Walz data
│   ├── notebook_walz.jl           --> Notebook to process Walz data
│   └── photosynthetic_and_stomatal_parameters.csv --> Computed photosynthetic and stomatal parameters data
├── 8-spad                         --> Processed SPAD data
│   ├── SPAD_models.csv            --> SPAD models
│   └── notebook_spad.jl           --> Notebook to process SPAD data
├── 9-database                     --> Database of all processed data
│   ├── database_10min.csv.bz2     --> Database of all processed data aggregated to match the 10min CO2 measurement
│   ├── database_5min.csv.bz2      --> Database of all processed data aggregated to match the 5min output CO2 measurement
│   └── database_notebook.jl       --> Notebook to process the database
├── EcotronAnalysis.jl             --> Package to process the thermal camera data
│   ├── LICENSE
│   ├── Manifest.toml
│   ├── Project.toml
│   ├── README.md
│   ├── src
│   │   ├── EcotronAnalysis.jl
│   │   └── thermal_images
│   │       ├── compute_all_images.jl
│   │       ├── compute_jpg_temperature_distributed.jl
│   │       ├── parse_mask_name.jl
│   │       ├── plot_mask.jl
│   │       ├── read_FLIR.jl
│   │       ├── temperature_from_jpg.jl
│   │       └── temperature_in_mask.jl
│   └── test
│       ├── runtests.jl
│       └── test_data
│           ├── 20210308_180009_R.jpg
│           └── P1F3-20210427_154213-20210428_080428_XY_Coordinates_V1.csv
├── Manifest.toml                  --> Manifest of the Julia environment (tracks dependencies versions)
├── Project.toml                   --> Project of the Julia environment  (tracks dependencies)
└── README.md                      --> This file
```


## To do

- [ ] Check all data
- [ ] Make a release of the data on Zenodo
- [ ] Use https://github.com/JuliaImages/ExifViewer.jl now that https://github.com/JuliaImages/ExifViewer.jl/issues/17 is fixed
- [ ] Reconstruct the plants in 3d:
  - [ ] Separate each leaf and make a mesh for it. Then identify it and name it accordingly.
  - [ ] Make an OPF for each plant from this collection of leaf meshes, using them as ref. meshes with no transformation
  - [ ] Add attributes such as SPAD and photosynthetic and conductance parameters.