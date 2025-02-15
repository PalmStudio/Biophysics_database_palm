# Ecotron 2021

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.12704284.svg)](https://doi.org/10.5281/zenodo.12704284)

- [Ecotron 2021](#ecotron-2021)
  - [Folder structure](#folder-structure)
  - [Database](#database)
  - [Notebook links](#notebook-links)
    - [Climate](#climate)
    - [Time synchronization](#time-synchronization)
    - [CO₂ fluxes](#co-fluxes)
    - [Leaf temperature](#leaf-temperature)
    - [H₂O fluxes (transpiration)](#ho-fluxes-transpiration)
    - [Leaf gas exchange](#leaf-gas-exchange)
    - [SPAD](#spad)
    - [Making the database](#making-the-database)
    - [3D reconstructions](#3d-reconstructions)
  - [Usage](#usage)
    - [Pluto](#pluto)
      - [Install Pluto](#install-pluto)
      - [Open a notebook](#open-a-notebook)
    - [Download and instantiate](#download-and-instantiate)

The Ecotron is a controlled environment facility for plants located in Montpellier, France. In this work, we did an experiment that investigated the behaviour of oil palm (*Elaeis guineensis*) in response to different environmental conditions. The conditions were defined based on an average daily variation from Libo, Indonesia, *i.e.* a day with no rainfall and near-average air temperature and humidity. This base condition was then modified by adding more CO2, less radiation, more or less temperature, and more or less vapour pressure deficit.

The height resulting conditions were the following:

- 400ppm: the base condition
- 600ppm: 50% more CO2
- 800ppm: 100% more CO2
Cloudy: This is the same as the base condition but with the PAR values based on the most cloudy day in our database from Sumatra. The PAR dynamic is kept the same as in the base condition, though. The maximum PPFD was 130 µmol m² s⁻¹ at 51cm from the lamps, compared to 300 in the reference scenario.
- Cold: -30% °C compared to the base condition
- Hot: +30% °C
- DryCold: -30% relative humidity and -30% °C
- DryHot: -30% relative humidity and +30% °C

Two microcosms were used during 2 months to measure each of the four plants with each condition. The two microcosms are 114cm (Width) x 113cm (Depth) x 152cm (Height) chambers with a radiation and climate control system that can precisely control the temperature, humidity, and CO2 concentration. The first microcosm was used to store the plants, always following the base conditions, and the second one was used to experiment on different situations.

Measurements included:

- Climate data inside the microcosm
- CO2 fluxes with a Picarro G2101-i, measuring the CO2 concentration in the chamber for 5 minutes, and input CO2 concentration for 5 minutes
- H2O fluxes with a precision scale, considering that any change in the weight of the potted plant is due to loss of H2O fluxes by transpiration, as the pot was sealed with a plastic film during the experiment in the second microcosm. The code to control the scale is available [here](https://github.com/PalmStudio/Precision_scale-Raspberry_Pi) [![DOI](https://zenodo.org/badge/385182511.svg)](https://doi.org/10.5281/zenodo.14862493)
- Leaf temperature, measured with a thermal camera. The code to control the camera is available [here](https://github.com/PalmStudio/FLIR_Vue_Pro-Raspberry_Pi) [![DOI](https://zenodo.org/badge/384170107.svg)](https://doi.org/10.5281/zenodo.14862497)
- Lidar scans of the plants are done each week using a Riegl VZ400. Each plant was extracted from the co-registered point clouds using Riegl RiSCAN Pro. The plants were then reconstructed using Blender.
- Biomass and surface measurements of all plant organs were also performed at the end of the experiment.
- SPAD measurements of each leaf of the plants
- A-Cᵢ and Gs-A/(Cₐ√Dₗ) response curves using a portable gas analyzer (Walz GFS-3000) for model calibration
- Light mapping in the microcosm with a Sunscan device (Delta-T)

This repository does not contain the raw thermal images and the raw lidar data taken during the experiment because they are too large to be stored on Git (images: 60Go, 24Go when compressed). The data is available on a [dedicated repository in Zenodo](https://doi.org/10.5281/zenodo.12704284).

Here are the reconstructions of the plants on top of the point clouds over time:

![3d reconstruction](11-outputs/Reconstructions_LiDAR_all.png)

## Folder structure

```text
This folder
├── 00-data                        --> Contains raw, unprocessed data
│   ├── lidar                      --> lidar data for the 3D reconstruction of the plants
│   │   ├── lidar.tar.bz2          --> lidar point clouds for each plant and session
│   │   ├── README.md              --> Instructions on how to use the lidar data
│   │   └── reconstructions.tar.bz2 -> 3D reconstructions of the plants
│   ├── climate                    --> Climatic data from the growth chamber
│   │   ├── README.md
│   │   └── climate.zip            --> Climatic data archive
│   ├── door_opening               --> Door opening data (when the door of the chamber was opened/closed)
│   │   ├── Mic3_door_opening.csv  --> Door opening data for the Mic3 chamber (Mic means microcosm)
│   │   └── Mic4_door_opening.csv  --> Door opening data for the Mic4 chamber
│   ├── morphology_and_biomass     --> Morphological and biomass data from destruction at the end (weight, height, etc.)
│   │   ├── bulbs_weight.csv       --> Bulb weight data
│   │   ├── leaves_weight.csv      --> Leaves weight data
│   │   └── roots_weight.csv       --> Roots weight data
│   ├── picarro_flux                --> CO2 flux data from the Picarro
│   │   ├── data_mean_flux.csv      --> Mean CO2 flux data
│   │   └── data_mean_flux.xlsx     --> Mean CO2 flux data in Excel format (original format)
│   ├── scale_weight               --> Weight data from the scale
│   │   ├── README.md
│   │   └── weights.tar.bz2        --> Weight data archive
│   ├── scenario_sequence          --> Sequence of the scenarios
│   │   ├── README.md              --> Instructions on how to use the scenario sequence data
│   │   ├── SequencePlanteMicro3.csv -> Sequence of measurement in Mic3 for the plants
│   │   └── SequenceScenarioMicro3.csv -> Sequence of the scenarios in Mic3 for each day
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
├── 01-climate                     --> Contains processed climatic data
│   ├── climate_mic3.csv           --> Climatic data for Mic3
│   ├── climate_mic3_10min.csv     --> Climatic data for Mic3, aggregated to 10 minutes matching CO2 input/output measurement cycle
│   ├── climate_mic3_5min.csv      --> Climatic data for Mic3, aggregated to 5 minutes matching CO2 output measurement
│   ├── climate_mic4.csv           --> Climatic data for Mic4
│   └── climate_notebook.jl        --> Notebook to process climatic data
├── 02-time-synchronization        --> Computation of the data to synchronize all sensors to UTC
│   ├── README.md
│   ├── match_scale_camera_time.csv -> Match between the scale and the thermal camera
│   ├── time_synchronization.csv   --> Time synchronization data
│   └── time_synchronization_notebook.jl -> Notebook to compute time synchronization data
├── 03-CO2                         --> Processed CO2 data
│   ├── CO2_fluxes.csv              --> CO2 fluxes data
│   └── CO2_notebook.jl            --> Notebook to process CO2 data
├── 04-thermal_camera_measurements --> Processed thermal camera data
│   ├── 1-compute_leaf_temperature.jl -> Script to compute leaf temperature (careful, it takes several hours to process)
│   ├── 2-visualize_temperature_notebook.jl -> Notebook to visualize processed leaf temperature
│   └── leaf_temperature.csv.bz2   --> Leaf temperature data (at 1min time-scale, but with information to match with CO2 fluxes)
├── 05-transpiration               --> Processed plant transpiration data
│   ├── README.md
│   ├── plant_sequence_delayed_corrected.csv --> Plant sequence with corrected delay
│   ├── transpiration_10min.csv.bz2 -> Plant transpiration data aggregated to match the 10 minutes CO2 measurement
│   ├── transpiration_first_5min.csv.bz2 -> Plant transpiration data aggregated to match the 5min output CO2 measurement
│   └── transpiration_notebook.jl  --> Notebook to process plant transpiration data
├── 06-walz                        --> Processed Walz data
│   ├── notebook_walz.jl           --> Notebook to process Walz data
│   └── photosynthetic_and_stomatal_parameters.csv -> Computed photosynthetic and stomatal parameters data
├── 07-spad                        --> Processed SPAD data
│   ├── SPAD_models.csv            --> SPAD models
│   └── notebook_spad.jl           --> Notebook to process SPAD data
├── 08-reconstruction
│   ├── build_opfs.jl              --> Script to make OPF files out of the 3D reconstructions of the plants
│   ├── reconstructions.tar.bz2    --> 3D reconstructions of the plants, as a list of OPF files
│   ├── translations.csv           --> Translations to match OPF files and point clouds (OPFs are center the pot to the origin)
│   └── visualize_plants_notebook.jl -> Notebook to visualize the plants in 3D
├── 09-database                    --> Database of all processed data
│   ├── columns.csv                --> Description of the columns in the database
│   ├── database_10min.csv.bz2     --> Database of all processed data aggregated to match the 10min CO2 measurement
│   ├── database_5min.csv.bz2      --> Database of all processed data aggregated to match the 5min output CO2 measurement
│   ├── database_notebook.jl       --> Notebook to process the database
│   └── plant_surface.csv          --> Measured plant surfaces
├── 11-outputs
│   └── Reconstructions_LiDAR_all.png --> One of the outputs tracked in the repository
├── EcotronAnalysis.jl             --> Package to process the thermal camera data
│   └── ...
├── Manifest.toml                  --> Manifest of the Julia environment (tracks dependencies versions)
├── Project.toml                   --> Project of the Julia environment  (tracks dependencies)
└── README.md                      --> This file
```

## Database

The database of all processed data is in the `09-database` folder or in the releases of this repository. It is available in two versions: one aggregated to match the 10-minute CO2 measurement and one aggregated to match the 5-minute output CO2 measurement.

The database is a compressed CSV file (`.csv.bz2`) and can be read using the following command:

``` bash
bzip2 -d database_5min.csv.bz2
```

Or using Julia with the following command:

``` julia
using CSV, DataFrames, CodecBzip2
db = open(Bzip2DecompressorStream, "./09-database/database_5min.csv.bz2") do io
    CSV.read(io, DataFrame)
end
```

The database has the following columns:

| name                     | Unit             | type              | Description                                                                                                                                                    |     |
|--------------------------|------------------|-------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------|-----|
| DateTime_start           | UTC              | ISODateTimeFormat | DateTime of the start of the measurement                                                                                                                       |     |
| DateTime_end             | UTC              | ISODateTimeFormat | DateTime of the end of the measurement (either the 5-min output measurement window or the whole 10-min output-input)                                          |     |
| Plant                    | \-               | Int               | Plant ID                                                                                                                                                       |     |
| Leaf                     | ID               | Int               | Leaf ID, leaf ID 1 is the first emitted leaf (the oldest)                                                                                                      |     |
| Scenario                 | \-               | String            | Scenario forcing climatic conditions                                                                                                                           |     |
| Sequence                 | \-               | Int               | Sequence for the scenario. Plants can stay in the chamber for one or several days (one or several scenarios). The sequence changes value when the plant changes. |     |
| DateTime_start_CO2_in    | UTC              | ISODateTimeFormat | DateTime of the start of the CO2 input measurement (CO2 was measured for 5min input, then 5min output, end of CO2 output is equal to `DateTime_end`)           |     |
| DateTime_start_sequence  | UTC              | ISODateTimeFormat | DateTime of the start of the sequence                                                                                                                          |     |
| DateTime_end_sequence    | UTC              | ISODateTimeFormat | DateTime of the end of the sequence                                                                                                                            |     |
| CO2_outflux_umol_s       | μmol plant⁻¹ s⁻¹ | Float             | CO2 flux measured from the chamber (outflux from the chamber)                                                                                                  |     |
| CO2_dry_input            | ppm              | Float             | CO2 concentration of the input flux in the chamber                                                                                                             |     |
| CO2_dry_output           | ppm              | Float             | CO2 concentration of the output flux of the chamber                                                                                                            |     |
| Ta_instruction           | Celsius degree   | Float             | Instruction on the air temperature of the chamber                                                                                                              |     |
| Ta_measurement           | Celsius degree   | Float             | Effective air temperature of the chamber (measurement)                                                                                                         |     |
| Rh_instruction           | \%               | Float             | Instruction on the relative humidity in the chamber                                                                                                            |     |
| Rh_measurement           | \%               | Float             | Effective relative humidity in the chamber (measurement)                                                                                                       |     |
| R_instruction            | \%               | Float             | Instruction on the radiation in the chamber (0 = turned off, 1 = maximal intensity)                                                                            |     |
| R_measurement            | μmol m⁻² s⁻¹     | Float             | Effective radiation in the chamber (measurement)                                                                                                               |     |
| CO2_ppm                  | ppm              | Float             | CO2 concentration in the chamber                                                                                                                               |     |
| CO2_influx               |                  | Float             | Input CO2 flux of the chamber                                                                                                                                  |     |
| CO2_instruction          | ppm              | Float             | Instruction for the CO2 concentration in the chamber                                                                                                           |     |
| transpiration_linear_g_s | g plant⁻¹ s⁻¹    | Float             | Transpiration of the plant, computed from the rate of change within the 5min window using the slope of a linear regression (uses all points)                   |     |
| transpiration_diff_g_s   | g plant⁻¹ s⁻¹    | Float             | Transpiration of the plant, computed from the difference in weight between the beginning and end of the time-step (uses fewer points)                           |     |
| Tl_mean                  | Celsius degree   | Float             | Average leaf temperature of all pixels in the mask for the leaf                                                                                                |     |
| Tl_min                   | Celsius degree   | Float             | Minimum leaf temperature of all pixels in the mask for the leaf                                                                                                |     |
| Tl_max                   | Celsius degree   | Float             | Maximum leaf temperature of all pixels in the mask for the leaf                                                                                                |     |
| Tl_std                   | Celsius degree   | Float             | Standard deviation of the leaf temperature of all pixels in the mask for the leaf                                                                              |     |
| Date_walz                | UTC              | ISODateFormat     | Date of measurement of the response curves on which the parameters are fitted on (VcMaxRef, JMaxRef, RdRef, g0 and g1)                                         |     |
| Leaf_walz                | ID               | Int               | ID of the leaf on which the response curve was measured                                                                                                        |     |
| VcMaxRef                 | μmol m⁻² s⁻¹     | Float             | Reference VcMax, fitted on the response curve preceding the plant sequence                                                                                     |     |
| JMaxRef                  | μmol m⁻² s⁻¹     | Float             | Reference JMax, fitted on the response curve preceding the plant sequence                                                                                      |     |
| RdRef                    | μmol m⁻² s⁻¹     | Float             | Reference Rd, fitted on the response curve preceding the plant sequence                                                                                        |     |
| TPURef                   | μmol m⁻² s⁻¹     | Float             | Reference TPU, fitted on the response curve preceding the plant sequence                                                                                       |     |
| Tr                       | Celsius degree   | Float             | Reference temperature on which the parameters were fitted                                                                                                      |     |
| g0                       | mol[CO2] m⁻² s⁻¹ | Float             | g0, fitted on the response curve preceding the plant sequence                                                                                                  |     |
| g1                       | kPa\^0.5         | Float             | g1, fitted on the response curve preceding the plant sequence                                                                                                  |     |
| VcMaxRef_mean_leaf       | μmol m⁻² s⁻¹     | Float             | Reference VcMax, averaged on all measurements of this leaf during the whole experiment                                                                         |     |
| JMaxRef_mean_leaf        | μmol m⁻² s⁻¹     | Float             | Reference JMax, averaged on all measurements of this leaf during the whole experiment                                                                          |     |
| RdRef_mean_leaf          | μmol m⁻² s⁻¹     | Float             | Reference RdMax, averaged on all measurements of this leaf during the whole experiment                                                                         |     |
| TPURef_mean_leaf         | μmol m⁻² s⁻¹     | Float             | Reference TPU, averaged on all measurements of this leaf during the whole experiment                                                                           |     |
| Tr_mean_leaf             | μmol m⁻² s⁻¹     | Float             | Reference temperature on which the parameters were fitted, averaged over all measurements on that leaf during the whole experiment                             |     |
| g0_mean_leaf             | mol[CO2] m⁻² s⁻¹ | Float             | g0, averaged on all measurements of this leaf during the whole experiment                                                                                      |     |
| g1_mean_leaf             | kPa\^0.5         | Float             | g1, averaged on all measurements of this leaf during the whole experiment                                                                                      |     |
| VcMaxRef_mean_plant      | μmol m⁻² s⁻¹     | Float             | Reference VcMax, averaged on all measurements of this plant (whatever the leaf) during the whole experiment                                                    |     |
| JMaxRef_mean_plant       | μmol m⁻² s⁻¹     | Float             | Reference JMax, averaged on all measurements of this plant (whatever the leaf) during the whole experiment                                                     |     |
| RdRef_mean_plant         | μmol m⁻² s⁻¹     | Float             | Reference Rd, averaged on all measurements of this plant (whatever the leaf) during the whole experiment                                                       |     |
| TPURef_mean_plant        | μmol m⁻² s⁻¹     | Float             | Reference TPU, averaged on all measurements of this plant (whatever the leaf) during the whole experiment                                                      |     |
| Tr_mean_plant            | μmol m⁻² s⁻¹     | Float             | Reference temperature of the measurements, averaged on all measurements of this plant (whatever the leaf) during the whole experiment                          |     |
| g0_mean_plant            | mol[CO2] m⁻² s⁻¹ | Float             | g0, averaged on all measurements of this plant (whatever the leaf) during the whole experiment                                                                 |     |
| g1_mean_plant            | kPa\^0.5         | Float             | g1, averaged on all measurements of this plant (whatever the leaf) during the whole experiment                                                                 |     |
|                          |                  |                   |                                                                                                                                                                |     |
|                          |                  |                   |                                                                                                                                                                |     |

## Notebook links

You may paste the commands into a terminal to open the Pluto notebooks. Note that you must install Julia first and Pluto on your global environment. See the [Usage](#usage) section for more details.

### Climate

``` bash
julia -e 'using Pluto; Pluto.run(notebook = "01-climate/climate_notebook.jl")'
```

### Time synchronization

``` bash
julia -e 'using Pluto; Pluto.run(notebook = "02-time-synchronization/time_synchronization_notebook.jl")'
```

### CO₂ fluxes

``` bash
julia -e 'using Pluto; Pluto.run(notebook = "03-CO2/CO2_notebook.jl")'
```

### Leaf temperature

Computation: The leaf temperature is computed in a Julia script rather than a Pluto notebook because it takes a long time to process. You can find the script in the `04-thermal_camera_measurements/1-compute_leaf_temperature.jl`.

> [!WARNING]
> This notebook takes several hours to process as it computes the leaf temperature for each plant leaf for each image. It is recommended to run it on a powerful computer and know what you're doing.

- Visualization:

    ``` bash
    julia -e 'using Pluto; Pluto.run(notebook = "04-thermal_camera_measurements/2-visualize_temperature_notebook.jl")'
    ```

### H₂O fluxes (transpiration)

``` bash
julia -e 'using Pluto; Pluto.run(notebook = "05-transpiration/transpiration_notebook.jl")'
```

### Leaf gas exchange

These are the A-Cᵢ and Gs-A/(Cₐ√Dₗ) response curves.

``` bash
julia -e 'using Pluto; Pluto.run(notebook = "06-walz/notebook_walz.jl")'
```

### SPAD

``` bash
julia -e 'using Pluto; Pluto.run(notebook = "07-spad/notebook_spad.jl")'
```

### Making the database

``` bash
julia -e 'using Pluto; Pluto.run(notebook = "09-database/database_notebook.jl")'
```

### 3D reconstructions

The 3D reconstructions and visualization of the plants are done using a Pluto notebook. You can open it using the following command:

``` julia
julia -e 'using Pluto; Pluto.run(notebook = "08-reconstruction/visualize_plants_notebook.jl")'
```

Note that if you want to do the 3D reconstructions of the plants alone, it can be done using a script. You'll have to open this repository in VS Code and then open a Julia REPL in the repository. Then, you can open and run the following script: "08-reconstruction/build_opfs.jl".

Also, note that one of the data archive is not included in this repository because it is too large. You can download it from the Zenodo repository.
It is named `lidar.tar.bz2`, and should be located in `00-data/lidar/lidar.tar.bz2`. We use the [unzip-http](https://github.com/saulpw/unzip-http) tool to extract and download only the necessary files from the whole archive.

## Usage

### Pluto

Most of the resources are Pluto reactive notebooks. You know when a Julia script (a `.jl` file) is a notebook when it starts with "\### A Pluto.jl notebook \###". In this case, Pluto is used to execute the file.

#### Install Pluto

To install Pluto, enter the package manager mode in Julia by pressing `]` in the REPL, and then execute the following code:

``` julia
add Pluto
```

Then, each time you want to use Pluto, type the following command in the REPL (in Julia mode):

``` julia
using Pluto
```

#### Open a notebook

There are different ways to open a notebook, but the same function is always used: `Pluto.run()`.

The most straightforward way is just to run it:

``` julia
using Pluto
Pluto.run()
```

Then, you'll have to navigate manually to your notebook.

A second way is to open a notebook by passing its path, *e.g.*:

``` julia
Pluto.run(notebook = "01-climate/climate_notebook.jl")
```

Watch [this video](https://www.youtube.com/watch?v=jdEqGOv8ycc&list=PLLiJ249IkzRFxZGALbKy75_ZyHxYCUmuk&index=4) if you need more details about how to use Pluto.

### Download and instantiate

If you want to use the resources from this repository locally, the best way is to download a local copy (or clone it if you know GIT). To do so, click on the green button in this page called "Code":

![clone button](website/content/assets/github_clone.png)

And choose "Download ZIP":

![download button](website/content/assets/github_download.png)

Then, unzip the file and open the directory in VS Code, or just open Julia in a command prompt/terminal in this repository.
