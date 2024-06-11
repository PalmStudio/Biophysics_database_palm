# Thermal images

Leaf temperature was measured with a a FLIR Vue™ Pro R thermal camera that took one image every second. The camera was placed on the farthest top left corner of the chamber, pointing to the center of the chamber to ensure the best visibility of the plant leaves. 

The code to control the camera is available [here](https://github.com/ARCHIMED-platform/FLIR_Vue_Pro-Raspberri_Pi)

This repository contains the raw thermal images taken during the experiment.

The archive was made using `tar` with `bzip2`:

```bash
tar -cjvf images.tar.bz2 images
```

The images are named with the following convention: `YYYYMMDD_HHMMSS_R.jpg`. The date and time correspond to the time at which the image was taken, with a delay of UTC+58m32s in the camera clock. So to get the correct time, you need to remove 58m32s to the time in the file name.

The images can be extracted with the following command:

```bash
tar -xjvf images.tar.bz2
```

If you need specific dates only, you can extract them with the following command:

```bash
for date in 20210406 20210407
do
    tar -xjf "images.tar.bz2" "images/${date}*.jpg"
done
```

Or depending on your version of `tar`, using the `--wildcards` option:

```bash
tar -xjf "images.tar.bz2" --wildcards "images/20210406*.jpg" "images/20210407*.jpg"
```

or the `--include` option:

```bash
tar -xjf "images.tar.bz2" --include="images/20210406*.jpg" --include="images/20210407*.jpg"
```
