library(ggplot2)
library(reshape2)
library(gdata)
library(maps)
library(mapproj)
library(ggmap)
library(gplots)
library(R2jags)
library(coda)
library(gridExtra)
library(Hmisc)

setwd("~/Dropbox/Projects/In Progress/Herring_Haida_Gwaii/Code")
#setwd("~/Dropbox/Projects/In Progress/Code")
#setwd("~/Desktop/Herring_Section")
source('multiplot.R')
source('theme_acs.R')

x=read.csv("qad.csv")

#all stocks
ggplot(x,aes(x=YEAR,y=STARTDOY))+
  stat_summary(fun.data=mean_cl_normal)+
  geom_smooth(se=FALSE)+
  theme_acs()+
  ylab("Start of Spawn DOY")+
  xlab("Year")+
  ggtitle("All Spawning Stocks")



#for Haida Gwaii
hg<-subset(x,STATAREA %in% c(1,2,3,5,6,11,12,21,23,24,25))

ggplot(hg,aes(x=YEAR,y=STARTDOY))+
  stat_summary(fun.data=mean_cl_normal)+
  geom_smooth(se=FALSE)+
  theme_acs()+
  ylab("Start of Spawn DOY")+
  xlab("Year")+
  ggtitle("Haida Gwaii")

#by section
ggplot(hg,aes(x=YEAR,y=STARTDOY,colour=factor(STATAREA)))+
  stat_summary(fun.data=mean_cl_normal)+
  geom_smooth(se=FALSE)+
  theme_acs()+
  theme(legend.position="none")+
  facet_wrap(~STATAREA,scales="free")+
  ylab("Start of Spawn DOY")+
  xlab("Year")+
  ggtitle("Haida Gwaii")





