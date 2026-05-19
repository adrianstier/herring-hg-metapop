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

#Data Simulation
setwd("~/Dropbox/Projects/In Progress/Pinniped_Herring_HG/Code")
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

pdo<-read.csv("pdo.csv")
pdosummer<-subset(pdo,month %in% c(3,4,5,6)) #average april<-june
pdoxb<-c(tapply(pdo$Value,list(pdo$year),mean))
pdo2<-pdoxb[87:160] #1940-2013
pdo3<-pdo2[11:74] #1950-2013


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
  xmat[1,i]<-zmat[1,i]+log(1-Pc_sim[1,i])
}


#siulate 2:nYears

for(j in 1:ncol(zmat)){
  for(i in 2:nrow(zmat)){
    zmat[i,j]<- xmat[i-1,j]+rnorm(1,uvec[j],0)+pdocoef_sim*pdo3[i]+delta_sim[i,j]
    xmat[i,j]<- zmat[i,j]+log(1-Pc_sim[i,j])
    
  }
}


#calculate amount of fish caught on log scale for simulated catch data
#zmat is log scale number of fish before catch, xmat is number after 
ctab_sim<-zmat-xmat
ctab_sim[ctab_sim==-Inf] <- 0

mm<-melt(xmat)
mm$value2<-exp(mm$value)

ggplot(mm,aes(x=Var1,y=value,group=factor(Var2)))+
  geom_line(aes(colour=factor(Var2)))+
  facet_wrap(~Var2,scales="free_y")+
  theme_acs()


## ==================
## adjust true X to include catchability (q)
## ==================

#Q modification 
q_sim<-2
tauR_sim<-100

SHI_sim<-xmat+q_sim






########################################################################
############JAGS CODE to fit model 
########################################################################



#Begin JAGS code
jagsscript = cat("
         model {  
         
         ##########################
         #OBSERVATION MODEL PRIORS and LIKELIHOODs
         ##########################
         
         tauR ~ dunif(1,100); #this is the estimated variance prior for Spawn Index
         q ~ dgamma(.02,0.001);  #Fraction of Spawn Observed on spawn surveys estiamted across all sites
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
jags.data = list("Y"=Y, "nYears"=nYears,"nSites"=nSites,"pdo"=pdo3,"ctab"=ctab2_1,"c_prior"=c_prior) # named list
jags.data.p = list("Y", "nYears","nSites","distMat5","pdo","ctab","c_prior") # named list



jags.params=c("X","sigma2","U","Umu","Usig","delta","Z","pdocoef","q","Pc","tauR","psi") # parameters in the linear model


model.loc="normal_spatialRW_11sites_DiagEqual_v2_psi_free.txt" # name of the txt file

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
    "psi" = runif(1,0,1.5),1
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

save("model","mDIC","X","sigma2","U","Umu","Usig","Z","delta","sigma2","pdo","pdocoef","Pc","q","tauR","psi",file="herring_jags_F_11sites_diag_equal_var_v2_psifree.RData")


#load("herring_jags_F_11sites_diag_equal_var_v2.RData")
load("herring_jags_F_11sites_diag_equal_var_v2_psifree.RData")



