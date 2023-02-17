# Pots weight

## Aim

Measure the plant transpiration from the weight of the potted plants. The weight of the pot and plant was continuously measured during the experiment using a connected precision scale. The pot and soil were isolated using a plastic bag, so any change in the pot weight was due to the plant transpiration (+/- the saturation inside the bag).

## Measurement phases

There are five phases of measurement due to changes in the measurement setup:

- phase 0, from 09/03/2021 to 10/03/2021, logged in the file `Weights_1.txt`. In this phase we used a regular computer with a script that read the data from the scale (1000C-3000D) for one minute, and logged its average onto the computer. The DateTime is in UTC+1.
- phase 1, from 2021-03-10T15:08:23 to 2021-03-15T14:49:06, file `weightsPhase1.txt`. We changed computers to use one from the Ecotron, which was at UTC-4min.
- phase 2, from 2021-03-15T15:46:13 to 2021-03-27T01:19:27, file `weightsPhase2.txt`. In this measurement phase, we changed the script to log the data every second, without any averaging as we decided it is better to log the raw data and make the average afterward. The DateTime lag was fixed, so it is now in UTC. These data end the day before day-time change. Data is lost for the weekend (after 2021-03-27T01:19:27) because the weight of the plant was above the maximum capacity of the scale. 
- phase 3, from 2021-03-30T09:45:01 to 2021-04-08T07:03:59, file `weightsPhase3.txt`. This phase is the same as phase 3, there is just a data gap because we were investigating why data logging was not working anymore (we didn't see any error on the scale).
- phase 4, from 2021-04-07T10:46:19 to 2021-05-02T06:49:33, file `weightsPhase4.txt`. We received the new precision scale (XB3200C) that we just bought (we borrowed the first one). So in this phase we changed the scale, and also isntalled a Raspberry Pi to log the data. The Raspberry Pi is connected to the scale via USB, and the data is logged every second. The DateTime has a lag of 1 day, 47 minutes and 12 seconds compared to UTC (Raspberry: 2021-04-12T13:02:43 ; Thermal camera: 20210413_144827_R.jpg, with a delay of 3512s, so 2021-04-13T13:49:55 UTC)