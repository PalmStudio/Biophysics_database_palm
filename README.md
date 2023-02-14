# Ecotron 2021

WIP !
petit paragraphe pas trop long qui écrit le projet, regroupe les donénes mesurées à lécotron et fait en préttt pour une base de données commune.


Describe the folders and files structure (use tree).

actual tree (21-07-26)
Ecotron2021
├───0-data               --> Contains raw data et processed data by scripts to make them more clear or more useable.
│   ├───0-raw            --> Contains raw data not processed
│   │   ├───climate      --> environnemental data from the microcosms.
│   │   ├───leaves_size  --> little file containing data before Ecotron experimentation on leaves size.
│   │   ├───morphology_and_biomass   -->
│   │   ├───opening_door  -->
│   │   ├───picarro_flux  -->
│   │   ├───pot_weight    -->
│   │   ├───scale_weight  -->
│   │   │   └───Backups   -->
│   │   ├───scenario_sequence 
│   │   ├───smse
│   │   ├───spad
│   │   ├───thermal_camera_images
│   │   ├───thermal_camera_roi_coordinates
│   │   └───walz
│   ├───1-climate
│   ├───2-CO2
│   ├───3-transpiration
│   ├───4-thermal_camera_measurements
│   ├───5-walz
│   ├───6-picarro_flux
│   ├───7-scenarios
│   └───8-not_FSPM_modeling
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
To do:

- [ ] Ask Sebastien why no climatic data 30/04/2021 between 17h10 and 18h10? Idem on 26/04/2021 between 12h44 and 12h55.
- [ ] Sort the thermal images in different folders according to consecutive periods of time where the plant doesn't move,
and move the ones we don't want into a "backup" folder.
- [ ] Make masks for leaves for each consecutive thermal images
- [ ] compute the mean, median, max and min leaf temperature in the masks (use Julia). And put that in a new file for leaves temp.
- [ ] Reconstruct the plants in 3d:
  - [ ] Separate each leaf and make a mesh for it. Then identify it and name it accordingly.
  - [ ] Make an OPF for each plant from this collection of leaf meshes, using them as ref. meshes with no transformation