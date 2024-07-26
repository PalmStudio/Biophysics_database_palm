# Script for generating data paper figures & tables ---------------------------------


# load packages -----------------------------------------------------------


packs <- c("lubridate", "stringr", "tidyverse", "viridis", "Vpalmr", "data.table", "yaml", "archimedR", "png", "cowplot", "ggpattern")
InstIfNec <- function(pack) {
  if (!do.call(require, as.list(pack))) {
    do.call(install.packages, as.list(pack))
  }
  do.call(require, as.list(pack))
}
lapply(packs, InstIfNec)


# inputs ------------------------------------------------------------------


colors_event <- c("darkolivegreen3", "darkolivegreen4", "darkolivegreen", "cyan", "blue3", "firebrick", "firebrick1", "grey")
names(colors_event) <- c("400ppm", "600ppm", "800ppm", "DryCold", "Cold", "Hot", "DryHot", "Cloudy")

tabelEvent <- data.frame(event = c(paste0("S", 1:8), "WalzClosed", "WalzOpen"), scenar = c("400ppm", "Cloudy", "600ppm", "Cold", "800ppm", "DryCold", "Hot", "DryHot", "WalzClosed", "WalzOpen"))

myTheme <- theme_minimal() %+replace%
  theme(
    text = element_text(
      face = "plain", size = 16,
      angle = 0, lineheight = 0.9
    ),
    axis.title = element_text(
      face = "plain", size = 20,
      angle = 0, lineheight = 0.9
    ),
    plot.title = element_text(size = rel(1.2)),
    axis.text = element_text(face = "plain", size = 16),
    legend.title = element_blank()
  )

myTheme_multi <- theme_bw() %+replace%
  theme(
    text = element_text(
      face = "plain", size = 16,
      angle = 0, lineheight = 0.9
    ),
    axis.title = element_text(
      face = "plain", size = 20,
      angle = 0, lineheight = 0.9
    ),
    plot.title = element_text(size = rel(1.2)),
    axis.text = element_text(face = "plain", size = 16),
    legend.title = element_blank()
  )

# calendar -------------------------------------------------------------


cal_raw <- fread("0-data/calendrier.csv") %>%
  mutate(Date = dmy(Date))
# %>%
#   filter(Date<ymd('2021-04-26'))

reco <- fread("0-data/ReconstructionsDates.csv") %>%
  data.frame() %>%
  mutate(Date = dmy(Date))

cal <- rbind(cal_raw, reco) %>%
  tidyr::gather(key = "plant", value = "event", P1, P2, P3, P4)


cal[cal$event %in% c("Curves (rat\x8e)", "Curves rat\x8e", ""), "event"] <- "A"
cal[cal$event %in% c("S3 (+nuit)", "S1 (erreur S3)", "S3*"), "event"] <- "S3"
cal[cal$event %in% c("S4 (chgt matin)", "S4 rat\x8e"), "event"] <- "S4"
cal[cal$event %in% c("S8 (+nuit)"), "event"] <- "S8"
cal[cal$event %in% c("S5 rat\x8e"), "event"] <- "S5"
cal[cal$event %in% c("S6 rat\x8e"), "event"] <- "S6"
cal[cal$event %in% c("Curves", "CurveF+2", "CurvesF+1", "Curves (manque HR)", "CurveF+1"), "event"] <- "Response curves"
cal[cal$event %in% c("A"), "event"] <- "Storage"
cal[cal$event %in% c("SWalzC"), "event"] <- "WalzClosed"
cal[cal$event %in% c("SWalzO"), "event"] <- "WalzOpen"
cal[cal$event %in% c("Reconstruction"), "event"] <- "3D"
unique(cal$event)


cal <- merge(cal, tabelEvent, all.x = T)

ggplot() +
  geom_tile(data = cal, aes(x = Date, y = plant, fill = scenar), col = 1) +
  geom_tile(data = cal %>% filter(is.na(scenar)), aes(x = Date, y = plant), fill = "white", col = 1) +
  geom_point(data = cal %>% filter(event == "Response curves"), aes(x = Date, y = plant, col = "Response curves", shape = "Response curves"), size = 2) +
  geom_point(data = cal %>% filter(event == "3D"), aes(x = Date, y = plant, col = "3D", shape = "3D"), size = 2) +
  scale_x_date() +
  scale_fill_manual(values = c(colors_event, WalzClosed = "orange", WalzOpen = "yellow"), name = "Scenario") +
  scale_color_manual(name = "", values = c("Response curves" = 1, "3D" = 2)) +
  scale_shape_manual(name = "", values = c("Response curves" = 8, "3D" = 16)) +
  myTheme +
  labs(x = "", y = "Plant")

ggsave(filename = "2-figuresTables/calendar.pdf", width = 12, height = 4)


# leaf gas exchange -------------------------------------------------------
param <- data.table::fread("../07-walz/photosynthetic_and_stomatal_parameters.csv")
CurveCO2 <- data.table::fread(input = "0-data/Simu_photosynthetic_curve.csv")
CurveGs <- data.table::fread(input = "0-data/Simu_gs_curve.csv")

day <- ymd("2021-03-03")

param_sub <- param %>%
  filter(Date == day) %>%
  mutate(Cᵢ = 1000, A = 15, Gₛ = 0.09, Dₗ = 10)

gr_CO2 <- CurveCO2 %>%
  filter(Date == day) %>%
  ggplot() +
  geom_point(aes(x = Cᵢ, y = A, col = "Obs"), size = 2) +
  geom_line(aes(x = Cᵢ_sim, y = A_sim, col = "FvCB")) +
  geom_text(
    data = param_sub, aes(x = Cᵢ, y = A, label = paste("Vcmax:", round(VcMaxRef, 2), "\n", "Jmax:", round(JMaxRef, 2), "\n", "TPU:", round(TPURef, 2), "\n", "Rd:", round(RdRef, 2))),
    hjust = 0, col = 2
  ) +
  myTheme_multi +
  labs(
    x = expression(C[i] * " (ppm)"),
    y = expression(A[n] * " (" * mu * mol * " " * m * " "**-2 * " " * s**-1 * ")")
  ) +
  scale_color_manual(values = c("Obs" = 1, "FvCB" = 2)) +
  theme(legend.position = c(0.1, 0.9)) +
  facet_wrap(~ paste("Plant", Plant, "Leaf", Leaf, " ", Date))


gr_gs <- CurveGs %>%
  filter(Date == day) %>%
  ggplot() +
  geom_point(aes(x = Dₗ, y = Gₛ, col = "Obs"), size = 2) +
  geom_line(aes(x = Dₗ, y = Gₛ_sim, col = "Medlyn")) +
  myTheme_multi +
  geom_text(
    data = param_sub, aes(x = Dₗ, y = Gₛ, label = paste("g0:", round(g0, 2), "\n", "g1:", round(g1, 2))),
    hjust = 0, col = "blue"
  ) +
  labs(
    x = expression(D[l] * " (kPa)"),
    y = expression(g[s] * " (" * mol * " " * m * " "**-2 * " " * s**-1 * ")")
  ) +
  scale_color_manual(values = c("Obs" = 1, "Medlyn" = "blue")) +
  theme(legend.position = c(0.8, 0.9)) +
  facet_wrap(~ paste("Plant", Plant, "Leaf", Leaf, " ", Date))

plot_grid(gr_CO2, gr_gs, ncol = 2, labels = c("A", "B"))

ggsave(filename = "2-figuresTables/LeafGasExchanges.pdf", width = 12, height = 6)

# climate -----------------------------------------------------------------

mic3_raw <- fread("../02-climate/climate_mic3.csv") %>%
  mutate(
    Date = ymd(str_sub(DateTime, start = 1, end = 10)),
    hms = str_sub(DateTime, 12, 19)
  ) %>%
  filter(hms(hms) >= hms("05:00:00") & hms(hms) <= hms("20:00:00"))


mic3 <- merge(mic3_raw, cal %>% filter(!is.na(scenar)), all.y = T) %>%
  rename(
    `Temperature (°C)` = Ta_measurement,
    `Relative humidity (%)` = Rh_measurement,
    `PAR (mircomol of CO2 m-2 s-1)` = R_measurement
  ) %>%
  tidyr::gather(key = "variable", "value", `Temperature (°C)`, `Relative humidity (%)`, `PAR (mircomol of CO2 m-2 s-1)`)

mic3_m <- merge(mic3_raw, cal %>% filter(!is.na(scenar)), all.y = T) %>%
  group_by(scenar, hms) %>%
  summarize(
    Ta_measurement = median(Ta_measurement, na.rm = T),
    Rh_measurement = median(Rh_measurement, na.rm = T),
    R_measurement = median(R_measurement, na.rm = T),
    CO2_ppm = median(CO2_ppm, na.rm = T)
  ) %>%
  ungroup() %>%
  rename(
    `Temperature (°C)` = Ta_measurement,
    `Relative humidity (%)` = Rh_measurement,
    `PAR (mircomol of CO2 m-2 s-1)` = R_measurement,
    `CO2 (ppm)` = CO2_ppm
  ) %>%
  tidyr::gather(key = "variable", "value", `Temperature (°C)`, `Relative humidity (%)`, `PAR (mircomol of CO2 m-2 s-1)`, `CO2 (ppm)`)

ggplot() +
  geom_line(data = mic3 %>% filter(!(scenar %in% c("WalzClosed", "WalzOpen"))), aes(x = hms(hms), y = value, col = scenar, group = Date), alpha = 0.2) +
  geom_line(data = mic3_m %>% filter(!(scenar %in% c("WalzClosed", "WalzOpen"))), aes(x = hms(hms), y = value, col = scenar)) +
  facet_grid(variable ~ scenar, scale = "free_y") +
  scale_color_manual(values = colors_event, name = "Scenario") +
  scale_x_time() +
  labs(x = "Time of the day", y = "") +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 90))

ggsave(filename = "2-figuresTables/Scenarios.pdf", width = 12, height = 9)



### tests light
merge(mic3_raw, cal %>% filter(!is.na(scenar)), all.y = T) %>%
  filter((scenar %in% c("WalzClosed", "WalzOpen"))) %>%
  ggplot() +
  geom_line(aes(x = hms(hms), y = R_measurement, col = scenar, group = Date)) +
  scale_color_manual(values = c(colors_event, WalzClosed = "orange", WalzOpen = "yellow"), name = "Scenario") +
  scale_x_time() +
  labs(x = "Time of the day", y = "PAR (mircomol of CO2 m-2 s-1)") +
  myTheme +
  theme(panel.background = element_rect(fill = "grey"))

ggsave(filename = "2-figuresTables/SI_LightWalzOpenClose.pdf", width = 8, height = 5)

# mic3 %>%
#   filter(Date==ymd('2021-03-18')) %>%
#   ggplot()+
#   geom_line(aes(x=hms(hms),y=value,col=scenar,group=Date))+
#   facet_grid(variable~scenar,scale='free_y')+
#   scale_color_manual(values =colors_event,name='Scenario')+
#   scale_x_time()+
#   labs(x='Time of the day',y='')+
#   theme(axis.text.x = element_text(angle=90))



### same with database
dt_raw <- fread("../09-database/database_5min.csv") %>%
  mutate(
    Date = ymd(str_sub(DateTime_start, start = 1, end = 10)),
    hms = str_sub(DateTime_start, 12, 19)
  ) %>%
  filter(hms(hms) >= hms("05:00:00") & hms(hms) <= hms("20:00:00"))


dt <- dt_raw %>%
  rename(
    `Temperature (°C)` = Ta_measurement,
    `Relative humidity (%)` = Rh_measurement,
    `PAR (mircomol of CO2 m-2 s-1)` = R_measurement,
    `CO2 (ppm)` = CO2_ppm
  ) %>%
  tidyr::gather(key = "variable", "value", `Temperature (°C)`, `Relative humidity (%)`, `PAR (mircomol of CO2 m-2 s-1)`, `CO2 (ppm)`)

dt_m <- dt_raw %>%
  group_by(Scenario, hms) %>%
  summarize(
    Ta_measurement = median(Ta_measurement, na.rm = T),
    Rh_measurement = median(Rh_measurement, na.rm = T),
    R_measurement = median(R_measurement, na.rm = T),
    CO2_ppm = median(CO2_ppm, na.rm = T)
  ) %>%
  ungroup() %>%
  rename(
    `Temperature (°C)` = Ta_measurement,
    `Relative humidity (%)` = Rh_measurement,
    `PAR (mircomol of CO2 m-2 s-1)` = R_measurement,
    `CO2 (ppm)` = CO2_ppm
  ) %>%
  tidyr::gather(key = "variable", "value", `Temperature (°C)`, `Relative humidity (%)`, `PAR (mircomol of CO2 m-2 s-1)`, `CO2 (ppm)`)

error <- dt %>%
  filter(Scenario == "")

error %>%
  group_by(Date) %>%
  select(Date, Plant) %>%
  distinct()


ggplot() +
  geom_line(data = dt, aes(x = hms(hms), y = value, col = as.factor(Plant), group = Date)) +
  facet_grid(variable ~ Scenario, scale = "free_y") +
  # scale_color_manual(values =colors_event,name='Scenario')+
  scale_x_time() +
  labs(x = "Time of the day", y = "") +
  theme(axis.text.x = element_text(angle = 90))


# thermal camera ----------------------------------------------------------
# th=dt_raw %>%
#   filter(Plant==1& Date>=ymd('2021/03/15') & Date<=ymd('2021/03/18')) %>%
#   select(Plant,Scenario,Sequence,Leaf,Date,DateTime_start,hms,Tl_mean,Tl_min,Tl_max,Tl_std,Ta_measurement) %>%
#   filter(!is.na(Leaf))
#
# picTherm=readPNG('2-figuresTables/masksP1.png')
#
# graphLeaf=th %>%
#   ggplot(aes(x=hms(hms),y=Tl_mean,col=paste('Leaf',Leaf),group=Leaf))+
#   geom_point(aes(x=hms(hms),y=Ta_measurement,col='Microcosm'))+
#   geom_line()+
#   scale_color_manual(values = c('Leaf 3'="#fee5d9",'Leaf 4'="#fcae91",'Leaf 6'="#fb6a4a",'Leaf 7'="#de2d26","Leaf 8"="#a50f15",'Microcosm'=1))+
#   scale_x_time()+
#   labs(y='Temperature (°C)',x='Time of the day')+
#   theme()+
#   myTheme
#
# cowplot::plot_grid(ggdraw() +
#                      draw_image(picTherm),
#                    graphLeaf,ncol=2,labels=c('A','B'))
#
#
# ggsave(filename = '2-figuresTables/LeafTemp.pdf',width = 16,height = 6)


th <- dt_raw %>%
  filter(Plant == 4 & Date >= ymd("2021/04/06") & Date <= ymd("2021/04/06")) %>%
  select(Plant, Scenario, Sequence, Leaf, Date, DateTime_start, hms, Tl_mean, Tl_min, Tl_max, Tl_std, Ta_measurement) %>%
  filter(!is.na(Leaf))

picTherm <- readPNG("2-figuresTables/maskP4.png")

graphLeaf <- th %>%
  ggplot(aes(x = hms(hms), y = Tl_mean, col = sprintf(paste("Leaf", sprintf("%02d", Leaf))), group = Leaf)) +
  geom_point(aes(x = hms(hms), y = Ta_measurement, col = "Microcosm")) +
  geom_line() +
  scale_color_manual(values = c("Leaf 02" = "#fee5d9", "Leaf 04" = "#fcbba1", "Leaf 06" = "#fc9272", "Leaf 07" = "#fb6a4a", "Leaf 08" = "#ef3b2c", "Leaf 09" = "#cb181d", "Leaf 10" = "#99000d", "Microcosm" = 1)) +
  scale_x_time() +
  labs(y = "Temperature (°C)", x = "Time of the day") +
  theme() +
  myTheme


cowplot::plot_grid(
  ggdraw() +
    draw_image(picTherm),
  graphLeaf,
  ncol = 2, labels = c("A", "B")
)


ggsave(filename = "2-figuresTables/LeafTempP4.pdf", width = 16, height = 6)

# dt_raw %>%
#   filter(is.na(Plant)) %>%
#   select(Date,Scenario) %>%
#   distinct()
#
# dt_raw %>%
#   filter(!is.na(Scenario) &!is.na(Leaf)) %>%
#   ggplot(aes(x=hms(hms),y=Tl_mean,col=sprintf(paste('Leaf',sprintf('%02d',Leaf))),group=paste(Date,Leaf,Plant)))+
#   geom_point(aes(x=hms(hms),y=Ta_measurement,col='Microcosm'))+
#   geom_line()+
#   scale_x_time()+
#   facet_grid(Plant~paste(Scenario))+
#   labs(y='Temperature (°C)',x='Time of the day')


# 3D reconstructions ------------------------------------------------------

picLeafPC <- readPNG("2-figuresTables/leafPC.png")
picLeafMesh <- readPNG("2-figuresTables/leafMesh.png")
picPlantPC <- readPNG("2-figuresTables/plantPC.png")
picPlantMesh <- readPNG("2-figuresTables/plantMesh.png")


p1 <- cowplot::plot_grid(
  ggdraw() +
    draw_image(picLeafPC),
  ggdraw() +
    draw_image(picLeafMesh)
)


p2 <- cowplot::plot_grid(
  ggdraw() +
    draw_image(picPlantPC),
  ggdraw() +
    draw_image(picPlantMesh)
)

cowplot::plot_grid(p1, p2, ncol = 1, rel_heights = c(0.405, 0.595), labels = c("A", "B"))

ggsave(filename = "2-figuresTables/reconstruction.pdf", width = 10, height = 11)



# Lidar area --------------------------------------------------------------


area <- data.table::fread(input = "0-data/ComparisonArea.csv")

# leaf area
pLeaf <- area %>%
  ggplot(aes(x = Planim_area, y = Manual_mesh_area, group = plant, fill = plant)) +
  geom_abline(slope = 1, intercept = 0, col = "grey") +
  geom_smooth(method = "lm", se = F, aes(col = plant)) +
  geom_label(aes(label = rank), col = 1) +
  # facet_wrap(~plant)+
  labs(
    x = expression("measured leaf area "(cm**2)),
    y = expression("3D mesh leaf area "(cm**2))
  ) +
  ylim(c(0, 1550)) +
  xlim(c(0, 1550)) +
  myTheme +
  theme(legend.position = c(0.9, 0.2))

pPlant <- area %>%
  group_by(plant) %>%
  summarize(
    `3D mesh` = sum(Manual_mesh_area),
    `leaf area meter` = sum(Planim_area)
  ) %>%
  ungroup() %>%
  tidyr::gather(key = "type", value = "PLA", `3D mesh`, `leaf area meter`) %>%
  ggplot(aes(x = plant, y = PLA / 10000, group = paste(plant, type))) +
  geom_col_pattern(aes(pattern = type), col = 1, position = position_dodge(), pattern_density = 0.5, pattern_fill = "white") +
  scale_pattern_manual(name = "", values = c(`leaf area meter` = "stripe", `3D mesh` = "none")) +
  theme_bw() +
  theme(plot.background = element_blank()) +
  labs(
    y = expression("plant leaf area "(m**2)),
    x = ""
  )

ggdraw() +
  draw_plot(pLeaf) +
  draw_plot(pPlant, x = 0.15, y = .55, width = .45, height = .45)

ggsave(filename = "2-figuresTables/compareArea.pdf", width = 8, height = 5)


# light maps --------------------------------------------------------------


#### light measures
## without plants
vid_raw <- fread(input = "../00-data/mappingLight/mapEmptyChamber.csv", dec = ",")


vid <- vid_raw %>%
  tidyr::gather(key = "Z", value = "PAR", contains("Z")) %>%
  mutate(Z = as.numeric(str_remove_all(Z, pattern = "[Z, ,c,m]"))) %>%
  # filter(Y>13 & Conditions=='Feutrine_sol')%>%
  filter(Y > 13) %>%
  mutate(X = X + 7) ### decalage de 7 cm pour être en accord avec la chambre reconstruite

lims <- range(vid$PAR, na.rm = T)

parVid <- vid %>%
  filter(Z != -105.4) %>%
  ggplot(aes(x = X, y = Y, fill = PAR)) +
  geom_tile() +
  coord_equal() +
  facet_grid(paste(sprintf("%03d", -Z), "cm from light") ~ Conditions) +
  scale_fill_viridis(option = "H") +
  scale_color_viridis(option = "D") +
  labs(fill = "PAR")


picSuncscan <- readPNG("2-figuresTables/sunScan2.png")



palms_raw <- fread(input = "../00-data/mappingLight/mapWithPalms.csv", dec = ",")

palm2 <- palms_raw %>%
  filter(Plant == "P2") %>%
  mutate(PAR = `Z_Tip-105.4cm`, Z = -105.4) %>%
  filter(Y > 13) %>%
  mutate(X = X + 7)


parPalm <- palm2 %>%
  ggplot(aes(x = X, y = Y, fill = PAR)) +
  geom_tile() +
  facet_grid(paste(-Z, "cm from light") ~ "BlackFelt_soil") +
  scale_fill_viridis(option = "H") +
  scale_color_viridis(option = "D") +
  coord_equal() +
  labs(fill = "PAR")


cowplot::plot_grid(parVid,
  plot_grid(
    ggdraw() +
      draw_image(picSuncscan, x = 0.1, y = -0.1, width = 1, height = 1.2), parPalm,
    ncol = 2
  ),
  ncol = 1,
  labels = c("A", "B"), rel_heights = c(0.6, 0.4)
)

ggsave(filename = "2-figuresTables/Light.pdf", width = 10, height = 12)



# light spectrum ----------------------------------------------------------

sp=fread(input = '../00-data/mappingLight/LEDspectrum.csv',dec=',')

sp%>%
  ggplot(aes(x=`waveLength(nm)`,y=`irradiance(microW/cm2/nm)`))+
  geom_line()+
  labs(x='Wave length (nm)',y=expression('Irradiance ('*mu*'W '*cm**-2*nm**-1*')'))+
  myTheme

ggsave(filename = "2-figuresTables/LightSpectrum.pdf", width = 10, height = 8)
