rm(list=ls())
######################################################################################################
#INPUT REAL DATA TO USE WHEN SIMULATING FAKE DATA 
######################################################################################################

#Potential solutions
#non log scale observation model 
#Q1: how are you assessing convergence? Things can be mixing slowly but converged... solution is to run longer chains.
#Q2: Which Xs and Pcs are having trouble? My guess would be that they are location-time combinations that have no data (either no spawn surveys or no observed catch or both).  If so, the Pcs and Xs are likely confounded.  This can be revealed by pairs plot.
#Fix Pc to zero when c_obs zero
#drop the spatial model 
#change the observation model for catch to be not log scale 
#3) If I understand the code correctly ctab and Y are the actual data for catch and spawn index, respectively. Are they formatted appropriately when they get ingested into JAGS?
#4) Which chains are getting stuck and where? I would start by dragging them away from zero with more informative priors, one by one.
#6) in your simulator, reduce the number of site-years with missing data and/or zeroes and see if the estimator works
#7) delta[i-1?]
#8) big.var of Z[1,j]
#9) Pc initial value
#10) AS changed to 1,2    ctab[INDEX[k,1],INDEX[k,2]] ~ dnorm((tl[INDEX[k,1],INDEX[k,2]]),1/psi) #distribution of catch data  LIKELIHOOD STATEMENT ****  

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
library(MASS)
library(Hmisc)

#Data Simulation

setwd("~/Dropbox/Projects/In Progress/Herring_Haida_Gwaii/Code")
source('multiplot.R')
source('theme_acs.R')

#setwd("/Users/ole.shelton/Documents/Adrian")
#setwd("~/Desktop/Imac_Herring_4_14")
#setwd("/Users/AdrianStierMBP2015/Dropbox/Projects/In Progress/pinniped_herring_hg/Imac_Herring_4_14")


######################################################################################################
#INPUT REAL DATA TO USE WHEN SIMULATING FAKE DATA 
######################################################################################################

## ==================
##  PDO
## ==================
#load pdo
pdo<-read.csv("pdo.csv")
pdosummer<-subset(pdo,month %in% c(3,4,5,6)) #average march<-june
pdoxb<-c(tapply(pdosummer$Value,list(pdosummer$year),mean))
pdo2<-pdoxb[97:162] #1940-2015
#pdo3<-pdo2[11:76] #1950-2013


## ==================
##  Spawn dat
## ==================
#spawn data
## ==================
##  Spawn Index
## ==================
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


svec<-unique(ym$site)
emat<-matrix(nrow=length(svec),ncol=2)
rownames(emat)<-svec

for(i in 1:length(svec)){
  temp<-subset(ym,site==svec[i])
  m1<-lm(temp$logSHI~temp$time)
  emat[i,1]<-coef(m1)[2]
  emat[i,2]<-summary(m1)$coef[4]
}

emat<-data.frame(emat)
colnames(emat)<-c("slope","slopeSE")   
mean(emat[,1])
sd(emat[,1])

aveSHI <- tapply(ym$logSHI,list(ym$site),mean,na.rm=TRUE)
sdSHI  <- tapply(ym$logSHI,list(ym$site),mean,na.rm=TRUE)

svec<-unique(ym$site)

## ==================
##  Catch data
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



## ==================
##  Set Params for Fake Data
## ==================
set.seed(11)

#I'll go through and define each of these parameters
# pdocoef_sim - simulated pdo effect
# uvec - vector of growth rates at given site
# Pc_sim - simulated proportion caught in each year
# c_prior_sim - simulated prior for the simulation 
# sigma2_sim - simulated site variance for each site
# delta_sim - simulated process variance fore each site/time
# xmat - after fishing biomass
# tauR_sim - simulated error in spawn index to spawn biomass converstion
# psi_sim - simulated error in observed versus estimated catch

## ==================
##  #Strength of PDO effect - **pdocoef** 
## ==================

pdocoef_sim<- -0.1 #pdo coefficient with negative sign, i.e.  cold water is good

## ==================
##  Population Growth - **U** Vec Estimate Slope time series for 9 Sites 
## ==================

umat<-matrix(nrow=length(svec),ncol=2)
rownames(umat)<-svec

for(i in 1:length(svec)){
  temp<-subset(ym,site==svec[i])
  m1<-lm(temp$logSHI~temp$time)
  umat[i,1]<-coef(m1)[2]
  umat[i,2]<-summary(m1)$coef[4]
}

umat<-data.frame(umat)
colnames(umat)<-c("slope","slopeSE")   

#make U's hierarchical 
Umu_sim  <- 0.2 #mean(umat[,1])
Usig_sim <- 0.1 #sd(umat[,1]) #could loosen this 
uvec<-rnorm(nSites,Umu_sim,Usig_sim)

## ==================
##  Catch Data: Fraction of Catch at Each site-time combiantion - **Pc** and Prior for Pc c_prior
## ==================

#make up some fishing impacts by proportion ranging from 0 to 1 
Pc_sim<-matrix(NA,nrow=nYears,ncol=nSites)

#Base the values on level of observed fishing
for(i in 1:nYears){
  for(j in 1:nSites){	
    Pc_sim[i,j]<-ifelse(logcatch[i,j]>0,
                        runif(1,0.001,0.5), #turn up/down fishing here
                        0
                        )
  }
}


## ==================
##  Catch Priors and Design matrix 
## ==================

#
#make a prior matrix that sets the upper bound of the uniform distribution for prior Pc to be 0.95 when it's a non-zero and 0.01 when it's zero

nonz        <- which(Pc_sim>0)
c_prior_sim <- matrix(0.95,nrow=nrow(Pc_sim),ncol=ncol(Pc_sim))
design.c    <- ifelse(Pc_sim>0,1,0)

## ==================
##  Variance (sigma2)
## ==================

sigma2 <- 0.3 # dgamma(0.01,0.01)
sigma2_sim = NA

for(i in 1:nSites){
  sigma2_sim[i] <-sigma2 #same variance across all sites, could pull form normal (rnorm(0,sigma2), but watch for negatives)
}

delta_sim<-matrix(nrow=nYears-1,ncol=nSites)
  for(j in 1:nSites){
    delta_sim[,j] <- rnorm(nYears-1,-0.5*sigma2_sim[j],sqrt(sigma2_sim[j])) 
  }

## ==================
##  Spawn Biomass X* and Spawn Biomass Plus Catch Z* First simulate starting, then to nYears
## ==================

#empty matrices
zmat<-matrix(NA,nrow=nYears,ncol = nSites) 
xmat<-matrix(NA,nrow=nYears,ncol = nSites)

#STARTING VALUES
#change starting values to be average of SHI time series
catch_sim<-matrix(NA,nrow=nYears,ncol=nSites)

# This is the observation error in spawn index (normal in log space)
tauR2_sim <- 0.5
# This is the observation error in catch (normal in log space)
psi2_sim  <- 0.0001


for(j in 1:nSites){
  zmat[1,j]      <- rnorm(1,aveSHI[j],1) #assume pre catch biomass (Z) is distriubted log SHI 
  catch_sim[1,j] <- zmat[1,j] + log(Pc_sim[1,j]) #calculate catch
  catch_sim[1,j] <- ifelse(catch_sim[1,j]>0,catch_sim[1,j],0) #deal with log(0)
  xmat[1,j]      <- zmat[1,j] - catch_sim[1,j]
}

#simulate 2:nYears
for(j in 1:nSites){
  for(i in 2:nYears){
    zmat[i,j]     <- xmat[i-1,j] + uvec[j] + delta_sim[i-1,j] + pdocoef_sim*pdo3[i] 
    xmat[i,j]     <- zmat[i,j] + log(1-Pc_sim[i,j]) 
    catch_sim[i,j]<- zmat[i,j] + log(Pc_sim[i,j]) #fish caught
    catch_sim[i,j]<-ifelse(catch_sim[i,j]>0,catch_sim[i,j],0) #deal with log(0)
  }
}

#could add in the NAs
#need to add constant like in real model *****

mm<-melt(xmat)
mm$value2<-exp(mm$value)

ggplot(mm,aes(x=Var1,y=value,group=factor(Var2)))+
  geom_line(aes(colour=factor(Var2)))+
  facet_wrap(~Var2,scales="free_y")+
  #theme_acs()+
  theme(legend.position="none")

## ==================
## adjust true X to include catchability (q)
## ==================

#add a Q of 2, with no error
log_q_sim    <- 0.7

#add a q conversion for SHI-->spawn biomass (x)
SHI_sim <- xmat+log_q_sim
SHI_obs <- matrix(rnorm(length(SHI_sim),SHI_sim,sqrt(tauR2_sim)),nrow(SHI_sim),ncol(SHI_sim))
  
mmshi<-melt(SHI_obs)
names(mmshi)<- c("year","site","SHI")
mmshi$x<-mm$value
mmshi$site = factor(mmshi$site)

ggplot(mmshi,aes(x=SHI,y=x,colour=site))+
  geom_point()+
  geom_abline(slope=1,intercept=0,lty=2)+
  facet_wrap(~site,scales="free")+
  theme_acs()

## ==================
## Estimating Catch Rates Only in Sites where Catch Reported
## ==================

#Identify Which Row-Column Combinations Where Catch>0
INDEX      <- NULL  
INDEX.zero <- NULL  
for(i in 1:nrow(catch_sim)){
  
  if(length(catch_sim[i,][catch_sim[i,]>0])>0){ 
    temp   <- data.frame(row = rep(i,length(which(catch_sim[i,]>0))),col = which(catch_sim[i,]>0))
    INDEX <- rbind(INDEX,temp)
  }
  
  if(length(catch_sim[i,][catch_sim[i,]==0])>0){ 
    temp.2 <- data.frame(row = rep(i,length(which(catch_sim[i,]==0))),col = which(catch_sim[i,]==0))
    INDEX.zero <- rbind(INDEX.zero,temp.2)
  }
}
  
nIndex      <- nrow(INDEX) #nubmer of row-column combinations with catch>0
nIndex.zero <- nrow(INDEX.zero) #nubmer of row-column combinations with catch>0

Catch.dummy <- catch_sim
Catch.dummy[Catch.dummy > 0] <- 1 #put 1 in places where >0 catch

# ##read in INDEX, nIndex, and Catch.dummy as data in jags.data



## ==================
## JAGS CODE to fit model
## ==================

#Begin JAGS code
jagsscript = cat("
                 model {  
                
##########################
#OBSERVATION MODEL PRIORS and LIKELIHOODs
##########################

log.q ~ dnorm(0,(1/0.1));  #Catchability Conversion from Spawn Index to Spawn Biomass 
tauR2  ~ dgamma(0.001,0.001); #this is the estimated variance prior for Spawn Index to Spawn Biomass Conversion
#psi   ~ dunif(0,0.01) #this is in variance for fishing set fixed to try to get convergence

# Prop. Catch (pc) Prior  (USES INDEX to find row-column combinations) for prior 
for(k in 1:nIndex){
         Pc[k] ~ dunif(0,0.95)
}
                 
for(i in 1:nYears) {
  for(j in 1:nSites) {
    Y[i,j] ~  dnorm(X[i,j]+log.q ,1/tauR2); #obs eq for spawn index. a normal pull with meam Xq LIKELIHOOD STATEMENT ****
  }
}


for(k in 1:nIndex){
    Pc.mat[INDEX[k,1],INDEX[k,2]] <-  Pc[k] 
    tl[INDEX[k,1],INDEX[k,2]]     <- Z[INDEX[k,1],INDEX[k,2]] + log(Pc[k])   #total catch
    ctab[INDEX[k,1],INDEX[k,2]]   ~ dnorm((tl[INDEX[k,1],INDEX[k,2]]),1/0.0001) #distribution of catch data  LIKELIHOOD STATEMENT ****  
}
for(k in 1:nIndex.zero){
    Pc.mat[INDEX.zero[k,1],INDEX.zero[k,2]] <- 0
}


##########################
#PROCESS MODEL PRIORS
##########################

# POPULATION GROWTH parameters U: 
Umu   ~  dnorm(0,1); #average population growth
Usig2 ~  dunif(0,100) #variance in population growth 

for(j in 1:nSites) {
  U[j] ~ dnorm(Umu,1/Usig2) #for each site U set as random variable prior 
}

#COVARIATE
pdoz2   <- 1
pdocoef ~ dnorm(0,1/pdoz2); #estimated impact of pdo of herring

#VARINCE MATRIX - Diagonal and Equal - same variance all sites 

# For indepenent and equal variances
sigma2 ~ dgamma(0.001,0.001); #set initial


for(j in 1:nSites) {
  sigma2.all[j] <- sigma2; #replicate initial value for all sigma2
}
    

# Estimate the initial state vector of population abundances

for(j in 1:nSites) {
      Z[1,j] ~ dnorm(5,1/100); # vague normal prior for first time step #changed from inverse 3/31
      X[1,j] <- Z[1,j] + log(1-Pc.mat[1,j]) # changed to reflect handwritten model 3/31
  }


#  Delta Prior

for(i in 1:(nYears-1)){
  for(j in 1:nSites) {
    delta[i,j] ~ dnorm(-0.5*sigma2.all[j],1/sigma2.all[j]) #changed from inverse 3/31
  }
}

      
for(i in 2:nYears){
  for(j in 1:nSites) {

  #fishing by site and global pdo estimates and U estimates 
  Z[i,j] <- X[(i-1),j]+U[j]+pdocoef*pdo[i-1]+delta[(i-1),j]

  #Estimate the state X with catch by site 
  X[i,j] <-Z[i,j]+log(1-Pc.mat[i,j]);

 }
}

} 
 ",file="simulator_diagonal_equal_var_olecatch.txt")


#data going into the model
jags.data = list("Y"=SHI_obs, "nYears"=nYears,"nSites"=nSites,"pdo"=pdo3,"ctab"=catch_sim,
                 "INDEX"=INDEX,"INDEX.zero"=INDEX.zero, "nIndex"=nIndex,"nIndex.zero"=nIndex.zero) # named list

jags.params=c("X","sigma2","U","Umu","Usig2","delta","Z","pdocoef","log.q","Pc","tauR2")#,"psi") # parameters in the linear model


model.loc="simulator_diagonal_equal_var_olecatch.txt" # name of the txt file

n.chains = 4
n.burnin = 15000
n.thin = 2
n.iter   = 20000

#number of recorded mcmc
runL <- n.chains*(n.iter-n.burnin)/n.thin

inits = NULL

#need to add the inits for the Pc and q params

for(i in 1:n.chains){
  inits[[i]]    <- list(
    "Umu" = rnorm(1,0,0.1), #alt just make it a little lower? 0.5 seems more realisitc
    "Usig2" = runif(1,0,1),
    "pdocoef" = rnorm(1,0,0.1),
    "log.q" = rnorm(1,0,0.1),
    "tauR2" = runif(1,0,1)
    #"delta" = matrix(runif(1,.05,1),nrow=nYears-1,ncol=nSites),
    #"Pc" = matrix(1e-07,nrow=nYears,ncol=nSites),
    #"psi" = runif(1,0,0.01),
    ) 
}
    
model = jags(jags.data, inits=inits,parameters.to.save=jags.params,
            model.file=model.loc, n.chains = n.chains, n.burnin=n.burnin, n.thin=n.thin, n.iter=n.iter, DIC=TRUE)

attach.jags(model)

# 
# model.p = list(jags.data.p1, inits=inits,parameters.to.save=jags.params,
#              model.file=model.loc, n.chains = 3, n.burnin=n.burnin, n.thin=n.thin, n.iter=n.iter, DIC=TRUE)
# 
# mod.fit <- do.call(jags.parallel,model.p) 

# timer.start <- proc.time()
# (run.time.in.min <- round(((proc.time()-timer.start)/60)["elapsed"], 0))

mDIC<-model$BUGSoutput$DIC 
pD<-model$BUGSoutput$pD
devi<-model$BUGSoutput$deviance

save("model","mDIC","X","sigma2","U","Umu","Usig2","Z","delta","sigma2","pdo","pdocoef","Pc","log.q","tauR2",#"psi",
     "log_q_sim","psi_sim","pdocoef_sim","Umu_sim","Usig_sim","tauR2_sim","sigma2_sim","design.c",
     file="simulator_diag_equal_design.c.RData")

jags.params=c("X","sigma2","U","Umu","Usig2","delta","Z","pdocoef","log.q","Pc","tauR2")#,"psi") # parameters in the linear model


#load("herring_jags_F_11sites_diag_equal_var_v2.RData")
load("simulator_diag_equal_design.c.RData")
########################################################################
############Quick Summary of Model Parameters
########################################################################

#names of array 

#head(model$BUGSoutput$sims.array)

#look at individual parameter means
model$BUGSoutput$mean$Pc
model$BUGSoutput$mean$X
model$BUGSoutput$mean$delta
model$BUGSoutput$mean$sigma2
model$BUGSoutput$mean$U
model$BUGSoutput$mean$Umu
model$BUGSoutput$mean$Usig2
model$BUGSoutput$mean$pdo
model$BUGSoutput$mean$log.q
#model$BUGSoutput$mean$psi
model$BUGSoutput$mean$tauR2


#dimmensions of the parameters
#nSites
#nYears
#str(model$BUGSoutput$sims.list)
#dim(model$BUGSoutput$sims.array)


########################################################################
############Chain Convergence and Posterior Distributions
########################################################################

#look at convergence of all variables 

#this is great for posteriors, but doesn't deal with the fact that the chains need to be viewed separate
createMcmcList = function(model) {
  McmcArray = as.array(model$BUGSoutput$sims.array)
  McmcList = vector("list",length=dim(McmcArray)[2])
  for(i in 1:length(McmcList)) McmcList[[i]] = as.mcmc(McmcArray[,i,])
  McmcList = mcmc.list(McmcList)
  return(McmcList)
}

myList<-createMcmcList(model)
#colnames(myList[[1]])#names of each of the output 

#Mylist is a reformatted version of the array that has the individual runs  
myList[[1]] #the number here refers to the chain number

#######
#PLOT ALL OUTPUT IN 1 BIG PDF
######

#setwd("~/Dropbox/Projects/In Progress/Herring_Haida_Gwaii/Figures/Posteriors and Chains") 


pdf(paste("simulator_diagonal_equal_design_c",Sys.Date(),".pdf"), onefile = TRUE)

## ==================
##  Predicted vs True X 
## ==================

plot(model)

tempmat<-model$BUGSoutput$mean$X
temp2<-melt(tempmat)
colnames(temp2) <-c("time","site","predicted")
temp2$true<-melt(xmat)$value
op<-melt(temp2,id.vars=c("time","site"))
op$site<-factor(op$site)

ggplot(op,aes(x=time,y=value,colour=site,group=variable,lty=variable))+
  geom_line()+
  facet_wrap(~site,scales="free")+
  theme_acs()+
  scale_colour_brewer(palette="Paired")+
  ggtitle("Pred. and True spawn biomass ")

## ==================
##  SHI vs q adjusted X
## ==================

temp2$SHI<-melt(SHI_sim)$value
temp2$xq <- temp2$predicted + median(model$BUGSoutput$mean$log.q)
temp4<-melt(temp2[,c(1,2,5,6)],id.vars=c("time","site"))

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
  


## ==================
##  Predicted vs True delta 
## ==================

tempmat<-model$BUGSoutput$mean$delta
temp2<-melt(tempmat)
colnames(temp2) <-c("time","site","predicted")
temp2$true<-melt(delta_sim)$value
op<-melt(temp2,id.vars=c("time","site"))
op$site<-factor(op$site)

ggplot(op,aes(x=time,y=value,colour=site,group=variable,lty=variable))+
  geom_line()+
  facet_wrap(~site,scales="free")+
  theme_acs()+
  scale_colour_brewer(palette="Paired")+
  ggtitle("Predicted and True DELTA")


## ==================
##  Predicted vs True PC 
## ==================
# 
# tempmat<-model$BUGSoutput$mean$Pc
# temp2<-melt(tempmat)
# colnames(temp2) <-c("time","site","predicted")
# temp2$true<-melt(Pc_sim)$value
# op<-melt(temp2,id.vars=c("time","site"))
# op$site<-factor(op$site)
# 
# ggplot(op,aes(x=time,y=value,colour=site,group=variable,lty=variable))+
#   geom_line()+
#   facet_wrap(~site,scales="free")+
#   theme_acs()+
#   scale_colour_brewer(palette="Paired")+
#   ggtitle("Predicted and True Fishing Rate(Pc)")
# 

## ==================
##  Predicted vs True Z
## ==================

tempmat<-model$BUGSoutput$mean$Z
temp2<-melt(tempmat)
colnames(temp2) <-c("time","site","predicted")
temp2$true<-melt(zmat)$value
op<-melt(temp2,id.vars=c("time","site"))
op$site<-factor(op$site)

ggplot(op,aes(x=time,y=value,colour=site,group=variable,lty=variable))+
  geom_line()+
  facet_wrap(~site,scales="free")+
  theme_acs()+
  scale_colour_brewer(palette="Paired")+
  ggtitle("Predicted and True Pre Catch Biomass")


####Umu and Ui estimates 
Umudf<-melt(model$BUGSoutput$sims.array[,,"Umu"])
Umudf$Var3<-"Umu"
Umudf<-Umudf[,c(1,2,4,3)]
umuci<-smedian.hilow(Umudf$value,conf.int=0.95)
umuci2<-quantile(Umudf$value,c(0.05,0.95))

tlist<-model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="U[1]"):which(colnames(myList[[1]])=="U[11]")]]
dimnames(tlist)[[3]]<-colnames(Y)
udf<-melt(tlist)


ucomp<-ggplot(udf,aes(x=Var3,y=value,colour=Var3))+
	geom_hline(yintercept=median(Umudf$value),lty=2)+
	geom_hline(yintercept= umuci2[1],lty=1,colour="grey")+
	geom_hline(yintercept= umuci2[2],lty=1,colour="grey")+
  geom_hline(yintercept= Umu_sim,colour="red")+
	stat_summary(fun.data=median_hilow,lty=2)+
	#stat_summary(fun.data=median_hilow,conf.int=0.5)+
	coord_flip()+
	theme_acs()+
	    theme(legend.position="none")+

	ylab("Population Growth Rate [U]")+
	xlab("Site Specific Population Growth")

print(ucomp)


#######
#Print Chains and Histograms
######

qdf<-melt(model$BUGSoutput$sims.array[,,"log.q"])
#psidf<-melt(model$BUGSoutput$sims.array[,,"psi"])
pdodf<-melt(model$BUGSoutput$sims.array[,,"pdocoef"])
Umudf<-melt(model$BUGSoutput$sims.array[,,"Umu"])
Usigdf<-melt(model$BUGSoutput$sims.array[,,"Usig2"])
tauRdf<-melt(model$BUGSoutput$sims.array[,,"tauR2"])
sigma2df<-melt(model$BUGSoutput$sims.array[,,"sigma2"])

slist<-list(qdf,pdodf,Umudf,Usigdf,tauRdf,sigma2df)#,#psidf)
nm<-c("log.q","pdocoef","Umu","Usig","tauR2","sigma2")#,"psi")

simvec<-c(log_q_sim,pdocoef_sim,Umu_sim,Usig_sim,tauR2_sim,sigma2_sim[1])#,psi_sim)

for(i in 1:length(slist)){
  temp<-slist[[i]]
  names(temp)<-c("num","chain","value")

gtemp<-ggplot(temp,aes(y=value,x=num,group=chain))+
      geom_line(aes(colour=factor(chain)))+
      geom_hline(yintercept=simvec[i],colour="red")+
      theme_acs()+
      ggtitle(nm[i])+
      theme(legend.position="none")

gtemp2<-ggplot(temp,aes(x=value))+
  geom_histogram()+
  geom_vline(xintercept=simvec[i],colour="red")+
  theme_acs()+
  geom_vline(xintercept = 0,colour="black",lty=2)+
  ggtitle(nm[i])


grid.arrange(gtemp,gtemp2,nrow=2, heights=c(1.2,1.2))
}


#####################
############U -estiamtes of states for each pouplation at each time step 
#####################


udf<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="U[1]"):which(colnames(myList[[1]])=="U[11]")]])

udf<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="U[1]"):which(colnames(myList[[1]])=="U[11]")]])
names(udf)<-c("num","chain","response","value")
udf$chain<-factor(udf$chain)
udf$section2<-as.character(sort(rep(seq(1:11),nrow(udf)/nSites)))

usimdf<- data.frame(uvec,"section2"=seq(1:11))

gtemp<- ggplot()+
  geom_line(data=udf,aes(y=value,x=num,group=chain,colour=chain))+
  geom_hline(data=usimdf,aes(yintercept=uvec),colour="red")+
  theme_acs()+
  facet_wrap(~section2)+
  theme(legend.position="none")+
  ggtitle("U Chains")


gtemp2<-ggplot()+
  geom_histogram(data=udf,aes(x=value))+
  geom_vline(data=usimdf,aes(xintercept=uvec),colour="red")+
  theme_acs()+
  geom_vline(xintercept = 0)+
  facet_wrap(~section2)+
  ggtitle("U Histogram")

grid.arrange(gtemp,gtemp2,nrow=2, heights=c(1.2,1.2))


dev.off()
















#####################
############X -estiamtes of states for each pouplation at each time step 
#####################
# 
# edf1<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="X[1,1]"):which(colnames(myList[[1]])=="X[66,11]")]])
# names(edf1)<-c("num","chain","response","value")
# edf1$chain<-factor(edf1$chain)
# 
# edf1$group<-factor(sort(rep(seq(1:nSites),runL)))
# edf1$year<-sort(rep(seq(1:nYears),runL*nSites))
# 
# xmat2<-xmat
# colnames(xmat2)<-seq(1:11)
# xdf<-melt(data.frame(xmat2,"year"=seq(1:nYears)),id.vars=c("year"))
# xdf$group<-sort(rep(seq(1:11),nYears))
# 
# for(i in 1:nYears){
#   tmp<-subset(edf1,year==i)
#   tmptrue<-subset(xdf,year==i)
#   gtemp<-ggplot()+
#     geom_line(data=tmp,aes(x=num,y=value,group=chain,colour=chain))+
#     geom_hline(data=tmptrue,aes(yintercept=value),colour="red")+
#     facet_wrap(~group)+
#     theme_acs()+
#     ggtitle(paste("X chains_time_",i))
#   
#     print(gtemp)
# }
# 
# 
# 
# 
# ####posterior by site*time combiantions. 
# chain<-c(rep("chain1",runL/3),rep("chain2",runL/3),rep("chain3",runL/3))
# num <- rep(seq(1:(runL/3)),3)
# mx<-melt(X)
# mx$chain<-chain
# mx$num<-num
# 
# xdf$Var3<-xdf$group
# 
# for(i in 1:nYears){
# tmp<-subset(mx,Var2==i)
# tmptrue<-subset(xdf,year==i)
# 
# gt<-ggplot()+
#   geom_histogram(data=tmp,aes(x=value))+
#   geom_vline(data=tmptrue,aes(xintercept=value),colour="red")+
#   facet_wrap(~Var3)+
#   theme_acs()+
#   geom_vline(xintercept = 0)+
#   ggtitle(paste("X Posterior time_",i,".pdf"))
# print(gt)
#   
# }
# 
# 
# 
# 
# #####################
# ############Delta -estiamtes of states for each population's change
# #####################
# 
# ##Posterior plots
# edf1<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="delta[1,1]"):which(colnames(myList[[1]])=="delta[66,11]")]])
# 
# names(edf1)<-c("num","chain","response","value")
# edf1$chain<-factor(edf1$chain)
# edf1$group<-factor(sort(rep(seq(1:nSites),runL)))
# 
# edf1$year<-sort(rep(seq(1:nYears),runL*nSites))
# 
# 
# for(i in 1:nYears){
#   tmp<-subset(edf1,year==i)
#  dcg<- ggplot(tmp,aes(x=num,y=value,group=chain))+
#     geom_line(aes(colour=chain))+
#     facet_wrap(~group)+
#     theme_acs()+
#   ggtitle(paste("Delta chains_time_",i,".pdf"))
#   print(dcg)
# }
# 
# ####posterior by site*time combiantions. 
# chain<-c(rep("chain1",runL/3),rep("chain2",runL/3),rep("chain3",runL/3))
# num <- rep(seq(1:(runL/3)),3)
# dx<-melt(delta)
# dx$chain<-chain
# dx$num<-num
# 
# 
# for(i in 1:nYears){
#   tmp<-subset(dx,Var2==i)
#   dhg<-ggplot(tmp,aes(x=value))+
#     geom_histogram()+
#     facet_wrap(~Var3)+
#     theme_acs()+
#     geom_vline(xintercept = 0)+
#   ggtitle(paste("Delta Posterior time_",i,".pdf"))
#   
#   print(dhg)
#   
# }
# 
# print(qhg)
# 
# 
# 
# #####################
# ############Pc -estiamtes of states for each population's change
# #####################
# model$BUGSoutput$sims.array[,,"Pc[1,1]"]
# 
# edf1<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="Pc[1,1]"):which(colnames(myList[[1]])=="Pc[66,11]")]])
# 
# names(edf1)<-c("num","chain","response","value")
# edf1$chain<-factor(edf1$chain)
# edf1$group<-factor(sort(rep(seq(1:11),runL)))
# 
# edf1$year<-sort(rep(seq(1:nYears),runL*nSites))
# 
# for(i in 1:nYears){
#   tmp<-subset(edf1,year==i)
#   pccg<-ggplot(tmp,aes(x=num,y=value,group=chain))+
#     geom_line(aes(colour=chain))+
#     facet_wrap(~group)+
#     theme_acs()
#     ggtitle(paste("chains_time_",i,".pdf"))
#   print(pccg)
# }
# 
# 
# ####posterior by site*time combiantions. 
# chain<-c(rep("chain1",runL/3),rep("chain2",runL/3),rep("chain3",runL/3))
# num <- rep(seq(1:(runL/3)),3)
# px<-melt(Pc)
# px$chain<-chain
# px$num<-num
# 
# 
# for(i in 1:nYears){
#   tmp<-subset(px,Var2==i)
#   pcg<-ggplot(tmp,aes(x=value))+
#     geom_histogram()+
#     facet_wrap(~Var3)+
#     theme_acs()+
#     geom_vline(xintercept = 0)+
#     ggtitle(paste("Pc Posteriors time_",i,".pdf"))
#   print(pcg)
# }
# 
# 
# 
# 
# dev.off()
# 
# 




## ==================
## TEST CHUNKS OF JAGS CODE (AS pre ole fixes)
## ==================

# tl<-matrix(NA,ncol=nSites,nrow=nYears)
# psi<-1000
# ctabnew<-matrix(NA,ncol=nSites,nrow=nYears)
# 
# Pc.mat <- Catch.dummy
# for(k in 1:nIndex){
#   Pc.mat[INDEX[k,1],INDEX[k,2]]    <- Catch.dummy[INDEX[k,1],INDEX[k,2]] * Pc[k] 
#   tl[INDEX[k,1],INDEX[k,2]]<-zmat[INDEX[k,1],INDEX[k,2]]+log(Pc[k])
#   ctabnew[INDEX[k,1],INDEX[k,2]] = dnorm(1,(tl[INDEX[k,1],INDEX[k,2]]),1/psi) #distribution of catch data  LIKELIHOOD STATEMENT ****  
#   
# }
# 
# 
# for(i in 2:nYears){
#   for(j in 1:nSites) {
#     
#     #fishing by site and global pdo estimates and U estimates 
#     zmat[i,j] <- xmat[(i-1),j]+uvec[j]+pdocoef_sim*pdo3[(i-1)]+delta_sim[(i-1),j]
#     
#     #Estimate the state X with catch by site 
#     xmat[i,j] <-zmat[i,j]+log(1-Pc.mat[i,j]);
#     
#   }
# }
