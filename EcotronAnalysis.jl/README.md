# EcotronAnalysis

This is a Julia package for the computation and analysis of data from the Ecotron
in Montpellier, France. 

The Ecotron is a controlled environment facility for plants. We made an experiment 
that consisted in investigating the behavior of oil palm (*Elaeis guineensis*) in response to 
a different environmental conditions. The conditions were defined based on an average daily variation from Libo, Indonesia, *i.e.* a day without rain, not too cold, not too hot. This base condition was then modified by adding more CO2, less radiation, more or less temperature, and more or less vapor pressure deficit. The height resulting conditions were the following:

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
- Leaf temperature, measured with a a FLIR Vue™ Pro R thermal camera. The code to control the camera is available [here](https://github.com/ARCHIMED-platform/FLIR_Vue_Pro-Raspberri_Pi)
- lidar scans of the plants each week, using a Riegl VZ400. Each plant was extracted from the co-registered point clouds using Riegl RiSCAN Pro. The plants were then reconstructed using Blender.
- Biomass and surface measurements of all organs of the plants were also performed at the end of the experiment.
