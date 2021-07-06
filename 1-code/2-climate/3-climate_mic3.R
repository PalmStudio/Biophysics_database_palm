# Load packages -----------------------------------------------------------

packs <- c('shiny','datasets',"lubridate", "stringr", "ggplot2",'dplyr','viridis','plotly','tidyr','data.table')
InstIfNec<-function (pack) {
  if (!do.call(require,as.list(pack))) {
    do.call(install.packages,as.list(pack))  }
  do.call(require,as.list(pack)) }
lapply(packs, InstIfNec)



# inputs ------------------------------------------------------------------

colors_scenar=c('darkolivegreen3','darkolivegreen4','darkolivegreen','cyan','blue3','firebrick','firebrick1','grey')
names(colors_scenar)=c("400ppm",'600ppm','800ppm','DryCold','Cold','Hot','DryHot','Cloudy')

##paramter for estimating saturated vapour pressure (SVP) for a given temperature
p1=18.9321
p2=5300.24

#get climate variables
files=list.files(path = '0-data/0-raw/Climate/',pattern = 'Mic3')
met_raw=NULL
for (f in files){
  sub=fread(file = paste0('0-data/0-raw/Climate/',f),skip = 1,header=F)
  colnames(sub)=c("V1","DateTime","Temp_c","Temp","HR_c","HR","PAR_c","PAR","CO2ppm","debitCO2","Mic") ##problem in Rmd with special character
  met_raw=rbind(met_raw,sub)
}


met=met_raw %>%
  mutate(DateTime=ymd_hms(DateTime),
         Date=ymd(str_sub(string = DateTime,start = 0,end = 10)),
         week=week(Date),
         hms=hms(str_sub(string = DateTime,start = 12,end = 19))
         # Temp=as.numeric(unlist(met_raw[,'mesure TÂ°C'])),
         # Temp_c=as.numeric(unlist(met_raw[,'consigne TÂ°C'])),
         # HR=as.numeric(unlist(met_raw[,'mesure HR'])),
         # HR_c=as.numeric(unlist(met_raw[,'consigne HR'])),
         # PAR=as.numeric(unlist(met_raw[,'mesure Rayo'])),
         # PAR_c=as.numeric(unlist(met_raw[,'consigne Rayo'])),
         # CO2ppm=as.numeric(unlist(met_raw[,'mesures [CO2]']))
  )%>%
  select(DateTime,Date,week,hms,Temp,Temp_c,HR,HR_c,PAR,PAR_c,CO2ppm)


##estimate VPD
met=met %>%
  mutate(VPD=(exp(p1-p2/(Temp+273)))*(1-HR/100),
         VPD_c=(exp(p1-p2/(Temp_c+273)))*(1-HR_c/100))



scenar=fread(input = '0-data/0-raw/scenario_sequence/SequenceScenarioMicro3.csv')%>%
  mutate(Date=dmy(Date))

met=merge(met,scenar,all.x=T)%>%
  filter(!is.na(Scenario))

met=met%>%
  filter(Scenario!='TestLight')
# graph -------------------------------------------------------------------

cons=met%>%
  select(DateTime,Date,week,Scenario,Temp_c,HR_c,VPD_c,PAR_c)%>%
  tidyr::gather(key='var',value='value',Temp_c,HR_c,VPD_c,PAR_c)%>%
  mutate(var=str_remove(var,'_c'),
         hms=hms(str_sub(string = DateTime,start = 12,end = 19)))



# gr_cons=cons %>%
#   ggplot(aes(x=hms,y=value,col=as.factor(Date),group=Date))+
#   geom_line(alpha=1)+
#   facet_grid(Scenario~var,scales = 'free_y')+
#   scale_x_time()+
#   scale_color_viridis_d()

mes=met%>%
  select(DateTime,Date,week,Scenario,Temp,HR,VPD,PAR,CO2ppm)%>%
  tidyr::gather(key='var',value='value',Temp,HR,VPD,PAR,CO2ppm)%>%
  mutate(hms=hms(str_sub(string = DateTime,start = 12,end = 19)))


# gr_mes=mes %>%
#   ggplot(aes(x=hms,y=value,col=as.factor(Date),group=Date))+
#   geom_line()+
#   facet_grid(var~Scenario,scales = 'free')+
#   scale_x_time()+
#   scale_color_viridis_d()


gr_clim=ggplot()+
  geom_vline(data=data.frame(Time=ymd_hms(paste(unique(mes$Date),'00:00:00'))),aes(xintercept=Time),col=1,lty=2)+
  geom_line(data=mes,aes(x=DateTime,y=value,col=Scenario,group=Date,lty='measurements'),lwd=1.2)+
  geom_line(data=cons,aes(x=DateTime,y=value,col=Scenario,group=Date,lty='instructions'),lwd=1.2,alpha=0.5)+
  facet_grid(var~.,scales = 'free')+
  scale_x_datetime()+
  scale_color_manual(values = colors_scenar)+
  ylab('')+
  xlab('')

# w=unique(mes$week)[1]
# sub_mes=mes%>%filter(week==w)
# sub_cons=cons%>%filter(week==w)
# 
# ggplot()+
#         # geom_vline(data=data.frame(Time=ymd_hms(paste(unique(sub_mes$Date),'00:00:00'))),aes(xintercept=Time),col=1,lty=2)+
#         geom_line(data=sub_mes,aes(x=hms,y=value,col=Scenario,group=Date,lty='measurements'),lwd=1.2)+
#         geom_line(data=sub_cons,aes(x=hms,y=value,col=Scenario,group=Date,lty='instructions'),lwd=1.2,alpha=0.5)+
#         facet_grid(var~Date,scales ='free_y')+
#         scale_x_time()+
#         scale_color_manual(values = colors_scenar)+
#         ylab('')+
#         xlab('')

