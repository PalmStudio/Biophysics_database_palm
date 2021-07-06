# Load packages -----------------------------------------------------------

packs <- c('data.table','shiny',"lubridate", "stringr", "ggplot2",'dplyr','viridis','plotly','tidyr','DT','scales','readxl')
InstIfNec<-function (pack) {
  if (!do.call(require,as.list(pack))) {
    do.call(install.packages,as.list(pack))  }
  do.call(require,as.list(pack)) }
lapply(packs, InstIfNec)



# inputs ------------------------------------------------------------------

d_save <- data.frame()
colors_plant=hue_pal()(4) 
names(colors_plant)=c("P1",'P2','P3','P5')


# colors_plant=hue_pal()(4) 
# names(colors_plant)=c("P1",'P2','P3','P5')

fl_raw=read_xlsx(path = '/0-data/0-raw/picarro_flux/data_mean_flux.xlsx',skip=1,col_names = F) ##change names because of markdown uncompatibility

colnames(fl_raw)=c("MPV1_time","CO2_dry_MPV1","delta13C_MPV1","MPV2_time","CO2_dry_MPV2","delta13C_MPV2","...7","CO2 differential ppm","Flow m3/h","surface m2","flux","...12","d13C differential")

fl=fl_raw%>%
  mutate(Time=MPV1_time,
         Date=ymd(str_sub(string = Time,start = 0,end = 10)),
         hms=hms(str_sub(string = Time,start = 12,end = 19)))%>%
  select(Time,Date,hms,flux)

# ui ----------------------------------------------------------------------
ui<-fluidPage(
  titlePanel("Picarro flux"),
  
  # sidebarLayout(
  #   
  #   sidebarPanel(
  #     uiOutput("plant")
  #   ),
  
  
  dateRangeInput('dateRange',
                 label = 'Date range',
                 start = min(fl$Date,na.rm=T), end = max(fl$Date,na.rm=T)
  ),
  
  plotlyOutput('graph'),
  
  fluidRow(
    column(3,
           fluidRow(
             column(12,
                    
                    DT::dataTableOutput("outliers"),
                    downloadButton("downloadData", "Download")
                    # tableOutput('outliers')
                    
             )
           )
    )
  )
  
  
  
)




# server ----------------------------------------------------------------------


server<-function(input, output,session){
  
  # load data ---------------------------------------------------------------
  
  fl_raw=read_xlsx(path = '../Data/PicarroFlux/data_mean_flux.xlsx',skip=1,col_names = F) ##change names because of markdown uncompatibility
  
  colnames(fl_raw)=c("MPV1_time","CO2_dry_MPV1","delta13C_MPV1","MPV2_time","CO2_dry_MPV2","delta13C_MPV2","...7","CO2 differential ppm","Flow m3/h","surface m2","flux","...12","d13C differential")
  
  fl=fl_raw%>%
    mutate(Time=MPV1_time,
           Date=ymd(str_sub(string = Time,start = 0,end = 10)),
           hms=hms(str_sub(string = Time,start = 12,end = 19)))%>%
    select(Time,Date,hms,flux)
  
  ## add scenar
  
  scenar=fread(input = '../Data/SequenceScenarioMicro3.csv')%>%
    mutate(Date=dmy(Date))
  
  fl=merge(fl,scenar,all.x=T)%>%
    filter(!is.na(Scenario))
  
  ### add plant
  MicPlant=fread(input = '../Data/SequencePlanteMicro3.csv',na.strings = '')%>%
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
  
  
  outL=fread(file='../Data/PicarroFlux/outliers.csv')%>%
    mutate(Time=ymd_hms(paste(str_sub(string = Time,start = 0,10),str_sub(string = Time,start = 12,19))),
           outlier=T)%>%
    mutate(flux=round(flux,4))
  
  fl=merge(fl,outL%>%
             mutate(Time=ymd_hms(paste(str_sub(string = Time,start = 0,10),str_sub(string = Time,start = 12,19))),
                    outlier=T),all.x=T)%>%
    filter(is.na(outlier))
  
  # inputs-----------------------------------------------------
  
  startDate<- reactive({
    input$dateRange[1]
  })
  
  endDate<- reactive({
    input$dateRange[2]
  })
  
  clean<- reactive({
    
    # plantI<-plantInput()
    # if (is.null(plantI)) return(NULL)
    
    startDate<-startDate()
    endDate<-endDate()
    # if (is.null(plantI)) return(NULL)
    
    
    out=NULL
    if(!is.null(event_data("plotly_click"))){
      
      d <- as.data.frame(event_data("plotly_click"))
      d_save <<- rbind(d_save,d)
      # %>%
      #   mutate(Time=ymd_hms(as.character(x)),
      #          flux=y)%>%
      #   select(Time,flux)
      
      # d_save=d_save%>%
      #   group_by(id,Comment,curve,x,y)%>%
      #   mutate(n=n())%>%
      #   mutate(outlier=ifelse(n%%2==0,'valid','outlier'))
      
      fl2=fl%>%
        mutate(x=as.numeric(Time),
               y=flux)%>%
        select(x,y,flux,Time,Plant,Scenario)
      
      sub=d_save
      
      out=merge(sub,fl2,all.x=T)%>%
        select(Time,Plant,Scenario,flux)%>%
        mutate(Time=as_datetime(Time))
      
    }
    
    
    gr=NULL
    if (is.null(out)){ 
      
      gr=fl%>%
        filter(Date>=ymd(startDate) & Date<= ymd(endDate) )%>%
        # filter(Plant %in% plantI)%>%
        ggplot()+
        geom_point(aes(x=Time,y=flux,col=Plant,group=paste(Plant,Scenario,Date)))+
        geom_line(aes(x=Time,y=flux,col=Plant,group=paste(Plant,Scenario,Date)))+
        ylab('CO2 flux (Âµmol/s)')+
        scale_x_time(breaks = seq(0,24,4)*3600,labels = paste0(seq(0,24,4),'h'))+
        # facet_wrap(~Scenario)+
        ylim(c(-1,max(fl$flux,na.rm=T)))+
        scale_color_manual(values = colors_plant)+
        theme_bw()
    }
    
    if (!is.null(out)){ 
      
      # out=fread(file='../../../Desktop/outliers.csv')%>%
      # mutate(Time=ymd_hms(paste(str_sub(string = Time,start = 0,10),str_sub(string = Time,start = 12,19))),
      # outlier=T)
      
      fl_clean=merge(fl,out%>%
                       mutate(Time=ymd_hms(paste(str_sub(string = Time,start = 0,10),str_sub(string = Time,start = 12,19))),
                              new_outlier=T),all.x=T)
      
      
      gr=fl_clean%>%
        filter(is.na(new_outlier))%>%
        filter(Date>=ymd(startDate) & Date<= ymd(endDate) )%>%
        # filter(Plant %in% plantI)%>%
        ggplot()+
        geom_point(aes(x=Time,y=flux,col=Plant,group=paste(Plant,Scenario,Date)))+
        geom_line(aes(x=Time,y=flux,col=Plant,group=paste(Plant,Scenario,Date)))+
        ylab('CO2 flux (Âµmol/s)')+
        scale_x_time(breaks = seq(0,24,4)*3600,labels = paste0(seq(0,24,4),'h'))+
        # facet_wrap(~Scenario)+
        ylim(c(-1,max(fl$flux,na.rm=T)))+
        scale_color_manual(values = colors_plant)+
        theme_bw()
    }
    
    
    
    res=list(graph=gr,out=out)
    return(res)
  })
  
  
  # tables-----------------------------------------------------
  # output$table <-  renderTable({res()})
  
  output$outliers = renderDataTable({
    clean<-clean()
    if (is.null(clean)) return(NULL)
    
    clean$out
  }
  ,rownames= FALSE)
  
  output$downloadData <- downloadHandler(
    
    filename = function() {
      paste('outliers.csv', sep = "")
    },
    content = function(file) {
      clean<-clean()
      if (is.null(clean)) return(NULL)
      # write.csv(FitParams(), file, row.names = FALSE)
      data.table::fwrite(clean$out, file, row.names = FALSE)
    }
  )
  
  # output$outliers = renderTable({
  #   clean<-clean()
  #   if (is.null(clean)) return(NULL)
  #   
  #   clean$out
  # }
  # ,rownames= FALSE)
  
  # visualisation-----------------------------------------------------
  output$graph<-renderPlotly({
    clean<-clean()
    if (is.null(clean)) return(NULL)
    
    gr=clean$graph
    
    if(!is.null(gr)){
      ggplotly(gr)
    }
    
  })
  
  
}
# Run app -------------------------------
shinyApp(ui = ui, server = server)