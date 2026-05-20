library(reshape2)

setwd("~/Dropbox/Projects/In Progress/Pinniped_Herring_HG/Code")
#setwd("/users/eric.ward/downloads")
#setwd("~/Desktop/Code_SSL")

x=read.csv("stellers_dec15_2014.csv",stringsAsFactors=FALSE)

#load data
x=read.csv("stellers_dec15_2014.csv",stringsAsFactors=FALSE)

#replace zeros with NAs
x[x==0] <- NA

hg <- subset(x,Region_small=="HaidaGwaii")

#Estimate  Matrix. Get 'as the seal swims' from B Blake
#visually exp seems to fit better, but not so great
hga <- subset(hg,Site!="") #FORRESTERISLAND
hgb <- melt(hga,id.vars=c(colnames(hga)[1:6])) #melt
#hgb$Longitude<- hgb$Longitude*-1 #reorg long away from china... 
hgb$year<-as.numeric(substr(as.character(hgb$variable),2,5)) #year without load issues
hgb$count<-as.numeric(hgb$value)

#pull out data where there were not counts
hgc <- hgb[which(is.na(hgb$count)==F),]

distMat4<-as.matrix(read.csv("ssl_dist_shore.csv")[,-1]/1000)


############################################
#Set up Matrix for JAGS code 
############################################


#convert this to matrix the long way so it's clear what's going on
hg.names=c("1971", "1973" ,"1977","1982" ,"1987", "1992" ,"1994","1998","2002","2006","2008","2010","2013")
years = seq(1971,2013)
nYears = length(years)
nSites = dim(hg)[1]

#Generate a Matrix that has all sites and all years with NAs for all missing values 
Y = matrix(NA, nSites,nYears)
for(i in 1:nSites) {
  for(j in 1:length(hg.names)) {
    if(is.na(hg[i,j+6])==FALSE) Y[i,as.numeric(hg.names[j])-min(years)+1] = hg[i,j+6]
  }
}
#transpose so year is row and column is site
Y = t(Y)
Y = log(Y)

