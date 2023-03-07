# Walz measurements

This folder contains leaf-level response data acquired using a Walz GFS-3000 portable gas exchange system. The data is compressed into a `tar.bz2` archive that consists on a set of CSV files with the following naming convention: `P<Plant ID>F<Leaf ID><month (double digit)><day (double digit)>.csv`. So a file named `P1F20129.csv` correspond to the data acquired on the 29th of January 2021 for the second leaf of the first plant.

Two different experiments were conducted, with a different purpose:

1. half of the leaves of the plants were measured at the lab during a pre-experiment, coupled with SPAD measurements. The objective of these measurements was to get the effect of leaf nitrogen content on the photosynthetic parameters of the leaf, with the hypothesis that very young leaves have low photosynthetic capacity, more mature leaves have high photosynthetic capacity, and decreasing again with age dur to remobilization. We use this dataset to fit a relationship between the SPAD and the effect on the photosynthesis parameters.

1. one leaf per plant was measured before putting the plant under different a climatic sequence in the microcosm 3. The objective is to measure the plant photosynthetic capacity just before a sequence to parameterize our models as close to reality as possible, and eventually control for the effect of plant age and any other factor. It also can be used to investigate weither systematic measurements are necessary for the simulation of a plant, or if there is an effect of the scenario on the photosynthetic capacity of the plant, *e.g.* is the hot and dry scenarion hard on the plant.

All leaves of the plants were regularly measured for their SPAD, so we can use the pre-experiment to recompute the photosynthetic capacity of each leaf on the plant based on the reference leaf.

## Pre-experiment 

Each plant was studied for a week. The plant was taken out of CIRAD's greenhouse at 8:40AM in the morning and placed in the lab room, at 150m walking distance. In the lab, the plant only received natural light, and light from the lamps. The program was named R-C-L-RH, with the following conditions:
- Flow : 750
- Impeller : 7
- Light PAR top : 1500
- CO2 : 400 ppm
- H2O M. rh at 65%
- T. Mode cuv at 25°C 

After waiting for about 10 minutes for the conditions in the chamber to stabilize (*i.e.* finding the ZPcuv), the right part of the leaf (just after the limbus separation) was placed into the chamber, and the program was launched for 13419 seconds. The plant of interest was placed back in the greenhouse right after the measurement. Walz materials were controlled every week (silica, humidifier, CO2 absorbent, CO2 cartridge).

## Ecotron experiment

In this experiment, the plants were measured every time before a measurement sequence, always on the same leaf (P1F6, P2F5, P3F5, P5F7). These leaves were the second youngest leaves at the beginning of the experiment. This choice was made to get leaves that were already mature at the beginning of the experiment, and still active and the end of the experiment. The goal was to have a GFS-3000 measurement curve before each series of scenario. The Walz remained in the Microcosm 4 (storage microcosm), where the plants were in optimal conditions under the control scenario. The plant of interest was measured with the Walz in the morning, and put into the Microcosm 3 (measurement Microcosm, with one plant monitored at a time).

At the end of the experiment, we made a different set of curves on the higher rank leaves (P1F70416 / P1F80422 / P2F60420 / P5F80415 / P5F90421). The GFS-3000 measuring head was placed in Microcosm 3 with the reference scenario (S1 = 400ppm). They were two types of scenarii. The first one is called closed (CLSD), in which a measuring curves occurred (constant 1500µmol/m²/s² of PPFD, 25°C, 70% HR), CLSD files are P5F70427.csv and P1F60428.csv. The second scenario is called opened (OPND), in which there is no fluorescence head on top of the measuring head. It allows the part of the leaf inside the chamber to receive light from the chamber's light sources. OPND files are P5F70429.csv and P1F60430.csv. "TEST2.csv", "TEST3.csv" are files aimed at testing different timestep of record for the CLSD program. 
"P1F6TSTC" and "P3F5TRYC.csv" were test files for the closed program. "P3F5OPND.csv" was the test file for the opened (OPND) program.

We also tested the temperature curve in combination with CO2/light/RH curves. These measurements are found in "P1F60426.csv" and "P1F60503.csv". 

R-C-L-RH, or R-CO2-L-RH, is available in the `R-CO2-L-RH.prg` file.
The temperature program, or R-Temp, is available at `R-Temp2.prg`
Opened and Closed programs are available at `OpenedWalz.prg` and `ClosedWalz.prg` respectively.

## Output files 

Inside each CSV file, the columns correspond to:

| Value          | Definition                                                                                                                                                              | Range, options                           | Unit, format    |   |
|----------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------|-----------------|---|
| Date           | Date (international   standard date notation)                                                                                                                           |                                          | yyyy-mm-dd      |   |
| Time           | Time (international standard time notation)                                                                                                                             | 00:00:00 -23:59:59                       | hh : mm:ss : ss |   |
| Code           | Position of solenoid valves                                                                                                                                             | MP, ZP                                   | String          |   |
| Object         | Object number, for differentiation of several objects within   one report file                                                                                          | 0001-9999                                | #               |   |
| Area or Weight | Reference value of the sample used for calculations                                                                                                                     | Area : .01...999.99, Weight : 1...999999 | cm2 or mg       |   |
| Status         | Operating status of   components                                                                                                                                        |                                          | String          |   |
| CO2abs         | CO2 mole fraction in reference cell of analyzer, equal to CO2   concen- tration at the inlet of cuvette.                                                                | 0 ... 5000                               | ppm             |   |
| CO2sam         | CO2 mole fraction in sample cell of analyzer (usually not   shown in the software)                                                                                      | 0 ... 5000                               | ppm             |   |
| dCO2ZP         | =CO2sam - CO2abs (in ZP mode)                                                                                                                                           | -99.99 ... +99.99                        | ppm             |   |
| dCO2MP         | =CO2sam(t) - CO2abs(t-CO2delay) (in MP mode)                                                                                                                            | -99.99 ... +99.99                        | ppm             |   |
| H2Oabs         | H2O mole fraction in reference cell of analyzer, equal to H2O   concen- tration at the inlet of cuvette.                                                                | 0 ... 75000                              | ppm             |   |
| H2Osam         | H2O mole fraction in sample cell of analyzer (usually not   shown in the software)                                                                                      | 0 ... 75000                              | ppm             |   |
| dH2OZP         | =H2Osam - H2Oabs (in ZP mode)                                                                                                                                           | -60000 ... +60000                        | ppm             |   |
| dH2OMP         | =H2Osam - H2Oabs (in MP mode)                                                                                                                                           | -60000 ... +60000                        | ppm             |   |
| Flow           | Gas flow through the cuvette                                                                                                                                            | -75 ... +1500                            | µmol/s          |   |
| Pamb           | Ambient barometric pressure                                                                                                                                             | 60 ... 110                               | kPa             |   |
| Aux1           | Input signal of an additional sensor connected to AUX IN                                                                                                                | 0 ... 4095                               | mV              |   |
| Aux2           | Input signal of an additional sensor connected to AUX IN                                                                                                                | 0 ... 4095                               | mV              |   |
| Tcuv           | Cuvette temperature measured in lower half                                                                                                                              | -10 ... +55                              | °C              |   |
| Ft             | transient Fluorescence in Chart                                                                                                                                         | 0…4000                                   | mV              |   |
| Fm’            | Fluorescence of the illuminated leaf during a saturating light   pulse                                                                                                  | 0…4000                                   | mV              |   |
| Fo’            | Fluorescence of reoxidized photo- system II illuminated with   only far red illumination and measuring light after a saturating light pulse                             | 0…4000                                   | mV              |   |
| Yield          | Quantum yield of photosynthetic electron transport (Genty et   al. 1989, for a mathematical deriva- tion see Schreiber et al. 1995)                                     | 0..0.85                                  |                 |   |
| ETR            | Electron transport rate                                                                                                                                                 |                                          | µmol/(m² s)     |   |
| qN             | Non-photochemical quenching (Schreiber et al. 1986)                                                                                                                     | 0..1                                     |                 |   |
| qP             | photochemical quenching with no connectivity (Schreiber et al.   1986)                                                                                                  | 0..1                                     |                 |   |
| qL             | photochemical quenching with in- finite connectivity                                                                                                                    | 0..1                                     |                 |   |
| NPQ            | Non-photochemical quenching (Bilger and Björkman, 1990)                                                                                                                 | 0..10                                    |                 |   |
| Y(NPQ)         | Quantum yield of NPQ related en- ergy loss                                                                                                                              | 0..1                                     |                 |   |
| Y(NO)          | Quantum yield of intrinsic energy loss (only calculated on   user-re- quest)                                                                                            | 0..1                                     |                 |   |
| ETR-Fac        | Factor used to calculate the elec- tron transport. Corresponds   to the proportion of light absorbed by photosystems. The value needs to be   entered by the user       | 0..1                                     |                 |   |
| Ttop           | Cuvette temperature measured in upper half                                                                                                                              | -10 ... +55                              | °C              |   |
| Tleaf          | Leaf temperature                                                                                                                                                        | Tcuv-30 ... Tcuv+30                      | °C              |   |
| Tamb           | Ambient temperature                                                                                                                                                     | -10 ... +55                              | °C              |   |
| PARtop         | Photosynthetically active radiation measured with sensor in   upper cu- vette half                                                                                      | 0 ... 3200                               | µmol/(m2*s)     |   |
| PARbot         | Photosynthetically active radiation measured with sensor in   lower cu- vette half                                                                                      | 0 ... 3200                               | µmol/(m2*s)     |   |
| PARamb         | Ambient photosynthetically active radiation measured with   external sensor MQS-B/GFS                                                                                   | 0 ... 3200                               | µmol/(m2*s)     |   |
| Imp            | ImpSet value for impeller                                                                                                                                               | 0 ... 9                                  | steps           |   |
| Tmin           | Minimum or maximum tempera- ture (measured near Peltier ele-   ment instead of Ttop in Standard Measuring Head 3010-S Version 1 or in Gas   Exchange Chamber 3010-GWK1) | -10 ... +55                              | °C              |   |
| rH             | Relative humidity in the cuvette                                                                                                                                        | calculated                               | %               |   |
| E              | Transpiration rate                                                                                                                                                      | calculated                               | mmol/(m2*s)     |   |
| VPD            | Vapor pressure deficit between ob- ject (leaf) and air                                                                                                                  | calculated                               | Pa/kPa          |   |
| GH2O           | Water vapor conductance                                                                                                                                                 | calculated                               | mmol/(m2*s)     |   |
| A              | Assimilation rate                                                                                                                                                       | calculated                               | µmol/(m2*s)     |   |
| ci             | Intercellular CO2 mole fraction                                                                                                                                         | calculated                               | ppm             |   |
| ca             | CO2 mole fraction in the cuvette (=CO2sam-dCO2ZP)                                                                                                                       | calculated                               | ppm             |   |
| wa             | H2O mole fraction in the cuvette (=H2Osam-dH2OZP)                                                                                                                       | calculated                               | ppm             |   |
| Optional       |                                                                                                                                                                         |                                          |                 |   |
| Fo             | Fluorescence of the dark-adapted leaf with only the measuring   light on                                                                                                | 0…4000, should range between 100 and 600 | mV              |   |
| Fm             | Fluorescence of the dark-adapted leaf during a saturating   light pulse                                                                                                 | 0…4000                                   | mV              |   |
| Fv/Fm          | Maximal quantum efficiency of photosystem II (Kitajima and   But- ler 1975 and Butler and Kitajima 1975)                                                                | 0…0.84                                   |                 |   |
| F              | Fluorescence                                                                                                                                                            | 0… 4000                                  | mV              |   |