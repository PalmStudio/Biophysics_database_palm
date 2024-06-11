# Light sensors Data


This folder includes measurements for mapping the light environment within the chamber using a Sunscan device (Delta-T).

The file ``mapEmptyChamber.csv`` contains data collected when the chamber is empty. The device consists of 64 sensors positioned every 1.6 cm along the Y-axis. Each measurement is taken at a specific distance from the light source (Z=0) and from the left side of the chamber (X=0). The measurements were conducted under two conditions: 

1. Empty microcosm to capture direct and diffuse radiation (noFelt)
2. Empty microcosm with black felt on the walls to eliminate scattered light (BlackFelt).

The file `mapPlantChamber.csv` contains data collected when a plant is positioned within the chamber. The same device is placed at the base of the plant (the top of the pot is indicated as a distance to the light source; Z-tip). Each measurement is recorded at a specific distance from the center of the plant (X=0), with the plant positioned in the center of the chamber.
