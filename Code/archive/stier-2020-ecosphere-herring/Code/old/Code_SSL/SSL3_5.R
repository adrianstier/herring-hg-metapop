setwd("~/Dropbox/Projects/In Progress/Plan B/DFO_Heatmaps/Code")
setwd("/users/eric.ward/downloads")
setwd("~/Desktop/Code_SSL")

x=read.csv("stellers_dec15_2014.csv",stringsAsFactors=FALSE)


library(ggplot2)
library(reshape2)
library(gdata)
library(maps)
library(mapproj)
library(ggmap)
library(gplots)
library(R2jags)
library(coda)
source('theme_acs.R')
source('multiplot.R')


############################################
#####Spatial Distribution 
############################################

sitex<-subset(x,Region_small=="HaidaGwaii")
sites<-sitex[,c(1,2,3,4,19)]
sites$presabs<-as.numeric((sites$X2013 > 0) & (!is.na(sites$X2013)))
sites$X2013[3]=0
sites$SiteType2 <- ifelse(sites$SiteType=="R","Rookery","Haulout")


#site map
al1 = get_map(location = c(-135,51.5,-131,55), zoom = 7, maptype = 'terrain')
al1MAP = ggmap(al1)

sitesSSL<-al1MAP+
            geom_point(data = sites, aes(x = Longitude, y = Latitude,fill=factor(presabs),size=X2013),pch=21)+
            geom_point(data = sites, aes(x = Longitude, y = Latitude,pch=SiteType2))+
            geom_text(data = sites,aes(x = Longitude, y = Latitude,label=Site),vjust=.1,hjust=-.1)+
            scale_size(range = c(4, 10))+
            ggtitle("Steller Sea Lion 2013")
  
print(sitesSSL)
ggsave("allsites_MAPHG.pdf")

#multiplot(sitesSSL,hmap,cols=2)

#ask whether number of haulouts has increased through time 
head(x)
subset(x,SiteType!="R"&Region_small=="HaidaGwaii")

#melt down to long form 
x2 <- melt(x,id.vars=c(colnames(x)[1:6]))
x2$SiteType2 <- ifelse(x2$SiteType=="R","Rookery","Haulout")
x2$year<-as.numeric(substr(as.character(x2$variable),2,5))
x2$count<-as.numeric(x2$value)
x2$presabs <-ifelse(x2$count>0,1,0)


#number of haultouts through time
ho <-subset(x2,SiteType!="R"&Region_small=="HaidaGwaii")
ho2<-melt(tapply(ho$presabs,list(ho$year),sum,na.rm=T))

gghaul<-ggplot(ho2,aes(x=Var1,y=value))+
geom_line()+
ylab("num haulouts")+
xlab("year")+
theme_acs()

n<-melt(tapply(ho$count,list(ho$year),sum,na.rm=T))
ggnum<-ggplot(n,aes(x=Var1,y=value))+
geom_line()+
ylab("num sea lions")+
xlab("year")+
theme_acs()

pc<-data.frame("year"=n[,1],"percapita"=n[,2]/ho2[,2])
ggpc<-ggplot(pc,aes(x=year,y=percapita))+
geom_line()+
ylab("sea lions per haul out")+
xlab("year")+
theme_acs()

pdf("myplot.pdf",width=3)
multiplot(gghaul,ggnum,ggpc)
dev.off() 


#plot out all the time series for each major region
ggplot(x2,aes(x=year,y=count),group=Site)+
  geom_point(aes(colour=Site,pch=SiteType2))+
  geom_line(aes(colour=Site))+
  facet_wrap(~Region_small,scales="free_y")+
  theme_acs()

ggsave("allsites_TS.pdf")


#just Rookeries
rook <-subset(x2,SiteType=="R")
ggplot(rook,aes(x=year,y=count),group=Site)+
  geom_point(aes(colour=Site,pch=SiteType2))+
  geom_line(aes(colour=Site))+
  facet_wrap(~Region_small,scales="free_y")+
  theme_acs()

ggsave("rookeries_TS.pdf")

#rookeries HG
rookhg<-subset(rook,Site %in% c("GARCIN RKS","CAPE ST. JAMES"))

ggplot(rookhg,aes(x=year,y=count),group=Site)+
  geom_point(aes(colour=Site))+
  geom_line(aes(colour=Site))+
  theme_acs()+
  xlab("Year")+
  ylab("Number of Sea Lions on Rookery")

x2_2013 <-subset(x2,year==2013)
al1 = get_map(location = c(-135,44,-130,55), zoom = 5, maptype = 'terrain')
al1MAP = ggmap(al1)
al1MAP+
  geom_point(data = x2, aes(x = Longitude, y = Latitude,size=count,colour=SiteType2,pch=SiteType2))+
  labs(title="AllSites2013")

ggsave("allsites_Map.pdf")http://127.0.0.1:32689/graphics/plot_zoom_png?width=1200&height=900


#subset Northern Coast
x3 <-subset(x2,Region_large=="NorthernBC")

ggplot(x3,aes(x=year,y=count),group=Site)+
  geom_point(aes(colour=Site,pch=SiteType2))+
  geom_line(aes(colour=Site))+
  facet_wrap(~Region_small,scales="free_y")+
  theme_acs()

ggsave("northerncoast_TS.pdf")

#subset Haida Gwaiia

x4<-subset(x2,Region_small=="HaidaGwaii")
ggplot(x4,aes(x=year,y=count),group=Site)+
  geom_point(aes(colour=Site,pch=SiteType2))+
  geom_line(aes(colour=Site))+
  #geom_smooth(aes(colour=Site),se=F)+
  facet_wrap(~Region_small,scales="free_y")+
  theme_acs()

ggsave("justHG_TS.pdf")


#remove forrester
x4b <- subset(x4,Site!="FORRESTERISLAND")

hgnf<- ggplot(x4b,aes(x=year,y=count),group=Site)+
  geom_point(aes(colour=Site,pch=SiteType2))+
  geom_line(aes(colour=Site))+
  #geom_smooth(aes(colour=Site),se=F)+
  facet_wrap(~Region_small,scales="free_y")+
  theme_acs()+
  ggtitle("Steller Sea Lions by Haul Out")

print(hgnf)
ggsave("justHG_noF_TS.pdf")

multiplot(hgnf,ggher,cols=2)


#just 2013 HG


al1 = get_map(location = c(lon = -132.304474, lat = 53), zoom = 7, maptype = 'terrain')
al1MAP = ggmap(al1)
al1MAP+
  geom_point(data = x4, aes(x = Longitude, y = Latitude,size=count,colour=SiteType2,pch=SiteType2))+
  facet_wrap(~year)

ggsave("HG_AllYears_Map.pdf")


#all years loop map
x4b<-subset(x4,count!="NA"&SiteType2=="Haulout")

####################################
#####Just Haul Out Sites SIZE
####################################

for(i in 1:length(yr)){
temp <- subset(x4b,year==yr[i]&presabs==1)
ggtemp<-ggmap(al1)+
            geom_point(data = temp, aes(x = Longitude, y = Latitude,size=count))+
            scale_size_continuous(limits=c(0,800),range=c(4,10))+
	        theme_acs()+
            ggtitle(paste(yr[i],"_SSL"))
print(ggtemp)
           
            ggsave(paste(yr[i],"_SSL_HauloutOnly.png"))
}


####################################
#####Presence-Absence of Sites
####################################
 
for(i in 1:length(yr)){
temp <- subset(x4b,year==yr[i]&presabs==1)
ggtemp<-ggmap(al1)+
            geom_point(data = temp, aes(x = Longitude, y = Latitude), colour= "yellow")+
	        theme_acs()+
            ggtitle(paste(yr[i],"_SSL"))
print(ggtemp)
           
            ggsave(paste(yr[i],"_SSL_HauloutOnly_presabs.png"))
}



####################################
#####Rookeries
####################################
x4c<-subset(x4,count!="NA"&SiteType2=="Rookery")

for(i in 1:length(yr)){
temp <- subset(x4c,year==yr[i]&presabs==1)
ggtemp<-ggmap(al1)+
            geom_point(data = temp, aes(x = Longitude, y = Latitude,size=count))+
            scale_size_continuous(limits=c(0,4100),range=c(4,10))+
	        theme_acs()+
            ggtitle(paste(yr[i],"_SSL"))
print(ggtemp)
           
            ggsave(paste(yr[i],"_SSL_Rookeries_only.png"))
}
 



al1 = get_map(location = c(-135,51.5,-131,55), zoom = 7, maptype = 'terrain')
yr <- as.numeric(levels(factor(x2$year)))


for(i in 1:length(yr)){
temp <- subset(x4,year==yr[i])
ggtemp<-ggmap(al1)+
            geom_point(data = temp, aes(x = Longitude, y = Latitude,size=count,colour=SiteType2,pch=SiteType2))+
            scale_size_continuous(limits=c(0,3000),range=c(4,10))+
	        theme_acs()+
	        facet_grid(.~ SiteType2)
            ggtitle(paste(yr[i],"_SSL"))
            print(ggtemp)
           
            ggsave(paste(yr[i],"_SSL.png"))
}




hg2013 <- ggmap(al1)+
            geom_point(data = x5, aes(x = Longitude, y = Latitude,size=count,colour=SiteType2,pch=SiteType2))+
            scale_size(range = c(4, 10))+
            theme_acs()+
            ggtitle("2013_SSL")


#just 2013 HG
x5 <- subset(x4,year==2013)
#al1 = get_map(location = c(lon = -132.304474, lat = 53), zoom = 7, maptype = 'terrain')
al1 = get_map(location = c(-135,51.5,-131,55), zoom = 7, maptype = 'terrain')


hg2013 <- ggmap(al1)+
            geom_point(data = x5, aes(x = Longitude, y = Latitude,size=count,colour=SiteType2,pch=SiteType2))+
            scale_size(range = c(4, 10))+
            theme_acs()+
            ggtitle("2013_SSL")

print(hg1992)

ggsave("HG_2013_Map.pdf")

#just 1992
x6 <- subset(x4,year==1992)

hg1992 <- ggmap(al1)+
            geom_point(data = x6, aes(x = Longitude, y = Latitude,size=count,colour=SiteType2,pch=SiteType2))+
            scale_size(range = c(4, 10))+
            theme_acs()+
            ggtitle("1992_SSL")


print(hg1992)

ggsave("HG_1992_Map.pdf")

multiplot(hg1992,hg2013,cols=2)

############################################
#####Build and Evaluate a Model with Space and Time 
############################################

library(R2jags)
library(coda)
library(MARSS)
library(nlme)
library(PBSmapping)
library(reshape2)
library(ggplot2)

source('theme_acs.R')

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


ggplot(hgc,aes(x=year,y=count),group=Site)+
  geom_point(aes(colour=Site,pch=SiteType))+
  geom_line(aes(colour=Site))+
  #geom_smooth(aes(colour=Site),se=F)+
  facet_wrap(~Region_small,scales="free_y")+
  theme_acs()


# #convert the lat longs to decimal degrees 
# #visually exp seems to fit better, but not so great
# locs <- data.frame("X"=hgc$Latitude, "Y"=hgc$Longitude,"PID" =1, "POS" =seq(1,length(hgc$Longitude)))
# 
# 
# #Estimate Distance Matrix. Get 'as the seal swims' from B Blake
# attr(locs,"zone") <- 15 #i use this number as the site number 
# attr(locs, "projection") ="LL"
# locsLL = convUL(locs,southern=FALSE)
# # Now we can create a matrix of distances
# distMat = as.matrix(dist(locsLL[c("X","Y")],upper=T,diag=T))
# # Let's also store a matrix of squared distances
# distMat2 = distMat^2
# 
# #alt dist with rgdal
# library('grdal')
# utm.proj <- "+proj=utm +zone=10 ellps=WGS84" 
# new    <-     cbind(hgc$Longitude,hgc$Latitude)
# new.sp    <- SpatialPoints(new,CRS("+proj=longlat +ellps=WGS84 +datum=WGS84"))
# new.sp.utm    <- spTransform(new.sp, CRS(utm.proj))
# distMat3 = as.matrix(dist(data.frame(new.sp.utm),upper=T,diag=T))
# 
# 
# #jitter for spatial autocor 
# hgc$lat = jitter(hgc$Latitude)
# hgc$lon = jitter(hgc$Longitude)
# 
# #explore correlation function of seal abundance using GLS
# mod.exp = gls(count ~ year, correlation=corExp(form=~lat+lon,nugget=T),data=hgc) 
# mod.gaus = gls(count ~ year, correlation=corGaus(form=~lat+lon,nugget=T),data=hgc)
# 
# var.exp <- Variogram(mod.exp, form =~ lat+lon)
# plot(var.exp,main="Exponential",ylim=c(0,1))
# var.gaus <- Variogram(mod.gaus, form =~ lat+lon)
# plot(var.gaus,main="Gaussian",ylim=c(0,1))

#blake's distance matrix for coastal swim converted to KM
distMat4<-as.matrix(read.csv("h_dist_shore.csv")[,-1]/1000)


############################################
#Set up Matrix for JAGS code 
############################################


# EW: convert this to matrix the long way so it's clear what's going on
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


############################################
#JAGS CODE to fit model 
############################################


jagsscript = cat("
model {  
   # Populations are independent, so the Q matrix is [NOT] diagonal. We'll assume
   # B = 1, and there's no scaling (A) parameters because each time series = 1 state.
   # Unlike MARSS, we can model the trends (U) as random effects - meaning we'll estimate
   # a shared mean and sd across populations, as well as the deviations from that
   Umu ~ dnorm(0,1);
   Usig ~ dunif(0,100);
   Utau <- 1/(Usig*Usig);
   for(i in 1:nSites) {
   U[i] ~ dnorm(Umu,Utau);
   }
   
   tau ~ dgamma(0.01,0.01);
   sigma2 <- 1/tau;
   invEta ~ dgamma(0.01,0.01);
   eta <- 1/invEta;
   logtheta ~ dnorm(0,0.01);
   theta <- exp(logtheta);
   for(i in 1:nSites) {
      for(j in 1:nSites) {
         Q[i,j] <- sigma2 * exp(-theta * distMat4[i,j]) + eta*diag[i,j]; #spatial autocorrelation 
      }
   }   
   # JAGS wants us to use the matrix inverse
   tauQ[1:nSites,1:nSites] <- inverse(Q[1:nSites,1:nSites]); #precision matrix for jags

   # Estimate the initial state vector of population abundances
   for(i in 1:nSites) {
      X[1,i] ~ dnorm(3,0.01); # vague normal prior 
   }
   # Autoregressive process for remaining years
   for(i in 1:nSites) {zeros[i]<-0;} #start first year with mean zero with spatial correlation using the tauQ matrix above
   delta[1,1:nSites] ~ dmnorm(zeros,tauQ[1:nSites,1:nSites]);
   for(i in 2:nYears) {
      delta[i,1:nSites] ~ dmnorm(delta[i-1,1:nSites],tauQ[1:nSites,1:nSites]); 
      for(j in 1:nSites) {
         predX[i,j] <- X[i-1,j] + U[j];
         X[i,j] <- predX[i,j] + delta[i,j];
      }
   }

   # Observation model
   tauR ~ dgamma(0.001,0.001);
   for(i in 1:nYears) {
     for(j in 1:nSites) {
       Y[i,j] ~ dnorm(X[i,j],tauR);
     }
   }
}  

",file="normal_spatialRW.txt")


jags.data = list("diag"=diag(nSites),"Y"=Y, "nYears"=nYears,"nSites"=nSites,"distMat4"=distMat4) # named list

jags.params=c("X","theta","eta","sigma2","U","Umu","Usig","delta","Q") # parameters in the linear regression model
model.loc="normal_spatialRW.txt" # name of the txt file

model = jags(jags.data, parameters.to.save=jags.params,
             model.file=model.loc, n.chains = 3, n.burnin=25000, n.thin=10, n.iter=35000, DIC=TRUE)

attach.jags(model)

#look at iindividual parameter sets
model$BUGSoutput$mean$X
model$BUGSoutput$mean$U
model$BUGSoutput$mean$delta
model$BUGSoutput$mean$theta
model$BUGSoutput$mean$Q

#look at each of the outputs by each run 
names(model$BUGSoutput$sims.list)

#look at the performance of the different chains
matplot(model$BUGSoutput$sims.array[,,16])

#consider grep to look at matching

hist(model$BUGSoutput$sims.matrix[,16])
image(model$BUGSoutput$mean$delta)




















#look at slopes for time
evec<-rep(0,15)
for(i in 1:15){
  evec[i] <-coef(lm(Y[,i]~seq(1:43)))[2]
}

#####
#####OLD
#####
#maps (old)
# m=read.table("pac_coastline.dat",col.names=c("lon","lat"))
# 
# 
# 
# #subset out the lat long regions
# mZ = m[m$lat < 60 & m$lat > 0 & (m$lon > 100 | m$lon < -100),]
# 
# 
# ggplot()+
#   geom_path(data=mZ,aes(x=lon,y=lat))+
#   coord_map(projection="mercator", orientation = c(90, 180, 0),xlim=c(100,250),ylim=c(45,60))+
#   geom_point(data=x5,aes(x=Longitude2,y=Latitude,size=value),colour="red")+
#   theme_acs()
# 

