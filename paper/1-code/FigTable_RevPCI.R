# Script for generating data paper figures & tables ---------------------------------


# load packages -----------------------------------------------------------

packs <- c("lubridate", "stringr", "tidyverse", "viridis", "data.table", "yaml", "archimedR", "png", "cowplot", "ggpattern",'ggpmisc','cowplot','ggrepel','plotly','scales')
InstIfNec <- function(pack) {
  if (!do.call(require, as.list(pack))) {
    do.call(install.packages, as.list(pack))
  }
  do.call(require, as.list(pack))
}
lapply(packs, InstIfNec)


# inputs ------------------------------------------------------------------

colors_plant=c('#a6611a','#dfc27d','#80cdc1','#018571')
names(colors_plant)=c("P1",'P2','P3','P5')

colors_scenar=c('#1b9e77','#d95f02','#7570b3','#e7298a','#66a61e','#e6ab02','#a6761d','#666666','white')
names(colors_scenar)=c("400ppm",'600ppm','800ppm','DryCold','Cold','Hot','DryHot','LowPAR','Storage')


colors_event <- c('#1b9e77','#d95f02','#7570b3','#e7298a','#66a61e','#e6ab02','#a6761d','#666666')
names(colors_event) <- c("400ppm", "600ppm", "800ppm", "DryCold", "Cold", "Hot", "DryHot", "LowPAR")

shape_event <- paste(c(1:8))
names(shape_event) <- c("400ppm", "600ppm", "800ppm", "DryCold", "Cold", "Hot", "DryHot", "LowPAR")

tabelEvent <- data.frame(event = c(paste0("S", 1:8), "WalzClosed", "WalzOpen"), scenar = c("400ppm", "LowPAR", "600ppm", "Cold", "800ppm", "DryCold", "Hot", "DryHot", "WalzClosed", "WalzOpen"))

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


# f.vpd0=function(Temp,HR,p1=18.9321,p2=5300.24){
#   (exp(p1-p2/(Temp+273)))*(1-HR/100)
# }
f.vpd=function(Temp,HR){
  # es=0.61808*exp((17.27*Temp)/(Temp+273))
  es=0.61121*exp((18.678-Temp/234.5)*(Temp/(257.14+Temp)))
  ea=es*HR/100
  es-ea
}

# Temp=c(23,27)
# Hr=c(75,30)
# 
# f.vpd0(Temp = Temp,HR=Hr)
# f.vpd(Temp = Temp,HR=Hr)


# scenario ref ------------------------------------------------------------


# AllScenar=fread('0-data/SequencePlantScenar.csv')%>%
#   mutate(Date=dmy(Date)) %>% 
#   group_by(Plant,Scenario) %>% 
#   mutate(rep=paste('rep',row_number())) %>% 
#   ungroup()



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
    x = expression(A*'/'*'('*C[a]*sqrt('VPD')*')' *" (ppm)"),
    y = expression(g[s] * " (" * mol * " " * m * " "**-2 * " " * s**-1 * ")")
  ) +
  scale_color_manual(values = c("Obs" = 1, "Medlyn" = "blue")) +
  theme(legend.position = c(0.8, 0.9)) +
  facet_wrap(~ paste("Plant", Plant, "Leaf", Leaf, " ", Date))

plot_grid(gr_CO2, gr_gs, ncol = 2, labels = c("A", "B"))


ggsave(filename = "2-figuresTables/LeafGasExchanges.pdf", width = 12, height = 6)

# climate -----------------------------------------------------------------

### remove open door

database_raw<- fread("../09-database/database_5min.csv") %>% 
  mutate(
    Date = ymd(str_sub(DateTime_start, start = 1, end = 10)),
    hms = str_sub(DateTime_start, 12, 19))

database_raw=database_raw %>% 
  mutate(Plant=paste0('P',Plant)) 

database <- database_raw%>%
  rename(
    `Temperature (°C)` = Ta_measurement,
    `Relative humidity (%)` = Rh_measurement,
    `PAR (µmol m-2 s-1)` = R_measurement,
    `CO2 (ppm)` = CO2_ppm,
  ) %>%
  mutate(`VPD (kPa)`=f.vpd(HR = `Relative humidity (%)`,Temp=`Temperature (°C)`) ) %>%
  tidyr::gather(key = "variable", "value",`CO2 (ppm)`, `Temperature (°C)`, `Relative humidity (%)`, `PAR (µmol m-2 s-1)`,`VPD (kPa)`)


ggplot() +
  geom_point(data = database %>% filter(!(Scenario %in% c("WalzClosed",'WalzOpen', "Mixed") & hms>hms('04:30:00') & hms<hms('21:00:00')) & outlier=='no'), aes(x = hms(hms), y = value, group = Date), alpha = 0.8,size=0.3) +
  facet_grid(variable ~ Scenario, scale = "free_y") +
  scale_x_time() +
  labs(x = "Time of the day", y = "") +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 90),
        legend.position='none')

ggsave(filename = "2-figuresTables/Scenarios.pdf", width = 16, height = 20,units = 'cm')


# calendar -------------------------------------------------------------

cal_0=fread('../00-data/scenario_sequence/calendar.csv')


ScenarRep=database_raw %>% filter(!(Scenario %in% c('Mixed') & hms>hms('04:30:00') & hms<hms('21:30:00')) & outlier=='no') %>%
  dplyr::select(Plant,Scenario,Date,hms,CO2_outflux_umol_s) %>% 
  distinct() %>% 
  group_by(Plant,Scenario,Date) %>% 
  summarize(n=n()) %>% 
  ungroup() %>% 
  data.frame()

nFull=12*6 ##number of measurements for a full day

cal=merge(cal_0,
          ScenarRep %>% select(Date,Plant,Scenario,n),all.x=T) %>% 
  mutate(alpha=(ifelse(n>=nFull,0,(nFull-n))/nFull)) %>% 
  group_by(Date,Plant) %>% 
  arrange(Date,Plant,n) %>% 
  mutate(ref=ifelse(n==max(n),'yes','no'))

ggplot() +
  geom_tile(data = cal %>% filter(ref=='yes'), aes(x = Date, y = Plant,fill = n), col = 1) +
  geom_tile(data = cal %>% filter(Scenario==''), aes(x = Date, y = Plant), fill = "white", col = 1) +
  geom_point(data = cal %>% filter(event == "Response curves"), aes(x = Date, y = Plant, col = "Response curves", shape = "Response curves"), size = 2,position = position_nudge(y = 0.3)) +
  geom_point(data = cal %>% filter(event == "3D"), aes(x = Date, y = Plant, col = "3D", shape = "3D"), size = 2,position = position_nudge(y = -0.3)) +
  geom_text(data = cal%>%filter(ref=='yes'), aes(x = Date, y = Plant,label=Scenario),col='white',angle = 90,size=3) +
  scale_x_date() +
  scale_fill_gradient(name ='# measurements') +
  scale_color_manual(name = "", values = c("Response curves" = 1, "3D" = 2)) +
  scale_shape_manual(name = "", values = c("Response curves" = 8, "3D" = 16)) +
  myTheme +
  theme(legend.position = 'right',legend.title = element_text(colour = 1,size = 10),legend.direction = "vertical",legend.box = "vertical")+
  labs(x = "", y = "Plant")

ggsave(filename = "2-figuresTables/calendar.pdf", width = 15, height =8)


# thermal camera ----------------------------------------------------------

th <- database_raw %>%
  filter(Plant == 'P4' & Date >= ymd("2021/04/06") & Date <= ymd("2021/04/06")) %>%
  select(Plant, Scenario, Sequence, Leaf, Date, DateTime_start, hms, Tl_mean,Tl_mean_corrected, Tl_min, Tl_max, Tl_std, Ta_measurement) %>%
  filter(!is.na(Leaf))

picTherm <- readPNG("2-figuresTables/maskP4.png")

graphLeaf <- ggplot() +
  geom_ribbon(data=th%>%filter(hms(hms)>=hms('05:55:00') & hms(hms)<=hms('19:10:00')),aes(x = hms(hms), ymax = Inf, ymin = -Inf),fill = 'yellow', alpha = 0.3)+
  geom_ribbon(data=th%>%filter(hms(hms)<=hms('06:00:00')),aes(x = hms(hms), ymax = Inf, ymin = -Inf),fill = 'grey40', alpha = 0.3)+
  geom_ribbon(data=th%>%filter(hms(hms)>=hms('19:00:00')),aes(x = hms(hms), ymax = Inf, ymin = -Inf),fill = 'grey40', alpha = 0.3)+
  geom_point(data=th,aes(x = hms(hms), y = Ta_measurement, col = "Microcosm")) +
  geom_line(data=th,aes(x = hms(hms), y = Tl_mean_corrected, col = sprintf(paste("Leaf", sprintf("%02d", Leaf))), group = Leaf)) +
  scale_color_manual(values = c("Leaf 02" = "#fee5d9", "Leaf 04" = "#fcbba1", "Leaf 06" = "#fc9272", "Leaf 07" = "#fb6a4a", "Leaf 08" = "#ef3b2c", "Leaf 09" = "#cb181d", "Leaf 10" = "#99000d", "Microcosm" = 1)) +
  scale_x_time() +
  labs(y = "Temperature (°C)", x = "Time of the day") +
  ggtitle('Plant 4, April 6th, Scenario Hot')+
  theme() +
  myTheme


cowplot::plot_grid(
  ggdraw() +
    draw_image(picTherm),
  graphLeaf,
  ncol = 2, labels = c("A", "B")
)


ggsave(filename = "2-figuresTables/LeafTempP4.pdf", width = 16, height = 6)

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

### evolution of area

fullarea_raw=fread('../00-data/LiDAR/reconstructions/plant_surface_from_mesh.csv') %>% 
  mutate(Date=dmy(Date)) %>% 
  rename(Plant=plant) %>% 
  data.table()

fullarea=merge(fullarea_raw,cal  %>% data.table()) %>% 
  filter(Scenario!='' | event=='3D')  %>% 
  group_by(Date,Plant) %>% 
  mutate(ScenarDay=ifelse(n==max(n),'yes','no')) %>% 
  filter(ScenarDay=='yes'| is.na(ScenarDay))

ggplot()+
  geom_line(data=fullarea %>% 
              filter(!is.na(Scenario)| event=='3D'),aes(x=Date,y=PLA/10000,col=Plant,group=Plant))+
  geom_point(data=fullarea %>% 
               filter( event=='3D'),aes(x=Date,y=PLA/10000,group=Plant),pch=24,size=6)+
  geom_point(data=fullarea %>% 
               filter( ScenarDay=='yes' & event!='3D'),aes(x=Date,y=PLA/10000,fill=Plant,group=Plant),pch=21,size=5)+
  geom_point(data=fullarea %>% 
               filter(!is.na(Scenario) & event!='3D'),aes(x=Date,y=PLA/10000,shape=Scenario,group=Plant),size=4)+
  
  labs(
    y = expression("plant leaf area "(m**2)),
    x = "Date"
  )+
  scale_shape_manual(name='',values = shape_event)+
  myTheme

ggsave(filename = "2-figuresTables/EvolArea.pdf", width = 9, height = 5)



area_obs=data.table::fread("../00-data/morphology_and_biomass/leaves_weight.csv") %>% 
  mutate(plant=paste0('P',plant)) %>% 
  filter(!is.na(area_cm2)) %>% 
  dplyr::select(plant,rank,area_cm2) 

area_recons=data.table::fread("../00-data/lidar/reconstructions/leaf_surface_from_mesh.csv") %>% 
  rename(plant=Plant)

area=merge(area_obs,area_recons)

pLeaf <- area %>%
  ggplot(aes(x = area_cm2, y = Manual_mesh_area, group = plant, fill = plant,col = plant)) +
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
    `leaf area meter` = sum(area_cm2,na.rm=T)
  ) %>%
  ungroup() %>%
  tidyr::pivot_longer(names_to = "type", values_to = "PLA", cols=c(`3D mesh`, `leaf area meter`)) %>%
  ggplot(aes(x = plant, y = PLA / 10000, group = paste(plant, type))) +
  geom_col_pattern(aes(pattern = type), col = 1, position = position_dodge(), pattern_density = 0.5, pattern_fill = "white") +
  scale_pattern_manual(name = "", values = c(`leaf area meter` = "stripe", `3D mesh` = "none")) +
  theme_bw() +
  theme(plot.background = element_blank(),
        legend.position='top') +
  labs(
    y = expression("plant leaf area "(m**2)),
    x = ""
  )

ggdraw() +
  draw_plot(pLeaf) +
  cowplot::draw_plot(pPlant, x = 0.55, y = 0.10, width = 0.4, height = 0.5)

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
plantPos=data.frame(X=57,X1=9,Y=58.4)

parVid <- ggplot() +
  geom_tile(data=vid %>%
              filter(Z != -105.4),aes(x = X, y = Y, fill = PAR)) +
  geom_point(data=plantPos,aes(x=X,y=Y),pch=4)+
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


parPalm <-ggplot() +
  geom_tile(data=palm2,aes(x = X, y = Y, fill = PAR)) +
  geom_point(data=plantPos,aes(x=X1,y=Y),pch=4)+
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



# all the fluxes ------------------------------------------------------------------


### all plants


donAll=merge(database_raw%>% filter(!(Scenario %in% c("WalzClosed","WalzOpen",'Mixed') & hms>hms('04:30:00') & hms<hms('21:30:00')) & outlier=='no') %>% 
               dplyr::select(Plant,Scenario,Date,hms,CO2_outflux_umol_s,transpiration_diff_g_s) %>% 
               distinct() %>% 
               data.frame(),
             ScenarRep %>% 
               filter(!(Scenario %in% c("WalzClosed","WalzOpen"))) %>% 
               dplyr::select(Plant,Date,Scenario,n) %>%
               filter(n>8*6) %>%  ### remove data with unsufficient data
               group_by(Plant,Scenario) %>% 
               mutate(rep=paste('rep',row_number())) %>% 
               ungroup()
             ,all.x=F,all.y=T) 

AllFCo2=donAll%>% 
  filter(!(Scenario %in% c('WalzClosed','WalzOpen'))) %>% 
  ggplot(aes(x=hms(hms),y=CO2_outflux_umol_s,group=paste(Plant,Scenario,rep),col=rep))+
  geom_point(alpha=0.5)+
  facet_grid(Scenario~Plant)+
  ylab(expression('CO'[2]*' flux '*(mu*mol*' '*s**-1)))+
  xlab(expression('Time of the day'))+
  myTheme+
  scale_color_manual(values=c('rep 1'="#1b9e77",'rep 2'='#d95f02','rep 3'='#7570b3'))+
  theme(axis.text = element_text(
    size = 12))+
  # scale_color_grey()+
  scale_x_time(breaks = seq(0,24,8)*3600,labels = paste0(seq(0,24,8),'h'))

AllFH2o=donAll%>% 
  filter(!(Scenario %in% c('WalzClosed','WalzOpen'))) %>% 
  ggplot(aes(x=hms(hms),y=transpiration_diff_g_s,col=rep,group=paste(Plant,Scenario,rep)))+
  geom_line()+
  facet_grid(Scenario~Plant)+
  ylab(expression('H'[2]*"O"*' flux ' *(g*' '*s**-1)))+
  xlab(expression('Time of the day'))+
  myTheme+
  theme(axis.text = element_text(
    size = 12))+
  scale_color_manual(values=c('rep 1'="#1b9e77",'rep 2'='#d95f02','rep 3'='#7570b3'))+
  scale_x_time(breaks = seq(0,24,8)*3600,labels = paste0(seq(0,24,8),'h'))

# plot_grid(AllFCo2,AllFH2o,labels = c('A','B'),ncol=1)
AllFCo2
ggsave(filename = "2-figuresTables/FluxesCO2.pdf", width = 12, height = 8)

# both transpi and Co2 for one plant----------------------------------------------------

don=merge(database_raw %>% 
            data.frame(),
          ScenarRep %>% 
            filter(!(Scenario %in% c("WalzClosed","WalzOpen"))) %>% 
            dplyr::select(Plant,Date,Scenario,n) %>%
            group_by(Plant,Scenario) %>% 
            mutate(ref=ifelse(n==max(n),'yes','no')) %>% 
            ungroup() %>%
            filter(ref=='yes')
          ,all.x=F,all.y=T)


maxTranspi=max(don$transpiration_diff_g_s,na.rm=T)
maxCO2=max(don$CO2_outflux_umol_s,na.rm=T)

don2=don%>%gather('var',"val",transpiration_diff_g_s,CO2_outflux_umol_s)%>%
  mutate(val = if_else(var == 'CO2_outflux_umol_s', val, val / (maxTranspi / maxCO2)))%>%
  filter(Plant %in% c('P3'))

ggplot()+
  geom_ribbon(data=don2%>%filter(hms(hms)<hms('06:00:00') ),aes(x = hms(hms), ymax = Inf, ymin = -Inf),fill = 'grey40', alpha = 0.3)+
  geom_ribbon(data=don2%>%filter(hms(hms)>hms('19:00:00')),aes(x = hms(hms), ymax = Inf, ymin = -Inf),fill = 'grey40', alpha = 0.3)+
  geom_ribbon(data=don2%>%filter(hms(hms)<=hms('19:00:00') & hms(hms)>=hms('06:00:00') ),aes(x = hms(hms), ymax = Inf, ymin = -Inf),fill = 'yellow', alpha = 0.3)+
  geom_line(data=don2%>%filter(var=='CO2_outflux_umol_s'),aes(x=hms(hms),y=val,col='CO2',group=paste(Scenario,Date)),lwd=1)+
  geom_line(data=don2%>%filter(var=='transpiration_diff_g_s'),aes(x=hms(hms),y=val,col='H2O',group=paste(Scenario,Date)),lwd=1)+
  scale_x_time(breaks = seq(0,24,6)*3600,labels = paste0(seq(0,24,6),'h'))+
  scale_y_continuous(sec.axis = sec_axis(trans = ~ . * (maxTranspi / maxCO2),
                                         name = expression('H'[2]*"O"*' flux ' *(g*' '*s**-1)))) +
  facet_wrap(~paste(Scenario,'\n',Date),ncol=4)+
  ylab(expression('CO'[2]*' flux '*(mu*mol*' '*s**-1)))+
  xlab(expression('Time of the day'))+
  myTheme+
  theme(legend.position='none',
        axis.title.y.left =  element_text(color=hue_pal()(1)),
        axis.title.y.right =  element_text(color=hue_pal()(2)[2]),
        axis.text.y.left =  element_text(color=hue_pal()(1)),
        axis.text.y.right =  element_text(color=hue_pal()(2)[2]),
        
  )


ggsave(filename = "2-figuresTables/Day_fluxes_P3.pdf", width = 12, height = 8)



# test light --------------------------------------------------------------

testLight=fread('../09-database/database_light_experiment.csv') %>% 
  mutate(Date = ymd(str_sub(DateTime, start = 1, end = 10)),
         hms = str_sub(DateTime, 12, 19)) %>% 
  data.frame()

testLight %>% 
  filter(hms(hms)<=hms('17:00:00') & hms(hms)>=hms('12:00:00')) %>% 
  ggplot()+
  geom_line(aes(x=hms(hms),y=PARamb,group=Date,lty='Microcosm'))+
  geom_line(aes(x=hms(hms),y=PARtop,group=Date,lty='Walz head')) +
  scale_x_time(breaks = seq(0,24,1)*3600,labels = paste0(seq(0,24,1),'h'))+
  ylab(expression('PPFD ' *(µmol*' '*m**-2*' '*s**-1)))+
  xlab(expression('Time of the day'))+
  facet_wrap(Walz_head~paste('(',Plant,' ',Date,')'),ncol=2)+
  theme(legend.title = element_blank())

ggsave(filename = "2-figuresTables/SI_LightWalzOpenClose.pdf", width = 8, height = 5)

### flux in the chamber
maxA=max(testLight$A,na.rm=T)
maxPAR=max(testLight$PARamb,na.rm=T)

testLight=testLight%>%
  mutate(relPAR=PARamb/(maxPAR/maxA)) 


testLight%>%
  filter(hms(hms)<=hms('17:00:00') & hms(hms)>=hms('10:00:00')) %>% 
ggplot()+
  geom_line(aes(x=hms(hms),y=relPAR,group=paste(Plant,Walz_head)),lwd=1,col='grey')+
  geom_point(aes(x=hms(hms),y=A,group=paste(Plant,Walz_head)),lwd=1,col='black')+
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
        axis.text.y.right =  element_text(color='grey')
  )

ggsave(filename = "2-figuresTables/WalzTests.pdf", width = 16, height = 8)




