library(ggplot2)
library(reshape2)
library(gdata)
library(maps)
library(mapproj)
library(ggmap)
library(gplots)
library(pracma)
library(timeSeries)

#co map ssl and herring

setwd("~/Dropbox/Projects/In Progress/Pinniped_Herring_HG/Code")
source('theme_acs.R')
source('multiplot.R')

#load herring data 
x=read.csv("HG_Spawn_Survey_1940_2013b.csv")
x<- x[c(1,3,13,14,15,16)]
x$SHI2<-log(x$SHI+1)
x$presabs <-ifelse(x$SHI>0,1,0)

#load ssl data 
s=read.csv("stellers_dec15_2014.csv",stringsAsFactors=FALSE)
#melt down to long form 
s2 <- melt(s,id.vars=c(colnames(s)[1:6]))
s2$SiteType2 <- ifelse(s2$SiteType=="R","Rookery","Haulout")
s2$year<-as.numeric(substr(as.character(s2$variable),2,5))
s2$count<-as.numeric(s2$value)
s2$presabs <-ifelse(s2$count>0,1,0)
s3 <-subset(s2,Region_large=="NorthernBC")
s4<-subset(s2,Region_small=="HaidaGwaii")
s4b<-subset(s4,count!="NA"&SiteType2=="Haulout")


z<-read.csv("ssl_empty.csv")
z2<-z[,44:80]
time<-seq(1940,2013)
site<-as.numeric(z2[1,])
which(site!="NA")
z3<-data.frame(z[,c(1:6)],t(interpNA(t(z2),method="linear")))
s2 <- melt(z3,id.vars=c(colnames(s)[1:6]))
s2$SiteType2 <- ifelse(s2$SiteType=="R","Rookery","Haulout")
s2$year<-as.numeric(substr(as.character(s2$variable),2,5))
s2$count<-as.numeric(s2$value)
s2$presabs <-ifelse(s2$count>0,1,0)
s3 <-subset(s2,Region_large=="NorthernBC")
s4<-subset(s2,Region_small=="HaidaGwaii")
s4b<-subset(s4,count!="NA"&SiteType2=="Haulout")



#site map
al1 = get_map(location = c(-135,51.5,-131,55), zoom = 7, maptype = 'terrain')
al1MAP = ggmap(al1)

#merge data files 
herring<-x[,c(1,2,5,6,8)]
herring<-herring[,c(1,3,4,2,5)]

seals<-s4b[,c(2,3,8,10,11)]
seals<-seals[,c(4,1,2,3)]
seals$presabs<-ifelse(seals$value>0,1,0)
names(herring)<-names(seals)
seals$variable<-"seals"
herring$variable<-"herring"
comb<-rbind(seals,herring)


yr<-seq(1977,2013)

for(i in 1:length(yr)){
  temp_herr <- subset(comb,year==yr[i]&variable=="herring")
  temp_seal <- subset(comb,year==yr[i]&variable=="seals"&presabs==1)

jpeg(filename = paste(yr[i],"_ssl_herring_comb.jpg"),width = 800, height = 480)

  
g1<-  ggmap(al1)+
    geom_point(data = temp_seal, aes(x = Longitude, y = Latitude),size=4,pch=15)+
    geom_point(data = temp_herr, aes(x = Longitude, y = Latitude,size=value,fill=factor(presabs)),pch=21)+
    scale_size_continuous(limits=c(0,902762),range=c(4,10))+
    theme_acs()+
    ggtitle(paste(yr[i],"Herring_SSL"))
 print(g1) 
  dev.off()
}

