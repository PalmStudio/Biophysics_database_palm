# Load packages -----------------------------------------------------------

packs <- c("lubridate", "stringr", "ggplot2",'dplyr','viridis','plotly','tidyr','data.table')
InstIfNec<-function (pack) {
  if (!do.call(require,as.list(pack))) {
    do.call(install.packages,as.list(pack))  }
  do.call(require,as.list(pack)) }
lapply(packs, InstIfNec)




#  Test with data every seconds ------------------------------------------------
don=fread(file='0-data/0-raw/walz/TEST2.csv')%>%
  mutate(Time=hms(Time))


don%>%
  ggplot(aes(x=Time,y=A))+
  geom_point()+
  scale_x_time()

##average every 30s
don30=don%>%
  mutate(r=row_number(),
         R=r%/%30)%>%
  group_by(R)%>%
  summarize(Time=last(Time)-15,A=mean(A))%>%
  ungroup()

### average every 10s
don10=don%>%
  mutate(r=row_number(),
         R=r%/%10)%>%
  group_by(R)%>%
  summarize(Time=last(Time)-5,A=mean(A))%>%
  ungroup()

### average every 5s
don5=don%>%
  mutate(r=row_number(),
         R=r%/%5)%>%
  group_by(R)%>%
  summarize(Time=last(Time)-2.5,A=mean(A))%>%
  ungroup()

ggplot()+
  geom_point(data=don,aes(x=Time,y=A,col='raw'),alpha=0.5)+
  geom_point(data=don30,aes(x=Time,y=A,col='av30'))+
  geom_line(data=don30,aes(x=Time,y=A,col='av30'))+
  geom_point(data=don10,aes(x=Time,y=A,col='av10'))+
  geom_line(data=don10,aes(x=Time,y=A,col='av10'))+
  geom_point(data=don5,aes(x=Time,y=A,col='av5'))+
  geom_line(data=don5,aes(x=Time,y=A,col='av5'))+
  scale_x_time()



#  Test 2 with data every 5 seconds ------------------------------------------------
test=fread(file='0-data/0-raw/walz/P3F5OPND.csv')%>%
  mutate(Time=hms(Time))


test%>%
  ggplot(aes(x=Time,y=A,col=GH2O))+
  geom_point()+
  scale_x_time()  

test%>%
  ggplot(aes(x=Time,y=GH2O))+
  geom_point()+
  scale_x_time()

test%>%
  ggplot(aes(x=Time,y=CO2abs))+
  geom_point()+
  scale_x_time()
