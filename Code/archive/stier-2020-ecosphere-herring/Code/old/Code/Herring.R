setwd("~/Dropbox/Projects/In Progress/Plan B/Pinniped_Herring_HG/Code")

n.colors<-5
label.location<-c(128,54.5)
years<-1951:2014
n.years<-length(years)
her.data<-read.table("ALLSPAWN.csv",header=T,sep=",")
her.data<-her.data[which(her.data$YEAR %in% years),]



hg.areas<-c(1,2)
prd.areas<-c(3, 4, 5)
cc.areas<-c(6, 7, 8, 9, 10)
sog.areas<-c(14, 15, 16, 17, 18, 19, 20, 28, 29)
wcvi.areas<-c(21, 23, 24, 25, 26)
max.obs<-max(her.data$SPAINDEX/1000)
max.spawn.areas<-length(unique(her.data$LOC_NAME))

her.data<-her.data[which(her.data$STATAREA %in% c(hg.areas,prd.areas)),]