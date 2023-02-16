# Ecotron 2021

The Ecotron is a controlled environment facility for plants located in Montpellier, France. In this work, we made an experiment that consisted in investigating the behavior of oil palm (*Elaeis guineensis*) in response to different environmental conditions. The conditions were defined based on an average daily variation from Libo, Indonesia, *i.e.* a day without rain, not too cold, not too hot. This base condition was then modified by adding more CO2, less radiation, more or less temperature, and more or less vapor pressure deficit. 

The height resulting conditions were the following:

- 400ppm: the base condition
- 600ppm: 50% more CO2
- 800ppm: 100% more CO2
- Cloudy: XX% less radiation (to check)
- Cold: XX less Celsius degrees 
- Hot: XX more Celsius degrees
- DryCold: XX less Celsius degrees and XX% less vapor pressure deficit
- DryHot: XX more Celsius degrees and XX% less vapor pressure deficit
 
Two microcosms where used during 2 months to measure each of four plants with each condition. The two microcosms are 1m x 1m x 1.5m chambers with a light and climate control system that can precisely control the temperature, humidity, and CO2 concentration. The first microcosm was used to store the plants, always following the base conditions, and the second one was used to perform the experiment on different conditions. 

Measurements included: 

- CO2 fluxes with a Picarro XXX, measuring the CO2 concentration in the chamber for 5 minutes, and input CO2 concentration for 5 minutes
- H2O fluxes with a precision scale, considering that any change in the weight of the potted plant is due to loss of H2O fluxes by transpiration, as the pot was seeled with a plastic film during the experiment in the second microcosm. The code to control the scale is available [here](https://github.com/ARCHIMED-platform/Precision_scale-Raspberry_Pi)
- Leaf temperature, measured with a thermal camera
- LiDAR scans of the plants each week, using a Riegl VZ400. Each plant was extracted from the co-registered point clouds using Riegl RiSCAN Pro. The plants were then reconstructed using Blender.
- Biomass and surface measurements of all organs of the plants were also performed at the end of the experiment.


## Leaf temperature

Leaf temperature was measured with a a FLIR Vue™ Pro R thermal camera that took one image every second. The camera was placed on the farthest top left corner of the chamber, pointing to the center of the chamber to ensure the best visibility of the plant leaves. The camera was controlled by a Raspberry Pi, using the code available [here](https://github.com/ARCHIMED-platform/FLIR_Vue_Pro-Raspberri_Pi)

In total, 78289 images were taken during the experiment. The images are named with the following convention: `YYYYMMDD_HHMMSS_R.jpg`. The date and time correspond to the time at which the image was taken, from the camera clock (which had a delay of 58m32s).
This repository should contain the raw thermal images taken during the experiment, but the full data base is too large to be stored on Git (60Go). So only a test-set is available here in the `sample` archive. The raw images are available on a dedicated repository in Zenodo.


```
This folder
├───0-data               --> Contains raw data and processed data
│   ├───0-raw            --> Contains raw, unprocessed data
│   │   ├───climate      --> environmental data from the microcosms.
│   │   ├───leaves_size  --> leaf sizes before the experiment
│   │   ├───morphology_and_biomass  --> biomass and surface measurements of all organs of the plants at the end of the experiment
│   │   ├───opening_door  --> opening and closing of the door of the microcosm (used to filter data)
│   │   ├───picarro_flux  --> CO2 fluxes
│   │   ├───pot_weight    --> weight of the pot with the plant before each measurement session
│   │   ├───scale_weight  --> weight of the plant during measurements (used to compute transpiration)
│   │   ├───scenario_sequence --> sequence of the scenarios per day and per plant 
│   │   ├───smse          --> reference climatic data from the SMSE trial in Indonesia
│   │   ├───spad          --> SPAD measurements of each leaf of the plants
│   │   ├───thermal_camera_images --> thermal images of the plants (processed output only, else it takes too much space, 60Go)
│   │   ├───thermal_camera_roi_coordinates --> coordinates of the ROI of the thermal images
│   │   └───walz          --> measurements at leaf scale using a portable gas analyzer for model calibration
│   ├───1-climate         --> processed climate data from the microcosms
│   ├───2-CO2             --> processed CO2 fluxes
│   ├───3-transpiration   --> processed transpiration fluxes
│   ├───4-thermal_camera_measurements --> processed thermal images
│   ├───5-walz            --> processed measurements at leaf scale
│   ├───6-picarro_flux    
│   ├───7-scenarios       --> scenarios per day and per plant
│   └───8-not_FSPM_modeling --> Simulation of the plant biophysics using a crop model
├───1-code
│   ├───0-functions
│   ├───1-transpiration
│   ├───2-climate
│   ├───3-CO2_fluxes
│   ├───4-thermal_camera
│   ├───5-walz
│   ├───6-not_FSPM_modeling
│   └───7-scenario_making
└───2-output
    ├───1-CO2flux_graphs
    └───2-transpi_graphs
```

- [ ] Ask Sebastien why no climatic data 30/04/2021 between 17h10 and 18h10? Idem on 26/04/2021 between 12h44 and 12h55.
- [ ] Sort the thermal images in different folders according to consecutive periods of time where the plant doesn't move,
and move the ones we don't want into a "backup" folder.
- [ ] Make masks for leaves for each consecutive thermal images
- [ ] compute the mean, median, max and min leaf temperature in the masks (use Julia). And put that in a new file for leaves temp.
- [ ] Reconstruct the plants in 3d:
  - [ ] Separate each leaf and make a mesh for it. Then identify it and name it accordingly.
  - [ ] Make an OPF for each plant from this collection of leaf meshes, using them as ref. meshes with no transformation