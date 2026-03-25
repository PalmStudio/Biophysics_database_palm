# Script for generating data paper figures & tables ---------------------------------


# load packages -----------------------------------------------------------


packs <- c("lubridate", "stringr", "tidyverse", "viridis", "Vpalmr", "data.table", "yaml", "archimedR", "png", "cowplot", "ggpattern",'ggpmisc','cowplot','ggrepel','plotly','scales')
InstIfNec <- function(pack) {
  if (!do.call(require, as.list(pack))) {
    do.call(install.packages, as.list(pack))
  }
  do.call(require, as.list(pack))
}
lapply(packs, InstIfNec)


# inputs ------------------------------------------------------------------

colors_plant=hue_pal()(4) 
names(colors_plant)=c("P1",'P2','P3','P5')

colors_scenar=c('darkolivegreen3','darkolivegreen4','darkolivegreen','cyan','blue3','firebrick','firebrick1','grey')
names(colors_scenar)=c("400ppm",'600ppm','800ppm','DryCold','Cold','Hot','DryHot','Cloudy')



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


f.vpd=function(Temp,HR,p1=18.9321,p2=5300.24){
  (exp(p1-p2/(Temp+273)))*(1-HR/100)
}
  
Temp=c(23,27)
Hr=c(75,30)

f.vpd(Temp = Temp,HR=Hr)

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
param <- data.table::fread("../06-walz/photosynthetic_and_stomatal_parameters.csv")
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
  mutate(var=A/(Cₐ*sqrt(Dₗ))) %>% 
  ggplot() +
  geom_point(aes(x = var, y = Gₛ, col = "Obs"), size = 2) +
  geom_line(aes(x = var, y = Gₛ_sim, col = "Medlyn"))+
  myTheme_multi +
  geom_text(
    data = param_sub, aes(x =A/(Cᵢ*sqrt(Dₗ)), y = Gₛ, label = paste("g0:", round(g0, 2), "\n", "g1:", round(g1, 2))),
    hjust = 0, col = "blue"
  ) +
  labs(
    x = expression(A*'/'*'('*C[a]*D[l]^0.5*')' *" (ppm)"),
    y = expression(g[s] * " (" * mol * " " * m * " "**-2 * " " * s**-1 * ")")
  ) +
  scale_color_manual(values = c("Obs" = 1, "Medlyn" = "blue")) +
  theme(legend.position = c(0.8, 0.9)) +
  facet_wrap(~ paste("Plant", Plant, "Leaf", Leaf, " ", Date))

plot_grid(gr_CO2, gr_gs, ncol = 2, labels = c("A", "B"))


ggsave(filename = "2-figuresTables/LeafGasExchanges.pdf", width = 12, height = 6)

# climate -----------------------------------------------------------------

mic3_raw <- fread("../01-climate/climate_mic3.csv") %>%
  mutate(
    Date = ymd(str_sub(DateTime, start = 1, end = 10)),
    hms = str_sub(DateTime, 12, 19)
  ) %>%
  filter(hms(hms) >= hms("05:00:00") & hms(hms) <= hms("20:00:00"))


mic3 <- merge(mic3_raw, cal %>% filter(!is.na(scenar)), all.y = T) %>%
  rename(
    `Temperature (°C)` = Ta_measurement,
    `Relative humidity (%)` = Rh_measurement,
    `PAR (µmol m-2 s-1)` = R_measurement
  ) %>%
  tidyr::gather(key = "variable", "value", `Temperature (°C)`, `Relative humidity (%)`, `PAR (µmol m-2 s-1)`)
# 
# mic3_m <- merge(mic3_raw, cal %>% filter(!is.na(scenar)), all.y = T) %>%
#   group_by(scenar, hms) %>%
#   summarize(
#     Ta_measurement = median(Ta_measurement, na.rm = T),
#     Rh_measurement = median(Rh_measurement, na.rm = T),
#     R_measurement = median(R_measurement, na.rm = T),
#     CO2_ppm = median(CO2_ppm, na.rm = T)
#   ) %>%
#   ungroup() %>%
#   rename(
#     `Temperature (°C)` = Ta_measurement,
#     `Relative humidity (%)` = Rh_measurement,
#     `PAR (µmol m-2 s-1)` = R_measurement,
#     `CO2 (ppm)` = CO2_ppm
#   ) %>%
#   tidyr::gather(key = "variable", "value", `Temperature (°C)`, `Relative humidity (%)`, `PAR (µmol m-2 s-1)`, `CO2 (ppm)`)
# 
# ggplot() +
#   geom_line(data = mic3 %>% filter(!(scenar %in% c("WalzClosed", "WalzOpen"))), aes(x = hms(hms), y = value, group = Date), alpha = 0.2) +
#   geom_line(data = mic3_m %>% filter(!(scenar %in% c("WalzClosed", "WalzOpen"))), aes(x = hms(hms), y = value)) +
#   facet_grid(variable ~ scenar, scale = "free_y") +
#   # scale_color_manual(values = colors_event, name = "Scenario") +
#   scale_x_time() +
#   labs(x = "Time of the day", y = "") +
#   theme_bw() +
#   theme(axis.text.x = element_text(angle = 90),
#         legend.position='bottom')


### remove open door
database_raw<- fread("../09-database/database_5min.csv") %>% 
  mutate(
    Date = ymd(str_sub(DateTime_start, start = 1, end = 10)),
    hms = str_sub(DateTime_start, 12, 19)
  ) %>%
  filter(hms(hms) >= hms("05:00:00") & hms(hms) <= hms("20:00:00"))

database <- database_raw%>%
    rename(
      `Temperature (°C)` = Ta_measurement,
      `Relative humidity (%)` = Rh_measurement,
      `PAR (µmol m-2 s-1)` = R_measurement,
      `CO2 (ppm)` = CO2_ppm,
    ) %>%
  mutate(`VPD (kPa)`=f.vpd(HR = `Relative humidity (%)`,Temp=`Temperature (°C)`,p1=18.9321,p2=5300.24) ) %>%
    tidyr::gather(key = "variable", "value",`CO2 (ppm)`, `Temperature (°C)`, `Relative humidity (%)`, `PAR (µmol m-2 s-1)`,`VPD (kPa)`)

# database_m <- database_raw %>%
#   group_by(Scenario, hms) %>%
#   summarize(
#     Ta_measurement = median(Ta_measurement, na.rm = T),
#     Rh_measurement = median(Rh_measurement, na.rm = T),
#     R_measurement = median(R_measurement, na.rm = T),
#     CO2_ppm = median(CO2_ppm, na.rm = T)
#   ) %>%
#   ungroup() %>%
#   rename(
#     `Temperature (°C)` = Ta_measurement,
#     `Relative humidity (%)` = Rh_measurement,
#     `PAR (µmol m-2 s-1)` = R_measurement,
#     `CO2 (ppm)` = CO2_ppm
#   ) %>%
#   tidyr::gather(key = "variable", "value", `Temperature (°C)`, `Relative humidity (%)`, `PAR (µmol m-2 s-1)`, `CO2 (ppm)`)

ggplot() +
    geom_line(data = database %>% filter(!(Scenario %in% c("TestLight", ""))), aes(x = hms(hms), y = value, group = Date), alpha = 0.2) +
    # geom_line(data = database_m %>% filter(!(scenar %in% c("WalzClosed", "WalzOpen"))), aes(x = hms(hms), y = value)) +
    facet_grid(variable ~ Scenario, scale = "free_y") +
    # scale_color_manual(values = colors_event, name = "Scenario") +
    scale_x_time() +
    labs(x = "Time of the day", y = "") +
    theme_bw() +
    theme(axis.text.x = element_text(angle = 90),
          legend.position='bottom')

ggsave(filename = "2-figuresTables/Scenarios.pdf", width = 16, height = 18,units = 'cm')



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
  ggplot(aes(x = Planim_area, y = Manual_mesh_area, group = plant, fill = plant,col = plant)) +
  geom_abline(slope = 1, intercept = 0, col = "grey") +
  geom_smooth(method = "lm", se = F, aes(col = plant)) +
  stat_poly_eq(use_label(c("eq", "R2")))+
  geom_label(aes(label = rank), col = 1) +
  # facet_wrap(~plant)+
  labs(
    x = expression("measured leaf area "(cm**2)),
    y = expression("3D mesh leaf area "(cm**2))
  ) +
  ylim(c(0, 1550)) +
  xlim(c(0, 1550)) +
  myTheme +
  theme(legend.position = c(0.1, 0.4))

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
  draw_plot(pPlant, x = 0.55, y = .15, width = .45, height = .45)

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

sp <- fread(input = "../00-data/mappingLight/LEDspectrum.csv", dec = ",")

sp %>%
  ggplot(aes(x = `waveLength(nm)`, y = `irradiance(microW/cm2/nm)`)) +
  geom_line() +
  labs(x = "Wave length (nm)", y = expression("Irradiance (" * mu * "W " * cm**-2 * nm**-1 * ")")) +
  myTheme

ggsave(filename = "2-figuresTables/LightSpectrum.pdf", width = 10, height = 8)



# fluxes ------------------------------------------------------------------

AllScenar=fread('0-data/SequencePlantScenar.csv')%>%
  mutate(Date=dmy(Date))%>%
  filter(Plant!='' & Ref=='T')

don_raw=fread(input = "0-data/database_5min.csv")%>%
  mutate(Date=ymd(str_sub(DateTime_start,start = 0,end = 10)),
         hms=str_sub(DateTime_start,12,19),
         Plant=paste0('P',Plant))

don=merge(don_raw,AllScenar,all.y=T)

# both transpi and Co2 ----------------------------------------------------

maxTranspi=max(don$transpiration_diff_g_s,na.rm=T)
maxCO2=max(don$CO2_outflux_umol_s,na.rm=T)

don2=don%>%gather('var',"val",transpiration_diff_g_s,CO2_outflux_umol_s)%>%
  mutate(val = if_else(var == 'CO2_outflux_umol_s', val, val / (maxTranspi / maxCO2)))%>%
  filter(Plant %in% c('P3'))

ggplot()+
  geom_ribbon(data=don2%>%filter(hms(hms)<=hms('18:30:00')),aes(x = hms(hms), ymax = Inf, ymin = -Inf),fill = 'lightgrey', alpha = 0.3)+
  geom_ribbon(data=don2%>%filter(hms(hms)>=hms('05:30:00')),aes(x = hms(hms), ymax = Inf, ymin = -Inf),fill = 'lightgrey', alpha = 0.3)+
  geom_line(data=don2%>%filter(var=='CO2_outflux_umol_s'),aes(x=hms(hms),y=val,col='CO2',group=paste(Scenario,Date)),lwd=1)+
  geom_line(data=don2%>%filter(var=='transpiration_diff_g_s'),aes(x=hms(hms),y=val,col='H2O',group=paste(Scenario,Date)),lwd=1)+
  scale_x_time(breaks = seq(0,24,6)*3600,labels = paste0(seq(0,24,6),'h'))+
  scale_y_continuous(sec.axis = sec_axis(trans = ~ . * (maxTranspi / maxCO2),
                                         name = expression('H2O flux ' *(g[H20]*' '*s**-1)))) +
  facet_wrap(~Scenario,ncol=4)+
  ylab(expression('CO2 flux ' *(mu*mol[C02]*' '*s**-1)))+
  xlab(expression('Time of the day'))+
  myTheme+
  theme(legend.position='none',
        axis.title.y.left =  element_text(color=hue_pal()(1)),
        axis.title.y.right =  element_text(color=hue_pal()(2)[2]),
        axis.text.y.left =  element_text(color=hue_pal()(1)),
        axis.text.y.right =  element_text(color=hue_pal()(2)[2]),
        
  )


ggsave(filename = "2-figuresTables/Day_fluxes.pdf", width = 12, height = 8)

### valeurs intégrées

molCO2togr=44.0095

int=don%>%
  select(Plant,Scenario,hms,transpiration_diff_g_s,CO2_outflux_umol_s)%>%
  distinct()%>%
  group_by(Plant,Scenario)%>%
  filter(hms(hms)<=hms('19:30:00') & hms(hms)>=hms('05:30:00'))%>% # filter complete day
  mutate(nb_mes=n())%>%
  filter(nb_mes>83)%>% # remove incomplete day
  summarize(CO2_tot_g=sum(CO2_outflux_umol_s)*(60*10)/(10**6)*molCO2togr, #sec-->mn-->day-->mol-->g
            H2O_tot=sum(transpiration_diff_g_s)*60*10)%>%
  ungroup()

grCO2=int%>%
  group_by(Scenario)%>%
  summarize(mean=mean(CO2_tot_g,na.rm=T),
            sd=sd(CO2_tot_g,na.rm=T))%>%
  ungroup()%>%
  ggplot(aes(x=Scenario,y=mean,col=Scenario))+
  geom_col(position='dodge',aes(fill=Scenario),alpha=0.8,col=1)+
  geom_errorbar(aes(x = Scenario,ymin = mean-sd,ymax=mean+sd),width = 0.25)+
  myTheme+
  ylab(expression('C assimilation '*(g[CO[2]]*' '*day**-1)))+
  xlab('')+
  coord_flip()+
  scale_fill_manual(values = colors_scenar)+
  scale_color_manual(values = colors_scenar)+
  theme(legend.position = 'none')


grH2O=int%>%
  group_by(Scenario)%>%
  summarize(mean=mean(H2O_tot/100,na.rm=T),
            sd=sd(H2O_tot/100,na.rm=T))%>%
  ungroup()%>%
  ggplot(aes(x=Scenario,y=mean,col=Scenario))+
  geom_col(position='dodge',aes(fill=Scenario),alpha=0.8,col=1)+
  geom_errorbar(aes(x = Scenario,ymin = mean-sd,ymax=mean+sd),width = 0.25)+
  myTheme+
  ylab(expression('Transpiration '*(100*g[H2O]*' '*day**-1)))+
  xlab('')+
  coord_flip()+
  scale_fill_manual(values = colors_scenar)+
  scale_color_manual(values = colors_scenar)+
  theme(legend.position = 'none')

### water use efficiency
grWUE=int%>%
  mutate(WUE=abs(CO2_tot_g)/H2O_tot)%>%
  group_by(Scenario)%>%
  summarize(mean=mean(WUE,na.rm=T),
            sd=sd(WUE,na.rm=T))%>%
  ungroup()%>%
  ggplot(aes(x=Scenario,y=mean,col=Scenario))+
  geom_col(position='dodge',aes(fill=Scenario),alpha=0.8,col=1)+
  geom_errorbar(aes(x = Scenario,ymin = mean-sd,ymax=mean+sd),width = 0.25)+
  myTheme+
  ylab(expression('Water use efficiency '*(g[CO[2]]*' '*g[H2O]**-1)))+
  xlab('')+
  coord_flip()+
  scale_fill_manual(values = colors_scenar)+
  scale_color_manual(values = colors_scenar)+
  theme(legend.position = 'none')


plot_grid(grCO2,grH2O,grWUE,ncol=3)


ggsave(filename = "2-figuresTables/Integrated_fluxes.pdf", width = 16, height = 8)



# test light --------------------------------------------------------------
#### Licor data
close1=read.csv(file='../00-data/walz/walz/scenarii/closed/P5F70427.csv',sep=';',header=F,dec='.',skip =2)


head=str_split(string = readLines(con ='../00-data/walz/walz/scenarii/closed/P5F70427.csv' ,n = 1),pattern = ';')[[1]]

colnames(close1)=head

close1=close1%>%
  mutate(Plant='P4',
         Walz_head='WalzClosed')


close2=read.csv(file='../00-data/walz/walz/scenarii/closed/P1F60428.csv',sep=';',header=F,dec='.',skip =2)

colnames(close2)=head

close2=close2%>%
  mutate(Plant='P1',
         Walz_head='WalzClosed')


open1=read.csv(file='../00-data/walz/walz/scenarii/opened/P5F70429.csv',sep=';',header=F,dec='.',skip =2)
headO=str_split(string = readLines(con ='../00-data/walz/walz/scenarii/opened/P5F70429.csv' ,n = 1),pattern = ';')[[1]]
colnames(open1)=headO

open1=open1%>%
  mutate(Plant='P4',
         Walz_head='WalzOpen')

open2=read.csv(file='../00-data/walz/walz/scenarii/opened/P1F60430.csv',sep=';',header=F,dec='.',skip =2)
colnames(open2)=headO

open2=open2%>%
  mutate(Plant='P1',
         Walz_head='WalzOpen')


vars=c('Date','Time','PARtop','Tleaf','Tcuv','Tamb','Ttop','PARamb','rh','VPD','E','GH2O','A','ci','ca','wa','Plant','Walz_head')

walz=bind_rows(close1%>%
                 dplyr::select(vars),
               close2%>%
                 dplyr::select(vars),
               open1%>%
                 dplyr::select(vars),
               open2%>%
                 dplyr::select(vars)
)%>%
  mutate(Time=hms(Time), 
         hms=Time,
         hour=Time@hour,
         minute=Time@minute,
         Date=ymd(Date))%>%
  filter(hms(hms)<=hms('17:00:00') & hms(hms)>=hms('12:00:00'))
  
walz %>% 
  filter(hms(hms)<=hms('17:00:00') & hms(hms)>=hms('12:00:00')) %>% 
  group_by(Plant,Walz_head) %>% 
  summarize(maxA=max(A),
            minA=min(A),
            coef=sd(A)/mean(A)*100)

climWalz=mic3 %>% 
  filter(Date %in% unique(walz$Date) & variable=="PAR (µmol m-2 s-1)") %>% 
  mutate(PAR=value) %>% 
  select(Date,hms,PAR)

maxA=max(walz$A,na.rm=T)
maxPAR=max(climWalz$PAR,na.rm=T)

climWalz=merge(climWalz %>% 
  mutate(relPAR=PAR/(maxPAR/maxA),
         hms=hms(hms)+hms('02:00:00')),
  walz %>% select(Date,Plant,Walz_head) %>% distinct(),all.x=T,all.y=F)%>%
  filter(hms(hms)<=hms('17:00:00') & hms(hms)>=hms('12:00:00'))

ggplot()+
  geom_line(data=climWalz,aes(x=hms(hms),y=relPAR,group=paste(Plant,Walz_head)),lwd=1,col='grey')+
  geom_point(data=walz,aes(x=hms(hms),y=A,group=paste(Plant,Walz_head)),lwd=1,col='black')+
  facet_wrap(Plant~Walz_head,scales='free_x')+
  scale_x_time(breaks = seq(0,24,1)*3600,labels = paste0(seq(0,24,1),'h'))+
  scale_y_continuous(sec.axis = sec_axis(trans = ~ . * (maxPAR / maxA),
                                         name = expression('PPFD ' *(µmol*' '*m**-2*' '*s**-1)))) +
  ylab(expression(A[n] * " (" * mu * mol * " " * m * " "**-2 * " " * s**-1 * ")"))+
  xlab(expression('Time of the day'))+
  myTheme+
  theme(legend.position='none',
        axis.title.y.left =  element_text(color='black'),
        axis.title.y.right =  element_text(color='grey'),
        axis.text.y.left =  element_text(color='black'),
        axis.text.y.right =  element_text(color='grey'),
        
  )

ggsave(filename = "2-figuresTables/WalzTests.pdf", width = 16, height = 8)
