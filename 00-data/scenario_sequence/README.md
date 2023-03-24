# Scenario sequence

This folder contains the data associated to the sequence of scenarios that we used in the experiment. The data are in:

- `SequenceScenarioMicro3.csv`: the plant and scenario associated to each day of the experiment. Some scenario x plant sets are repeated in the experiment, and some are incomplete because we switched plants during the day. The column `Ref` helps identify one reference day for each scenario and plant that is complete and free of issues.
- `SequencePlanteMicro3.csv`: the scenario sequence for each plant, with the date of the start and end of the scenario. Note that a plant can stay in the chamber for several days. This data is used to identify when a plant is in a scenario, and when it is not (plant switching, tests...).
