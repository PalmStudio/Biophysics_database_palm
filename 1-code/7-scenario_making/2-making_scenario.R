
# -------------------------------------------------------------------------###
### script to represent Ecotron Scenario from SMSE climate data

# -------------------------------------------------------------------------###


# Load packages -----------------------------------------------------------

packs <- c('shiny','datasets',"lubridate", "stringr", "ggplot2",'dplyr','viridis','plotly','tidyr','scales','cowplot')
InstIfNec<-function (pack) {
  if (!do.call(require,as.list(pack))) {
    do.call(install.packages,as.list(pack))  }
  do.call(require,as.list(pack)) }
lapply(packs, InstIfNec)


##paramter for estimating saturated vapour pressure (SVP) for a given temperature
p1=18.9321
p2=5300.24


# import meteo data -------------------------------------------------------------

###coversion factor J.cm-2-->W.m-2
conv0=10000/3600


###incident radiation
###coversion factor W.m-2.1h-->micromol.m-2.s-1 of PAR
conv1=0.48*4.6

don=data.table::fread(file = '0-data/0-raw/smse/Meteo_hour_SMSE.csv',sep=';',dec='.')%>%
  mutate(
    Date=dmy(Date),
    Time=as.POSIXct(x=Time,format='%H:%M'),
    Year=year(Date),
    Month=as.factor(month.abb[month(Date)]),
    VPD=(exp(p1-p2/(Temp+273)))*(1-HR/100),
    RG_Wm2=`RG_J.cm-2`*conv0,
    PAR=RG_Wm2*conv1)


levels(don$Month)=list("Jan"="Jan","Feb"="Feb","Mar"='Mar','Apr'="Apr",'May'='May','Jun'='Jun','Jul'='Jul','Aug'='Aug','Sep'='Sep','Oct'='Oct','Nov'='Nov','Dec'='Dec')



###remove errors recorded

don=don%>%
  filter(!(Month %in% c('Dec') & Year==2014) & 
           !(Month %in% c('Jan','Feb','Mar','Apr','May','Dec') & Year==2015) &
           !(Month %in% c('Jan','Feb','Mar','Apr','May','Jun','Jul') & Year==2016))

####daily RG
###conversion factor W.m-2.1h-1 of GR-->MJ.m-2.day-1 of PAR
conMJday=3600*10**-6


don%>%
  group_by(Date)%>%
  summarize(RG_MJm2=sum(RG_Wm2*conMJday))

summary(don)




cor(don%>%
      select(Temp,HR,PAR,VPD))
# average per month -------------------------------------------------------



sum=don%>%
  group_by(Year,Month,Time)%>%
  summarize(Temp=mean(Temp),HR=mean(HR),VPD=mean(VPD),PAR=mean(PAR))%>%
  ungroup()



sum%>%
  ggplot(aes(x=Time,y=Temp,col=Year,group=paste(Year,Month)))+
  geom_line()+
  facet_wrap(~Month)+
  scale_color_viridis()+
  scale_x_datetime(breaks ='2 hour',date_labels = format('%H:%M'))+
  theme(axis.text.x=element_text(angle=90))+
  ylab('Temperature (Â°C)')


sum%>%
  ggplot(aes(x=Time,y=HR,col=Year,group=paste(Year,Month)))+
  geom_line()+
  facet_wrap(~Month)+
  scale_color_viridis()+
  scale_x_datetime(breaks ='4 hour',date_labels = format('%H:%M'))+
  theme(axis.text.x=element_text(angle=90))+
  ylab('Relative Humidity (%)')


sum%>%
  ggplot(aes(x=Time,y=VPD,col=Year,group=paste(Year,Month)))+
  geom_line()+
  facet_wrap(~Month)+
  scale_color_viridis()+
  scale_x_datetime(breaks ='4 hour',date_labels = format('%H:%M'))+
  theme(axis.text.x=element_text(angle=90))+
  ylab('VPD (kPa)')



sum%>%
  ggplot(aes(x=Time,y=PAR,col=Year,group=paste(Year,Month)))+
  geom_line()+
  facet_wrap(~Month)+
  scale_color_viridis()+
  scale_x_datetime(breaks ='4 hour',date_labels = format('%H:%M'))+
  theme(axis.text.x=element_text(angle=90))+
  ylab(expression ('Incident '~"PPFD "*(mu*mol*' '*m**-2*' '*s**-1)))

grid=sum%>%
  select(Temp,HR,PAR,VPD)

# plot(grid)
# cor(grid)



# select specific days ----------------------------------------------------

don%>%
  filter(Time>'2020-12-09 12:00:00' & PAR>quantile(PAR,0.60))%>%
  filter(PAR==min(PAR))


# daily average -----------------------------------------------------------------

av=don%>%
  gather(key = 'var',value='value',Temp,HR,PAR)%>%
  group_by(var,Time)%>%
  summarize(mean_val=mean(value),max_val=quantile(x = value,probs = 0.95),min_val=quantile(x = value,probs = 0.05),sd=sd(value))%>%
  ungroup()



av%>%
  ggplot()+
  geom_line(aes(x=Time,y=mean_val))+
  geom_line(aes(x=Time,y=max_val),lty=2)+
  geom_line(aes(x=Time,y=min_val),lty=2)+
  facet_wrap(~var,scale='free_y')


# generate scenario -------------------------------------------------------
dev=0.3 ###% of deviation of a variable from ref value

ref=av%>%
  mutate(scenario='reference',
         value=mean_val)

hot=av%>%
  mutate(scenario='hot',
         value=ifelse(test = var=='Temp',yes = mean_val*(1+dev),no = mean_val))

cold=av%>%
  group_by(Time,var)%>%
  mutate(scenario='cold',
         value=ifelse(test = var=='Temp',yes = max(c(min_val,mean_val*(1-dev))),no = mean_val))

dry_hot=av%>%
  group_by(Time,var)%>%
  mutate(scenario='dry_hot',
         value=ifelse(test = var=='Temp',yes = mean_val*(1+dev),
                      no = ifelse(test = var=='HR',yes = max(c(min_val,mean_val*(1-dev))),no = mean_val)))
dry_cold=av%>%
  group_by(Time,var)%>%
  mutate(scenario='dry_cold',
         value = ifelse(test = var=='HR',yes = max(c(min_val,mean_val*(1-dev))),
                        no = ifelse(var=='Temp',yes = max(c(min_val,mean_val*(1-dev))),no = mean_val)))

# 
# humid_hot=av%>%
#   group_by(Time,var)%>%
#   mutate(scenario='humid_hot',
#          value=ifelse(test = var=='Temp',yes = mean_val*(1+dev),no = mean_val),
#          value=ifelse(test = var=='HR',yes = min(c(max_val,mean_val*(1+dev))),no = mean_val))

cloudy=av%>%
  group_by(Time,var)%>%
  mutate(scenario='cloudy',
         value=ifelse(test = var=='PAR',yes = max(c(min_val,mean_val*(1-dev))),no = mean_val))

## CO2 600

## CO2 800


# sunny=av%>%
#   group_by(Time,var)%>%
#   mutate(scenario='sunny',
#          value=ifelse(test = var=='PAR',yes = mean_val*(1+dev),no = mean_val))
# 
# sunnydry=av%>%
#   group_by(Time,var)%>%
#   mutate(scenario='sunnydry',
#          value=ifelse(test = var=='Temp',yes = mean_val*(1+dev),no = mean_val),
#          value=ifelse(test = var=='HR',yes = max(c(min_val,mean_val*(1-dev))),no = mean_val),
#          value=ifelse(test = var=='PAR',yes = mean_val*(1+dev),no = mean_val))
# 
# cloudyhumid=av%>%
#   group_by(Time,var)%>%
#   mutate(scenario='cloudyhumid',
#          value=ifelse(test = var=='PAR',yes = max(c(min_val,mean_val*(1-dev))),no = mean_val),
#          value=ifelse(test = var=='HR',yes = mean_val*(1+dev),no = mean_val),
#          value=ifelse(test = var=='Temp',yes = max(c(min_val,mean_val*(1-dev))),no = mean_val))



scenar=dplyr::bind_rows(ref,cold,hot,dry_hot,dry_cold,cloudy)%>%
  mutate(hour=str_sub(string = Time,start = 12,end = 19))



graph_scenar=scenar%>%
  ggplot(aes(x=hms(hour),y=value,col=scenario))+
  geom_line()+
  facet_grid(var~scenario,scale='free')+
  scale_x_time(breaks=seq(0,24,4)*3600,labels =seq(0,24,4))


don_space=scenar%>%
  tidyr::spread(key=var,value=value)%>%
  group_by(scenario,hour)%>%
  summarize(HR=round(mean(HR,na.rm=T)),
            PAR  =round(mean(PAR,na.rm=T)),
            Temp=round(mean(Temp,na.rm=T),1))%>%
  mutate(PAR  =ifelse(PAR<5,0,PAR))%>%
  select(PAR,HR,Temp)%>%
  ungroup()

graph_space=plot(don_space[,c('PAR','HR','Temp')])

# extract conditions ------------------------------------------------------
ref_time=c('00:00:00','02:00:00','04:00:00','06:00:00','08:00:00','10:00:00','12:00:00',
           '14:00:00',
           '16:00:00',
           '18:00:00',
           "20:00:00",
           '22:00:00')

table=scenar%>%
  mutate(hour=str_sub(string = Time,start = 12,end = 19))%>%
  filter(hour %in% ref_time)%>%
  tidyr::spread(key=var,value=value,drop=T)%>%
  group_by(scenario,hour)%>%
  summarize(HR=round(mean(HR,na.rm=T)),
            PAR  =round(mean(PAR,na.rm=T)),
            Temp=round(mean(Temp,na.rm=T),1))%>%
  mutate(PAR  =ifelse(PAR<5,0,PAR))

colnames(table)=c('Scenario','Hour','HR (%)','PAR (micr.mol.m-2.s-1)','Temp (deg C)')

data.table::fwrite(table, "0-data/7-scenarios/making_scenario_output.csv")
