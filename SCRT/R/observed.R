observed<-function(design,statistic,data=read.table(file.choose(new=FALSE))){

  if(design=="CRD"|design=="RBD"|design=="ATD"|design=="AB"){
    observed.a<-data[,2][data[,1]=="A"]
    observed.b<-data[,2][data[,1]=="B"]
    if(statistic=="A-B"){
      observed.statistic<-mean(observed.a)-mean(observed.b)
    }
    if(statistic=="B-A"){
      observed.statistic<-mean(observed.b)-mean(observed.a)
    }
    if(statistic=="|A-B|"){
      observed.statistic<-abs(mean(observed.a)-mean(observed.b))
    }
  }
  
  if(design=="ABA"){
    observed.a1<-data[,2][data[,1]=="A1"]
    observed.b1<-data[,2][data[,1]=="B1"]	
    observed.a2<-data[,2][data[,1]=="A2"]	
    observed.a<-c(observed.a1,observed.a2)	
    if(statistic=="A-B"){
      observed.statistic<-mean(observed.a)-mean(observed.b1)
    }
    if(statistic=="B-A"){
      observed.statistic<-mean(observed.b1)-mean(observed.a)
    }
    if(statistic=="|A-B|"){
      observed.statistic<-abs(mean(observed.a)-mean(observed.b1))
    }
    if(statistic=="PA-PB"){
      observed.statistic<-((mean(observed.a1)+mean(observed.a2))/2)-(mean(observed.b1))
    }
    if(statistic=="PB-PA"){
      observed.statistic<-mean(observed.b1)-((mean(observed.a1)+mean(observed.a2))/2)
    }
    if(statistic=="|PA-PB|"){
      observed.statistic<-abs(((mean(observed.a1)+mean(observed.a2))/2)-mean(observed.b1))
    }
    if(statistic=="AA-BB"){
      observed.statistic<-(mean(observed.a1)+mean(observed.a2))-(mean(observed.b1))
    }
    if(statistic=="BB-AA"){
      observed.statistic<-(mean(observed.b1))-(mean(observed.a1)+mean(observed.a2))
    }
    if(statistic=="|AA-BB|"){
      observed.statistic<-abs((mean(observed.a1)+mean(observed.a2))-(mean(observed.b1)))
    }
  }
  
  if(design=="ABAB"){
    observed.a1<-data[,2][data[,1]=="A1"]
    observed.b1<-data[,2][data[,1]=="B1"]	
    observed.a2<-data[,2][data[,1]=="A2"]	
    observed.b2<-data[,2][data[,1]=="B2"]	
    observed.a<-c(observed.a1,observed.a2)	
    observed.b<-c(observed.b1,observed.b2)	
    if(statistic=="A-B"){
      observed.statistic<-mean(observed.a)-mean(observed.b)
    }
    if(statistic=="B-A"){
      observed.statistic<-mean(observed.b)-mean(observed.a)
    }
    if(statistic=="|A-B|"){
      observed.statistic<-abs(mean(observed.a)-mean(observed.b))
    }
    if(statistic=="PA-PB"){
      observed.statistic<-((mean(observed.a1)+mean(observed.a2))/2)-((mean(observed.b1)+mean(observed.b2))/2)	
    }
    if(statistic=="PB-PA"){
      observed.statistic<-((mean(observed.b1)+mean(observed.b2))/2)-((mean(observed.a1)+mean(observed.a2))/2)
    }
    if(statistic=="|PA-PB|"){
      observed.statistic<-abs(((mean(observed.a1)+mean(observed.a2))/2)-((mean(observed.b1)+mean(observed.b2))/2))
    }
    if(statistic=="AA-BB"){
      observed.statistic<-(mean(observed.a1)+mean(observed.a2))-(mean(observed.b1)+mean(observed.b2))
    }
    if(statistic=="BB-AA"){
      observed.statistic<-(mean(observed.b1)+mean(observed.b2))-(mean(observed.a1)+mean(observed.a2))
    }
    if(statistic=="|AA-BB|"){
      observed.statistic<-abs((mean(observed.a1)+mean(observed.a2))-(mean(observed.b1)+mean(observed.b2)))
    }
  }
  
  if(design=="MBD"){
    observed.a<-list() 
    for(it in 1:(ncol(data)/2)){
      observed.a[[it]]<-data[,it*2][data[,(it*2)-1]=="A"]
    }
    observed.b<-list()
    for(it in 1:(ncol(data)/2)){
      observed.b[[it]]<-data[,it*2][data[,(it*2)-1]=="B"]
    }
    if(statistic=="A-B"){
      differences<-numeric(ncol(data)/2)
      for(it in 1:(ncol(data)/2)){
        differences[it]<-mean(observed.a[[it]])-mean(observed.b[[it]])
      }
    }
    if(statistic=="B-A"){
      differences<-numeric(ncol(data)/2)
      for(it in 1:(ncol(data)/2)){
        differences[it]<-mean(observed.b[[it]])-mean(observed.a[[it]])
      }
    }
    if(statistic=="|A-B|"){
      differences<-numeric(ncol(data)/2)
      for(it in 1:(ncol(data)/2)){
        differences[it]<-abs(mean(observed.a[[it]])-mean(observed.b[[it]]))
      }
    }
    observed.statistic<-mean(differences)
  }
  
  return(observed.statistic)

}
