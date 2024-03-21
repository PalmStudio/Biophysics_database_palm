# Ecotron 2021 {#ecotron-2021}

-   [Ecotron 2021](#ecotron-2021)
    -   [Folder structure](#folder-structure)
    -   [Database](#database)
    -   [Notebook links](#notebook-links)
        -   [Climate](#climate)
        -   [Time synchronization](#time-synchronization)
        -   [CO₂ fluxes](#co-fluxes)
        -   [Leaf temperature](#leaf-temperature)
        -   [H₂O fluxes (transpiration)](#ho-fluxes-transpiration)
        -   [Leaf gas exchange (A-Cᵢ and Gs-A/(Cₐ√Dₗ) response curves)](#leaf-gas-exchange-a-cᵢ-and-gs-acₐdₗ-response-curves)
        -   [SPAD](#spad)
        -   [Making the database](#making-the-database)
        -   [3D reconstructions](#3d-reconstructions)
    -   [Usage](#usage)
        -   [Pluto](#pluto)
            -   [Install Pluto](#install-pluto)
            -   [Open a notebook](#open-a-notebook)
        -   [Download and instantiate](#download-and-instantiate)
    -   [To do](#to-do)

The Ecotron is a controlled environment facility for plants located in Montpellier, France. In this work, we made an experiment that consisted in investigating the behavior of oil palm (*Elaeis guineensis*) in response to different environmental conditions. The conditions were defined based on an average daily variation from Libo, Indonesia, *i.e.* a day without rain, not too cold, not too hot. This base condition was then modified by adding more CO2, less radiation, more or less temperature, and more or less vapor pressure deficit.

The height resulting conditions were the following:

-   400ppm: the base condition
-   600ppm: 50% more CO2
-   800ppm: 100% more CO2
-   Cloudy: the same as base condition but with the PAR values based on the most cloudy day of our database from Sumatra. The dynamic of the PAR is kept as in the base condition though. The maximum PPFD was 130 µmol m² s⁻¹ at 51cm from the lamps, compared to 300 in the reference scenario.
-   Cold: -30% °C compared to the base condition
-   Hot: +30% °C
-   DryCold: -30% relative humidity and -30% °C
-   DryHot: -30% relative humidity and +30% °C

Two microcosms where used during 2 months to measure each of four plants with each condition. The two microcosms are 114cm (Width) x 113cm (Depth) x 152cm (Height) chambers with a radiation and climate control system that can precisely control the temperature, humidity, and CO2 concentration. The first microcosm was used to store the plants, always following the base conditions, and the second one was used to perform the experiment on different conditions.

Measurements included:

-   CO2 fluxes with a Picarro G2101-i, measuring the CO2 concentration in the chamber for 5 minutes, and input CO2 concentration for 5 minutes
-   H2O fluxes with a precision scale, considering that any change in the weight of the potted plant is due to loss of H2O fluxes by transpiration, as the pot was seeled with a plastic film during the experiment in the second microcosm. The code to control the scale is available [here](https://github.com/ARCHIMED-platform/Precision_scale-Raspberry_Pi)
-   Leaf temperature, measured with a thermal camera
-   LiDAR scans of the plants each week, using a Riegl VZ400. Each plant was extracted from the co-registered point clouds using Riegl RiSCAN Pro. The plants were then reconstructed using Blender.
-   Biomass and surface measurements of all organs of the plants were also performed at the end of the experiment.
-   SPAD measurements of each leaf of the plants
-   A-Cᵢ and Gs-A/(Cₐ√Dₗ) response curves using a portable gas analyzer (Walz GFS-3000) for model calibration

This repository does not contain the raw thermal images and the raw LiDAR data taken during the experiment, because they are too large to be stored on Git (images: 60Go, 24Go when compressed). The data is available on a dedicated repository in Zenodo.

## Folder structure {#folder-structure}

```         
This folder
├── 00-data                         --> Contains raw, unprocessed data
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
├── 02-climate                      --> Contains processed climatic data
│   ├── climate_mic3.csv           --> Climatic data for Mic3
│   ├── climate_mic3_10min.csv     --> Climatic data for Mic3, aggregated to 10 minutes matching CO2 inut/output measurement cycle
│   ├── climate_mic3_5min.csv      --> Climatic data for Mic3, aggregated to 5 minutes matching CO2 output measurement
│   ├── climate_mic4.csv           --> Climatic data for Mic4
│   └── climate_notebook.jl        --> Notebook to process climatic data
├── 03-time-synchronization         --> Computation of the data to synchronize all sensors to UTC time
│   ├── README.md
│   ├── correspondance_scale_camera_time.csv --> Correspondance between the scale and the thermal camera
│   ├── time_synchronization.csv             --> Time synchronization data
│   └── time_synchronization_notebook.jl     --> Notebook to compute time synchronization data
├── 04-CO2                          --> Processed CO2 data
│   ├── CO2_fluxes.csv             --> CO2 fluxes data
│   └── CO2_notebook.jl            --> Notebook to process CO2 data
├── 05-thermal_camera_measurements  --> Processed thermal camera data
│   ├── 1-compute_leaf_temperature.jl --> Script to compute leaf temperature (careful, it takes several hours to process)
│   ├── 2-vizualise_temperature.jl --> Notebook to vizualise processed leaf temperature
│   └── leaf_temperature.csv.bz2   --> Leaf temperature data (at 1min time-scale, but with information to match with CO2 fluxes)
├── 06-transpiration                --> Processed plant transpiration data
│   ├── README.md
│   ├── plant_sequence_delayed_corrected.csv --> Plant sequence with corrected delay
│   ├── transpiration_10min.csv.bz2 --> Plant transpiration data aggregated to match the 10 minutes CO2 measurement
│   ├── transpiration_first_5min.csv.bz2 --> Plant transpiration data aggregated to match the 5min output CO2 measurement
│   └── transpiration_notebook.jl  --> Notebook to process plant transpiration data 
├── 07-walz                         --> Processed Walz data
│   ├── notebook_walz.jl           --> Notebook to process Walz data
│   └── photosynthetic_and_stomatal_parameters.csv --> Computed photosynthetic and stomatal parameters data
├── 08-spad                         --> Processed SPAD data
│   ├── SPAD_models.csv            --> SPAD models
│   └── notebook_spad.jl           --> Notebook to process SPAD data
├── 09-database                     --> Database of all processed data
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

## Database {#database}

You can find the database of all processed data in the `09-database` folder, or in the releases of this repository. The database is available in two versions: one aggregated to match the 10min CO2 measurement, and one aggregated to match the 5min output CO2 measurement.

The database is a compressed CSV file (`.csv.bz2`), and can be read using the following command:

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
|---------|---------|---------|---------------------------------------|---------|
| DateTime_start           | UTC              | ISODateTimeFormat | DateTime of the start of the measurement                                                                                                                       |     |
| DateTime_end             | UTC              | ISODateTimeFormat | DateTime of the end of the measurement (either the 5-min output measurement window, or the whole 10-min output-input)                                          |     |
| Plant                    | \-               | Int               | Plant ID                                                                                                                                                       |     |
| Leaf                     | ID               | Int               | Leaf ID, leaf ID 1 is the first emitted leaf (the oldest)                                                                                                      |     |
| Scenario                 | \-               | String            | Scenario forcing climatic conditions                                                                                                                           |     |
| Sequence                 | \-               | Int               | Sequence for the scenario. Plants can stay in the chamber for one or several days (one or several scenario). The sequence change value when the plant changes. |     |
| DateTime_start_CO2_in    | UTC              | ISODateTimeFormat | DateTime of the start of the CO2 input measurement (CO2 was measured for 5min input, then 5min output, end of CO2 output is equal to `DateTime_end`)           |     |
| DateTime_start_sequence  | UTC              | ISODateTimeFormat | DateTime of the start of the sequence                                                                                                                          |     |
| DateTime_end_sequence    | UTC              | ISODateTimeFormat | DateTime of the end of the sequence                                                                                                                            |     |
| CO2_outflux_umol_s       | umol plant-1 s-1 | Float             | CO2 flux measured from the chamber (outflux from the chamber)                                                                                                  |     |
| CO2_dry_input            | ppm              | Float             | CO2 concentration of the input flux in the chamber                                                                                                             |     |
| CO2_dry_output           | ppm              | Float             | CO2 concentration of the output flux of the chamber                                                                                                            |     |
| Ta_instruction           | Celsius degree   | Float             | Instruction on the air temperature of the chamber                                                                                                              |     |
| Ta_measurement           | Celsius degree   | Float             | Effective air temperature of the chamber (measurement)                                                                                                         |     |
| Rh_instruction           | \%               | Float             | Instruction on the relative humidity in the chamber                                                                                                            |     |
| Rh_measurement           | \%               | Float             | Effective relative humidity in the chamber (measurement)                                                                                                       |     |
| R_instruction            | \%               | Float             | Instruction on the radiation in the chamber (0 = turned off, 1 = maximal intensity)                                                                            |     |
| R_measurement            | umol m-2 s-1     | Float             | Effective radiation in the chamber (measurement)                                                                                                               |     |
| CO2_ppm                  | ppm              | Float             | CO2 concentration in the chamber                                                                                                                               |     |
| CO2_influx               |                  | Float             | Input CO2 flux of the chamber                                                                                                                                  |     |
| CO2_instruction          | ppm              | Float             | Instruction for the CO2 concentration in the chamber                                                                                                           |     |
| transpiration_linear_g_s | g plant-1 s-1    | Float             | Transpiration of the plant, computed from the rate of change within the 5min window using the slope of a linear regression (uses all points)                   |     |
| transpiration_diff_g_s   | g plant-1 s-1    | Float             | Transpiration of the plant, computed from the difference in weight between the begining and end of the time-step (uses fewer points)                           |     |
| Tl_mean                  | Celsius degree   | Float             | Average leaf temperature of all pixels in the mask for the leaf                                                                                                |     |
| Tl_min                   | Celsius degree   | Float             | Minimum leaf temperature of all pixels in the mask for the leaf                                                                                                |     |
| Tl_max                   | Celsius degree   | Float             | Maximum leaf temperature of all pixels in the mask for the leaf                                                                                                |     |
| Tl_std                   | Celsius degree   | Float             | Standard deviation of the leaf temperature of all pixels in the mask for the leaf                                                                              |     |
| Date_walz                | UTC              | ISODateFormat     | Date of measurement of the response curves on which the parameters are fitted on (VcMaxRef, JMaxRef, RdRef, g0 and g1)                                         |     |
| Leaf_walz                | ID               | Int               | ID of the leaf on which the response curve was measured                                                                                                        |     |
| VcMaxRef                 | umol m-2 s-1     | Float             | Reference VcMax, fitted on the response curve preceding the plant sequence                                                                                     |     |
| JMaxRef                  | umol m-2 s-1     | Float             | Reference JMax, fitted on the response curve preceding the plant sequence                                                                                      |     |
| RdRef                    | umol m-2 s-1     | Float             | Reference Rd, fitted on the response curve preceding the plant sequence                                                                                        |     |
| TPURef                   | umol m-2 s-1     | Float             | Reference TPU, fitted on the response curve preceding the plant sequence                                                                                       |     |
| Tr                       | Celsius degree   | Float             | Reference temperature on which the parameters were fitted                                                                                                      |     |
| g0                       | mol[CO2] m-2 s-1 | Float             | g0, fitted on the response curve preceding the plant sequence                                                                                                  |     |
| g1                       | kPa\^0.5         | Float             | g1, fitted on the response curve preceding the plant sequence                                                                                                  |     |
| VcMaxRef_mean_leaf       | umol m-2 s-1     | Float             | Reference VcMax, averaged on all measurements of this leaf during the whole experiment                                                                         |     |
| JMaxRef_mean_leaf        | umol m-2 s-1     | Float             | Reference JMax, averaged on all measurements of this leaf during the whole experiment                                                                          |     |
| RdRef_mean_leaf          | umol m-2 s-1     | Float             | Reference RdMax, averaged on all measurements of this leaf during the whole experiment                                                                         |     |
| TPURef_mean_leaf         | umol m-2 s-1     | Float             | Reference TPU, averaged on all measurements of this leaf during the whole experiment                                                                           |     |
| Tr_mean_leaf             | umol m-2 s-1     | Float             | Reference temperature on which the parameters were fitted, averaged over all measurements on that leaf during the whole experiment                             |     |
| g0_mean_leaf             | mol[CO2] m-2 s-1 | Float             | g0, averaged on all measurements of this leaf during the whole experiment                                                                                      |     |
| g1_mean_leaf             | kPa\^0.5         | Float             | g1, averaged on all measurements of this leaf during the whole experiment                                                                                      |     |
| VcMaxRef_mean_plant      | umol m-2 s-1     | Float             | Reference VcMax, averaged on all measurements of this plant (whatever the leaf) during the whole experiment                                                    |     |
| JMaxRef_mean_plant       | umol m-2 s-1     | Float             | Reference JMax, averaged on all measurements of this plant (whatever the leaf) during the whole experiment                                                     |     |
| RdRef_mean_plant         | umol m-2 s-1     | Float             | Reference Rd, averaged on all measurements of this plant (whatever the leaf) during the whole experiment                                                       |     |
| TPURef_mean_plant        | umol m-2 s-1     | Float             | Reference TPU, averaged on all measurements of this plant (whatever the leaf) during the whole experiment                                                      |     |
| Tr_mean_plant            | umol m-2 s-1     | Float             | Reference temperature of the measurements, averaged on all measurements of this plant (whatever the leaf) during the whole experiment                          |     |
| g0_mean_plant            | mol[CO2] m-2 s-1 | Float             | g0, averaged on all measurements of this plant (whatever the leaf) during the whole experiment                                                                 |     |
| g1_mean_plant            | kPa\^0.5         | Float             | g1, averaged on all measurements of this plant (whatever the leaf) during the whole experiment                                                                 |     |
|                          |                  |                   |                                                                                                                                                                |     |
|                          |                  |                   |                                                                                                                                                                |     |

## Notebook links {#notebook-links}

Here are the commands that you may paste into a terminal to open the Pluto notebooks. Note that you have to install Julia first, and install Pluto on your global environment. See the [Usage](#usage) section for more details.

### Climate {#climate}

``` bash
julia -e 'using Pluto; Pluto.run(notebook = "02-climate/climate_notebook.jl")'
```

### Time synchronization {#time-synchronization}

``` bash
julia -e 'using Pluto; Pluto.run(notebook = "03-time-synchronization/time_synchronization_notebook.jl")'
```

### CO₂ fluxes

``` bash
julia -e 'using Pluto; Pluto.run(notebook = "04-CO2/CO2_notebook.jl")'
```

### Leaf temperature {#leaf-temperature}

-   Computation:

    ``` bash
    #julia -e 'using Pluto; Pluto.run(notebook = "05-thermal_camera_measurements/1-compute_leaf_temperature.jl")'
    ```

-   Visualization:

    ``` bash
    julia -e 'using Pluto; Pluto.run(notebook = "05-thermal_camera_measurements/2-vizualise_temperature.jl")'
    ```

### H₂O fluxes (transpiration)

``` bash
julia -e 'using Pluto; Pluto.run(notebook = "06-transpiration/transpiration_notebook.jl")'
```

### Leaf gas exchange (A-Cᵢ and Gs-A/(Cₐ√Dₗ) response curves) {#leaf-gas-exchange-a-cᵢ-and-gs-acₐdₗ-response-curves}

``` bash
julia -e 'using Pluto; Pluto.run(notebook = "07-walz/notebook_walz.jl")'
```

### SPAD {#spad}

``` bash
julia -e 'using Pluto; Pluto.run(notebook = "08-spad/notebook_spad.jl")'
```

### Making the database {#making-the-database}

``` bash
julia -e 'using Pluto; Pluto.run(notebook = "09-database/database_notebook.jl")'
```

### 3D reconstructions

The 3D reconstructions of the plants are done using a script. You'll have to open this repository in VS Code, and then open a Julia REPL in the repository. Then, you can open and run the following script: "10-reconstruction/build_opfs.jl".

The visualization of the 3D reconstructions is done using a Pluto notebook. You can open it using the following command:

``` julia
Pluto.run(notebook = "10-reconstruction/visualize_plants.jl")
```

## Usage {#usage}

### Pluto {#pluto}

Most of the resources are Pluto reactive notebooks. You know when a julia script (a `.jl` file) is a notebook when it starts with "\### A Pluto.jl notebook \###". In this case, use Pluto to execute the file.

#### Install Pluto {#install-pluto}

To install Pluto, enter the package manager mode in Julia by pressing `]` in the REPL, and then execute the following code:

``` julia
add Pluto
```

Then, each time you want to use Pluto, type the following command in the REPL (in julia mode):

``` julia
using Pluto
```

#### Open a notebook {#open-a-notebook}

There are different ways to open a notebook, but it's always using the same function: `Pluto.run()`.

The most simple way is to just run it:

``` julia
using Pluto
Pluto.run()
```

Then you'll have to navigate manually to your notebook.

A second way is to open a notebook by passing its path, *e.g.*:

``` julia
Pluto.run(notebook = "02-climate/climate_notebook.jl")
```

Watch [this video](https://www.youtube.com/watch?v=jdEqGOv8ycc&list=PLLiJ249IkzRFxZGALbKy75_ZyHxYCUmuk&index=4) if you need more details about how to use Pluto.

### Download and instantiate {#download-and-instantiate}

If you want to use the resources from this repository locally, the best way is to download a local copy (or clone it if you know GIT). To do so, click on the green button in this page called "Code":

![](www_readme/clone_button.png)

And choose "Download ZIP":

![](www_readme/Download_ZIP.png)

Then, unzip the file, and open the directory in VS Code, or just open Julia in a command prompt / terminal in this repository and use *e.g.*:

## To do {#to-do}

-   [ ] Check all data
    -   [ ] For CO2, 2021-03-27 to 30 is `missing` for the plant, but should be plant 5 (as seen in the plant sequence). This is three days where we can't use the H20 data because of a scale failure.
    -   [ ] Light is spelled "ligth" in the Walz files, replace.
    -   [ ] Select days that are "clean", i.e. full data for the whole day, no door opening, etc.
    -   [ ] Make sure we have the 3D reconstructions for all plants and days that are clean
    -   [ ] Add irrigations to the database (from the transpiration db)
    -   [ ] For Eₐᵣ, Eₐⱼ, Hdⱼ, take values from the literature that correspond to tropical plants (see Kumarathunge et al. 2019, New Phytologist)
    -   [ ] For the fact that CO2 800ppm is simulated higher than CO2 600ppm when the observation is the opposite, see correction of Medlyn's model in Dewar et al. 2018 (New Phytologist), eq.11 in the paper that is the same model than Medlyn, but removes Gamma\* to Ca in the model.
-   [ ] Make a release of the data on Zenodo
-   [ ] Use <https://github.com/JuliaImages/ExifViewer.jl> now that <https://github.com/JuliaImages/ExifViewer.jl/issues/17> is fixed
-   [ ] Make a zenodo for 00-data/LiDAR/LiDAR_data.tar.bz2
-   [ ] Make a zenodo for 00-data/thermal_camera_images/images.tar.bz2
-   [ ] Reconstruct the plants in 3d:
    -   [x] Separate each leaf and make a mesh for it. Then identify it and name it accordingly.
    -   [x] Make an OPF for each plant from this collection of leaf meshes, using them as ref. meshes with no transformation
    -   [ ] Add attributes such as SPAD and photosynthetic and conductance parameters.
