# Load packages -----------------------------------------------------------

packs <- c("lubridate", "stringr", "ggplot2",'dplyr','viridis','plotly','tidyr','data.table')
InstIfNec<-function (pack) {
  if (!do.call(require,as.list(pack))) {
    do.call(install.packages,as.list(pack))  }
  do.call(require,as.list(pack)) }
lapply(packs, InstIfNec)

close1=read.csv(file='0-data/0-raw/walz/P5F70427.csv',sep=';',header=F,dec='.',skip =2)


head=str_split(string = readLines(con ='0-data/0-raw/walz/P5F70427.csv' ,n = 1),pattern = ';')[[1]]

colnames(close1)=head

close1=close1%>%
  mutate(Plant='P5',
         Walz_head='Close')


close2=read.csv(file='0-data/0-raw/walz/P1F60428.csv',sep=';',header=F,dec='.',skip =2)

colnames(close2)=head

close2=close2%>%
  mutate(Plant='P1',
         Walz_head='Close')


open1=read.csv(file='0-data/0-raw/walz/P5F70429.csv',sep=';',header=F,dec='.',skip =2)
headO=str_split(string = readLines(con ='0-data/0-raw/walz/P5F70429.csv' ,n = 1),pattern = ';')[[1]]
colnames(open1)=headO

open1=open1%>%
  mutate(Plant='P5',
         Walz_head='Open')

open2=read.csv(file='0-data/0-raw/walz/P1F60430.csv',sep=';',header=F,dec='.',skip =2)
colnames(open2)=headO

open2=open2%>%
  mutate(Plant='P1',
         Walz_head='Open')


vars=c('Time','PARtop','Tleaf','Tcuv','Tamb','Ttop','PARamb','rh','VPD','E','GH2O','A','ci','ca','wa','Plant','Walz_head')

don=bind_rows(close1%>%
                dplyr::select(vars),
              close2%>%
                dplyr::select(vars),
              open1%>%
                dplyr::select(vars),
              open2%>%
                dplyr::select(vars)
)%>%
  mutate(Time=hms(Time))

don%>%
  ggplot(aes(x=Time,y=A,col=PARamb))+
  geom_point()+
  scale_color_viridis(name='PAR out')+
  scale_x_time()+
  facet_grid(Plant~Walz_head)


don%>%
  ggplot(aes(x=Time,y=GH2O,col=PARamb))+
  geom_point()+
  scale_color_viridis(name='PAR out')+
  scale_x_time()+
  facet_wrap(Plant~Walz_head,scales='free_y')
