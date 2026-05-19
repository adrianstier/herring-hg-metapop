library(ggplot2)
library(reshape2)
library(gdata)
library(maps)
library(mapproj)
library(ggmap)
library(gplots)
library(R2jags)
library(coda)

#Data Simulation

setwd("/Users/AdrianStierMBP2015/Dropbox/Projects/In Progress/pinniped_herring_hg/Imac_Herring_4_14")
source('multiplot.R')
source('theme_acs.R')
######
#Set params for simple time series model 
######


#actual spawn data
x=read.csv("HG_Spawn_Survey_1940_2013b.csv")
x<- x[c(1,3,13,14,15,16)]
years = seq(1950,2013)
nYears = length(years)
nSites = 9

x2 <- x[,c(1,2,3)]
w <- reshape(x2, 
             timevar = "section",
             idvar = c("year"),
             direction = "wide")[,-1]

#replace zeros with NAs
w[w==0] <- NA

#double check that it has time ont he rows and sites on the column
Y= as.matrix(w)

#subset out Cartwright Sound (4)-no catch data, Masset (11), Skitigate (22), and Naden Harbor (12) - iffy spawn surveys
Y = Y[-c(1:10),-c(4,7,8,10)] #drop site 4 since we have no catch data 

#Y = Y/0.5 #q coefficient to turn into biomass
Y = log(Y)


ym<-melt(Y)
ym<-data.frame(ym,rep(seq(1:nrow(Y)),ncol(Y)))
names(ym)<-c("crap","site","logSHI","time")
ym$SHI<-exp(ym$logSHI)

ggplot(ym,aes(x=time,y=SHI))+
  #geom_point(aes(colour=site))+
  geom_line(aes(colour=site))+
  facet_wrap(~site,scales="free_y")+
  theme_acs()

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

smat<-data.frame(emat)
colnames(smat)<-c("slope","slopeSE")   
mean(smat[,1])
sd(smat[,1])




#load pdo
pdo<-read.csv("pdo.csv")
pdosummer<-subset(pdo,month %in% c(3,4,5,6)) #average april<-june
pdoxb<-c(tapply(pdo$Value,list(pdo$year),mean))
pdo2<-pdoxb[87:160] #1940-2013
pdo3<-pdo2[11:74] #1950-2013

beta<- 0.15
E<-rnorm(1,0,var(as.numeric(Y),na.rm=TRUE))

#distance matrix by coastline
distMat4<-as.matrix(read.csv("h_dist_shore.csv")[,-1]/1000)
distMat5<-distMat4[-c(4,7,8,10),-c(4,7,8,10)]


#set starting values based on the spawn index data (Y)
emat<-matrix(ncol=9,nrow=64)

nYears<-nrow(emat)
nSites<-ncol(emat)


for(i in 1:ncol(emat)){
  emat[1,i]<-rnorm(length(mean(Y,na.rm=T)),mean(Y,na.rm=T),var(as.numeric(Y),na.rm=T))
}

#change starting values to be average of time s eries 
aveSHI<- tapply(ym$logSHI,list(ym$site),mean,na.rm=TRUE)
sdSHI<- tapply(ym$logSHI,list(ym$site),mean,na.rm=TRUE)


for(i in 1:ncol(emat)){
  emat[1,i]<-rnorm(1,aveSHI[i],1)
}

##Simulate a  Model with autoregressive random walk 

#deterministic means and variance 
for(j in 1:ncol(emat)){
  for(i in 2:nrow(emat)){
    emat[i,j]<-emat[i-1,j]+smat[j,1]+beta*pdo3[i]+smat[j,2]*sqrt(64)
  }
}

####
##U is a pull from a population that is normally distributed and has a variance of 
####

for(j in 1:ncol(emat)){
  for(i in 2:nrow(emat)){
    emat[i,j]<-emat[i-1,j]+rnorm(1,smat[j,1],(smat[j,2]*sqrt(64)))+beta*pdo3[i]
    
  }
}



matplot(emat)
mm<-melt(emat)
mm$value2<-exp(mm$value)

ggplot(mm,aes(x=Var1,y=value2,group=factor(Var2)))+
  geom_line(aes(colour=factor(Var2)))+
  scale_y_log10()+
  theme_acs()

ggplot(mm,aes(x=Var1,y=value2,group=factor(Var2)))+
  geom_line(aes(colour=factor(Var2)))+
  facet_wrap(~Var2,scales="free_y")+
  theme_acs()


#make up fake fishing tab, start with empty zeros

ctab_sim<-matrix(0,ncol=9,nrow=64)
 



########################################################################
############JAGS CODE to fit model 
########################################################################



#Begin JAGS code
jagsscript = cat("
                 model {  
                 
                 ##########################
                 #OBSERVATION MODEL PRIORS and LIKLIHOODs
                 ##########################
                 
                 tauR ~ dunif(1,100); #this is the estimated variance prior for Spawn Index
                 q ~ dgamma(.02,0.001);  #Fraction of Spawn Observed on spawn surveys estiamted across all sites
                 
                #psi ~ 0.1 #dunif(0,10) #this is in variance for fishing set fixed to try to get convergence
                 
                 for(i in 1:nYears) {
                 for(j in 1:nSites) {
                 Y[i,j] ~  dnorm(X[i,j]*q,1/tauR); #obs eq for spawn index. a normal pull with meam Xq LIKELIHOOD STATEMENT ****
                 
                 tl[i,j]<-Z[i,j]+log(Pc[i,j]) #total biomass to estimate biomass (Z) + catch fraciton (Pc) 
                 
                 ctab[i,j] ~ dnorm(tl[i,j],1/.1) #distribution of catch data  LIKELIHOOD STATEMENT ****
                 }
                 }
                 
                 for(i in 1:nYears) {
                 for(j in 1:nSites) {
                 Pc[i,j] ~ dbeta(1,1) 
                 }
                 }
                 
                 ##########################
                 #PROCESS MODEL PRIORS
                 ##########################
                 
                 # POPULATION GROWTH parameters U: 
                 Umu ~ dnorm(0,1); #average population growth
                 Usig ~ dunif(0,100); #variance in population growth 
                 Utau <- 1/(Usig*Usig);#precision of variance in pop growth
                 
                 for(i in 1:nSites) {
                 U[i] ~ dnorm(Umu,Utau) #for each site U set as random variable prior 
                 }
                 
                 #COVARIATE
                 pdocoef~dnorm(0,1); #estimated impact of pdo of herring
                 
                 #VARINCE SPATIAL VARIANCE AND COVARIANCE
                 sigma2 ~ dgamma(0.01,0.01) #variance 
                 
                 #eta ~ dgamma(0.01,0.01) #wiggle on distance decay
                 
                 logtheta ~ dnorm(0,0.01) #rate of distance decay
                 theta <- exp(logtheta)
                 
                 #variance covariance matrix, and Precision matrix inverse for Q
                 for(i in 1:nSites) {
                 for(j in 1:nSites) {
                 #Q[i,j] <- sigma2 * exp(-theta * distMat5[i,j]) + eta*diag[i,j];
                 Q[i,j] <- sigma2 * exp(-theta * distMat5[i,j]) #no nugget 
                 
                 }
                 }   
                 
                 tauQ[1:nSites,1:nSites] <- inverse(Q[1:nSites,1:nSites]);
                 
                 
                 # Estimate the initial state vector of population abundances
                 for(j in 1:nSites) {
                 X[1,j] ~ dnorm(20,0.1); # vague normal prior for first time step
                 Z[1,j] <- X[1,j]-log(1-Pc[1,j])
                 }
                 
                 
                 # Initial Values for Delta
                 for(j in 1:nSites) {zeros[j]<-0;}
                 delta[1,1:nSites] ~ dmnorm(zeros,tauQ[1:nSites,1:nSites]);
                 
                 #Autoregressive change in pop through time that's uniqe to site/time
                 for(i in 2:nYears) {
                 delta[i,1:nSites] ~ dmnorm(delta[i-1,1:nSites],tauQ[1:nSites,1:nSites]);
                 for(j in 1:nSites) {
                 
                 
                 #fishing by site and global pdo estimates and U estimates 
                 dummy[i-1,j] <- X[i-1,j]+U[j]+pdocoef*pdo[i-1]; 
                 
                 
                 #make second dummy variable Z to add in the delta param
                 Z[i,j] <- dummy[i-1,j]+delta[i,j]; 
                 
                 
                 #Estimate the state X with catch by site 
                 X[i,j] <-Z[i,j]+log(1-Pc[i,j]);
                 
                 
                 }
                 }
                 } 
                 ",file="normal_spatialRW_9sites.txt")


#data going into the model
jags.data = list("Y"=emat, "nYears"=nYears,"nSites"=nSites,"distMat5"=distMat5,"pdo"=pdo3,"ctab"=ctab_sim) # named list

jags.params=c("X","theta","sigma2","U","Umu","Usig","delta","Q","pdocoef","q","Pc","tauR") # parameters in the linear regression model

#jags.params=c("X","theta","eta","sigma2","U","Umu","Usig","delta","Q","pdocoef","q","Pc","tauR") # parameters in the linear regression model
# jags.params=c("X","theta","eta","sigma2","U","Umu","Usig","delta","Q","pdocoef","q","Pc","psi","tauR") # parameters in the linear regression model
model.loc="normal_spatialRW_9sites.txt" # name of the txt file

n.chains = 3
n.burnin=9800
n.thin=3
n.iter=10000

#number of recorded mcmc
runL <- n.chains*(n.iter-n.burnin)/n.thin

Inits = NULL

#need to add the inits for the Pc and q params

for(i in 1:n.chains){
  Inits[[i]]    <- list(
    "Umu" = runif(1,.1,1), #alt just make it a little lower? 0.5 seems more realisitc
    "Usig" = runif(1,.05,1),
    "pdocoef" = runif(1,.05,1),
    #"tau" =runif(1,0.05,1),
    #"invEta" = runif(1,1,10),
    "logtheta" = runif(1,1,10),
    "delta" = matrix(runif(1,.05,1),nrow=nYears,ncol=nSites),
    "tauR" = runif(1,1,2),
    "Pc" = matrix(1e-05,nrow=nYears,ncol=nSites), #runif(1,.05,1) #reducing this and the variance on this psi
    #"psi" = runif(1,0,1.5),
    "q" = runif(1,0.01,0.999)
    
  ) 
}


#jags.model.rand.base.both = jags(jags.data, inits = Inits, parameters.to.save= jags.params, model.file=model.loc, 
#                                 n.chains = Nchain, n.burnin = Nburn, n.thin = 1, n.iter = Nburn+Niter, DIC = TRUE) 


model = jags(jags.data, inits=Inits,parameters.to.save=jags.params,
             model.file=model.loc, n.chains = n.chains, n.burnin=n.burnin, n.thin=n.thin, n.iter=n.iter, DIC=TRUE)

attach.jags(model)


