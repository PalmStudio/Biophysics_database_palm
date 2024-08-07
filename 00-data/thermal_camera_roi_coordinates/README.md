# Thermal camera masks

The thermal camera was positioned on the top corner of the left far side of the chamber, facing the center of the chamber. The aim of the camera is to measure leaves temperatures of the plants. The camera is not able to detect the leaves alone, so we need to define a region of interest (ROI) to focus on the leaves of the plants. The ROI is defined by a mask, that was defined using ImageJ (Fidji). The masks were defined for all leaves of a plant when it was first positioned for a measurement session, and used for all images of the plant during the measurement session. The masks were defined for each leaf so that the ROI is as big as possible, but always in the leaf of interest for all the session as to reduce the noise in the measurement when the leaf moves because of the wind. The masks were saved in the archive `00-data/0-raw/thermal_camera_roi_coordinates/ROI.zip`.

Then, masks point coordinates were extracted and saved in the tar `00-data/0-raw/thermal_camera_roi_coordinates/coordinates.tar.bz2` as CSV files with two columns for the X and Y coordinates of the points. Each CSV file is named following one of the following naming convention:

- P<plant ID>F<leaf ID>-<start time>-<end time>_XY_Coordinates_V<revision version>.csv
- P<plant ID>F<leaf ID>-S<session ID>-<start time>-<end time>_XY_Coordinates_V<revision version>.csv

where `<plant ID>` is the plant ID (1-4), `<leaf ID>` is the leaf ID, `<start time>` is the start time of application of the mask, `<end time>` is the end time of application of the mask, and `<revision version>` is the revision version of the mask (it was modified as soon as a leaf moves). So we have in the first case for example `P3F3-S1-S2-S3-20210308_174136-20210309_140728_XY_Coordinates.csv` for the third leaf of the third plant, between 2021-03-08T17:41:36 and 2021-03-09T14:07:28.

The archive was generated with the following command:

```bash
tar -cjvf coordinates.tar.bz2 -C ./coordinates .
```
