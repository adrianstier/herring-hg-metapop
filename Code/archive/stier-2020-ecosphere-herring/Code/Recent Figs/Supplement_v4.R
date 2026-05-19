######################################
#TOC
######################################

#1) Sum of Spawn index at arch and stocklet  scale


### ==================
## LOAD PACKAGES  
## ==================  

library(ggplot2)
library(reshape2)
library(gdata)
library(maps)
library(mapproj)
library(ggmap)
library(coda)
library(gridExtra)
library(Hmisc)
library(PBSmapping)
library(scales)
library("png")
# require("rgdal") # requires sp, will use proj.4 if installed

data(nepacLLhigh)
xlim=c(-134.5,-130)
ylim=c(51.75,54.4)

### ==================
## SET DIRECTORY AND LOAD DATA  
## ==================

setwd("~/Dropbox/Projects/In review/Herring_Haida_Gwaii/Code")


source('theme_acs.R') #plotting fcns
source('multiplot.R')

### ==================
## SET DIRECTORY AND LOAD DATA  
## ==================


x=read.csv("HG_Spawn_Survey_1940_2015.csv") #spawn data
c <- read.csv("herring_catch_local2015.csv") #catch data
load("diag_equal_design_c_noUsig_2q.RData") 

n.chains = 3
n.burnin = 250000
n.thin = 10
n.iter = 500000



#number of recorded mcmc
runL <- n.chains*(n.iter-n.burnin)/n.thin


### ==================
## Years and Sits 
## ==================

years = seq(1950,2015)
nYears = length(years)
nSites = 11


createMcmcList = function(model) {
  McmcArray = as.array(model$BUGSoutput$sims.array)
  McmcList = vector("list",length=dim(McmcArray)[2])
  for(i in 1:length(McmcList)) McmcList[[i]] = as.mcmc(McmcArray[,i,])
  McmcList = mcmc.list(McmcList)
  return(McmcList)
}

#reconstruct MCMC ouput
myList<-createMcmcList(model) #mcmc output 



pdf(paste("Posteriors-Chains-",Sys.Date(),".pdf"),onefile = TRUE,width=6, height=9)



qdf1<-melt(model$BUGSoutput$sims.array[,,"log.q[1]"])
qdf2<-melt(model$BUGSoutput$sims.array[,,"log.q[2]"])
tauRdf<-melt(model$BUGSoutput$sims.array[,,"tauR2"])
pdodf<-melt(model$BUGSoutput$sims.array[,,"pdocoef"])
Umudf<-melt(model$BUGSoutput$sims.array[,,"Umu"])
sigma2df<-melt(model$BUGSoutput$sims.array[,,"sigma2"])

slist<-list(qdf1,qdf2,tauRdf,pdodf,Umudf,sigma2df)
nm<-c("log.q[1]","log.q[2]","tauR2","pdocoef","Umu","sigma2")



for(i in 1:length(slist)){
  temp<-slist[[i]]
  names(temp)<-c("num","chain","value")
  
  gtemp<-ggplot(temp,aes(y=value,x=num,group=chain))+
    geom_line(aes(colour=factor(chain)))+
    theme_acs()+
    ggtitle(nm[i])+
    theme(legend.position="none")
  
  smedian.hilow(temp$value,conf.int=0.95)
  
  
  gtemp2<-ggplot(temp,aes(x=value))+
    geom_histogram()+
    theme_acs()+
    geom_vline(xintercept = 0,colour="red")+
    ggtitle(nm[i])
  
  grid.arrange(gtemp,gtemp2,nrow=2, heights=c(1.2,1.2))
}

dev.off()