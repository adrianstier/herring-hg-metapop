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
#setwd("~/Desktop/Imac_Herring_4_14")
#setwd("/Users/AdrianStierMBP2015/Dropbox/Projects/In Progress/pinniped_herring_hg/Imac_Herring_4_14")
source('multiplot.R')
source('theme_acs.R')

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
pdo2<-pdoxb[87:162] #1940-2015
pdo3<-pdo2[11:76] #1950-2013

## ==================
##  Spawn dat
## ==================

#spawn data
x=read.csv("HG_Spawn_Survey_1940_2015.csv")
x<- x[c(1,3,13,14,15,16)]
x$presabs <-ifelse(x$SHI>0,1,0)

years = seq(1950,2015)
nYears = length(years)
nSites = 11

x2 <- x[,c(1,2,4)]
w <- reshape(x2, 
             timevar = "section_name",
             idvar = c("year"),
             direction = "wide")[,-1]

w[w==0] <- NA#replace zeros with NAs
Y= as.matrix(w)
Y = Y[-c(1:10),-c(4)] #drop site 4
Y = log(Y)
Y <- Y[,c(9,10,11,8,12,5,1,4,3,2,7,6)] #reorder for CAR
Y <- Y[,c(1:11)]#subset out Masset inslet - limited data 

ym<-melt(Y)
ym<-data.frame(ym,rep(seq(1:nrow(Y)),ncol(Y)))
names(ym)<-c("crap","site","logSHI","time")

ggplot(ym,aes(x=time,y=logSHI))+
  geom_point(aes(colour=site))+
  geom_smooth(method="lm")+
  facet_grid(.~site)+
  theme_acs()

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

aveSHI<- tapply(ym$logSHI,list(ym$site),mean,na.rm=TRUE)
sdSHI<- tapply(ym$logSHI,list(ym$site),mean,na.rm=TRUE)

svec<-unique(ym$site)

## ==================
##  Catch dat
## ==================

c <- read.csv("herring_catch_local2015.csv")
yr_c<-unique(c$Year)
c$presabs <-ifelse(c$TotalCatch>0,1,0)

#subset out Cartwright Sound (4) 
c<-subset(c,Section %in% c(1,2,3,5,6,11,12,21,22,23,24,25))
ctab<-data.frame(tapply(c$CatchJan_Apr,list(c$Year,c$Section),sum)) #just spring catch
ctab2<-ctab
ctab2_1_car<-ctab2[,c(9,10,11,8,12,5,1,4,3,2,7,6)] #car model
ctab2_1_car<-ctab2_1_car[,c(1:11)]
colnames(ctab2_1_car)<-colnames(Y)
ctab2_1_car <-log(ctab2_1_car+1)
ctab2_1_car<-as.matrix(ctab2_1_car)

## ==================
##  Set Params for Fake Data
## ==================
set.seed(10)

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

pdocoef_sim<- -0.2 #pdo coefficient with negative sign, i.e.  cold water is good


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
Umu_sim<- 0.2 #mean(umat[,1])
Usig_sim<-.05#sd(umat[,1]) #could loosten this 
uvec<-rnorm(nSites,Umu_sim,Usig_sim)


## ==================
##  Catch Data: Fraction of Catch at Each site-time combiantion - **Pc** and Prior for Pc c_prior
## ==================

#make up some fishing impacts by proportion ranging from 0 to 1 
Pc_sim<-matrix(NA,nrow=nYears,ncol=nSites)

#Base the values on level of observed fishing

for(i in 1:nYears){
  for(j in 1:nSites){	
    Pc_sim[i,j]<-ifelse(ctab2_1_car[i,j]>0,
                        runif(1,0.001,0.75), #turn up/down fishing here
                        0
    )
  }
}

#
#make a prior matrix that sets the upper bound of the uniform distribution for prior Pc to be 0.95 when it's a non-zero and 0.01 when it's zero

nonz<-which(Pc_sim>0)
c_prior_sim<-matrix(0.001,nrow=nrow(Pc_sim),ncol=ncol(Pc_sim))

for(i in 1:length(nonz)){
  c_prior_sim[nonz[i]]<-0.95
}


## ==================
##  Variance (sigma2)
## ==================

sigma2<- dgamma(0.01,0.01)
sigma2_sim = NA

for(i in 1:nSites){
  sigma2_sim[i] <-sigma2 #same variance across all sites, could pull form normal (rnorm(0,sigma2), but watch for negatives)
}


delta_sim<-matrix(ncol=nSites,nrow=nYears)

for(i in 1:nSites){
  for(j in 1:nYears){
    
    delta_sim[j,i] <- rnorm(1,0,sigma2_sim[i]) 
    
  }
}



## ==================
##  Spawn Biomass X* and Spawn Biomass Plus Catch Z* First simulate starting, then to nYears
## ==================

#empty matrices
zmat<-matrix(NA,nrow=nYears,ncol = nSites) 
xmat<-matrix(NA,nrow=nYears,ncol = nSites)

#STARTING VALUES
#change starting values to be average of SHI time series
for(i in 1:nSites){
  zmat[1,i]<-rnorm(1,aveSHI[i],1) #assume pre catch biomass is 
  xmat[1,i]<-max(zmat[1,i]+log(1-Pc_sim[1,i]),0.001)
}


#siulate 2:nYears

for(j in 1:ncol(zmat)){
  for(i in 2:nrow(zmat)){
    zmat[i,j]<- xmat[i-1,j]+rnorm(1,uvec[j],0)+pdocoef_sim*pdo3[i]+delta_sim[i,j]
    xmat[i,j]<- max(zmat[i,j]+log(1-Pc_sim[i,j]),0.001) #don't let it go below 0.001 (1 metric ton)
    
  }
}


#calculate amount of fish caught on log scale for simulated catch data
#zmat is log scale number of fish before catch, xmat is number after 

ctab_sim<-zmat-xmat
#need to add constant like in real model *****

mm<-melt(xmat)
mm$value2<-exp(mm$value)

ggplot(mm,aes(x=Var1,y=value,group=factor(Var2)))+
  geom_line(aes(colour=factor(Var2)))+
  facet_wrap(~Var2,scales="free_y")+
  theme_acs()+
  theme(legend.position="none")


## ==================
## adjust true X to include catchability (q)
## ==================

#add a Q of 2, with no error
q_sim<-2
tauR_sim<-0
psi_sim <- 0

#add a q of 
SHI_sim<-xmat+q_sim

mmshi<-melt(SHI_sim)
names(mmshi)<- c("year","site","SHI")
mmshi$x<-mm$value
mmshi$site = factor(mmshi$site)

ggplot(mmshi,aes(x=SHI,y=x,colour=site))+
  geom_point()+
  geom_abline(slope=1,intercept=0,lty=2)+
  facet_wrap(~site,scales="free")+
  theme_acs()


## ==================
## JAGS CODE to fit model
## ==================


#Begin JAGS code
jagsscript = cat("
                 model {  
                
##########################
#OBSERVATION MODEL PRIORS and LIKELIHOODs
##########################

tauR ~ dunif(0,100); #this is the estimated variance prior for Spawn Index
q ~ dnorm(0,2);  #Fraction of Spawn Observed on spawn surveys estiamted across all sites
psi ~ dunif(0,100) #this is in variance for fishing set fixed to try to get convergence

for(i in 1:nYears) {
  for(j in 1:nSites) {
    Y[i,j] ~  dnorm(X[i,j]+q,1/tauR); #obs eq for spawn index. a normal pull with meam Xq LIKELIHOOD STATEMENT ****
    
    tl[i,j]<-Z[i,j]+log(Pc[i,j]) #total biomass caught (tl) is qual to to estimated biomass (Z) pre catch + catch (Pc) 
    
    ctab[i,j] ~ dnorm(tl[i,j],1/psi) #distribution of catch data  LIKELIHOOD STATEMENT ****

  }
}

for(i in 1:nYears) {
  for(j in 1:nSites) {
    Pc[i,j] ~ dunif(0,c_prior[i,j]) #dbeta(1,1) #Fraction of Spawn Caught for each site, c_prior catches the hard variance for catch=0
  }
}

##########################
#PROCESS MODEL PRIORS
##########################

# POPULATION GROWTH parameters U: 
Umu ~ dnorm(0,1); #average population growth
Usig ~ dunif(0,100); #variance in population growth 
Usig2<-Usig*Usig

for(i in 1:nSites) {
  U[i] ~ dnorm(Umu,1/Usig2) #for each site U set as random variable prior 
}

#COVARIATE
pdoz2<-1

pdocoef~dnorm(0,1/pdoz2); #estimated impact of pdo of herring

#VARINCE MATRIX - Diagonal and Equal - same variance all sites 

# For indepenent and equal variances
sigma2[1] ~ dgamma(0.001,0.001); #set initial

  for(i in 2:nSites) {
    sigma2[i] <- sigma2[1]; #replicate initial value for all sigma2
}



# Estimate the initial state vector of population abundances


for(j in 1:nSites) {
      #X[1,j] ~ dnorm(5,1/sigma2[j]); # vague normal prior for first time step #changed from inverse 3/31
      Z[1,j] ~ dnorm(5,1/sigma2[j]); # vague normal prior for first time step #changed from inverse 3/31
	  #Z[1,j] <- X[1,j] + log(1-Pc[1,j])
    X[1,j] <- Z[1,j] + log(1-Pc[1,j]) # changed to reflect handwritten model 3/31
}


#  Delta Values
for(i in 1:nYears){
for(j in 1:nSites) {delta[i,j] ~ dnorm(0,1/sigma2[j]) #changed from inverse 3/31
}
}

      
for(i in 2:nYears){
for(j in 1:nSites) {

#fishing by site and global pdo estimates and U estimates 
Z[i,j] <- X[i-1,j]+U[j]+pdocoef*pdo[i-1]+delta[i,j]

#Estimate the state X with catch by site 
X[i,j] <-Z[i,j]+log(1-Pc[i,j]);

 }
} 
} 
 ",file="simulator_diagonal_equal.txt")


#data going into the model
jags.data = list("Y"=SHI_sim, "nYears"=nYears,"nSites"=nSites,"pdo"=pdo3,"ctab"=ctab_sim,"c_prior"=c_prior_sim) # named list

jags.params=c("X","sigma2","U","Umu","Usig","delta","Z","pdocoef","q","Pc","tauR","psi") # parameters in the linear model


model.loc="simulator_diagonal_equal.txt" # name of the txt file

n.chains = 3
n.burnin=1000
n.thin=5
n.iter=10000


#number of recorded mcmc
runL <- n.chains*(n.iter-n.burnin)/n.thin

inits = NULL

#need to add the inits for the Pc and q params

for(i in 1:n.chains){
  inits[[i]]    <- list(
    "Umu" = runif(1,-1,1), #alt just make it a little lower? 0.5 seems more realisitc
    "Usig" = runif(1,.05,1),
    "pdocoef" = runif(1,-1,1),
    "delta" = matrix(runif(1,.05,1),nrow=nYears,ncol=nSites),
    "tauR" = runif(1,1,2),
    "Pc" = matrix(1e-07,nrow=nYears,ncol=nSites),
    "psi" = runif(1,0,1.5),
    "q" = runif(1,0.01,0.999)
    ) 
}
    
    

model = jags(jags.data, inits=inits,parameters.to.save=jags.params,
            model.file=model.loc, n.chains = n.chains, n.burnin=n.burnin, n.thin=n.thin, n.iter=n.iter, DIC=TRUE)

attach.jags(model)

# 
# model.p = list(jags.data.p, inits=inits,parameters.to.save=jags.params,
#              model.file=model.loc, n.chains = 3, n.burnin=n.burnin, n.thin=n.thin, n.iter=n.iter, DIC=TRUE)
# 
# mod.fit <- do.call(jags.parallel,model.p) 

# timer.start <- proc.time()
# (run.time.in.min <- round(((proc.time()-timer.start)/60)["elapsed"], 0))

mDIC<-model$BUGSoutput$DIC 
pD<-model$BUGSoutput$pD
devi<-model$BUGSoutput$deviance

save("model","mDIC","X","sigma2","U","Umu","Usig","Z","delta","sigma2","pdo","pdocoef","Pc","q","tauR","psi",
     "q_sim","psi_sim","pdocoef_sim","Umu_sim","Usig_sim","tauR_sim","sigma2_sim")
     ,file="simulator_diag_equal.RData")



#load("herring_jags_F_11sites_diag_equal_var_v2.RData")
load("simulator_diag_equal.RData")
########################################################################
############Quick Summary of Model Parameters
########################################################################
#names of array 

#head(model$BUGSoutput$sims.array)

#look at individual parameter means
model$BUGSoutput$mean$X
model$BUGSoutput$mean$U
model$BUGSoutput$mean$Umu
model$BUGSoutput$mean$delta
model$BUGSoutput$mean$Q
model$BUGSoutput$mean$pdo
model$BUGSoutput$mean$q
model$BUGSoutput$mean$psi
model$BUGSoutput$mean$Pc
model$BUGSoutput$mean$tauR


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

setwd("~/Dropbox/Projects/In Progress/Herring_Haida_Gwaii/Figures/Posteriors and Chains") 


pdf(paste("simulator_diagonal_equal",Sys.Date(),".pdf"), onefile = TRUE)

## ==================
##  Predicted vs True X 
## ==================

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
  scale_colour_brewer(palette="Paired")

## ==================
##  SHI vs q adjusted X
## ==================

temp2$SHI<-melt(SHI_sim)$value
temp2$xq <- temp2$predicted + median(model$BUGSoutput$mean$q)
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

tempmat<-model$BUGSoutput$mean$Pc
temp2<-melt(tempmat)
colnames(temp2) <-c("time","site","predicted")
temp2$true<-melt(Pc_sim)$value
op<-melt(temp2,id.vars=c("time","site"))
op$site<-factor(op$site)

ggplot(op,aes(x=time,y=value,colour=site,group=variable,lty=variable))+
  geom_line()+
  facet_wrap(~site,scales="free")+
  theme_acs()+
  scale_colour_brewer(palette="Paired")+
  ggtitle("Predicted and True Fishing Rate(Pc)")


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

qdf<-melt(model$BUGSoutput$sims.array[,,"q"])
psidf<-melt(model$BUGSoutput$sims.array[,,"psi"])
pdodf<-melt(model$BUGSoutput$sims.array[,,"pdocoef"])
Umudf<-melt(model$BUGSoutput$sims.array[,,"Umu"])
Usigdf<-melt(model$BUGSoutput$sims.array[,,"Usig"])
tauRdf<-melt(model$BUGSoutput$sims.array[,,"tauR"])
sigma2df<-melt(model$BUGSoutput$sims.array[,,"sigma2[1]"])

slist<-list(qdf,psidf,pdodf,Umudf,Usigdf,tauRdf,sigma2df)
nm<-c("q","psi","pdocoef","Umu","Usig","tauR","sigma2")

simvec<-c(q_sim,psi_sim,pdocoef_sim,Umu_sim,Usig_sim,tauR_sim,sigma2_sim[1])

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




#####################
############X -estiamtes of states for each pouplation at each time step 
#####################

edf1<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="X[1,1]"):which(colnames(myList[[1]])=="X[66,11]")]])
names(edf1)<-c("num","chain","response","value")
edf1$chain<-factor(edf1$chain)

edf1$group<-factor(sort(rep(seq(1:nSites),runL)))
edf1$year<-sort(rep(seq(1:nYears),runL*nSites))

xmat2<-xmat
colnames(xmat2)<-seq(1:11)
xdf<-melt(data.frame(xmat2,"year"=seq(1:nYears)),id.vars=c("year"))
xdf$group<-sort(rep(seq(1:11),nYears))

for(i in 1:nYears){
  tmp<-subset(edf1,year==i)
  tmptrue<-subset(xdf,year==i)
  gtemp<-ggplot()+
    geom_line(data=tmp,aes(x=num,y=value,group=chain,colour=chain))+
    geom_hline(data=tmptrue,aes(yintercept=value),colour="red")+
    facet_wrap(~group)+
    theme_acs()+
    ggtitle(paste("X chains_time_",i))
  
    print(gtemp)
}




####posterior by site*time combiantions. 
chain<-c(rep("chain1",runL/3),rep("chain2",runL/3),rep("chain3",runL/3))
num <- rep(seq(1:(runL/3)),3)
mx<-melt(X)
mx$chain<-chain
mx$num<-num

xdf$Var3<-xdf$group

for(i in 1:nYears){
tmp<-subset(mx,Var2==i)
tmptrue<-subset(xdf,year==i)

gt<-ggplot()+
  geom_histogram(data=tmp,aes(x=value))+
  geom_vline(data=tmptrue,aes(xintercept=value),colour="red")+
  facet_wrap(~Var3)+
  theme_acs()+
  geom_vline(xintercept = 0)+
  ggtitle(paste("X Posterior time_",i,".pdf"))
print(gt)
  
}




#####################
############Delta -estiamtes of states for each population's change
#####################

##Posterior plots
edf1<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="delta[1,1]"):which(colnames(myList[[1]])=="delta[66,11]")]])

names(edf1)<-c("num","chain","response","value")
edf1$chain<-factor(edf1$chain)
edf1$group<-factor(sort(rep(seq(1:nSites),runL)))

edf1$year<-sort(rep(seq(1:nYears),runL*nSites))


for(i in 1:nYears){
  tmp<-subset(edf1,year==i)
 dcg<- ggplot(tmp,aes(x=num,y=value,group=chain))+
    geom_line(aes(colour=chain))+
    facet_wrap(~group)+
    theme_acs()+
  ggtitle(paste("Delta chains_time_",i,".pdf"))
  print(dcg)
}

####posterior by site*time combiantions. 
chain<-c(rep("chain1",runL/3),rep("chain2",runL/3),rep("chain3",runL/3))
num <- rep(seq(1:(runL/3)),3)
dx<-melt(delta)
dx$chain<-chain
dx$num<-num


for(i in 1:nYears){
  tmp<-subset(dx,Var2==i)
  dhg<-ggplot(tmp,aes(x=value))+
    geom_histogram()+
    facet_wrap(~Var3)+
    theme_acs()+
    geom_vline(xintercept = 0)+
  ggtitle(paste("Delta Posterior time_",i,".pdf"))
  
  print(dhg)
  
}

print(qhg)



#####################
############Pc -estiamtes of states for each population's change
#####################
model$BUGSoutput$sims.array[,,"Pc[1,1]"]

edf1<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="Pc[1,1]"):which(colnames(myList[[1]])=="Pc[66,11]")]])

names(edf1)<-c("num","chain","response","value")
edf1$chain<-factor(edf1$chain)
edf1$group<-factor(sort(rep(seq(1:11),runL)))

edf1$year<-sort(rep(seq(1:nYears),runL*nSites))

for(i in 1:nYears){
  tmp<-subset(edf1,year==i)
  pccg<-ggplot(tmp,aes(x=num,y=value,group=chain))+
    geom_line(aes(colour=chain))+
    facet_wrap(~group)+
    theme_acs()
    ggtitle(paste("chains_time_",i,".pdf"))
  print(pccg)
}


####posterior by site*time combiantions. 
chain<-c(rep("chain1",runL/3),rep("chain2",runL/3),rep("chain3",runL/3))
num <- rep(seq(1:(runL/3)),3)
px<-melt(Pc)
px$chain<-chain
px$num<-num


for(i in 1:nYears){
  tmp<-subset(px,Var2==i)
  pcg<-ggplot(tmp,aes(x=value))+
    geom_histogram()+
    facet_wrap(~Var3)+
    theme_acs()+
    geom_vline(xintercept = 0)+
    ggtitle(paste("Pc Posteriors time_",i,".pdf"))
  print(pcg)
}




dev.off()


