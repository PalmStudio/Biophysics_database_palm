# load packages -----------------------------------------------------------

library(tidyverse)
library(stringr)
library(plotly)
library(data.table)
library(lubridate)

# import data -------------------------------------------------------------

Results_combined=data.table::fread(file = './0-data/3-thermal_camera_measurements/emptyroom0330_13-14h_AllPictureMeasure_File1.csv',header = T)

don = Results_combined %>%
  mutate(Time=ymd_hms(str_remove(string = Label,pattern = '_R')))


ggplotly(don %>%
ggplot()+
  geom_line(aes(y = Min,x=Time, colour = "Min")) + 
  geom_line(aes(y = Max,x=Time, colour = "Max")) +
  geom_line(aes(y = Mean,x=Time, colour = "Mean")) +
  # geom_errorbar(aes(ymin= Mean-StdDev, ymax=Mean-StdDev), width=.2, position=position_dodge(0.05))+
  labs(title = "Min/Max/Mean/StdDev of each slide",
       #subtitle = "",
       x="slide",
       y="Value in pixel (0-255)")+
  scale_x_datetime(date_breaks = 'days',date_minor_breaks = 'hours'))

