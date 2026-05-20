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

#Data Simulation
#setwd("~/Desktop/Imac_Herring_4_14")
#setwd("/Users/AdrianStierMBP2015/Dropbox/Projects/In Progress/pinniped_herring_hg/Imac_Herring_4_14")
source('multiplot.R')
source('theme_acs.R')
#load('herring_jags_F_9sites_simulate_nofishing.RData')

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

beta<- 0
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

# 
# for(i in 1:ncol(emat)){
#   emat[1,i]<-rnorm(1,aveSHI[i],1)
# }

set.seed(10)
for(i in 1:ncol(emat)){
  emat[1,i]<-rnorm(1,aveSHI[i],1)
}



##Simulate a  Model with autoregressive random walk 

# #deterministic means and variance 
# for(j in 1:ncol(emat)){
#   for(i in 2:nrow(emat)){
#     emat[i,j]<-emat[i-1,j]+smat[j,1]+beta*pdo3[i]+smat[j,2]
#   }
# }

####
##U is a pull from a population that is normally distributed and has a variance of 
####

#sd is shared across sites at 0.01 ~average of the 

for(j in 1:ncol(emat)){
  for(i in 2:nrow(emat)){
    emat[i,j]<-emat[i-1,j]+rnorm(1,smat[j,1],0.01)+beta*pdo3[i]
    
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


########################################################################
############JAGS CODE to fit model 
########################################################################



#Begin JAGS code
jagsscript = cat("
                 model {  
                 
                 ##########################
                 #OBSERVATION MODEL PRIORS and LIKLIHOODs
                 ##########################
                 
                 tauR ~ dunif(0,1); #this is the estimated variance prior for Spawn Index
                 q ~ dunif(.999,1.001);  #Fraction of Spawn Observed on spawn surveys estiamted across all sites
                 
                #psi ~ 0.1 #dunif(0,10) #this is in variance for fishing set fixed to try to get convergence
                 
                 for(i in 1:nYears) {
                 for(j in 1:nSites) {
                 Y[i,j] ~  dnorm(X[i,j]*q,1/tauR); #obs eq for spawn index. a normal pull with meam Xq LIKELIHOOD STATEMENT ****
                 
            
                 }
                 }
                 
                                
                 ##########################
                 #PROCESS MODEL PRIORS
                 ##########################
                 
                 # POPULATION GROWTH parameters U: 
                 Umu ~ dnorm(0,1/1); #average population growth
                 Usig ~ dunif(0,1); #SD among populations in population growth 
                 Utau <- 1/(Usig*Usig);#precision of variance in pop growth
                 
                 for(i in 1:nSites) {
                 U[i] ~ dnorm(Umu,Utau) #for each site U set as random variable prior 
                 }
                 
                 #COVARIATE
                 pdocoef~dnorm(0,1000); #estimated impact of pdo of herring
                 
                 #VARINCE SPATIAL VARIANCE AND COVARIANCE
                 sigma2 ~ dgamma(0.01,0.01) #variance 
                 #sigma2 ~ dunif(0,0.5) #variance 
                
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
                 
                zeta2 <- 9
                 
                 # Estimate the initial state vector of population abundances
                 for(j in 1:nSites) {

                 X[1,j] ~ dnorm(10,1/zeta2); # vague normal prior for first time step
                 Z[1,j] <- X[1,j]
                 }
                 
                 
                 # Initial Values for Delta
                 for(j in 1:nSites) {zeros[j]<-0;}
                 delta[1,1:nSites] ~ dmnorm(zeros,tauQ[1:nSites,1:nSites]);
                 
                 #Autoregressive change in pop through time that's uniqe to site/time
                  
                 for(i in 2:nYears) {
                 delta[i,1:nSites] ~ dmnorm(zeros,tauQ[1:nSites,1:nSites]);
                 #delta[i,1:nSites] ~ dmnorm(delta[i-1,1:nSites],tauQ[1:nSites,1:nSites]);
                 
                 for(j in 1:nSites) {
                 
                 
                 #fishing by site and global pdo estimates and U estimates 
                 dummy[i-1,j] <- X[i-1,j]+U[j]+pdocoef*pdo[i-1]; 
                 
                 
                 #make second dummy variable Z to add in the delta param
                 Z[i,j] <- dummy[i-1,j]+delta[i,j]; 
                 
                 
                 #Estimate the state X with catch by site 
                 X[i,j] <-Z[i,j];
                 
                 
                 }
                 }
                 } 
                 ",file="normal_spatialRW_9sites.txt")


#data going into the model
jags.data = list("Y"=emat, "nYears"=nYears,"nSites"=nSites,"distMat5"=distMat5,"pdo"=pdo3) # named list

jags.params=c("X","theta","sigma2","U","Umu","Usig","delta","Q","pdocoef","q","tauR") # parameters in the linear regression model

#jags.params=c("X","theta","eta","sigma2","U","Umu","Usig","delta","Q","pdocoef","q","Pc","tauR") # parameters in the linear regression model
# jags.params=c("X","theta","eta","sigma2","U","Umu","Usig","delta","Q","pdocoef","q","Pc","psi","tauR") # parameters in the linear regression model
model.loc="normal_spatialRW_9sites.txt" # name of the txt file

n.chains = 3
n.burnin=50
n.thin=5
n.iter=1000

#number of recorded mcmc
runL <- n.chains*(n.iter-n.burnin)/n.thin

Inits = NULL

#need to add the inits for the Pc and q params

for(i in 1:n.chains){
  Inits[[i]]    <- list(
    "Umu" = runif(1,-.2,.2), #alt just make it a little lower? 0.5 seems more realisitc
    "Usig" = runif(1,0.001,1),
    "pdocoef" = runif(1,.01,1),
    "logtheta" = runif(1,1,10),
    "delta" = matrix(runif(1,.05,1),nrow=nYears,ncol=nSites),
    "tauR" = runif(1,0,1),
    "q" = runif(1,0.999,1.001)
     
  ) 
}


#jags.model.rand.base.both = jags(jags.data, inits = Inits, parameters.to.save= jags.params, model.file=model.loc, 
#                                 n.chains = Nchain, n.burnin = Nburn, n.thin = 1, n.iter = Nburn+Niter, DIC = TRUE) 


model = jags(jags.data, inits=Inits,parameters.to.save=jags.params,
             model.file=model.loc, n.chains = n.chains, n.burnin=n.burnin, n.thin=n.thin, n.iter=n.iter, DIC=TRUE)

attach.jags(model)


save("model","X","theta","sigma2","U","Umu","Usig","delta","Q","pdo","pdocoef","q","tauR",file="herring_jags_F_9sites_simulate_nofishing.RData")

#save("model","X","theta","eta","sigma2","U","Umu","Usig","delta","Q","pdo","Pc","q","tauR",file="herring_jags_F_9sites.RData")
#save("model","X","theta","eta","sigma2","U","Umu","Usig","delta","Q","pdo","Pc","q","psi","tauR",file="herring_jags_F.RData")

#load("herring_jags_F_9sites_simulate_nofishing.RData")
########################################################################
############Quick Summary of Model Parameters
########################################################################
#names of array 

#look at individual parameter means
model$BUGSoutput$mean$X
model$BUGSoutput$mean$U
model$BUGSoutput$mean$Umu
model$BUGSoutput$mean$delta
model$BUGSoutput$mean$theta
model$BUGSoutput$mean$Q
model$BUGSoutput$mean$pdo
model$BUGSoutput$mean$q
model$BUGSoutput$mean$psi
model$BUGSoutput$mean$Pc
model$BUGSoutput$mean$tauR

#dimmensions of the parameters
nSites
nYears
str(model$BUGSoutput$sims.list)
dim(model$BUGSoutput$sims.array)




########################################################################
############Chain Convergence and Posterior Distributions
########################################################################

#look at convergence of all variables 
#plot(model)

#this is great for posteriors, but doesn't deal with the fact that the chains need to be viewed separate
createMcmcList = function(model) {
  McmcArray = as.array(model$BUGSoutput$sims.array)
  McmcList = vector("list",length=dim(McmcArray)[2])
  for(i in 1:length(McmcList)) McmcList[[i]] = as.mcmc(McmcArray[,i,])
  McmcList = mcmc.list(McmcList)
  return(McmcList)
}

myList<-createMcmcList(model)

#Mylist is a reformatted version of the array that has the individual runs  
myList[[1]] #the number here refers to the chain number

#######
#PLOT ALL OUTPUT IN 1 BIG PDF
######

setwd("~/Dropbox/Projects/In Progress/Pinniped_Herring_HG/Code/Figures") 


pdf(paste("Simulated_Chains and Posteriors",Sys.Date(),".pdf"), onefile = TRUE)

#############
#Predicted versus Observed
############

#acual data 
mm2 <- mm[,-4]
names(mm2) <- c("time","site","shi")

#pull out the x data 

model$BUGSoutput$sims.array[,,"X[1,1]"]

#means
tempmat<-model$BUGSoutput$mean$X
colnames(tempmat) <-c("site1","site2","site3","site4","site5","site6","site7","site8","site9")
temp2<-melt(tempmat)
colnames(temp2) <-c("time","site","X")

#temp3<-reshape(temp2,timevar = "site",idvar=c("time"),direction="wide")[,-1]

mm3<-data.frame(mm2,temp2[,'X'])
names(mm3)<-c("time","site","observed","predicted")
mm4<-melt(mm3,id.vars<-c("time","site"))

gpo<-ggplot(mm4,aes(x=time,y=value,group=variable))+
  geom_line(aes(colour=factor(site),lty=variable))+
  facet_wrap(~site,scales="free_y")+
  theme_acs()+
  ggtitle("Predicted X and Observed SHI")

print(gpo)

#######
#Print Chains and Histograms
######

qdf<-melt(model$BUGSoutput$sims.array[,,"q"])
pdodf<-melt(model$BUGSoutput$sims.array[,,"pdocoef"])
thetadf<-melt(model$BUGSoutput$sims.array[,,"theta"])
Umudf<-melt(model$BUGSoutput$sims.array[,,"Umu"])
Usigdf<-melt(model$BUGSoutput$sims.array[,,"Usig"])
tauRdf<-melt(model$BUGSoutput$sims.array[,,"tauR"])
sigma2df<-melt(model$BUGSoutput$sims.array[,,"sigma2"])

slist<-list(qdf,pdodf,thetadf,Umudf,Usigdf,tauRdf,sigma2df)
nm<-c("q","pdocoef","theta","Umu","Usig","tauR","sigma2")



for(i in 1:length(slist)){
  temp<-slist[[i]]
  names(temp)<-c("num","chain","value")
  
  gtemp<-ggplot(temp,aes(y=value,x=num,group=chain))+
    geom_line(aes(colour=factor(chain)))+
    theme_acs()+
    ggtitle(nm[i])+
    theme(legend.position="none")
  
  gtemp2<-ggplot(temp,aes(x=value))+
    geom_bar()+
    theme_acs()+
    geom_vline(xintercept = 0,colour="red")+
    ggtitle(nm[i])
  
  
  grid.arrange(gtemp,gtemp2,nrow=2, heights=c(1.2,1.2))
}


#####################
############U -estiamtes of states for each pouplation at each time step 
#####################


udf<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="U[1]"):which(colnames(myList[[1]])=="U[9]")]])


udf<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="U[1]"):which(colnames(myList[[1]])=="U[9]")]])
names(udf)<-c("num","chain","response","value")
udf$chain<-factor(udf$chain)

gtemp<- ggplot(udf,aes(y=value,x=num,group=chain))+
  geom_line(aes(colour=chain))+
  theme_acs()+
  facet_wrap(~response)+
  theme(legend.position="none")+
  ggtitle("U Chains")


gtemp2<-ggplot(udf,aes(x=value))+
  geom_bar()+
  theme_acs()+
  geom_vline(xintercept = 0)+
  facet_wrap(~response)+
  ggtitle("U Histogram")

grid.arrange(gtemp,gtemp2,nrow=2, heights=c(1.2,1.2))




#####################
############X -estiamtes of states for each pouplation at each time step 
#####################

edf1<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="X[1,1]"):which(colnames(myList[[1]])=="X[64,9]")]])
names(edf1)<-c("num","chain","response","value")
edf1$chain<-factor(edf1$chain)

edf1$group<-factor(sort(rep(seq(1:nSites),runL)))
edf1$year<-sort(rep(seq(1:nYears),runL*nSites))

for(i in 1:nSites){
  tmp<-subset(edf1,year==i)
  gtemp<-ggplot(tmp,aes(x=num,y=value,group=chain))+
    geom_line(aes(colour=chain))+
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


for(i in 1:nSites){
  tmp<-subset(mx,Var2==i)
  gt<-ggplot(tmp,aes(x=value))+
    geom_bar()+
    facet_wrap(~Var3)+
    theme_acs()+
    geom_vline(xintercept = 0)+
    ggtitle(paste("X Posterior time_",i,".pdf"))
  print(gt)
  
}




#####################
############Delta -estiamtes of states for each population's change
#####################

#means
tempmat<-model$BUGSoutput$mean$delta
colnames(tempmat) <-c("site1","site2","site3","site5","site6","site7","site8","site9","site10")
temp2<-melt(tempmat)
colnames(temp2) <-c("time","site","delta")
# 
# #add site names from df2
# ggplot(temp2,aes(x=time,y=site,fill=delta))+
#   geom_tile()+
#   theme_acs()
# 
# ggplot(temp2,aes(x=time,y=delta,group=factor(site)))+
#   geom_line(aes(colour=factor(site)))+
#   theme_acs()


##Posterior plots
model$BUGSoutput$sims.array[,,"delta[1,1]"]

edf1<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="delta[1,1]"):which(colnames(myList[[1]])=="delta[64,9]")]])

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


for(i in 1:nSites){
  tmp<-subset(dx,Var2==i)
  dhg<-ggplot(tmp,aes(x=value))+
    geom_bar()+
    facet_wrap(~Var3)+
    theme_acs()+
    geom_vline(xintercept = 0)+
    ggtitle(paste("Delta Posterior time_",i,".pdf"))
  
  print(dhg)
  
}


#####################
############Q -estiamtes of states for each population's change
#####################
#means
tempmat<-model$BUGSoutput$mean$Q
cov2cor(tempmat)

colnames(tempmat) <-c("site1","site2","site3","site5","site6","site7","site8","site9","site10")
temp2<-melt(tempmat)
colnames(temp2) <-c("time","site","Q")

model$BUGSoutput$sims.array[,,"Q[1,1]"]

edf1<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="Q[1,1]"):which(colnames(myList[[1]])=="Q[9,9]")]])
names(edf1)<-c("num","chain","response","value")
edf1$chain<-factor(edf1$chain)

qcg<-ggplot(edf1,aes(y=value,x=num,group=chain))+
  geom_line(aes(colour=chain))+
  theme_acs()+
  facet_wrap(~response)+
  ggtitle("Q Chains")

print(qcg)

qhg<-ggplot(edf1,aes(x=value))+
  geom_bar()+
  theme_acs()+
  geom_vline(xintercept = 0)+
  facet_wrap(~response)+
  ggtitle("Q Posterior")

print(qhg)



#####################
############Pc -estiamtes of states for each population's change
#####################

#means
tempmat<-model$BUGSoutput$mean$Pc
colnames(tempmat) <-c("site1","site2","site3","site4","site5","site6","site7","site8","site9")
temp2<-melt(tempmat)
colnames(temp2) <-c("time","site","Pc")

#add site names from df2
pcall<-ggplot(temp2,aes(x=time,y=factor(site),fill=Pc))+
  geom_tile()+
  theme_acs()+
  ggtitle("Pc Through Time and Across Sites")

print(pcall)
# ggplot(temp2,aes(x=time,y=Pc,group=site))+
#   geom_line(aes(colour=site))+
#   theme_acs()



##Posterior plots
model$BUGSoutput$sims.array[,,"Pc[1,1]"]

edf1<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="Pc[1,1]"):which(colnames(myList[[1]])=="Pc[64,12]")]])

names(edf1)<-c("num","chain","response","value")
edf1$chain<-factor(edf1$chain)
edf1$group<-factor(sort(rep(seq(1:12),runL)))

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
    geom_bar()+
    facet_wrap(~Var3)+
    theme_acs()+
    geom_vline(xintercept = 0)+
    ggtitle(paste("Pc Posteriors time_",i,".pdf"))
  print(pcg)
}


dev.off()

