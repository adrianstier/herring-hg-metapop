## ==================
##  Load Library & Set Directory
## ==================

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

ym<-melt(Y)
ym<-data.frame(ym,rep(seq(1:nrow(Y)),ncol(Y)))
names(ym)<-c("crap","site","logSHI","time")

#plot spawn index through time
ggplot(ym,aes(x=time,y=logSHI))+
  geom_point(aes(colour=site))+
  geom_smooth(method="lm")+
  facet_grid(.~site)

## ==================
##  Ballpark Population Growth Rates from inear regresion on log data
## ==================

#loop through each site to estimate the slope of spawn index through time
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
tauR2  ~ dgamma(2,2); #this is the estimated variance prior for Spawn Index to Spawn Biomass Conversion
#psi   ~ dunif(0,0.01) #this is in variance for fishing set fixed to try to get convergence

# Prop. Catch (pc) Prior  (USES INDEX to find row-column combinations) for prior 
for(k in 1:nIndex){
         Pc[k] ~ dunif(0,0.95)
}
                 
for(i in 1:nYears) {
  for(j in 1:nSites) {
    Y[i,j] ~  dnorm(X[i,j]+log.q ,1/tauR2); #obs eq for spawn index. a normal pull with mean Xq LIKELIHOOD STATEMENT ****
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
rho ~ dunif(-1,1)
pdoz2   <- 1
pdocoef ~ dnorm(0,1/pdoz2); #estimated impact of pdo of herring

#VARINCE MATRIX - Diagonal and Equal - same variance all sites 

# For indepenent and unequal variances

  for(j in 1:nSites) {
    sigma2.all[j] ~ dgamma(0.001,0.001);
}


# Estimate the initial state vector of population abundances

for(j in 1:nSites) {
      Z[1,j] ~ dnorm(5,1/100); # vague normal prior for first time step #changed from inverse 3/31
      X[1,j] <- Z[1,j] + log(1-Pc.mat[1,j]) # changed to reflect handwritten model 3/31
  }


#  Delta Prior

for(j in 1:nSites){
  delta[1,j] ~ dnorm(0,1/sigma2.all[j])
}

for(i in 2:(nYears)){
  for(j in 1:nSites) {
    delta[i,j] ~ dnorm(rho*delta[i-1,j],1/sigma2.all[j]) #changed from inverse 3/31
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
 ",file="diagonal_unequal_design_c_autocor_delta.txt")


#data going into the model
jags.data = list("Y"=logSHI, "nYears"=nYears,"nSites"=nSites,"pdo"=pdo2,"ctab"=logcatch,
                 "INDEX"=INDEX,"INDEX.zero"=INDEX.zero, "nIndex"=nIndex,"nIndex.zero"=nIndex.zero) # named list

jags.params=c("X","sigma2.all","rho","U","Umu","Usig2","delta","Z","pdocoef","log.q","Pc","tauR2")


model.loc="diagonal_unequal_design_c_autocor_delta.txt" # name of the txt file

n.chains = 4
n.burnin = 10000
n.thin = 10
n.iter = 30000

#number of recorded mcmc
runL <- n.chains*(n.iter-n.burnin)/n.thin

inits = NULL

#need to add the inits for the Pc and q params

for(i in 1:n.chains){
  inits[[i]]    <- list(
    "Umu" = rnorm(1,0,0.1),
    "Usig2" = runif(1,0,1),
    "pdocoef" = rnorm(1,0,0.1),
    "log.q" = rnorm(1,0,0.1),
    "tauR2" = runif(1,0,1),
    "rho" = runif(1,0,1)
      ) 
}
    
model = jags(jags.data, inits=inits,parameters.to.save=jags.params,
            model.file=model.loc, n.chains = n.chains, n.burnin=n.burnin, n.thin=n.thin, n.iter=n.iter, DIC=TRUE)

#attach.jags(model)

mDIC<-model$BUGSoutput$DIC 
pD<-model$BUGSoutput$pD
devi<-model$BUGSoutput$deviance

## ==================
## Save/Load model output
## ==================
setwd("~/Dropbox/Projects/In Progress/Herring_Haida_Gwaii/Code")


save("model","mDIC","inits",
     file="diag_unequal_design_c_autocor_delta.RData")

setwd("~/Dropbox/Projects/In Progress/Herring_Haida_Gwaii/Code")

load("diag_unequal_design_c_autocor_delta.RData")


## ==================
## Quick Summary of Model Parameters
## ==================

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
#colnames(myList[[1]])#names of each of the output 
# myList[[1]] #the number here refers to the chain number


## ==================
##  Plot single PDF of output Chain Convergence and Posterior Distributions
## ==================

setwd("~/Dropbox/Projects/In Progress/Herring_Haida_Gwaii/Figures/Posteriors and Chains") 
pdf(paste("diagonal_unequal_design_c_autocor_delta",Sys.Date(),".pdf"), onefile = TRUE)

plot(model)

## ==================
##  Aggregate Site Labels
## ==================

#labels for graph
sitelab<-paste(rep("Section",11),as.character(unique(x$section))[-c(4,7)])
sitelab2<-unique(x$section_name)[-c(4,7)]
data.frame(sitelab,sitelab2)

## ==================
##  SHI vs q adjusted X
## ==================

#melt spawn index (SHI) 
y2<-data.frame("time"=seq(1,nYears,1),logSHI)
mm2 <- melt(y2,id.vars<-"time")
names(mm2) <- c("time","site","shi")


#means
tempmat<-model$BUGSoutput$mean$X
colnames(tempmat) <-sitelab2
temp2<-melt(tempmat)
colnames(temp2) <-c("time","site","X")

# Predicted versus SHI obs vs 1:1 - ballpark q (catchability)
# jsdf<- data.frame(temp2,"shi"=mm2$shi)  
# 
# ggplot(jsdf,aes(x=shi,y=X,colour=site))+
#   geom_point()+
#   geom_abline(slope=1,intercept=0,lty=2)+
#   facet_wrap(~site,scales="free")+
#   scale_colour_brewer(palette="Paired")+
#   theme_acs()


temp2$SHI<-melt(logSHI)$value
temp2$xq <- temp2$X + median(model$BUGSoutput$mean$log.q)
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
  

## ==================
##  Catchability (q), PDOcoef, Archipelago growth, Arch var, 
## ==================

qdf<-melt(model$BUGSoutput$sims.array[,,"log.q"])
tauRdf<-melt(model$BUGSoutput$sims.array[,,"tauR2"])
# psidf<-melt(model$BUGSoutput$sims.array[,,"psi"])
pdodf<-melt(model$BUGSoutput$sims.array[,,"pdocoef"])
#thetadf<-melt(model$BUGSoutput$sims.array[,,"theta"])
Umudf<-melt(model$BUGSoutput$sims.array[,,"Umu"])
Usigdf<-melt(model$BUGSoutput$sims.array[,,"Usig2"])
rhodf<-melt(model$BUGSoutput$sims.array[,,"rho"])

#sigma2df<-melt(model$BUGSoutput$sims.array[,,"sigma2"])

slist<-list(qdf,tauRdf,pdodf,Umudf,Usigdf,rhodf)
nm<-c("q","tauR2","pdocoef","Umu","Usig2","rho")

for(i in 1:length(slist)){
  temp<-slist[[i]]
  names(temp)<-c("num","chain","value")
  
  gtemp<-ggplot(temp,aes(y=value,x=num,group=chain))+
    geom_line(aes(colour=factor(chain)))+
    theme_acs()+
    ggtitle(nm[i])+
    theme(legend.position="none")
  
  gtemp2<-ggplot(temp,aes(x=value))+
    geom_histogram()+
    theme_acs()+
    geom_vline(xintercept = 0,colour="red")+
    ggtitle(nm[i])
  
  grid.arrange(gtemp,gtemp2,nrow=2, heights=c(1.2,1.2))
}

## ==================
##  Variance of Each Stocklet
## ==================


sdf<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="sigma2.all[1]"):which(colnames(myList[[1]])=="sigma2.all[11]")]])

names(sdf)<-c("num","chain","response","value")
sdf$chain<-factor(sdf$chain)
sdf$section2<-as.character(sort(rep(unique(x$section)[-c(4,7)],nrow(sdf)/nSites)))


gtemp<- ggplot(sdf,aes(y=value,x=num,group=chain))+
  geom_line(aes(colour=chain))+
  theme_acs()+
  facet_wrap(~section2,scales="free")+
  theme(legend.position="none")+
  ggtitle("Sigma2 Chains")


gtemp2<-ggplot(sdf,aes(x=value))+
  geom_histogram()+
  theme_acs()+
  geom_vline(xintercept = 0,lty=2)+
  facet_wrap(~section2,scales="free")+
  ggtitle("Sigma2 Histogram")

grid.arrange(gtemp,gtemp2,nrow=2, heights=c(1.2,1.2))

## ==================
##  Stocklet Specific Populaiton Growth Estimats (Ui)
## ==================

udf<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="U[1]"):which(colnames(myList[[1]])=="U[11]")]])
names(udf)<-c("num","chain","response","value")
udf$chain<-factor(udf$chain)
udf$section2<-as.character(sort(rep(unique(x$section)[-c(4,7)],nrow(udf)/nSites)))

gtemp<- ggplot(udf,aes(y=value,x=num,group=chain))+
  geom_line(aes(colour=chain))+
  theme_acs()+
  facet_wrap(~section2)+
  theme(legend.position="none")+
  ggtitle("U Chains")

gtemp2<-ggplot(udf,aes(x=value))+
  geom_histogram()+
  theme_acs()+
  geom_vline(xintercept = 0)+
  facet_wrap(~section2)+
  ggtitle("U Histogram")

grid.arrange(gtemp,gtemp2,nrow=2, heights=c(1.2,1.2))


## ==================
##  Archipelago Population Growth Estimates by Stocklet(Umu)
## ==================

####
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
  stat_summary(fun.data=median_hilow,lty=2)+
  #stat_summary(fun.data=median_hilow,conf.int=0.5)+
  coord_flip()+
  theme_acs()+
  theme(legend.position="none")+
  ylab("Population Growth Rate [U]")+
  xlab("Site Specific Population Growth")+
  ggtitle("Populaiton Growth -dist decay model")

print(ucomp)


# ## ==================
# ## Estiamted Spawning Biomass (X) for each time step  
# ## ==================
# 
# edf1<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="X[1,1]"):which(colnames(myList[[1]])=="X[66,11]")]])
# names(edf1)<-c("num","chain","response","value")
# edf1$chain<-factor(edf1$chain)
# 
# edf1$group<-factor(sort(rep(seq(1:nSites),runL)))
# edf1$year<-sort(rep(seq(1:nYears),runL*nSites))
# 
# 
# for(i in 1:nSites){
#   tmp<-subset(edf1,year==i)
#   gtemp<-ggplot(tmp,aes(x=num,y=value,group=chain))+
#     geom_line(aes(colour=chain))+
#     facet_wrap(~group)+
#     theme_acs()+
#     ggtitle(paste("X chains_time_",i))
#   
#   print(gtemp)
# }
# 
# 
# ####posterior by site*time combiantions. 
# mx<-melt(X)
# names(mx)<-c("iter","time","stocklet","value")
# 
# 
# for(i in 1:nSites){
#   tmp<-subset(mx,time==i)
#   gt<-ggplot(tmp,aes(x=value))+
#     geom_histogram()+
#     facet_wrap(~stocklet)+
#     theme_acs()+
#     geom_vline(xintercept = 0)+
#     ggtitle(paste("X Posterior time_",i,".pdf"))
#   print(gt)
#   
# }
# 
## ==================
## Estiamted Process Variation (delta) through time
## ==================

#means
tempmat<-model$BUGSoutput$mean$delta
colnames(tempmat) <-colnames(SHI_car)
temp2<-melt(tempmat)
colnames(temp2) <-c("time","site","delta")
# 

dp<-ggplot(temp2,aes(x=time,y=delta,group=factor(site)))+
  geom_line(aes(colour=factor(site)))+
  theme_acs()
print(dp)

# 
# ## ==================
# ## Estiamted Process Variation (delta) chains & posteriors for each time step & stocklet
# ## ==================
# # 
# # #model$BUGSoutput$sims.array[,,"delta[1,1]"]
# # edf1<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="delta[1,1]"):which(colnames(myList[[1]])=="delta[66,11]")]])
# # 
# # names(edf1)<-c("num","chain","response","value")
# # edf1$chain<-factor(edf1$chain)
# # edf1$group<-factor(sort(rep(seq(1:nSites),runL)))
# # 
# # edf1$year<-sort(rep(seq(1:nYears),runL*nSites))
# # 
# # 
# # for(i in 1:nYears){
# #   tmp<-subset(edf1,year==i)
# #   dcg<- ggplot(tmp,aes(x=num,y=value,group=chain))+
# #     geom_line(aes(colour=chain))+
# #     facet_wrap(~group)+
# #     theme_acs()+
# #     ggtitle(paste("Delta chains_time_",i,".pdf"))
# #   print(dcg)
# # }
# # 
# # #posterior by site*time combiantions. 
# # dx<-melt(delta)
# # names(dx)<-c("iter","time","stocklet","value")
# # 
# # 
# # for(i in 1:nYears){
# #   tmp<-subset(dx,time==i)
# #   dhg<-ggplot(tmp,aes(x=value))+
# #     geom_histogram()+
# #     facet_wrap(~stocklet)+
# #     theme_acs()+
# #     geom_vline(xintercept = 0)+
# #     ggtitle(paste("Delta Posterior time_",i,".pdf"))
# #   
# #   print(dhg)
# #   
# # }
# # 
# # print(qhg)
# 
# 
# ## ==================
# ## Estiamted Average Catch Rate (Pc) through time by stocklet
# ## ==================
# 
# #means
# tempmat<-model$BUGSoutput$mean$Pc
# 
# INDEX2<-data.frame(INDEX,"posterior"=tempmat)
# names(INDEX2)<-c("time","stocklet","posterior")
# INDEX2$stocklet<-factor(INDEX2$stocklet)
# 
# #add site names from df2
# pcplot<-ggplot(INDEX2,aes(x=time,y=posterior))+
#   geom_point()+
#   facet_wrap(~stocklet)+
#   theme_acs()+
#   ggtitle("predicted catch")
# 
# print(pcplot)
# 
# ## ==================
# ## Estiamted Catch Rate (Pc) chains & posteriors for each time step & stocklet
# ## ==================
# 
# edf1<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="Pc[1]"):which(colnames(myList[[1]])=="Pc[156]")]])
# 
# names(edf1)<-c("num","chain","response","value")
# edf1$chain<-factor(edf1$chain)
# 
# ggplot(edf1,aes(x=num,y=value,group=chain))+
#   geom_line(aes(colour=chain))+
#   facet_wrap(~response)+
#   theme_acs()+
#   ggtitle(paste("Pc chains.pdf"))
# 
# 
# #could use some histogram plots too

dev.off()

