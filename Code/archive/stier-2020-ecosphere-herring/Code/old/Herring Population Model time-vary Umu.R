## ==================
##  Load Library & Set Directory
## ==================

library(ggplot2)
library(reshape2)
library(R2jags)
library(coda)
library(gdata)
library(Hmisc)
library(gridExtra)
library(MCMCvis)

setwd("~/Dropbox/Projects/In Progress/Herring_Haida_Gwaii/Code")

source('multiplot.R')
source('theme_acs.R')

## ==================
##  Time and Sites
## ==================
years = seq(1950,2015)
nYears = length(years)
nSites = 11

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



## ==================
##  Catch data
## ==================

c <- read.csv("herring_catch_local2015.csv")
yr_c<-unique(c$Year)
c$presabs <-ifelse(c$TotalCatch>0,1,0)

unique(c[,c('Section','Name')]) #look at sections and names

c<-drop.levels(subset(c,Section %in% c(1,2,3,5,6,12,21,22,23,24,25)))#subset out Cartwright Sound (4), Masset (11)
ctab<-data.frame(tapply(c$CatchJan_Apr,list(c$Year,c$Name),sum)) #just spring catch

data.frame(colnames(Y),colnames(ctab)) #compare column names
ctab2<-ctab[,c(11,7,8,2,5,6,3,9,1,4,10)] #re order so catch table matches spawn table 
data.frame(colnames(logSHI),colnames(ctab2)) #double check column orders match

colnames(logSHI)<-colnames(ctab2)

ctab2<-as.matrix(ctab2)
logcatch<-log(ctab2+1)


## ==================
##  Catch Priors and Design matrix 
## ==================

#make a prior matrix that sets the upper bound of the uniform distribution for prior Pc to be 0.95 when it's a non-zero and 0.01 when it's zero
nonz        <- which(logcatch>0)
c_prior_sim <- matrix(0.95,nrow=nrow(logcatch),ncol=ncol(logcatch))
design.c    <- ifelse(logcatch>0,1,0)


## ==================
## Estimating Catch Rates Only in Sites where Catch Reported
## ==================

#Identify Which Row-Column Combinations Where Catch>0
INDEX      <- NULL  
INDEX.zero <- NULL  
for(i in 1:nrow(logcatch)){
  
  if(length(logcatch[i,][logcatch[i,]>0])>0){ 
    temp   <- data.frame(row = rep(i,length(which(logcatch[i,]>0))),col = which(logcatch[i,]>0))
    INDEX <- rbind(INDEX,temp)
  }
  
  if(length(logcatch[i,][logcatch[i,]==0])>0){ 
    temp.2 <- data.frame(row = rep(i,length(which(logcatch[i,]==0))),col = which(logcatch[i,]==0))
    INDEX.zero <- rbind(INDEX.zero,temp.2)
  }
}

nIndex      <- nrow(INDEX) #nubmer of row-column combinations with catch>0
nIndex.zero <- nrow(INDEX.zero) #nubmer of row-column combinations with catch>0

Catch.dummy <- logcatch
Catch.dummy[Catch.dummy > 0] <- 1 #put 1 in places where >0 catch

##read in INDEX, nIndex, and Catch.dummy as data in jags.data


#read in a vector of q to index two q's
#surface 1950-1987 
length(1950:1987)

#scuba 1988-present 
length(1988:2015)

q_idx<-c(rep(1,38),rep(2,28))

## ==================
## Parameters and Definitions 
## ==================



## ==================
## JAGS CODE to fit model
## ==================

#Begin JAGS code
jagsscript = cat("
                 model {  
                 
                 ##########################
                 #OBSERVATION MODEL PRIORS and LIKELIHOODs
                 ##########################
                 
                 tauR2  ~ dgamma(2,2); #this is the estimated variance prior for Spawn Index to Spawn Biomass Conversion
                 #psi   ~ dunif(0,0.01) #this is in variance for fishing set fixed to try to get convergence
                 
                 #Catchability Conversion from Spawn Index to Spawn Biomass 
                 
                 for(q in 1:2) {
                    log.q[q] ~ dnorm(0,10) 
                 }
                 
                 # Prop. Catch (pc) Prior  (USES INDEX to find row-column combinations) for prior 
                 
                 for(k in 1:nIndex){
                     Pc[k] ~ dunif(0,0.95)
                 }
                 
                 for(i in 1:nYears) {
                    for(j in 1:nSites) {
                     Y[i,j] ~  dnorm((X[i,j]+log.q[q_idx[i]]),1/tauR2); #obs eq for spawn index. a normal dist mean Xq LIKELIHOOD STATEMENT*
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
                 Umu[1]   ~  dnorm(0,1); #average population growth
                 rho ~ dunif(-1,1) ## sometimes it freaks out if rho gets close to 1 so you can change to 0.999 if needed
                 zeta2 ~ dgamma(1,100) ### go to dgamma(0.1,10)

                  for(i in 2:nYears) {
                    Umu[i] ~ dnorm( rho * Umu[i-1], 1 / (zeta2 / ( 1- rho^2)) ) #as needs clarificaiton on a-this var term zeta b-autoregressive?
                  }

                 #COVARIATE
                 pdoz2   <- 1
                 pdocoef ~ dnorm(0,1/pdoz2); #estimated impact of pdo of herring
                 
                 #VARINCE MATRIX - Diagonal and Equal - same variance all sites 
                 
                 # For indepenent and equal variances
                 sigma2 ~ dgamma(0.001,0.001); #set initial
                     # INT ~ dnorm()
                      # SLOPE ~ dnorm()

                  # #### time varying sigma2
                  # for(i in 1:nYears) {
                  #   sigma2[i] = exp(INT + SLOPE * i)
                  # }

                  for(j in 1:nSites) {
                     sigma2.all[j] <- sigma2; #replicate initial value for all sigma2
                  }
                 
                 # Estimate the initial state vector of population abundances
                 
                 for(j in 1:nSites) {
                    Z[1,j] ~ dnorm(5,1/100); # vague normal prior for first time step #changed from inverse 3/31
                    X[1,j] <- Z[1,j] + log(1-Pc.mat[1,j]) # changed to reflect handwritten model 3/31
                 }

                 #  Delta Prior
                 for(i in 1:(nYears)){
                  for(j in 1:nSites) {
                    delta[i,j] ~ dnorm(0,1/sigma2.all[j]) #changed from inverse 3/31
                  }
                 }

                 for(i in 2:nYears){
                    for(j in 1:nSites) {
                 
                      #fishing by site and global pdo estimates and U estimates 
                      Z[i,j] <- X[(i-1),j]+ Umu[i] + pdocoef*pdo[i-1] + delta[(i-1),j]
                 
                      #Estimate the state X with catch by site 
                      X[i,j] <-Z[i,j]+log(1-Pc.mat[i,j]);
                    }
                 }
                 
                 } 
                 ",file="diag_equal_design_c_2q_timevaryingU.RData.txt")


#data going into the model
jags.data = list("Y"=logSHI, "nYears"=nYears,"nSites"=nSites,"pdo"=pdo2,"ctab"=logcatch,
                 "INDEX"=INDEX,"INDEX.zero"=INDEX.zero, "nIndex"=nIndex,"nIndex.zero"=nIndex.zero,"q_idx"=q_idx) # named list

jags.params=c("X","sigma2","Umu","delta","Z","pdocoef","log.q","Pc","tauR2","rho","zeta2")

model.loc="diag_equal_design_c_2q_timevaryingU.RData.txt" # name of the txt file

n.chains = 3
n.burnin = 1000000
n.thin = 10
n.iter = 1500000

#number of recorded mcmc
runL <- n.chains*(n.iter-n.burnin)/n.thin

inits = NULL

for(i in 1:n.chains){
  inits[[i]]    <- list(
    # "Umu" = rnorm(1,0,0.1),
    #"Usig2" = runif(1,0,1),
    "pdocoef" = rnorm(1,0,0.1),
    #"log.q" = rnorm(1,0,0.1),
    "tauR2" = runif(1,0,1)
  ) 
}

model = jags(jags.data, inits=inits,parameters.to.save=jags.params,
             model.file=model.loc, n.chains = n.chains, n.burnin=n.burnin, n.thin=n.thin, n.iter=n.iter, DIC=TRUE)

#attach.jags(model)

mDIC<-model$BUGSoutput$DIC 
pD<-model$BUGSoutput$pD
devi<-model$BUGSoutput$deviance

## ==================
## Save model output
## ==================

setwd("~/Dropbox/Projects/In Progress/Herring_Haida_Gwaii/Code")

save("model","mDIC","inits",
     file="diag_equal_design_c_noUsig_2q_timevaryingU.RData")

load("diag_equal_design_c_noUsig_2q_timevaryingU.RData") 


## ==================
## Quick Summary of Model Parameters
## ==================

#look at individual parameter means
model$BUGSoutput$mean$Pc
model$BUGSoutput$mean$X
model$BUGSoutput$mean$delta
model$BUGSoutput$mean$sigma2
#model$BUGSoutput$mean$U
# model$BUGSoutput$mean$Umu
#model$BUGSoutput$mean$Usig2
model$BUGSoutput$mean$pdo
model$BUGSoutput$mean$log.q[1]
model$BUGSoutput$mean$log.q[2]
model$BUGSoutput$mean$tauR2

#new ones for the moving window

model$BUGSoutput$mean$Umu
model$BUGSoutput$mean$rho
model$BUGSoutput$mean$zeta2

plot(model$BUGSoutput$mean$Umu)


#dimmensions of the parameters
str(model$BUGSoutput$sims.list)
#dim(model$BUGSoutput$sims.array)

## ==================
##  Agregate MCMC Output
## ==================

createMcmcList = function(model) {
  McmcArray = as.array(model$BUGSoutput$sims.array)
  McmcList = vector("list",length=dim(McmcArray)[2])
  for(i in 1:length(McmcList)) McmcList[[i]] = as.mcmc(McmcArray[,i,])
  McmcList = mcmc.list(McmcList)
  return(McmcList)
}


#Mylist is a reformatted version of the array that has the individual runs  
myList<-createMcmcList(model)


#pdf(paste("Posteriors-Chains-timevaryingU",Sys.Date(),".pdf"),onefile = TRUE,width=6, height=9)


qdf1<-melt(model$BUGSoutput$sims.array[,,"log.q[1]"])
qdf2<-melt(model$BUGSoutput$sims.array[,,"log.q[2]"])
tauRdf<-melt(model$BUGSoutput$sims.array[,,"tauR2"])
pdodf<-melt(model$BUGSoutput$sims.array[,,"pdocoef"])
#Umudf<-melt(model$BUGSoutput$sims.array[,,"Umu"])
sigma2df<-melt(model$BUGSoutput$sims.array[,,"sigma2"])
rhodf<-melt(model$BUGSoutput$sims.array[,,"rho"])
zeta2df<-melt(model$BUGSoutput$sims.array[,,"zeta2"])

slist<-list(qdf1,qdf2,tauRdf,pdodf,sigma2df,rhodf,zeta2df)
nm<-c("log.q[1]","log.q[2]","tauR2","pdocoef","sigma2","rho","zeta2")



for(i in 1:length(slist)){
  temp<-slist[[i]]
  names(temp)<-c("num","chain","value")
  
  gtemp<-ggplot(temp,aes(y=value,x=num,group=chain))+
    geom_line(aes(colour=factor(chain)))+
    theme_bw()+
    ggtitle(nm[i])+
    theme(legend.position="none")
  
  smedian.hilow(temp$value,conf.int=0.95)
  
  
  gtemp2<-ggplot(temp,aes(x=value))+
    geom_histogram()+
    theme_bw()+
    geom_vline(xintercept = 0,colour="red")+
    ggtitle(nm[i])
  
  grid.arrange(gtemp,gtemp2,nrow=2, heights=c(1.2,1.2))
}



umudf<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="Umu[1]"):which(colnames(myList[[1]])=="Umu[66]")]])
names(umudf)<-c("num","chain","response","value")
umudf$chain<-factor(umudf$chain)
umudf$section2<-as.character(sort(rep(unique(x$section)[-c(4,7)],nrow(umudf)/nSites)))


gtemp<- ggplot(umudf,aes(y=value,x=num,group=chain))+
  geom_line(aes(colour=chain))+
  theme_bw()+
  facet_wrap(~section2)+
  theme(legend.position="none")+
  ggtitle("Us Chains")


gtemp2<-ggplot(umudf,aes(x=value))+
  geom_bar()+
  theme_bw()+
  geom_vline(xintercept = 0)+
  facet_wrap(~section2)+
  ggtitle("Us Histogram")

grid.arrange(gtemp,gtemp2,nrow=2, heights=c(1.2,1.2))


dev.off()


MCMCpstr(model,params='Umu',func=mean)
MCMCpstr(model,params='Umu',func=function(x) quantile(x,probs=c(0.025,0.975)))


MCMCtrace(model,params='Umu')

MCMCplot(model,params='Umu')


