
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

tabelEvent=data.frame(event=c(paste0('S',1:8)),scenar=c("400ppm",'Cloudy','600ppm','Cold','800ppm','DryCold','Hot','DryHot'))

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
  mutate(Date=dmy(Date)) %>% 
  filter(Date<ymd('2021-04-26'))

cal=cal_raw%>%
  tidyr::gather(key = 'plant',value = 'event',P1,P2,P3,P4)


cal[cal$event %in% c('Curves (rat\x8e)',"S6 rat\x8e","S4 rat\x8e","S5 rat\x8e","Curves rat\x8e",''),'event']='A'
cal[cal$event %in% c("S3 (+nuit)",'S3*',"S1 (erreur S3)"),'event']='S3'
cal[cal$event %in% c("S4 (chgt matin)" ),'event']='S4'
cal[cal$event %in% c("S8 (+nuit)"),'event']='S8'
cal[cal$event %in% c('Curves',"CurveF+2","CurvesF+1","Curves (manque HR)","CurveF+1" ),'event']='Response curves'
cal[cal$event %in% c("A"),'event']='Storage'
unique(cal$event)


cal=merge(cal,tabelEvent,all.x=T) 

ggplot()+
  geom_tile(data=cal,aes(x=Date,y=plant,fill=scenar),col=1)+
  geom_point(data=cal%>%filter(event=='Response curves'),aes(x=Date,y=plant,col='Response curves'),pch=8)+
  scale_x_date()+
  scale_fill_manual(values =colors_event,name='Scenario')+
  scale_color_manual(name='',values=list('Response curves'=1))+
  myTheme+
  labs(x='',y='Plant')

ggsave(filename = '2-figuresTables/calendar.pdf',width = 12,height = 3)


# climate -----------------------------------------------------------------
# mic4_raw=fread('../02-climate/climate_mic4.csv') %>% 
#   mutate(Date=ymd(str_sub(DateTime,start=1,end=10)),
#          hms=str_sub(DateTime,12,19)) 


# mic4=mic4_raw%>%
#   mutate(scenar='400ppm')%>% 
#   rename(`Temperature (°C)`=Ta_measurement,
#          `Relative humidity (%)`=Rh_measurement,
#          `PAR (mircomol of CO2 m-2 s-1)`=R_measurement,
#          `CO2 (ppm)`=CO2_ppm) %>% 
#   tidyr::gather(key = 'variable','value',`Temperature (°C)`,`Relative humidity (%)`,`PAR (mircomol of CO2 m-2 s-1)`,`CO2 (ppm)`)
# 


# mic4 %>% 
#   ggplot()+
#   geom_line(aes(x=hms(hms),y=value,col=scenar,group=Date),alpha=0.2)+
#   geom_smooth(aes(x=hms(hms),y=value,col=scenar))+
#   facet_grid(variable~.,scale='free_y')+
#   scale_color_manual(values =colors_event,name='Scenario')+
#   myTheme

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
  geom_line(data=mic3,aes(x=hms(hms),y=value,col=scenar,group=Date),alpha=0.2)+
  geom_line(data=mic3_m,aes(x=hms(hms),y=value,col=scenar))+
  facet_grid(variable~scenar,scale='free_y')+
  scale_color_manual(values =colors_event,name='Scenario')+
    scale_x_time()+
  labs(x='Time of the day',y='')+
    theme(axis.text.x = element_text(angle=90))

ggsave(filename = '2-figuresTables/Scenarios.pdf',width = 10,height = 8)
