######
##SUPPLEMENT
######

######################################
#TOC
######################################

# WHAT IS THE DATA? 
# 0) Tile and Time series plots of catch and spawn data 

# HOW SIMILAR ARE STOCKLETS AND SPAWN THROUGH TIME? 
  #ccf plots for catch and spawn index 

# 1) Model Fit to Spawn Index at Archipelago and Stocklet Scales 
# 2) Model fit to Catch data at Archipelago and Stocklets Scales

# 3) Population Growth and Volatility, Ui, Variance, and CV of all Stocklets 
# 4) Covariance in Biomass across Stocklets, phi, and associated Q 
# 5) Covariance in fishing effort across Stocklets
# 6) Fishing (Pc) boxplot and map showing range of fishing effort by stocklet and across space
# 7) Covariance in process variance across stocklets
*# 8) Do more stocklets spawn in high biomass years 
# 9) Which Stocklet Contributed most to total biomass through time
# 10) Which stocklet Contributed most to spawn biomass after initial closure and most recently
# 11) Does Fishing Effort (Pc) or total Catch (pc*z) Correlate to Stocklet Biomass 
*# 12) Has Fishing been stronger in cold or warm years? 
*# 13) PDO autocorrelaiton through time (strings of warm and cold years)
*# 14) Has the contribution of climate changed through time?
# 15) MCMC Chain and Posteriors for All Parameters
# 16) Pairs plots of some of Major Posteriors 

######################################
#LOAD PACKAGES
######################################
#Turn Model Output into Maps
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
data(nepacLLhigh)
xlim=c(-134.5,-130)
ylim=c(51.75,54.4)



setwd("~/Dropbox/Projects/In review/Herring_Haida_Gwaii/Code")

source('theme_acs.R') #plotting fcns
source('multiplot.R')


######################################
#SET DIRECTORY AND LOAD DATA 
######################################

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


## ==================
## Define Functions 
## ==================

#string modifier
right = function (string, char){
  substr(string,nchar(string)-(char-1),nchar(string))
}


#geometric mean 
gm_mean = function(x, na.rm=TRUE, zero.propagate = FALSE){
  if(any(x < 0, na.rm = TRUE)){
    return(NaN)
  }
  if(zero.propagate){
    if(any(x == 0, na.rm = TRUE)){
      return(0)
    }
    exp(mean(log(x), na.rm = na.rm))
  } else {
    exp(sum(log(x[x > 0]), na.rm=na.rm) / length(x))
  }
}

# getting sigfigs on y axis right
fmt <- function(){
  function(x) format(x,nsmall = 2,scientific = FALSE)
}

#unique expand grid
expand.grid.unique <- function(x, y, include.equals=FALSE)
{
  x <- unique(x)
  y <- unique(y)
  g <- function(i)
  {
    z <- setdiff(y, x[seq_len(i-include.equals)]) 
    if(length(z)) cbind(x[i], z, deparse.level=0)
  }
  do.call(rbind, lapply(seq_along(x), g))
}


createMcmcList = function(model) {
  McmcArray = as.array(model$BUGSoutput$sims.array)
  McmcList = vector("list",length=dim(McmcArray)[2])
  for(i in 1:length(McmcList)) McmcList[[i]] = as.mcmc(McmcArray[,i,])
  McmcList = mcmc.list(McmcList)
  return(McmcList)
}

#reconstruct MCMC ouput
myList<-createMcmcList(model) #mcmc output 


## ==================
## Set up Distance Matrix by Coastline
## ==================

#distance matrix by coastline
distMat4<-as.matrix(read.csv("h_dist_shore.csv")[,-1]/1000)
distMat5<-distMat4[-c(4,7),-c(4,7)]

## ==================
## Define Spawn Data
## ==================

##  Spawn Index

x <- read.csv("HG_Spawn_Survey_1940_2015.csv")
x <- x[c(1,3,13,14,15,16)]
x$presabs <-ifelse(x$SHI>0,1,0)

x2 <- x[,c(1,2,4)]
w <- reshape(x2, 
             timevar   = "section_name",
             idvar     = c("year"),
             direction = "wide")[,-1]

w[w==0] <- NA#replace zeros with NAs
Y= as.matrix(w)
Y = Y[-c(1:10),-c(4,7)] #drop site 4 and 7
Y = log(Y)
logSHI<-Y

ym<-melt(Y)
ym<-data.frame(ym,rep(seq(1:nrow(Y)),ncol(Y)))
names(ym)<-c("crap","site","logSHI","time")

#plot spawn index through time
ggplot(ym,aes(x=time,y=logSHI))+
  geom_point(aes(colour=site))+
  geom_smooth(method="lm")+
  facet_grid(.~site)


## ==================
##  Define Catch data
## ==================

c <- read.csv("herring_catch_local2015.csv")
yr_c<-unique(c$Year)
c$presabs <-ifelse(c$TotalCatch>0,1,0)

unique(c[,c('Section','Name')]) #look at sections and names

c<-drop.levels(subset(c,Section %in% c(1,2,3,5,6,12,21,22,23,24,25)))#subset out Cartwright Sound (4), Masset (11)
ctab<-data.frame(tapply(c$CatchJan_Apr,list(c$Year,c$Name),sum)) #just spring catch

data.frame(colnames(Y),colnames(ctab)) #mismatch column names
ctab2<-ctab[,c(11,7,8,2,5,6,3,9,1,4,10)] #re order so catch table matches spawn table 
data.frame(colnames(logSHI),colnames(ctab2)) #double check column orders match

colnames(logSHI)<-colnames(ctab2)

ctab2<-as.matrix(ctab2)
logcatch<-log(ctab2+1)


#check that catch and spawn data are same format 
data.frame(colnames(Y),colnames(ctab2))




######################################
### MAKE SITE AND SUMMARY TABLE
######################################

#load in site name and location 
st<-read.csv("sitemeta.csv")
st2<-st[-c(4,7),]

#labels for graph
sitelab2<-unique(x$section_name)[-c(4,7)]
md<-data.frame(st2,sitelab2)
md$altsite<-substr(colnames(Y),5,28)



######################################
#1) TIME SERIES AND TILE PLOT OF AVAILABLE CATCH AND SPAWN DATA 
######################################
data.frame(colnames(Y),colnames(ctab2)) #name check

ndf<-data.frame(melt(Y),melt(ctab2))[,c(3:6)]
names(ndf)<-c("spawn","year","stocklet","catch")
ndf[ndf==0] <- NA
ndf$spawn<-scale(ndf$spawn)
ndf$catch<-scale(ndf$catch)
ndf2<-melt(ndf,id.vars=c("year","stocklet"))

ggplot(ndf2,aes(x=year,y=value))+
  geom_line(aes(colour=variable))+
  scale_colour_discrete( h =c(1,260))+
  facet_wrap(~stocklet)+
  theme_acs()

ndf2$bin<-ifelse(ndf2$value>-10,1,0)

ggplot(ndf2,aes(x=year,y=stocklet,fill=factor(bin)))+
  geom_tile(colour="black")+
  scale_fill_discrete( h =c(220,260))+
  facet_grid(.~variable)+
  theme_acs()+
  theme(legend.position="none")+
  scale_x_continuous(limits=c(1950,2015),breaks=c(1950,1960,1970,1980,1990,2000,2010,2020))

matplot(tapply(ndf2$bin,list(ndf2$year,ndf2$variable),sum,na.rm=T)/11,type="l",xlab=c("year"),ylab=c("proportion of sites"))


#plot of spawn data at stocklet and arch scale 

mms<-scale(Y)
mms<-data.frame("year"=seq(1950,2015,1),mms)
mms <- melt(mms,id.vars<-"year")
names(mms) <- c("year","site","shi")

mms2<-subset(mms,shi!="NA")

ggplot(mms,aes(x=year,y=shi,colour=site))+
  geom_hline(yintercept=0,lty=2)+
  geom_line(data=mms2,aes(x=year,y=shi,colour=site),lty=2)+
  geom_line()+
  geom_point(fill="white",pch=21)+
  theme_acs()+
  ylab("Scaled Spawn Index")+
  facet_wrap(~site)

#whole archipelago 

dfa<-data.frame("year"=seq(1950,2015,1),"cumspawn"=scale(rowSums(Y,na.rm=T)))
ggplot(dfa,aes(x=year,y=cumspawn))+
  geom_hline(yintercept=0,lty=2)+
  geom_line()+
  geom_point(fill="white",pch=21)+
  theme_acs()

######################################
#2) WHICH STOCKLETS ARE MOST SIMILAR IN SPAWN INDEX AND CATCH RATES
######################################

covmat<-matrix(NA,nSites,nSites)

for(i in 1:11){
  for(j in 1:11){
    tmp<-data.frame(Y[,i],Y[,j])
    tmp<-tmp[complete.cases(tmp),]
    s1<-ccf(rank(tmp[,1]),rank(tmp[,2]),lag.max=0)
    covmat[i,j]<-s1$acf[,,1]
  }
}

covmat[lower.tri(covmat)] <-NA
diag(covmat) <- NA

colnames(covmat)<-colnames(Y2)
rownames(covmat)<-colnames(Y2)

cdf<-melt(covmat)

#distribution of cross correlations 
ggplot(cdf,aes(x=value,fill=..x..))+
  geom_histogram(colour="black")+
  geom_vline(xintercept=0,lty=2)+
  scale_x_continuous(limits=c(-1,1))+
  scale_fill_gradient2(low="dodgerblue",high="firebrick")+
  ylab("Covariance")+
  theme_acs()

#pairwise cross correlaiton
ggplot(cdf,aes(x=Var1,y=Var2,fill=value,colour=value))+
  geom_tile()+
  scale_fill_gradient2(low="dodgerblue",high="firebrick")+
  scale_colour_gradient2(low="dodgerblue",high="firebrick")+
  theme_acs()+
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position="top")+
  xlab("")+
  ylab("")

######################################
#) FIT OF MODEL TO SPAWN AND CATCH DATA 
######################################

#############
#Predicted versus Observed Biomass 
############


#melt spawn index (SHI) 
y2<-data.frame("time"=seq(1,nYears,1),logSHI)
mm2 <- melt(y2,id.vars<-"time")
names(mm2) <- c("time","site","shi")


#means
tempmat<-model$BUGSoutput$mean$X
colnames(tempmat) <-colnames(logSHI)
temp2<-melt(tempmat)
colnames(temp2) <-c("time","site","X")

tempmatq<-melt(rbind(tempmat[c(1:38),]+median(model$BUGSoutput$mean$log.q[1]),
                     tempmat[c(39:66),]+median(model$BUGSoutput$mean$log.q[2])))

temp2$xq<-tempmatq$value 
temp2$SHI<-melt(logSHI)$value

temp3<-temp2[,c(1,2,4,5)]
temp4<-melt(temp3,id.vars=c("time","site"))

spawn <- subset(temp4,variable=="SHI")
xq <- subset(temp4,variable=="xq")

ggplot()+
  geom_line(data=xq,aes(x=time,y=value,colour=factor(site)))+
  geom_point(data=spawn,aes(x=time,y=value,colour=factor(site)))+
  facet_wrap(~site,scales="free_y")+
  theme_acs()+
  theme(legend.position="none")+
  ggtitle("Predicted (line) and Observed Spawning Biomass (dots)")+
  xlab("Time (years)")+
  ylab("Log Spawning Biomass")



##
tempmat<-model$BUGSoutput$mean$X
colnames(tempmat)<-colnames(Y)
tempmat<-data.frame(exp(tempmat))
tempmat$year<- 1950:2015
tempmat<-melt(tempmat,id.vars=c("year"))
names(tempmat)<- c("year","site","biomass")


ggplot(tempmat,aes(x=year,y=biomass,colour=site,fill=site))+
  geom_area()+
  theme_acs()+
  ylab("Predicted Herring Biomass")+
  xlab("Time")

#subset out Naden harbor and tasu for the smae plot 
tempmat2<-drop.levels(subset(tempmat,site!="SHI.Tasu.Sound...Gowgaia.Bay"))
tempmat2<-drop.levels(subset(tempmat2,site!="SHI.Naden.Harbour"))


ggplot(tempmat2,aes(x=year,y=biomass,colour=site,fill=site))+
  geom_area()+
  theme_acs()+
  ylab("Predicted Herring Biomass")+
  xlab("Time")+
  scale_x_continuous(limits=c(1950,2015),breaks=c(1950,1960,1970,1980,1990,2000,2010,2020))





#acual data 
colnames(Y)
y2<-data.frame("time"=seq(1,nYears,1),Y)
mm2 <- melt(y2,id.vars<-"time")
names(mm2) <- c("time","site","shi")



#means
tempmat<-model$BUGSoutput$mean$X
colnames(tempmat) <-sitelab2
temp2<-melt(tempmat)
colnames(temp2) <-c("time","site","X")

mm3<-data.frame(mm2[,-3],temp2[,'X'])
names(mm3)<-c("time","site","observed","predicted")
mm4<-melt(mm3,id.vars<-c("time","site"))
mm4$value2<-exp(mm4$value)


obs<-subset(mm4,variable=="observed")
pred<-subset(mm4,variable=="predicted")

ggplot()+
  geom_line(data=pred,aes(x=time,y=value2,colour=factor(site)))+
  geom_point(data=obs,aes(x=time,y=value2,colour=factor(site)))+
  facet_wrap(~site,scales="free_y")+
  theme_acs()+
  theme(legend.position="none")+
  ggtitle("Predicted X and Observed SHI_pointsObs")


ggplot(data=obs,aes(x=time,y=value2,colour=factor(site)))+
  geom_point()+
  geom_line()+
  #facet_wrap(~site,scales="free_y")+
  theme_acs()+
  theme(legend.position="none")+
  ggtitle("SpawnIndex")

#area plot of predicted biomass by stocklet 

pred$year<-1950:2015

ggplot(pred,aes(x=year,y=value2,colour=factor(site),fill=factor(site)))+
  geom_area()+
  theme_acs()+
  ylab("Predicted Herring Biomass")+
  xlab("Time")+
  scale_x_continuous(limits=c(1950,2015),breaks=c(1950,1960,1970,1980,1990,2000,2010,2020))



obs2<-subset(obs,site %in% c("SHI.Laskeek.Bay","SHI.Louscoone.Inlet"))
ggplot()+
  #geom_line(data=pred,aes(x=time,y=value2,colour=factor(site)))+
  geom_point(data=obs2,aes(x=time,y=value2,colour=factor(site)))+
  geom_line(data=obs2,aes(x=time,y=value2,colour=factor(site)),lty=2)+
  facet_wrap(~site,scales="free_y")+
  theme_acs()+
  theme(legend.position="none")+
  
  ggtitle("Predicted X and Observed SHI")

obs3<-subset(obs,site %in% c("SHI.Laskeek.Bay","SHI.Juan.Perez.Sound"))

ggplot()+
  #geom_line(data=pred,aes(x=time,y=value2,colour=factor(site)))+
  geom_point(data=obs3,aes(x=time,y=value2,colour=factor(site)))+
  geom_line(data=obs3,aes(x=time,y=value2,colour=factor(site)),lty=2)+
  facet_wrap(~site,scales="free_y")+
  theme_acs()+
  theme(legend.position="none")+
  
  ggtitle("Predicted X and Observed SHI")


mm5<-subset(mm4,variable=="predicted")

ggplot(mm5,aes(x=time,y=value2))+
  geom_line(aes(colour=factor(site)))+
  facet_wrap(~site,scales="free_y")+
  theme_acs()+
  theme(legend.position="none")+
  
  ggtitle("predicted X")




#######CATCH DATA
# tpc<-model$BUGSoutput$mean$Pc
# zpc<-model$BUGSoutput$mean$Z
# xpc<-model$BUGSoutput$mean$X
# 
# colnames(tpc)<-colnames(Y)
# tpc2<-melt(tpc)
# tpc2$year<-1950:2015
# 
# ggplot(tpc2,aes(x=year,y=value))+
#   geom_line(aes(colour=Var2))+
#   facet_wrap(~Var2,ncol=2)+
#   theme_acs()+
#   theme(legend.position="none")+
#   scale_x_continuous(limits=c(1950,2015),breaks=c(1950,1960,1970,1980,1990,2000,2010,2020))+
#   scale_y_continuous(limits=c(0,1),breaks=c(0,0.5,1.0))
# 
# 
# bcatch<-exp(zpc)*tpc
# colnames(bcatch)<-colnames(Y_car)
# colnames(ctab2_1_car)<-colnames(Y_car)
# 
# pcd<-data.frame(melt(bcatch),
#                 melt(ctab2_1_car)
# )
# names(pcd)<-c("year","site1","estimated","site2","reported")
# 
# pcd2<-melt(pcd,id.vars=c("year","site1","site2"))
# 
# pcgg<-ggplot(pcd2,aes(x=year,y=value))+
#   geom_line(aes(colour=variable,lty=variable))+
#   theme_acs()+
#   facet_wrap(~site1,scales="free_y")


# ggsave("catch_estimated_reported.pdf",pcgg)




#How has the number of sites fished changed through time? 
colnames(ctab2)<-colnames(Y)
cf<-melt(data.frame(ctab2,"year"=years),id.vars=c("year"))
cf2<-subset(cf,value>0)

cfts<-tapply(cf2$value,list(cf2$year),length)

# 
# ##Posterior plots
# edf1<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="Pc[1,1]"):which(colnames(myList[[1]])=="Pc[66,11]")]])
# 
# names(edf1)<-c("num","chain","response","value")
# edf1$chain<-factor(edf1$chain)
# edf1$group<-factor(sort(rep(seq(1:11),runL)))
# edf1$year<-sort(rep(seq(1:nYears),runL*nSites))
# names(edf1)<-c("num","chain","response","pc","section","year")

#####
#whole island sum Pc Through time
######
# 
# tpc<-model$BUGSoutput$mean$Pc
# colnames(tpc)<-colnames(Y_car)
# tpc2<-melt(tpc)
# tpc2$years<-years
# tpc3<-subset(tpc2,value>0.02)
# 
# pcd_t<-tapply(tpc3$value,list(tpc3$years),sum)
# pcd_e<-tapply(tpc3$value,list(tpc3$years),mean)
# 
# pcdf_sum<-data.frame("CumulativeCatchRate"=pcd_t,"AverageCatchRate"=pcd_e,"year"=names(pcd_t))
# pcdf_sum$year<-as.numeric(as.character(pcdf_sum$year))
# 
# pcg<-data.frame(melt(cbind(pcd_t,pcd_e)),c(rep("Cumulative Catch Rate",length(pcd_t)),rep("AverageCatchRate",length(pcd_e))))
# colnames(pcg)<-c("year","variable1","value","variable2")
# 
# 
# 
# 
# pcatchgg<-ggplot(pcg,aes(x=year,y=value))+
#   geom_line(aes(colour=variable2))+
#   facet_wrap(~variable2,ncol=1,scales="free_y")+
#   theme_acs()
# 
# print(pcatchgg)
# 







######################################
#) POPULATION GROWTH RATES AND MAP
######################################

###Popultaion Productivity
####Umu and Ui estimates 
Umudf<-melt(model$BUGSoutput$sims.array[,,"Umu"])
Umudf$Var3<-"Umu"
Umudf<-Umudf[,c(1,2,4,3)]
umuci<-smedian.hilow(Umudf$value,conf.int=0.95)
umuci2<-quantile(Umudf$value,c(0.05,0.95))

tlist<-model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="U[1]"):which(colnames(myList[[1]])=="U[11]")]]
dimnames(tlist)[[3]]<-colnames(Y_car)
udf<-melt(tlist)

names(sort(tapply(udf$value,list(udf$Var3),mean),decreasing=T))
levels(udf$Var3)
mean(tapply(udf$value,list(udf$Var3),mean))


udf$Var3=factor(udf$Var3,levels(udf$Var3)[c(11,7,10,2,8,9,3,6,1,4,5)])
#udf$Var3=substr(udf$Var3,5,28)

udf2<- data.frame("umed"=sort(tapply(udf$value,list(udf$Var3),median),decreasing=TRUE),
                  "usd"=tapply(udf$value,list(udf$Var3),median)+tapply(udf$value,list(udf$Var3),sd))

md<-md[c(11,7,8,5,10,3,4,9,2,1,6),] 
md$median_ui<-sort(tapply(udf$value,list(udf$Var3),median),decreasing=TRUE)
md$sd_ui<-tapply(udf$value,list(udf$Var3),median)+tapply(udf$value,list(udf$Var3),sd)



ucomp<-ggplot(udf,aes(x=Var3,y=value))+
  geom_hline(yintercept=median(Umudf$value),lty=1,colour="grey")+
  geom_hline(yintercept= umuci2[1],lty=2,colour="grey")+
  geom_hline(yintercept= umuci2[2],lty=2,colour="grey")+
  stat_summary(fun.data=median_hilow,lty=3,pch=21,fill="white")+
  stat_summary(fun.data=median_hilow,conf.int=0.5)+
  scale_y_continuous(labels = fmt())+
  ylab("Population Growth Rate [Ui]")+
  xlab("")+
  coord_flip()+
  theme_acs()+
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position="none") 

print(ucomp)



hmap <-ggplot()+
  geom_polygon(data=nepacLLhigh,aes(X,Y,group=PID),
               fill = "grey50",color="black") + #darkseagreen
  coord_map(xlim=xlim,ylim=ylim) +
  labs(y="",x="") +
  geom_point(data = md, aes(x = Longitude, y = Latitude,size=median_ui,colour=median_ui))+
  geom_text(data = md,aes(x = Longitude, y = Latitude,label=sitelab2),size=2,vjust=.1,hjust=-.1)+
  scale_colour_gradient2(low="#FF754C",high="#19FFC0",midpoint=mean(md$median_ui))+
  scale_size(range = c(2, 8),name="Pop. Growth Rate")+
  theme_acs()+
  theme(legend.position="right")+
  xlab("Longitude")+
  ylab("Latitutde")

print(hmap)


grid.arrange(ucomp,hmap,ncol=2, heights=c(1.2,1.2))

p = rectGrob()
grid.arrange(hmap,ucomp, ncol=2)



#####################
# ############tau2 -estiamtes of states for each pouplation at each time step 
# #####################
# 
# sdf<-model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="tau2[1]"):which(colnames(myList[[1]])=="tau2[11]")]]
# dimnames(sdf)[[3]]<-colnames(Y)
# sdf<-melt(sdf)
# names(sdf)<-c("num","chain","response","value")
# sdf$chain<-factor(sdf$chain)
# #sdf$section2<-as.character(sort(rep(unique(x$section)[-c(4,7)],nrow(sdf)/nSites)))
# 
# 
# gtemp<- ggplot(sdf,aes(y=value,x=num,group=chain))+
#   geom_line(aes(colour=chain))+
#   theme_acs()+
#   facet_wrap(~response)+
#   theme(legend.position="none")+
#   ggtitle("tau2 Chains")
# 
# 
# gtemp2<-ggplot(sdf,aes(x=value))+
#   geom_bar()+
#   theme_acs()+
#   geom_vline(xintercept = 0,lty=2)+
#   facet_wrap(~response)+
#   ggtitle("tau2 Histogram")
# 
# grid.arrange(gtemp,gtemp2,nrow=2, heights=c(1.2,1.2))
# 
# sdf$response=factor(sdf$response,levels(sdf$response)[c(11,7,10,2,8,9,3,6,1,4,5)])
# 
# 
# scomp<-ggplot(sdf,aes(x=response,y=value))+
#   #   geom_hline(yintercept=median(Umudf$value),lty=2)+
#   #   geom_hline(yintercept= umuci2[1],lty=1,colour="grey")+
#   #   geom_hline(yintercept= umuci2[2],lty=1,colour="grey")+
#   stat_summary(fun.data=median_hilow,lty=3,pch=21,fill="white")+
#   stat_summary(fun.data=median_hilow,conf.int=0.5)+
#   scale_y_continuous(labels = fmt())+
#   ylab("Within Population Variance [Sigma2]")+
#   xlab("")+
#   coord_flip()+
#   theme_acs()+
#   theme(axis.text.x = element_text(angle = 45, hjust = 1),
#         legend.position="none")  
# 
# print(scomp)
# ggsave("Sigma2_AllSites.pdf",scomp)
# 
# #IQR for U and Sigma2
# udat<-ggplot_build(ucomp)$data[[5]]
# sdat<-ggplot_build(scomp)$data[[2]]
# 
# combd<-data.frame(udat,sdat)[,c(1,3,4,5,9,10,11)]
# colnames(combd)<-c("site","umed","xmax","xmin","smed","ymax","ymin")
# combd<-combd[with(combd, order(-umed)), ]
# combd$site<-md$Name
# 
# uisigmai<-ggplot(data = combd,aes(x = umed,y = smed,colour=site)) + 
#   geom_point() + 
#   geom_errorbar(aes(ymin = ymin,ymax = ymax)) + 
#   geom_errorbarh(aes(xmin = xmin,xmax = xmax))+
#   #geom_smooth(colour="black",se=F,method="lm")+
#   theme_acs()+
#   xlab("Population Growth Rate [Ui]")+
#   ylab("Population Variance [Sigma2i]")
# 
# print(uisigmai)
# ggsave("Productivity-Variance.pdf",uisigmai)
# 
# ggplot_build(uisigmai)

# #############################
# ##CV: Estimate the coefficient of variation for the entire population and for each stocklet 
# #############################
# umudf<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="Umu")]])
# usigdf<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="Usig")]])
# pairdf<-data.frame("GrandMean"=umudf[,3],"GrandVar"=usigdf[,3],"chain"=usigdf[,2])
# 
# ggplot(pairdf,aes(x=GrandMean,y=GrandVar,colour=factor(chain)))+
#   geom_point()+
#   theme_acs()
# 
# grandcv<-data.frame("param"=rep("GrandCV",nrow(pairdf)),"CV"=pairdf$GrandVar/pairdf$GrandMean)
# 
# ggplot(grandcv,aes(x=param,y=CV))+
#   stat_summary(fun.data=median_hilow,lty=2)+
#   stat_summary(fun.data=median_hilow,conf.int=0.5)+
#   theme_acs()
# 
# #by stocklet
# 
# combd$cv<-combd$smed/combd$umed
# 
# #without error bars
# ggplot(combd,aes(x=site,y=cv))+
#   geom_bar(stat="identity")+
#   coord_flip()+
#   theme_acs()
# 
# 
# sdf2<-model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="tau2[1]"):which(colnames(myList[[1]])=="tau2[11]")]]
# dimnames(sdf2)[[3]]<-colnames(Y_car)
# sdf2<-melt(sdf2)
# 
# udf2<-model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="U[1]"):which(colnames(myList[[1]])=="U[11]")]]
# dimnames(udf2)[[3]]<-colnames(Y_car)
# udf2<-melt(udf2)
# 
# slist<-unique(udf2$Var3)
# 
# cdf<-sdf2
# cdf$value2<-udf2[,'value']
# cdf$cv<-cdf$value/cdf$value2
# 
# names(cdf)<-c("iter","chain","site","sd","mean","cv")
# 
# ggplot(cdf,aes(x=site,y=cv))+
#   #stat_summary(fun.data=median_hilow,lty=2)+
#   stat_summary(fun.data=median_hilow,conf.int=0.5)+
#   coord_flip()+
#   theme_acs()
# 
# 
# 
# 

######################################
#) DOES POPULATION GROWTH OR BIOMASS COVARY BY GEOGRAPHIC DISTANCE?
######################################

expand.grid.unique <- function(x, y, include.equals=FALSE)
{
  x <- unique(x)
  y <- unique(y)
  g <- function(i)
  {
    z <- setdiff(y, x[seq_len(i-include.equals)]) 
    if(length(z)) cbind(x[i], z, deparse.level=0)
  }
  do.call(rbind, lapply(seq_along(x), g))
}



#distance matrix by coastline
distMat4<-as.matrix(read.csv("h_dist_shore.csv")[,-1]/1000)
distMat5<-distMat4[-c(4,7),-c(4,7)]
distMatcar<-distMat5[c(8,9,10,7,11,5,1,4,3,2,6),c(8,9,10,7,11,5,1,4,3,2,6)]


distMate<-as.matrix(read.csv("h_dist_euc.csv")[,-1]/1000)
distMate2<-distMate[-c(4,7),-c(4,7)]
distMatecar<-distMate2[c(8,9,10,7,11,5,1,4,3,2,6),c(8,9,10,7,11,5,1,4,3,2,6)]


###############

u<-md$median_ui
u<-u[c(3,8,5,2,1,4,10,7,6,9,11)]


# emat<-matrix(NA,nrow=100,ncol=1)
# cb<-seq(1:11)


dd<-expand.grid.unique(seq(1:11),seq(1:11))
ddn<-expand.grid.unique(names(u),names(u))
emat<-matrix(NA,nrow=nrow(dd),ncol=3)

for(i in 1:nrow(dd)){
  tmp<-dd[i,]
  emat[i,1]<-distMatcar[tmp[1],tmp[2]]
  emat[i,2]<-distMatecar[tmp[1],tmp[2]]
  emat[i,3]<- u[tmp[1]] - u[tmp[2]]
}

dd2<-data.frame(dd,ddn,emat)
names(dd2)<-c("site1","site2","site1n","site2n","distance_fish","distance_bird","udiff")
# dd2$site1n=factor(dd2$site1n,levels(dd2$site1n)[c(8,1,4,3,9,5,10,2,7,6)])
# dd2$site2n=factor(dd2$site2n,levels(dd2$site2n)[c(names(u))])


dd3<-melt(dd2,id.vars=c("site1","site2","site1n","site2n","udiff"))

udd<-ggplot(dd3,aes(x=value,y=udiff))+
  geom_point()+
  geom_smooth(method="lm",se=F,colour="black")+
  theme_acs()+
  facet_wrap(~variable,scales="free")+
  xlab("Distance")+
  ylab("Difference in median productivity (Ui-Ui)")

ggsave("Udiff_byDistance.pdf",udd)

####absolute value of difference in Ui

covmat<-matrix(NA,nSites,nSites)

#lag0
for(i in 1:11){
  for(j in 1:11){
    covmat[i,j]<-(u[i]-u[j])
  }
}

covmat[lower.tri(covmat)] <-NA
diag(covmat)<-NA

colnames(covmat)<-names(u)
rownames(covmat)<- names(u)

udiffm<-melt(covmat)
##################


#All different groups
udabs<-ggplot(udiffm,aes(x=Var1,y=Var2,fill=value,colour=value))+
  geom_tile()+
  scale_fill_gradient(low="white",high="orange")+
  scale_colour_gradient(low="white",high="orange")+
  theme_acs()+
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position="top")+
  xlab("")+
  ylab("")

# ggsave("udiff_matrix.pdf",udabs)

uihg<-ggplot(udiffm,aes(x=value,fill=..x..))+
  geom_histogram(colour="black")+
  geom_vline(xintercept=0,lty=1)+
  geom_vline(xintercept=umuci[1],lty=2)+
  scale_x_continuous(limits=c(-1,1))+
  scale_fill_gradient2(low="dodgerblue",high="firebrick")+
  ylab("Difference in Pop. Growth Rate [delta Ui]")+
  theme_acs()

# ggsave("udiff_hist.pdf",uihg)








########################################################################
############PDO EFFECT THROUGH TIME AND 
########################################################################

#load pdo
pdo<-read.csv("pdo.csv")
pdosummer<-subset(pdo,month %in% c(3,4,5,6)) #average april<-june
pdoxb<-c(tapply(pdosummer$Value,list(pdosummer$year),mean))
pdo2<-pdoxb[87:162] #1940-20135
pdo3<-pdo2[11:76] #1950-2015
plot.ts(pdo3)

pdocoef<-model$BUGSoutput$mean$pdocoef


distpdoci<-smedian.hilow(pdocoef,conf.int=0.95)
distpdoiqr<-smedian.hilow(pdocoef,conf.int=0.5)

pdodf<-data.frame("pdo"=pdo3,
                  "medianci"=distpdoci[1]*pdo3,
                  "maxci"=distpdoci[3]*pdo3,
                  "minci"=distpdoci[2]*pdo3,
                  "maxiqr"=distpdoiqr[3]*pdo3,
                  "miniqr"=distpdoiqr[2]*pdo3
)

pdodf$year<-as.numeric(rownames(pdodf))

pdodf$hc<-ifelse(pdodf$medianci>0,"hot","cold")

pdotsgg<-ggplot(pdodf,aes(x=year,y=medianci))+
  geom_hline(yintercept=0,size=1)+
  geom_ribbon(aes(ymin=minci,ymax=maxci),fill="grey30",alpha=0.2)+
  geom_ribbon(aes(ymin=miniqr,ymax=maxiqr),fill="grey")+
  geom_point(aes(colour=hc))+
  # scale_colour_discrete(low="firebrick",high="dodgerblue")+
  geom_line(lty=2)+
  theme_acs()+
  ylab("PDO Effect (PDO*PDOcoef)")+
  xlab("Year")+
  scale_x_continuous(limits=c(1950,2015),breaks=c(1950,1960,1970,1980,1990,2000,2010,2020))


print(pdotsgg)

md$Name2<-c("Skincuttle","Juan Perez","Skidegate","Louscoone","Laskeek","Rennell","Englefield","Cumshewa","Port Louis","Tasu","Naden")

pdog<-ggplot(pdodf,aes(x=medianci,fill=..x..))+
  geom_histogram(colour="black")+
  geom_vline(xintercept=0,lty=1)+
  geom_vline(xintercept=umuci[1],lty=2)+
  geom_vline(xintercept=umuci[2],lty=1,colour="grey")+
  geom_vline(xintercept=umuci[3],lty=1,colour="grey")+
  #geom_text(data=md,aes(x=median_ui,y=0,label=Name2),angle=45)+
  #geom_vline(xintercept=md$median_ui,colour="grey",lty=2)+
  #scale_x_continuous(limits=c(-1,1))+
  scale_fill_gradient2(low="firebrick",high="dodgerblue")+
  xlab("PDO Effect (PDO*PDOcoef")+
  ylab("Frequency")+
  theme_acs()
print(pdog)

# ggsave("PdoHistogram.pdf",pdog)

pdodf2<-data.frame(site=rep("pdocoef",nrow(pdodf)),pdodf)

ggplot(pdodf2,aes(x=site,y=medianci))+
  geom_boxplot()+
  geom_point(aes(colour=medianci))+
  scale_colour_gradient2(low="firebrick",high="dodgerblue")+
  coord_flip()+
  theme_acs()+
  scale_y_continuous(limits=c(-0.10,0.4),breaks=c(-0.1,0,0.1,0.2,0.3,0.4))


head(pdodf)






#COVARIANCE OF PREDICTED STOCK BIOMASS
xmat<-model$BUGSoutput$mean$Z #can look at Z here perhaps to look at pre fishery biomass correlation
colnames(xmat)<-colnames(Y)

covmat<-matrix(NA,nSites,nSites)

#lag0
for(i in 1:11){
  for(j in 1:11){
    tmp<-data.frame(xmat[,i],xmat[,j])
    tmp<-tmp[complete.cases(tmp),]
    tmp<-subset(tmp,tmp[,1]>0.011 | tmp[,2]>0.011) #subset out zeros in one or both columns 
    s1<-ccf(rank(tmp[,1]),rank(tmp[,2]),lag.max=0)
    covmat[i,j]<-s1$acf[,,1]
  }
}


covmat[lower.tri(covmat)] <-NA
diag(covmat) <- NA

colnames(covmat)<-colnames(Y)
rownames(covmat)<-colnames(Y)

cdf<-melt(covmat)
# cdf$Var1<-substr(cdf$Var1,5,28)
# cdf$Var2<-substr(cdf$Var2,5,28)

#reorder so that there in the same order as distMat5
#c(7,10,9,8,6,5,)

xccfgg<-ggplot(cdf,aes(x=value,fill=..x..))+
  geom_histogram(colour="black")+
  geom_vline(xintercept=0,lty=2)+
  #scale_x_continuous(limits=c(-1,1))+
  scale_fill_gradient2(low="dodgerblue",high="firebrick")+
  ylab("Frequency")+
  xlab("Pairwise Cross Correlaiton of Estimated pre-catch Biomass")+
  theme_acs()



#All different groups
ccfmat<-ggplot(cdf,aes(x=Var1,y=Var2,fill=value,colour=value))+
  geom_tile()+
  scale_fill_gradient2(low="dodgerblue",high="firebrick")+
  scale_colour_gradient2(low="dodgerblue",high="firebrick")+
  theme_acs()+
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position="top")+
  xlab("")+
  ylab("")

multiplot(xccfgg,ccfmat,cols=2)

#####################
############FISHING EFFECTS 
#####################


