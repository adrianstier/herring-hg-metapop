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
## Set up Distance Matrix by Coastline
## ==================

#distance matrix by coastline
distMat4<-as.matrix(read.csv("h_dist_shore.csv")[,-1]/1000)
distMat5<-distMat4[-c(4,7),-c(4,7)]


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
tauR2  ~ dgamma(5,7); #this is the estimated variance prior for Spawn Index to Spawn Biomass Conversion
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

#distance decay parameters 
theta ~ dgamma(10,0.6) 
eta2 ~ dgamma(1.2,2.4)

#COVARIATE
pdoz2   <- 1
pdocoef ~ dnorm(0,1/pdoz2); #estimated impact of pdo of herring

#VARINCE MATRIX - Diagonal and Equal - same variance all sites 

# For indepenent and equal variances
#sigma2 ~ dgamma(0.001,0.001); #with the nugget this went to zero so switched 
sigma2 ~ dgamma(1.2,1.5)

for(j in 1:nSites) {
sigma2.all[j] <- sigma2; #replicate initial value for all sigma2
}


#dummy variable for q matrix var to SD 

for(j in 1:nSites) {
 	sigma.allb[j] <-sqrt(sigma2.all[j])  #this is SD not variance change to sigma 
}

#variance covariance matrix, and Precision matrix inverse for Q
#when i=j the diagonal is just sigma2 because distance=0

for(i in 1:nSites) {
	for(j in 1:nSites) {
    	Q[i,j] <- sigma.allb[i]*sigma.allb[j] * exp(-distMat5[i,j]/theta) + eta2*Diag[i,j]

  }
}   

tauQ[1:nSites,1:nSites] <- inverse(Q[1:nSites,1:nSites]) #inverse varcov matrix to be precision space

# Estimate the initial state vector of population abundances

for(j in 1:nSites) {
      Z[1,j] ~ dnorm(5,1/100); # vague normal prior for first time step #changed from inverse 3/31
      X[1,j] <- Z[1,j] + log(1-Pc.mat[1,j]) # changed to reflect handwritten model 3/31
  }


# Initial Values for Delta 
for(j in 1:nSites) {zeros[j]<-0}
delta[1,1:nSites] ~ dmnorm(zeros,tauQ[1:nSites,1:nSites]);


# change in pop through time that's uniqe to site/time
for(i in 2:nYears){

    delta[i,1:nSites] ~ dmnorm(zeros,tauQ[1:nSites,1:nSites]) #estimate procss variation - no temp autocor

  for(j in 1:nSites){
     
    Z[i,j] <- X[(i-1),j]+Umu+pdocoef*pdo[i-1]+delta[(i-1),j] #fishing by site and global pdo estimates and U estimates   
  	X[i,j] <-Z[i,j]+log(1-Pc.mat[i,j]) #Estimate the state X with catch by site

  }
}


} 
 ",file="diagonal_equal_design_c_DDspatial_noUsig.txt")


#data going into the model
jags.data = list("Y"=logSHI, "nYears"=nYears,"nSites"=nSites,"pdo"=pdo2,"ctab"= logcatch,
                 "INDEX"=INDEX,"INDEX.zero"=INDEX.zero, "nIndex"=nIndex,"nIndex.zero"=nIndex.zero,
                 "distMat5"=distMat5,"Diag"=diag(nSites)) # named list

jags.params=c("X","sigma2","Umu","delta","Z",
			"pdocoef","log.q","Pc","tauR2","Q","theta","eta2")



model.loc="diagonal_equal_design_c_DDspatial_noUsig.txt" # name of the txt file

n.chains = 4
n.burnin = 100000
n.thin = 10
n.iter = 150000

#number of recorded mcmc
runL <- n.chains*(n.iter-n.burnin)/n.thin

inits = NULL

#need to add the inits for the Pc and q params

for(i in 1:n.chains){
  inits[[i]]    <- list(
    "Umu" = 0.1,
    #"Usig2" = runif(1,0,1),
    "pdocoef" = -0.2,
    "log.q" = 3,
    "tauR2" = runif(1,0,1)
    #"theta" = runif(1,0,1)
    ) 
}
    
model = jags(jags.data, inits=inits,parameters.to.save=jags.params,
            model.file=model.loc, n.chains = n.chains, n.burnin=n.burnin, n.thin=n.thin, n.iter=n.iter, DIC=TRUE)

# attach.jags(model)

mDIC<-model$BUGSoutput$DIC 
pD<-model$BUGSoutput$pD
devi<-model$BUGSoutput$deviance

## ==================
## Save/Load model output
## ==================


# save("model","mDIC","X","U","Umu","Usig2","Z","delta","sigma2","pdo","pdocoef","Pc","log.q","tauR2",
#      "design.c",
#      file="diagonal_equal_design_c_DDspatial.Rdata")

# setwd("~/Desktop/Herring_2016")
# 
# save("model","mDIC","inits","design.c",
#      file="diagonal_equal_design_c_DDspatial_noUsig_eta.Rdata")

setwd("~/Dropbox/Projects/In Progress/Herring_Haida_Gwaii/Code")
# 
load("diagonal_equal_design_c_DDspatial_noUsig_eta.Rdata")


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

setwd("~/Dropbox/Projects/In Progress/Herring_Haida_Gwaii/Code")
pdf(paste("diagonal_equal_design_c_DDspatial_noUsig_nugget",Sys.Date(),".pdf"), onefile = TRUE)

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


temp2$SHI<-melt(logSHI)$value
temp2$xq <- temp2$X + median(model$BUGSoutput$mean$log.q) #add in the scalar for predicted SHI
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
##  Estimated Spawning Biomass (X) of all Stocks 
## ==================

#means by stocklet
tempmat<-scale(model$BUGSoutput$mean$X)
colnames(tempmat) <- colnames(Y) #<-seq(1,11,1)
temp2<-melt(tempmat)
colnames(temp2) <-c("time","site","x")
temp2$year<-years
temp2$year<-as.numeric(temp2$year)

t3<-data.frame("x"=tapply(temp2$x,list(temp2$year),mean))
t3$year<-years
t3$year<-as.numeric(t3$year)
t3$site<-12
t3$max<-tapply(temp2$x,list(temp2$time),max)
t3$min<-tapply(temp2$x,list(temp2$time),min)
names(t3)<-c("x","year","site","max","min")

bk<-seq(1950,2015,by=10)

#which populations are above and below long term average 
lta<-subset(temp2,year==2015)
lta$ab<-ifelse(lta$x>0,1,0)

#plot each stocklet and archipleago mean with bounds

ggplot()+
  geom_ribbon(data=t3,aes(x=year,ymin=min,ymax=max),colour="grey60")+
  geom_line(data=temp2,aes(x=year,y=x,colour=factor(site),lty=factor(site),group=site))+
  geom_line(data=t3,aes(x=year,y=x),colour="white",size=2)+
  geom_line(data=t3,aes(x=year,y=max))+
  geom_line(data=t3,aes(x=year,y=min))+
  #scale_colour_continuous(low="green",high="red")+
  geom_vline(xintercept=1967,colour="grey",lty=2)+ #this is the closure of the reduction 
  geom_vline(xintercept=1994,colour="grey",lty=2)+ #this is the big recent closure 
  geom_hline(yintercept=0)+
  theme_acs()+
  scale_x_continuous(breaks=bk)+
  #coord_trans(y="log10")+
  #scale_y_log10(breaks=c(.1,1,10),labels=c(0.1,1,10))+
  xlab("Year")+
  ylab("Scaled Estimated Total Biomass X")


## ==================
##  Catchability (q), PDOcoef, Archipelago growth, Arch var, 
## ==================

qdf<-melt(model$BUGSoutput$sims.array[,,"log.q"])
tauRdf<-melt(model$BUGSoutput$sims.array[,,"tauR2"])
# psidf<-melt(model$BUGSoutput$sims.array[,,"psi"])
pdodf<-melt(model$BUGSoutput$sims.array[,,"pdocoef"])
thetadf<-melt(model$BUGSoutput$sims.array[,,"theta"])
etadf<-melt(model$BUGSoutput$sims.array[,,"eta2"])
Umudf<-melt(model$BUGSoutput$sims.array[,,"Umu"])
#Usigdf<-melt(model$BUGSoutput$sims.array[,,"Usig2"])
sigma2df<-melt(model$BUGSoutput$sims.array[,,"sigma2"])

slist<-list(qdf,tauRdf,pdodf,Umudf,thetadf,etadf,sigma2df)
nm<-c("log.q","tauR2","pdocoef","Umu","theta","eta","sigma2")

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


#distance decay parameters 
# theta ~ dgamma(10,0.6) 
# eta2 ~ dgamma(1.2,2.4)
# sigma2 ~ dgamma(1.2,1.5)
# tauR2  ~ dgamma(5,7)


#theta
x=seq(0,60,by=0.01)
value<-rgamma(20000, shape=10, rate=0.6)
temp<-data.frame(20000,value)

gtheta<-
  ggplot()+
  geom_density(data=temp,aes(x=value,y=..scaled..),fill="dodgerblue",alpha=0.5,bw=1)+
  geom_density(data=thetadf,aes(x=value,y=..scaled..),fill="firebrick",alpha=0.75,bw=1)+
  theme_acs()+
  ggtitle("theta")

print(gtheta)


par(mfrow=c(2,1))
hist(thetadf$value,freq=F)
x=seq(0,60,by=0.01)
value<-dgamma(x, shape=10, rate=0.6)
t_df<-data.frame(x,value)
plot(t_df,xlim=c(0,60),type="l",col=2)

# ggplot(t_df,aes(x=x,y=value))+
#   geom_line()

gtheta2<-
  ggplot(data=thetadf,aes(x=value)) + 
  geom_histogram(aes(y=..density..)) +
  geom_density()+
  # geom_line(data=t_df,aes(x=x,y=value),colour="red")+
  stat_function(fun=dgamma, args=list(shape=10, rate=0.6),colour="red")+
  theme_acs()+
  ggtitle("Theta")
  
print(gtheta2)




#eta
x=seq(0,1,by=0.0001)
value<-rgamma(20000, shape=1.2, rate=2.4)
temp<-data.frame(20000,value)
  
geta<-
  ggplot()+
  geom_density(data=temp,aes(x=value,y=..scaled..),fill="dodgerblue",alpha=0.5,bw=0.1)+
  geom_density(data=etadf,aes(x=value,y=..scaled..),fill="firebrick",alpha=0.75,bw=0.01)+
  theme_acs()+
  ggtitle("eta2")+
  scale_x_continuous(limits=c(0,1))

print(geta)

par(mfrow=c(2,1))
hist(etadf$value,freq=F)
x=seq(0,1,by=0.0001)
value<-dgamma(x, shape=1.2, rate=2.4)
e_df<-data.frame(x,value)
plot(e_df,type="l",xlim=c(0,0.35),col=2)

geta2<-
  ggplot(data=etadf,aes(x=value)) + 
  geom_histogram(aes(y=..density..)) +
  geom_density()+
  # geom_line(data=t_df,aes(x=x,y=value),colour="red")+
  stat_function(fun=dgamma, args=list(shape=1.2, rate=2.4),colour="red")+
  theme_acs()+
  ggtitle("Eta2")

print(geta2)




#sigma2
x=seq(0,1,by=0.0001)
value<-rgamma(20000, shape=1.2, rate=1.5)
temp<-data.frame(20000,value)

gsigma2<-
  
  ggplot()+
  geom_density(data=temp,aes(x=value,y=..scaled..),fill="dodgerblue",alpha=0.5,bw=0.1)+
  geom_density(data=sigma2df,aes(x=value,y=..scaled..),fill="firebrick",alpha=0.75,bw=0.1)+
  theme_acs()+
  ggtitle("sigma2")+
  scale_x_continuous(limits=c(0,1))

print(gsigma2)

par(mfrow=c(2,1))
hist(sigma2df$value,freq=F)
x=seq(0,1,by=0.0001)
value<-dgamma(x, shape=1.2, rate=1.5)
s_df<-data.frame(x,value)
plot(s_df,type="l",xlim=c(0,0.4),col=2)

#tauR2
x=seq(0,2,by=0.0001)


value<-rgamma(20000, shape=5, rate=7)
temp<-data.frame(20000,value)

gtaur2<-
  
  ggplot()+
  geom_density(data=temp,aes(x=value,y=..scaled..),fill="dodgerblue",alpha=0.5,bw=0.1)+
  geom_density(data=tauRdf,aes(x=value,y=..scaled..),fill="firebrick",alpha=0.75,bw=0.1)+
  theme_acs()+
  ggtitle("tauR2")+
  scale_x_continuous(limits=c(0,2))

print(gtaur2)

par(mfrow=c(2,1))
hist(tauRdf$value,freq=F,xlim=c(0,2))
x=seq(0,2,by=0.0001)
value<-dgamma(x, shape=5, rate=7)
t_df<-data.frame(x,value)
plot(t_df,type="l",xlim=c(0,2),col=2)




multiplot(gtheta,geta,gsigma2,gtaur2,cols=2)



## ==================
##  Stocklet Specific Populaiton Growth Estimats (Ui)
## ==================
# 
# udf<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="U[1]"):which(colnames(myList[[1]])=="U[11]")]])
# names(udf)<-c("num","chain","response","value")
# udf$chain<-factor(udf$chain)
# udf$section2<-as.character(sort(rep(unique(x$section)[-c(4,7)],nrow(udf)/nSites)))
# 
# gtemp<- ggplot(udf,aes(y=value,x=num,group=chain))+
#   geom_line(aes(colour=chain))+
#   theme_acs()+
#   facet_wrap(~section2)+
#   theme(legend.position="none")+
#   ggtitle("U Chains")
# 
# gtemp2<-ggplot(udf,aes(x=value))+
#   geom_histogram()+
#   theme_acs()+
#   geom_vline(xintercept = 0)+
#   facet_wrap(~section2)+
#   ggtitle("U Histogram")
# 
# grid.arrange(gtemp,gtemp2,nrow=2, heights=c(1.2,1.2))
# 
# 
# ## ==================
# ##  Archipelago Population Growth Estimates by Stocklet(Umu)
# ## ==================
# 
# ####
# Umudf<-melt(model$BUGSoutput$sims.array[,,"Umu"])
# Umudf$Var3<-"Umu"
# Umudf<-Umudf[,c(1,2,4,3)]
# umuci<-smedian.hilow(Umudf$value,conf.int=0.95)
# umuci2<-quantile(Umudf$value,c(0.05,0.95))
# 
# tlist<-model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="U[1]"):which(colnames(myList[[1]])=="U[11]")]]
# dimnames(tlist)[[3]]<-colnames(Y)
# udf<-melt(tlist)
# 
# ucomp<-ggplot(udf,aes(x=Var3,y=value,colour=Var3))+
#   geom_hline(yintercept=median(Umudf$value),lty=2)+
#   geom_hline(yintercept= umuci2[1],lty=1,colour="grey")+
#   geom_hline(yintercept= umuci2[2],lty=1,colour="grey")+
#   stat_summary(fun.data=median_hilow,lty=2)+
#   #stat_summary(fun.data=median_hilow,conf.int=0.5)+
#   coord_flip()+
#   theme_acs()+
#   theme(legend.position="none")+
#   ylab("Population Growth Rate [U]")+
#   xlab("Site Specific Population Growth")+
#   ggtitle("Populaiton Growth -dist decay model")
# 
# print(ucomp)


## ==================
## Estiamted Spawning Biomass (X) for each time step  
## ==================

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


####posterior by site*time combiantions. 
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

## ==================
## Estiamted Process Variation (delta) through time
## ==================

##########################################
############Delta -estiamtes of states for each population's change
##########################################

#means
tempmat<-model$BUGSoutput$mean$delta
colnames(tempmat) <- colnames(Y) #<-seq(1,11,1)
temp2<-melt(tempmat)
colnames(temp2) <-c("time","site","delta")
#temp2$site<-as.numeric(temp2$site)
temp2$year<-years
temp2$year<-as.numeric(temp2$year)

# 
#add site names from df2
ggplot(temp2,aes(x=time,y=site,fill=delta))+
  geom_tile()+
  scale_fill_gradient2(low="red",high="dodgerblue")+
  theme_acs()
# 

t3<-data.frame("delta"=tapply(temp2$delta,list(temp2$time),mean))
t3$year<-years
t3$year<-as.numeric(t3$year)
t3$site<-12
t3$max<-tapply(temp2$delta,list(temp2$time),max)
t3$min<-tapply(temp2$delta,list(temp2$time),min)
names(t3)<-c("delta","year","site","max","min")

# dts<-ts(c(t3$delta),start=1950,end=2015,frequency=1)
# mppt<-cpt.mean(dts,method="PELT")
# cpts(mppt)
# plot(mppt)


# t3max<-t3[,c(2,3,5)]  
# names(t3max)<-c("year","site","delta")
# t3min<-t3[,c(2,3,4)]  
# names(t3min)<-c("year","site","delta")
# bk<-seq(1950,2015,by=10)

dp<-ggplot()+
  geom_ribbon(data=t3,aes(x=year,ymin=min,ymax=max),colour="grey60")+
  geom_line(data=temp2,aes(x=year,y=delta,colour=factor(site),lty=factor(site),group=site))+
  geom_line(data=t3,aes(x=year,y=delta),colour="white",size=2)+
  geom_hline(yintercept=0)+
  #geom_line(data=t3,aes(x=year,y=max))+
  #geom_line(data=t3,aes(x=year,y=min))+
  #scale_colour_continuous(low="green",high="red")+
  geom_vline(xintercept=1967,colour="grey",lty=2)+ #this is the closure of the reduction 
  geom_vline(xintercept=1994,colour="grey",lty=2)+ #this is the big recent closure 
  theme_acs()+
  scale_x_continuous(breaks=bk)+
  xlab("Year")+
  ylab("Detrended Population Performance (Delta)")
print(dp)

## ==================
## Estiamted Process Variation (delta) chains & posteriors for each time step & stocklet
## ==================
# 
# #model$BUGSoutput$sims.array[,,"delta[1,1]"]
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
#   dcg<- ggplot(tmp,aes(x=num,y=value,group=chain))+
#     geom_line(aes(colour=chain))+
#     facet_wrap(~group)+
#     theme_acs()+
#     ggtitle(paste("Delta chains_time_",i,".pdf"))
#   print(dcg)
# }
# 
# #posterior by site*time combiantions. 
# dx<-melt(delta)
# names(dx)<-c("iter","time","stocklet","value")
# 
# 
# for(i in 1:nYears){
#   tmp<-subset(dx,time==i)
#   dhg<-ggplot(tmp,aes(x=value))+
#     geom_histogram()+
#     facet_wrap(~stocklet)+
#     theme_acs()+
#     geom_vline(xintercept = 0)+
#     ggtitle(paste("Delta Posterior time_",i,".pdf"))
#   
#   print(dhg)
#   
# }
# 
# print(qhg)


## ==================
## Estiamted Average Catch Rate (Pc) through time by stocklet
## ==================

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

## ==================
## Estiamted Catch Rate (Pc) chains & posteriors for each time step & stocklet
## ==================

#edf1<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="Pc[1]"):which(colnames(myList[[1]])=="Pc[156]")]])

#names(edf1)<-c("num","chain","response","value")
#edf1$chain<-factor(edf1$chain)

#ggplot(edf1,aes(x=num,y=value,group=chain))+
#    geom_line(aes(colour=chain))+
#    facet_wrap(~response)+
#    theme_acs()+
#    ggtitle(paste("Pc chains.pdf"))


#could use some histogram plots too

dev.off()

