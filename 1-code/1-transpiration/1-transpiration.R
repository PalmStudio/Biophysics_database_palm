### script to visualise pot weight data and estimate plant transpiration

# Sys.setenv(TZ="UTC")
# Load packages -----------------------------------------------------------

packs <- c('shiny','data.table',"lubridate", "stringr", "ggplot2",'dplyr','viridis','tidyr','scales','cowplot','ggrepel','plotly','readxl')
InstIfNec<-function (pack) {
  if (!do.call(require,as.list(pack))) {
    do.call(install.packages,as.list(pack))  }
  do.call(require,as.list(pack)) }
lapply(packs, InstIfNec)

# input -------------------------------------------------------------------


colors_plant=hue_pal()(4) 
names(colors_plant)=c("P1",'P2','P3','P5')

colors_scenar=c('darkolivegreen3','darkolivegreen4','darkolivegreen','cyan','blue3','firebrick','firebrick1','grey','black')
names(colors_scenar)=c("400ppm",'600ppm','800ppm','DryCold','Cold','Hot','DryHot','Cloudy','TestLight')

# load data ---------------------------------------------------------------


# MicPlant=fread(input = '../Data/SequencePlanteMicro3.csv',na.strings = '')%>%
#   mutate(hour_start=dmy_hms(hour_start),
#         hour_end=dmy_hms(hour_end))%>%
#   mutate(Time=hour_start)

MicPlant=data.table::fread( file = '0-data/0-raw/scenario_sequence/SequencePlanteMicro3.csv',na.strings = '')%>%
  mutate(#Date_start=dmy(str_sub(string = hour_start,start = 0,end = 8)),
    hour_start=dmy_hms(hour_start),
    Time=hour_start,
    hour_end=dmy_hms(hour_end),
    weight=NA,
    Date=NA,
  )%>%
  data.frame()

### data from 10 to 15 march (average weight per minute) 
tr_raw1=fread(file = '0-data/0-raw/scale_weight/weightsPhase1.txt')%>%
  mutate(Date=ymd(str_sub(string = V1,start = 0,end = 10)),
         hms=str_sub(string = V1,start = 12,end = 19),
         Time=ymd_hms(paste(Date,hms)),
         weight=V2)%>%
  select(Time,Date,weight)%>%
  data.frame()

# check diff time between file creation and the last value recorded (folder time in Central European Time (CET))
### check why this delay???? no problem the day before
difftime(max(tr_raw1$Time),file.info(file = '0-data/0-raw/scale_weight/weightsPhase1.txt')$mtime) # should be 1 hour (ok for data in 15march)-> mtime is wrong on weightsPhase1.txt

tr1=rbind(tr_raw1,MicPlant%>%
            dplyr::select(Time,Date,weight))

# tr1=merge(tr1,MicPlant%>%
#             select(Time,Plant,Date_start,hour_start,hour_end),all=T)%>%
#   arrange(Time)%>%
#   fill(Date_start,Plant)%>%
#   group_by(Date_start,Plant)%>%
#   fill(hour_start,hour_end)%>%
#   ungroup()%>%
#   filter(!is.na(weight))

tr1=merge(tr1,MicPlant%>%
            select(Time,Plant,hour_start,hour_end),all=T)%>%
  arrange(Time)%>%
  fill(hour_start,Plant,hour_end)%>%
  ungroup()%>%
  filter(!is.na(weight))

### data from 15 march to 27 mars ( weight per second)   
tr_raw2=fread(file = '0-data/0-raw/scale_weight/weightsPhase2.txt')%>%
  mutate(Date=ymd(str_sub(string = V1,start = 0,end = 10)),
         hms=str_sub(string = V1,start = 12,end = 19),
         Time=ymd_hms(paste(Date,hms)),
         weight=V2)%>%
  select(Time,Date,weight)%>%
  data.frame()

# check diff time between file creation and the last value recorded (folder time in Central European Time (CET))
# folderTime2=ymd_hms(time =with_tz(file.info(file = '../Data/ScaleWeight/weightsPhase2.txt')$mtime,tzone = "UTC"))
difftime(max(tr_raw2$Time),file.info(file = '0-data/0-raw/scale_weight/weightsPhase2.txt')$mtime) #should be 1 hour! ok on 26 march--> mtime is wrong on weightsPhase2.txt

tr2=rbind(tr_raw2,MicPlant%>%
            dplyr::select(Time,Date,weight))



tr2=merge(tr2,MicPlant%>%
            select(Time,Plant,hour_start,hour_end),all=T)%>%
  arrange(Time)%>%
  fill(hour_start,Plant,hour_end)%>%
  ungroup()%>%
  filter(!is.na(weight))


### keep one data every minute

tr2=tr2%>%
  mutate(hm=paste0(str_sub(string = Time,start = 12,end = 17),'00'))%>%
  group_by(hour_start,Date,Plant,hm)%>%
  mutate(r=row_number())%>%
  filter(r==max(r))%>%
  ungroup()%>%
  select(colnames(tr1))


### data from 30 march to 7 april( weight per second)
tr_raw3=fread(file = '0-data/0-raw/scale_weight/weightsPhase3.txt')%>%
  mutate(Date=ymd(str_sub(string = V1,start = 0,end = 10)),
         hms=str_sub(string = V1,start = 12,end = 19),
         Time=ymd_hms(paste(Date,hms)),
         weight=V2)%>%
  select(Time,Date,weight)%>%
  data.frame()

# check diff time between file creation and the last value recorded (folder time in Central European Time (CEST))
# folderTime3=ymd_hms(time =with_tz(file.info(file = '../Data/ScaleWeight/weightsPhase3.txt')$mtime,tzone = "UTC"))
difftime(max(tr_raw3$Time),file.info(file = '0-data/0-raw/scale_weight/weightsPhase3.txt')$mtime) #ok UTC+2

# ##update last date
# MicPlant[is.na(MicPlant$hour_end),]$hour_end=last(tr_raw3$Time)

tr3=rbind(tr_raw3,MicPlant%>%
            dplyr::select(Time,Date,weight))


tr3=merge(tr3,MicPlant%>%
            select(Time,Plant,hour_start,hour_end),all=T)%>%
  arrange(Time)%>%
  fill(hour_start,Plant,hour_end)%>%
  ungroup()%>%
  filter(!is.na(weight))


### keep one data every minute

tr3=tr3%>%
  mutate(hm=paste0(str_sub(string = Time,start = 12,end = 17),'00'))%>%
  group_by(hour_start,Date,Plant,hm)%>%
  mutate(r=row_number())%>%
  filter(r==max(r))%>%
  ungroup()%>%
  select(colnames(tr1))


### data from 8 april ( weight per second)
tr_raw4=fread(file = '0-data/0-raw/scale_weight/weightsPhase4.txt')%>%
  mutate(Date_raw=ymd(str_sub(string = V1,start = 0,end = 10)),
         hms=str_sub(string = V1,start = 12,end = 19),
         Time_row=ymd_hms(paste(Date_raw,hms)),
         weight=V2)%>%
  select(Time_row,Date_raw,weight)%>%
  data.frame()

# check diff time between file creation and the last value recorded (folder time in Central European Time (CEST))
# folderTime4=ymd_hms(file.info(file = '../Data/ScaleWeight/weightsPhase4.txt')$mtime)

# delay4=difftime(max(tr_raw4$Time_row),file.info(file = '../Data/ScaleWeight/weightsPhase4.txt')$mtime,units = 'secs') 
delay4=difftime(max(tr_raw4$Time_row),ymd_hms('2021-05-03 09:35:33'),units = 'secs') 
delay4=delay4+2*3600

tr_raw4=tr_raw4%>%
  mutate(Time=Time_row-delay4,
         Date=ymd(str_sub(string = Time,start =0,end = 10)))%>%
  select(Time,Date,weight)%>%
  data.frame()

##update last date
# MicPlant[is.na(MicPlant$hour_end),]$hour_end=last(tr_raw4$Time)


tr4=rbind(tr_raw4,MicPlant%>%
            dplyr::select(Time,Date,weight))


tr4=merge(tr4,MicPlant%>%
            select(Time,Plant,hour_start,hour_end),all=T)%>%
  arrange(Time)%>%
  fill(hour_start,Plant,hour_end)%>%
  ungroup()%>%
  filter(!is.na(weight))


### keep one data every minute

tr4=tr4%>%
  mutate(hm=paste0(str_sub(string = Time,start = 12,end = 17),'00'))%>%
  group_by(hour_start,Date,Plant,hm)%>%
  mutate(r=row_number())%>%
  filter(r==max(r))%>%
  ungroup()%>%
  select(colnames(tr1))




# merge all files ---------------------------------------------------------


tr_all=rbind(tr1,tr2,tr3,tr4)
# tr_all=rbind(tr2)

tr_all=tr_all%>%
  group_by(hour_start,Plant)%>%
  # filter(Time>=hour_start & Time<=hour_end | Time>=hour_start & is.na(hour_end))%>%
  filter(Time>=hour_start & Time<=hour_end)%>%
  mutate(weight_rel=first(weight)-weight)%>%
  ungroup()%>%
  mutate(hms=hms(str_sub(string = Time,start = 12,end = 19)))

### add irrigation points and correct transpiration

tresh_irrig=5 ## diff weight treshold to consider irrigation


tr_all=tr_all%>%
  group_by(hour_start,Plant)%>%
  mutate(diff=weight_rel-lag(weight_rel),
         irrigation=ifelse(!is.na(diff) & -diff>tresh_irrig,-diff,0),
         transp_cumul=weight_rel+cumsum(irrigation),
         transp=diff+irrigation)%>%
  ungroup()


### add scenaro
scenar=fread(input = '0-data/0-raw/scenario_sequence/SequenceScenarioMicro3.csv',na.strings = '')%>%
  mutate(Date=dmy(Date))

tr_all=merge(tr_all,scenar,all.x=T)



# remove period of scale probleme; irrigation out otf the pot -----------------------------------------
# error=fread(file = '../Data/PeriodErrorScale.csv')%>%
#   mutate(hour_start=dmy_hms(hour_start),
#          hour_end=dmy_hms(hour_end))
# 
# period=NULL
# for (i in 1:nrow(error)){
#   sub_period=seq.POSIXt(from = ymd_hms(error[i,]$hour_start),to =ymd_hms(error[i,]$hour_end),by = 'sec') 
#   period=c(ymd_hms(period),ymd_hms(sub_period))
# }
# 
# 
# tr_all_c=tr_all%>%
#   filter(!(Time %in% period))

# graph -------------------------------------------------------------------

gr_irrig=ggplot()+
  geom_point(data=tr_all,aes(x=hms,y=transp,col=Plant))+
  # geom_vline(data=data.frame(Time=ymd_hms(paste(unique(tr_all$Date),'00:00:00'))),aes(xintercept=Time),col=1,lty=2)+
  # geom_col(data=tr_all%>%filter(irrigation>0),aes(x=Time,y=irrigation,col='irrigation'))+
  geom_vline(data=tr_all%>%filter(irrigation>0),aes(xintercept=hms),alpha=0.5,col='blue')+
  # geom_point(data=tr_all%>%filter(irrigation>0),aes(x=Time,y=irrigation,col='irrigation'))+
  # geom_text_repel(data=tr_all%>%filter(irrigation>0),aes(x=hms,y=max(tr_all$transp,na.rm=T),label=paste(round(irrigation),'ml')),col='blue',direction = 'y')+
  scale_x_time(breaks = seq(0,24,4)*3600,labels = paste0(seq(0,24,4),'h'))+
  ylab('Transpiration (ml.timestep-1)')+
  facet_wrap(~Date)


#### debug
dateStart=ymd('2021-04-12')
dateEnd=ymd('2021-04-14')
subTr=tr_all%>%
  filter(Date>=dateStart & Date<=dateEnd)

ggplotly(ggplot()+
           geom_point(data=subTr,aes(x=hms,y=transp,col=weight))+
           geom_vline(data=subTr%>%filter(irrigation>0),aes(xintercept=hms),alpha=0.5,col='blue')+
           # geom_point(data=tr_all%>%filter(irrigation>0),aes(x=Time,y=irrigation,col='irrigation'))+
           geom_text_repel(data=subTr%>%filter(irrigation>0),aes(x=hms,y=max(subTr$transp,na.rm=T),label=paste(round(irrigation),'ml')),col='blue',direction = 'y')+
           scale_x_time(breaks = seq(0,24,4)*3600,labels = paste0(seq(0,24,4),'h'))+
           ylab('Transpiration (ml.timestep-1)')+
           facet_grid(~Date))


# tr_all%>%
#   ggplot()+
#   geom_point(aes(x=Time,y=transp))+
#   scale_x_datetime()+
#   theme_minimal()

### integration over 10 mn
# test0=tr_raw2%>%
#   filter(Date=='2021-03-23')
# 
# test=tr_all%>%
#   filter(Date=='2021-03-23')
# 
# test_int=test%>%
#   arrange(Time)%>%
#   group_by(Date_start,Plant)%>%
#   mutate(hm=paste0(str_sub(string = Time,start = 12,end = 17),'00'),
#          mn=str_sub(string = Time,start = 16,end = 16))%>%
#   filter(str_sub(string = mn,start = str_length(mn),str_length(mn))=='0')%>%
#   select(Date_start,Date,Scenario,Plant,Time,hms,hm,weight,transp_cumul)%>%
#   mutate(dif_time=as.numeric(Time-lag(Time)),
#          transp_abs=transp_cumul-lag(transp_cumul),
#          transp=transp_abs*10/dif_time)

tr_int=tr_all%>%
  arrange(Time)%>%
  group_by(hour_start,Plant)%>%
  mutate(hm=paste0(str_sub(string = Time,start = 12,end = 17),'00'),
         mn=str_sub(string = Time,start = 16,end = 16))%>%
  filter(str_sub(string = mn,start = str_length(mn),str_length(mn))=='0')%>%
  select(hour_start,Date,Scenario,Plant,Time,hms,hm,transp_cumul)%>%
  mutate(dif_time=as.numeric(Time-lag(Time)),
         transp=(transp_cumul-lag(transp_cumul))*10/dif_time)

###1 remove points with scale problem
# outliers=c(ymd_hms('2021-03-30 15:40:57'),ymd_hms('2021-03-30 15:50:59'),ymd_hms('2021-03-30 16:00:59'),ymd_hms('2021-03-30 21:40:59'),ymd_hms('2021-03-31 3:40:59'),ymd_hms('2021-03-31 3:50:56'))
# 
# tr_int=tr_int%>%
#   filter(!(Time %in% outliers))

### check time lapse between measures
# summary(tr_int$dif_time)

# tr_sub=tr_all%>%
#   arrange(Time)%>%
#   group_by(Date_start,Plant)%>%
#   mutate(hm=paste0(str_sub(string = Time,start = 12,end = 17),'00'),
#          mn=str_sub(string = Time,start = 16,end = 16))%>%
#   filter(str_sub(string = mn,start = str_length(mn),str_length(mn))=='0')%>%
#   select(Date_start,Date,Scenario,Plant,Time,hms,hm,transp_cumul)%>%
#   mutate(dif_time=as.numeric(Time-lag(Time)),
#          transp=(transp_cumul-lag(transp_cumul))/dif_time)%>%
#   filter(Date=='2021-03-23')
# 
# ggplotly(tr_sub%>%
#   ggplot(aes(x=Time,y=transp))+
#     geom_line()+
#   geom_point(aes(col=dif_time)))
# ggplotly(ggplot()+
#   geom_point(data=tr_int%>%filter(Date>=ymd('2021-03-30')),aes(x=hms,y=transp,col=Time,group=paste(Plant,Scenario,Date)))+
#   ylab('transpiration (ml.10mn-1)')+
#   scale_x_time(breaks = seq(0,24,4)*3600,labels = paste0(seq(0,24,4),'h'))+
#   facet_wrap(Date~Scenario))
# 


gr_ht=ggplot()+
  geom_point(data=tr_int,aes(x=hms,y=transp,col=Plant,group=paste(Plant,Scenario,Date)))+
  ylab('transpiration (ml.10mn-1)')+
  # geom_ribbon(data=tr%>%filter(hms>=hms('18:30:00') | hms<=hms('05:30:00')),aes(x = Time, ymax = Inf, ymin = -Inf),fill = "lightgrey", alpha = 0.3)+
  # geom_vline(data=data.frame(Time=ymd_hms(paste(unique(tr_int$Date),'00:00:00'))),aes(xintercept=Time),col=2)+
  scale_x_time(breaks = seq(0,24,4)*3600,labels = paste0(seq(0,24,4),'h'))+
  facet_wrap(Date~Scenario)+
  theme_bw()+
  scale_color_manual(values = colors_plant)

gr_hs=ggplot()+
  geom_ribbon(data=tr_all%>%filter(hms>=hms('18:30:00')),aes(x = hms, ymax = Inf, ymin = -Inf),fill = "lightgrey", alpha = 0.3)+
  geom_ribbon(data=tr_all%>%filter(hms<=hms('05:30:00')),aes(x = hms, ymax = Inf, ymin = -Inf),fill = "lightgrey", alpha = 0.3)+
  geom_point(data=tr_int,aes(x=hms,y=transp,col=Scenario,group=paste(Plant,Scenario,Date)))+
  geom_line(data=tr_int,aes(x=hms,y=transp,col=Scenario,group=paste(Plant,Scenario,Date)))+
  ylab('Transpiration (ml.10mn-1)')+
  # geom_vline(data=data.frame(Time=ymd_hms(paste(unique(fl$Date),'00:00:00'))),aes(xintercept=Time),col=2)+
  ylim(c(-1,max(tr_int$transp,na.rm=T)))+
  scale_x_time(breaks = seq(0,24,4)*3600,labels = paste0(seq(0,24,4),'h'))+
  facet_wrap(~Plant)+
  theme_bw()+
  scale_color_manual(values = colors_scenar)

ggplotly(tr_int%>%
           filter(Scenario %in% c('DryHot'))%>%
           ggplot()+
           # geom_ribbon(data=tr_all%>%filter(hms>=hms('18:30:00')),aes(x = hms, ymax = Inf, ymin = -Inf),fill = "lightgrey", alpha = 0.3)+
           # geom_ribbon(data=tr_all%>%filter(hms<=hms('05:30:00')),aes(x = hms, ymax = Inf, ymin = -Inf),fill = "lightgrey", alpha = 0.3)+
           # geom_point(data=tr_int,aes(x=hms,y=transp,col=Scenario,group=paste(Plant,Scenario,Date)))+
           geom_point(data=,aes(x=hms,y=transp,col=Scenario,group=paste(Plant,Scenario,Date)))+
           ylab('Transpiration (ml.10mn-1)')+
           # geom_vline(data=data.frame(Time=ymd_hms(paste(unique(fl$Date),'00:00:00'))),aes(xintercept=Time),col=2)+
           ylim(c(-1,max(tr_int$transp,na.rm=T)))+
           scale_x_time(breaks = seq(0,24,4)*3600,labels = paste0(seq(0,24,4),'h'))+
           facet_wrap(~Plant)+
           theme_bw())


gr_hp=ggplot()+
  geom_ribbon(data=tr_all%>%filter(hms>=hms('18:30:00')),aes(x = hms, ymax = Inf, ymin = -Inf),fill = "lightgrey", alpha = 0.3)+
  geom_ribbon(data=tr_all%>%filter(hms<=hms('05:30:00')),aes(x = hms, ymax = Inf, ymin = -Inf),fill = "lightgrey", alpha = 0.3)+
  geom_point(data=tr_int,aes(x=hms,y=transp,col=Plant,group=paste(Plant,Scenario,Date)))+
  geom_line(data=tr_int,aes(x=hms,y=transp,col=Plant,group=paste(Plant,Scenario,Date)))+
  ylab('Transpiration (ml.10mn-1)')+
  # geom_vline(data=data.frame(Time=ymd_hms(paste(unique(fl$Date),'00:00:00'))),aes(xintercept=Time),col=2)+
  ylim(c(-1,max(tr_int$transp,na.rm=T)))+
  scale_x_time(breaks = seq(0,24,4)*3600,labels = paste0(seq(0,24,4),'h'))+
  facet_wrap(~Scenario)+
  theme_bw()+
  scale_color_manual(values = colors_plant)




# daily transpi -----------------------------------------------------------

tr_day=tr_all%>%
  arrange(Date,Time,Plant,Scenario)%>%
  group_by(Date,Scenario,Plant)%>%
  summarize(day_start=min(Time,na.rm=T),
            day_end=max(Time,na.rm=T),
            period=(max(Time,na.rm=T)-min(Time,na.rm=T)),
            nb_hour=n()/60,
            total_irrig=sum(irrigation),
            total_transp=sum(transp,na.rm=T),
            av_hourly_transp=total_transp/nb_hour)



sum_transpirrig=tr_day%>%
  filter(nb_hour>22)%>%
  tidyr::gather(key = 'var',value = 'ml.day-1',total_irrig,total_transp)%>%
  ggplot(aes(x=Scenario,fill=var,y=`ml.day-1`,group=paste(Plant, Date,var)))+
  geom_col(position='dodge',col=1)+
  facet_wrap(~Plant,scales='free_x')

