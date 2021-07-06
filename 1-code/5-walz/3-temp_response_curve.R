# Load packages -----------------------------------------------------------

packs <- c("lubridate", "stringr", "ggplot2",'dplyr','viridis','plotly','tidyr','data.table')
InstIfNec<-function (pack) {
  if (!do.call(require,as.list(pack))) {
    do.call(install.packages,as.list(pack))  }
  do.call(require,as.list(pack)) }
lapply(packs, InstIfNec)


# import data------------------------------------------------

# temp=fread(file='/0-data/0-raw/walz/P1F6TEMP.csv')%>%
# mutate(Time=hms(Time))

# temp=fread(file='/0-data/0-raw/walz/P5F70427.csv')%>%
#   mutate(Time=hms(Time))

filename='0-data/0-raw/walz/P1F60428.csv'

head=str_split(string = readLines(con =filename ,n = 1),pattern = ';')[[1]]
temp=read.csv(file = filename,sep=';',header=F,dec='.',skip =2)
colnames(temp)=head

temp=temp%>%
  mutate(Time=hms(Time))

temp%>%
  ggplot(aes(x=Time,y=A))+
  geom_point()+
  scale_x_time()

temp%>%
  ggplot(aes(x=Time,y=A))+
  geom_point()+
  scale_x_time()

temp%>%
  ggplot(aes(x=Time,y=Tcuv))+
  geom_point()+
  scale_x_time()

temp%>%
  # filter(Time>hms('13:30:00') & Time<hms('16:30:00'))%>%
  ggplot(aes(x=Time,y=A,col=PARamb))+
  geom_point()+
  scale_color_viridis(name='PAR out')+
  scale_x_time()
