### script to visualise Co2 flux data 


# Load packages -----------------------------------------------------------

packs <- c('shiny','data.table',"lubridate", "stringr", "ggplot2",'dplyr','viridis','tidyr','scales','cowplot','readxl','RColorBrewer')
InstIfNec<-function (pack) {
  if (!do.call(require,as.list(pack))) {
    do.call(install.packages,as.list(pack))  }
  do.call(require,as.list(pack)) }
lapply(packs, InstIfNec)


# input -------------------------------------------------------------------


colors_plant=hue_pal()(4) 
names(colors_plant)=c("P1",'P2','P3','P5')

colors_scenar=c('darkolivegreen3','darkolivegreen4','darkolivegreen','cyan','blue3','firebrick','firebrick1','grey')
names(colors_scenar)=c("400ppm",'600ppm','800ppm','DryCold','Cold','Hot','DryHot','Cloudy')

# display.brewer.pal(n = 5 , name = 'Paired')

# load data ---------------------------------------------------------------

fl_raw=read_xlsx(path = '0-data/0-raw/picarro_flux/data_mean_flux.xlsx',skip=1,col_names = F) ##change names because of markdown uncompatibility

colnames(fl_raw)=c("MPV1_time","CO2_dry_MPV1","delta13C_MPV1","MPV2_time","CO2_dry_MPV2","delta13C_MPV2","...7","CO2 differential ppm","Flow m3/h","surface m2","flux","...12","d13C differential")

fl=fl_raw%>%
  mutate(Time=MPV1_time,
         Date=ymd(str_sub(string = Time,start = 0,end = 10)),
         hms=hms(str_sub(string = Time,start = 12,end = 19)))%>%
  select(Time,Date,hms,flux)

## add scenar

scenar=fread(input = '0-data/0-raw/scenario_sequence/SequenceScenarioMicro3.csv')%>%
  mutate(Date=dmy(Date))

fl=merge(fl,scenar,all.x=T)%>%
  filter(!is.na(Scenario))

### add plant
MicPlant=fread(input = '0-data/0-raw/scenario_sequence/SequencePlanteMicro3.csv',na.strings = '')%>%
  mutate(hour_start=dmy_hms(hour_start),
         Time=hour_start,
         hour_end=dmy_hms(hour_end),
         hms=NA,
         flux=NA,
         Date=NA,
         Scenario=NA)

fl=rbind(fl,MicPlant%>%
           select(Date,Time,hms,flux,Scenario))

fl=merge(fl,MicPlant%>%
           select(Time,Plant,hour_start,hour_end),all.x=T)%>%
  arrange(Time)%>%
  fill(Plant)%>%
  group_by(Plant)%>%
  fill(hour_start,hour_end)%>%
  ungroup()%>%
  filter(!is.na(flux))%>%
  mutate(flux=round(flux,4))

### remove sharp vaiations

tresh=20 #tresh of deviation to consider outlier in sequential values

# fl=fl%>%
#   mutate(diff_flux=(flux-lag(flux))/flux*100,
#          diff_flux2=(flux-lead(flux))/flux*100,
#          outlier='no')%>%
#   mutate(outlier=ifelse(flux<=-1 ,'yes',outlier),
#          outlier=ifelse(abs(diff_flux)>tresh |abs(diff_flux2)>tresh ,'yes',outlier ))


out=fread(file='0-data/6-picarro_flux/outliers.csv')%>%
  mutate(Time=ymd_hms(paste(str_sub(string = Time,start = 0,10),str_sub(string = Time,start = 12,19))),
         outlier=T)%>%
  mutate(flux=round(flux,4))

fl_clean=merge(fl,out%>%
                 mutate(Time=ymd_hms(paste(str_sub(string = Time,start = 0,10),str_sub(string = Time,start = 12,19))),
                        outlier=T),all.x=T)%>%
  filter(is.na(outlier))

fl_clean=fl_clean%>%
  filter(Scenario!='TestLight')

# graphics ----------------------------------------------------------------


gr_ct=ggplot()+
  geom_point(data=fl_clean,aes(x=hms,y=flux,col=Plant,group=paste(Plant,Scenario,Date)))+
  geom_line(data=fl_clean,aes(x=hms,y=flux,col=Plant,group=paste(Plant,Scenario,Date)))+
  ylab('CO2 flux (Âµmol/s)')+
  # geom_ribbon(data=fl%>%filter(hms>=hms('18:30:00') | hms<=hms('05:30:00')),aes(x = Time, ymax = Inf, ymin = -Inf),fill = 'lightgrey', alpha = 0.3)+
  # geom_vline(data=data.frame(Time=ymd_hms(paste(unique(fl$Date),'00:00:00'))),aes(xintercept=Time),col=2)+
  scale_x_time(breaks = seq(0,24,4)*3600,labels = paste0(seq(0,24,4),'h'))+
  facet_wrap(Date~Scenario)+
  ylim(c(-1,max(fl_clean$flux,na.rm=T)))+
  scale_color_manual(values = colors_plant)+
  theme_bw()



gr_cs=ggplot()+
  geom_ribbon(data=fl_clean%>%filter(hms>=hms('18:30:00')),aes(x = hms, ymax = Inf, ymin = -Inf),fill = 'lightgrey', alpha = 0.3)+
  geom_ribbon(data=fl_clean%>%filter(hms<=hms('05:30:00')),aes(x = hms, ymax = Inf, ymin = -Inf),fill = 'lightgrey', alpha = 0.3)+
  geom_point(data=fl_clean,aes(x=hms,y=flux,col=Scenario,group=paste(Plant,Scenario,Date)))+
  geom_line(data=fl_clean,aes(x=hms,y=flux,col=Scenario,group=paste(Plant,Scenario,Date)))+
  ylab('CO2 flux (Âµmol/s)')+
  # geom_vline(data=data.frame(Time=ymd_hms(paste(unique(fl$Date),'00:00:00'))),aes(xintercept=Time),col=2)+
  ylim(c(-1,max(fl_clean$flux,na.rm=T)))+
  scale_x_time(breaks = seq(0,24,4)*3600,labels = paste0(seq(0,24,4),'h'))+
  facet_wrap(~Plant)+
  scale_color_manual(values = colors_scenar)+
  theme_bw()


gr_cp=ggplot()+
  geom_ribbon(data=fl_clean%>%filter(hms>=hms('18:30:00')),aes(x = hms, ymax = Inf, ymin = -Inf),fill = 'lightgrey', alpha = 0.3)+
  geom_ribbon(data=fl_clean%>%filter(hms<=hms('05:30:00')),aes(x = hms, ymax = Inf, ymin = -Inf),fill = 'lightgrey', alpha = 0.3)+
  geom_point(data=fl_clean,aes(x=hms,y=flux,col=Plant,group=paste(Plant,Scenario,Date)))+
  geom_line(data=fl_clean,aes(x=hms,y=flux,col=Plant,group=paste(Plant,Scenario,Date)))+
  ylab('CO2 flux (Âµmol/s)')+
  # geom_vline(data=data.frame(Time=ymd_hms(paste(unique(fl$Date),'00:00:00'))),aes(xintercept=Time),col=2)+
  ylim(c(-1,max(fl_clean$flux,na.rm=T)))+
  scale_x_time(breaks = seq(0,24,4)*3600,labels = paste0(seq(0,24,4),'h'))+
  facet_wrap(~Scenario)+
  scale_color_manual(values = colors_plant)+
  theme_bw()

# ggplotly(fl%>%
#   filter(Plant=='P2')%>%
# ggplot()+
#   geom_point(aes(x=hms,y=flux,col=as.factor(Date),group=paste(Plant,Scenario,Date)))+
#   geom_line(aes(x=hms,y=flux,col=as.factor(Date),group=paste(Plant,Scenario,Date)))+
#   ylab('CO2 flux (Âµmol/s)')+
#   ylim(c(-1,max(fl$flux,na.rm=T)))+
#   scale_x_time(breaks = seq(0,24,4)*3600,labels = paste0(seq(0,24,4),'h'))+
#   facet_wrap(Plant~Scenario)+
#   theme_bw())


# daily assim -------------------------------------------------------------

fl_day=fl_clean%>%
  arrange(Date,Time,Plant,Scenario)%>%
  group_by(Date,Scenario,Plant)%>%
  summarize(period=(max(Time,na.rm=T)-min(Time,na.rm=T)),total_flux=sum(flux))%>%
  mutate(flux_av_hour=total_flux/as.numeric(period))


# fl_day%>%
#   filter(period>23.8)%>%
#   ggplot(aes(x=Scenario,y=total_flux,fill=Plant))+
#   geom_col(position = 'dodge')+
#   facet_wrap(~Scenario,scale='free_x')
#   
