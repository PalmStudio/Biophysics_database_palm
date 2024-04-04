
# Script for generating data paper figures & tables ---------------------------------


# load packages -----------------------------------------------------------


packs <- c("lubridate", "stringr", 'tidyverse','viridis','Vpalmr','data.table','yaml','archimedR','png','cowplot')
InstIfNec<-function (pack) {
  if (!do.call(require,as.list(pack))) {
    do.call(install.packages,as.list(pack))  }
  do.call(require,as.list(pack)) }
lapply(packs, InstIfNec)


# inputs ------------------------------------------------------------------


colors_event=c('darkolivegreen3','darkolivegreen4','darkolivegreen','cyan','blue3','firebrick','firebrick1','grey')
names(colors_event)=c("400ppm",'600ppm','800ppm','DryCold','Cold','Hot','DryHot','Cloudy')

tabelEvent=data.frame(event=c(paste0('S',1:8),'WalzClosed','WalzOpen'),scenar=c("400ppm",'Cloudy','600ppm','Cold','800ppm','DryCold','Hot','DryHot','WalzClosed','WalzOpen'))

myTheme=theme_minimal() %+replace% 
  theme(
    text = element_text( face = "plain", size = 16,
                         angle = 0, lineheight = 0.9),
    axis.title = element_text( face = "plain", size = 20,
                               angle = 0, lineheight = 0.9),
    
    plot.title = element_text(size = rel(1.2)),
    axis.text = element_text(face = "plain", size = 16),
    legend.title = element_blank()
  )

# calendar -------------------------------------------------------------


cal_raw=fread('0-data/calendrier.csv') %>% 
  mutate(Date=dmy(Date)) 
# %>% 
#   filter(Date<ymd('2021-04-26'))

reco=fread('0-data/ReconstructionsDates.csv') %>% 
  data.frame() %>% 
  mutate(Date=dmy(Date))

cal=rbind(cal_raw,reco)%>%
  tidyr::gather(key = 'plant',value = 'event',P1,P2,P3,P4)


cal[cal$event %in% c('Curves (rat\x8e)',"Curves rat\x8e",''),'event']='A'
cal[cal$event %in% c("S3 (+nuit)","S1 (erreur S3)",'S3*'),'event']='S3'
cal[cal$event %in% c("S4 (chgt matin)","S4 rat\x8e"),'event']='S4'
cal[cal$event %in% c("S8 (+nuit)"),'event']='S8'
cal[cal$event %in% c("S5 rat\x8e"),'event']='S5'
cal[cal$event %in% c("S6 rat\x8e"),'event']='S6'
cal[cal$event %in% c('Curves',"CurveF+2","CurvesF+1","Curves (manque HR)","CurveF+1" ),'event']='Response curves'
cal[cal$event %in% c("A"),'event']='Storage'
cal[cal$event %in% c("SWalzC"),'event']='WalzClosed'
cal[cal$event %in% c("SWalzO"),'event']='WalzOpen'
cal[cal$event %in% c("Reconstruction"),'event']='3D'
unique(cal$event)


cal=merge(cal,tabelEvent,all.x=T) 

ggplot()+
  geom_tile(data=cal,aes(x=Date,y=plant,fill=scenar),col=1)+
  geom_point(data=cal%>%filter(event=='Response curves'),aes(x=Date,y=plant,col='Response curves',shape='Response curves'),size=2)+
  geom_point(data=cal%>%filter(event=='3D'),aes(x=Date,y=plant,col='3D',shape='3D'))+
  scale_x_date()+
  scale_fill_manual(values =c(colors_event,WalzClosed='orange',WalzOpen='yellow'),name='Scenario')+
  scale_color_manual(name='',values=c('Response curves'=1,'3D'=2))+
  scale_shape_manual(name='',values=c('Response curves'=8,'3D'=16))+
  myTheme+
  labs(x='',y='Plant')

ggsave(filename = '2-figuresTables/calendar.pdf',width = 12,height = 4)


# climate -----------------------------------------------------------------

mic3_raw=fread('../02-climate/climate_mic3.csv') %>% 
  mutate(Date=ymd(str_sub(DateTime,start=1,end=10)),
         hms=str_sub(DateTime,12,19)) %>% 
  filter(hms(hms)>=hms('05:00:00') & hms(hms)<=hms('20:00:00') )


mic3=merge(mic3_raw,cal%>%filter(!is.na(scenar)),all.y=T) %>% 
  rename(`Temperature (°C)`=Ta_measurement,
         `Relative humidity (%)`=Rh_measurement,
         `PAR (mircomol of CO2 m-2 s-1)`=R_measurement) %>% 
  tidyr::gather(key = 'variable','value',`Temperature (°C)`,`Relative humidity (%)`,`PAR (mircomol of CO2 m-2 s-1)`)

mic3_m=merge(mic3_raw,cal%>%filter(!is.na(scenar)),all.y=T)%>% 
  group_by(scenar,hms) %>% 
  summarize(Ta_measurement=median(Ta_measurement,na.rm=T),
            Rh_measurement=median(Rh_measurement,na.rm=T),
            R_measurement=median(R_measurement,na.rm=T),
            CO2_ppm=median(CO2_ppm,na.rm=T)) %>% 
  ungroup() %>% 
  rename(`Temperature (°C)`=Ta_measurement,
         `Relative humidity (%)`=Rh_measurement,
         `PAR (mircomol of CO2 m-2 s-1)`=R_measurement,
         `CO2 (ppm)`=CO2_ppm) %>% 
  tidyr::gather(key = 'variable','value',`Temperature (°C)`,`Relative humidity (%)`,`PAR (mircomol of CO2 m-2 s-1)`,`CO2 (ppm)`)

ggplot()+
  geom_line(data=mic3 %>% filter(!(scenar%in%c('WalzClosed','WalzOpen'))),aes(x=hms(hms),y=value,col=scenar,group=Date),alpha=0.2)+
  geom_line(data=mic3_m%>% filter(!(scenar%in%c('WalzClosed','WalzOpen'))),aes(x=hms(hms),y=value,col=scenar))+
  facet_grid(variable~scenar,scale='free_y')+
  scale_color_manual(values =colors_event,name='Scenario')+
  scale_x_time()+
  labs(x='Time of the day',y='')+
  theme_bw()+
  theme(axis.text.x = element_text(angle=90))

ggsave(filename = '2-figuresTables/Scenarios.pdf',width = 12,height =9)



### tests light
  merge(mic3_raw,cal%>%filter(!is.na(scenar)),all.y=T) %>% 
  filter((scenar%in%c('WalzClosed','WalzOpen')))%>% 
  ggplot()+
  geom_line(aes(x=hms(hms),y=R_measurement,col=scenar,group=Date))+
  scale_color_manual(values =c(colors_event,WalzClosed='orange',WalzOpen='yellow'),name='Scenario')+
  scale_x_time()+
  labs(x='Time of the day',y='PAR (mircomol of CO2 m-2 s-1)')+
  myTheme+
  theme(panel.background = element_rect(fill = 'grey'))

ggsave(filename = '2-figuresTables/SI_LightWalzOpenClose.pdf',width = 8,height =5)
  
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
dt_raw=fread('../09-database/database_5min.csv')%>% 
  mutate(Date=ymd(str_sub(DateTime_start,start=1,end=10)),
         hms=str_sub(DateTime_start,12,19)) %>% 
  filter(hms(hms)>=hms('05:00:00') & hms(hms)<=hms('20:00:00') )


dt=dt_raw %>% 
  rename(`Temperature (°C)`=Ta_measurement,
         `Relative humidity (%)`=Rh_measurement,
         `PAR (mircomol of CO2 m-2 s-1)`=R_measurement,
         `CO2 (ppm)`=CO2_ppm) %>% 
  tidyr::gather(key = 'variable','value',`Temperature (°C)`,`Relative humidity (%)`,`PAR (mircomol of CO2 m-2 s-1)`,`CO2 (ppm)`)

dt_m=dt_raw%>% 
  group_by(Scenario,hms) %>% 
  summarize(Ta_measurement=median(Ta_measurement,na.rm=T),
            Rh_measurement=median(Rh_measurement,na.rm=T),
            R_measurement=median(R_measurement,na.rm=T),
            CO2_ppm=median(CO2_ppm,na.rm=T)) %>% 
  ungroup() %>% 
  rename(`Temperature (°C)`=Ta_measurement,
         `Relative humidity (%)`=Rh_measurement,
         `PAR (mircomol of CO2 m-2 s-1)`=R_measurement,
         `CO2 (ppm)`=CO2_ppm) %>% 
  tidyr::gather(key = 'variable','value',`Temperature (°C)`,`Relative humidity (%)`,`PAR (mircomol of CO2 m-2 s-1)`,`CO2 (ppm)`)

error=dt%>%
  filter(Scenario=='')

error%>%
  group_by(Date) %>% 
  select(Date,Plant) %>% 
  distinct()


ggplot()+
  geom_line(data=dt,aes(x=hms(hms),y=value,col=as.factor(Plant),group=Date))+
  facet_grid(variable~Scenario,scale='free_y')+
  # scale_color_manual(values =colors_event,name='Scenario')+
  scale_x_time()+
  labs(x='Time of the day',y='')+
  theme(axis.text.x = element_text(angle=90))


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


th=dt_raw %>% 
  filter(Plant==5& Date>=ymd('2021/04/06') & Date<=ymd('2021/04/06')) %>% 
  select(Plant,Scenario,Sequence,Leaf,Date,DateTime_start,hms,Tl_mean,Tl_min,Tl_max,Tl_std,Ta_measurement) %>% 
  filter(!is.na(Leaf))

picTherm=readPNG('2-figuresTables/maskP4.png')

graphLeaf=th %>% 
  ggplot(aes(x=hms(hms),y=Tl_mean,col=sprintf(paste('Leaf',sprintf('%02d',Leaf))),group=Leaf))+
  geom_point(aes(x=hms(hms),y=Ta_measurement,col='Microcosm'))+
  geom_line()+
  scale_color_manual(values = c('Leaf 02'="#fee5d9",'Leaf 04'="#fcbba1",'Leaf 06'="#fc9272",'Leaf 07'="#fb6a4a","Leaf 08"="#ef3b2c","Leaf 09"="#cb181d","Leaf 10"="#99000d",'Microcosm'=1))+
  scale_x_time()+
  labs(y='Temperature (°C)',x='Time of the day')+
  theme()+
  myTheme
  

cowplot::plot_grid(ggdraw() +
  draw_image(picTherm),
  graphLeaf,ncol=2,labels=c('A','B'))


ggsave(filename = '2-figuresTables/LeafTempP4.pdf',width = 16,height = 6)

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

picLeafPC=readPNG('2-figuresTables/leafPC.png')
picLeafMesh=readPNG('2-figuresTables/leafMesh.png')
picPlantPC=readPNG('2-figuresTables/plantPC.png')
picPlantMesh=readPNG('2-figuresTables/plantMesh.png')


p1=cowplot::plot_grid(ggdraw() +
                     draw_image(picLeafPC),
                   ggdraw() +
                     draw_image(picLeafMesh))


p2=cowplot::plot_grid(ggdraw() +
                     draw_image(picPlantPC),
                   ggdraw() +
                     draw_image(picPlantMesh))

cowplot::plot_grid(p1,p2,ncol=1,rel_heights = c(0.405,0.595),labels=c('A','B'))

ggsave(filename = '2-figuresTables/reconstruction.pdf',width = 10,height = 11)


