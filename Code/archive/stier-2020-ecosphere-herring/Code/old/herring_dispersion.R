library(ggplot2)
library(reshape2)
library(gdata)
library(maps)
library(mapproj)
library(ggmap)
library(spatstat)
library(ape)
library(bbmle)
library(hotspots)

setwd("~/Dropbox/Projects/In Progress/Pinniped_Herring_HG/Code")
source('theme_acs.R')
source('multiplot.R')

#Spatial Dispersion of Haida Gwaii Herring 


########################################################################
############Index of dispersion (ID) variance/mean
########################################################################
x=read.csv("HG_Spawn_Survey_1940_2013b.csv")
x<- x[c(1,3,13,14,15,16)]
x$SHI2<-log(x$SHI+1)
x$presabs <-ifelse(x$SHI>0,1,0)

yr<-unique(x$year)
id <-c()

for(i in 1:length(yr)){
  temp <-subset(x,year==yr[i])$SHI
  xbar <- mean(temp)
  s2<- var(temp)
  id[i]<-s2/xbar
}

df <- data.frame("year"=yr,
                 "SHI"=melt(c(rowSums(tapply(x$SHI,list(x$year,x$section_name),sum),,na.rm=T)))[,1],
                 "ID"=id
                        )



########################################################################
############Is spatial pattern changing over time
########################################################################


df$MI<-rep(0,length(yr))

for(i in 1:length(yr)){
  temp <-subset(x,year==yr[i])[,c(2,5,6)]
  templl <-subset(x,year==yr[i])[,c(5,6)]
  t.dists <- as.matrix(dist(cbind(templl$Lon, templl$Lat)))
  t.dists.inv <- 1/t.dists
  diag(t.dists.inv) <- 0
  df[i,'MI']<-Moran.I(temp$SHI, t.dists.inv)$observed
}


########################################################################
############Mean Latitude over time 
########################################################################

df$Mlat<-rep(0,length(yr))

for(i in 1:length(yr)){
  temp <-subset(x,year==yr[i])[,c(2,5,6)]
  temp2<-subset(temp,SHI>0)
  df[i,'Mlat']<-mean(temp2$Latitude)
}

df2<- melt(df,id.vars="year")
ggplot(df2,aes(x=year,y=value))+
  geom_point(aes(colour=variable))+
  geom_line(aes(colour=variable))+
  facet_grid(variable~.,scales="free")+
  theme_acs()


########################################################################
############Ripley's K -spatial dispersion
########################################################################

#start out with lat, long, and shi
temp <-subset(x,year==yr[i])[,c(2,5,6)]
mypattern <- ppp(temp[,3], temp[,2],range(temp$Longitude),range(temp$Latitude))
plot(mypattern)
summary(mypattern)
plot(Kest(mypattern))

yr<-unique(x$year)
id <-c()

for(i in 1:length(yr)){
  temp <-subset(x,year==yr[i])$SHI
  xbar <- mean(temp)
  s2<- var(temp)
  id[i]<-s2/xbar
}


#great site for possible quesions to ask
#http://resources.arcgis.com/en/help/main/10.1/index.html#/Spatial_Statistics_toolbox_sample_applic#ations/005p00000004000000/



########################################################################
############What is the median distance to population center 
########################################################################


########################################################################
############What is the mean center of all populations? 
########################################################################
library(cluster)
df <- data.frame(X = rnorm(100, 0), Y = rpois(100, 2))
plot(df$X, df$Y)
points(pam(df, 1)$medoids, pch = 16, col = "red")

########################################################################
############does spatial autocorrelation change through time?
########################################################################

########################################################################
############Where are the hotspots for herring spawn
########################################################################



#starting values for mu and k 
m = mean(temp[,1])
v = var(temp[,1])

m.mom = m
k.mom = m/(v/m - 1)

#second likelihood function where it is the "formula interface"
m1 = mle2(temp~dnbinom(mu = mu,k),start = list(mu = mean(temp), k = k.mom), method ="L-BFGS-B",trace=TRUE,data=temp)


#plot likelihood profile
p1 = profile (m1)
plot (p1)

#quadratic confidence intervals

confint(m1)

