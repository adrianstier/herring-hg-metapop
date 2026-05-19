
library(ggplot2)
library(reshape2)
library(gdata)
library(maps)
library(mapproj)
library(ggmap)
library(gplots)
library(R2jags)
library(coda)

setwd("~/Dropbox/Projects/In Progress/Plan B/Pinniped_Herring_HG/Code")
setwd("~/Dropbox/Projects/In Progress/Code_SSL")
setwd("~/Desktop/Code_SSL")
source('theme_acs.R')

########################################################################
############ Load and plot herrring time series 
########################################################################

x=read.csv("HG_Spawn_Survey_1940_2013b.csv")
x<- x[c(1,3,13,14,15,16)]
x$SHI2<-log(x$SHI+0.1)
x$presabs <-ifelse(x$SHI>0,1,0)


#number of sites: 13
length(unique(x$section))
length(unique(x$section_name))

#plot out all the time series for each major region
ggher<-ggplot(x,aes(x=year,y=SHI),group=section_name)+
        geom_point(aes(colour=section_name))+
        geom_line(aes(colour=section_name))+
        #scale_y_log10()+
        theme_acs()+
        ggtitle("Herring By Spawn Area")
  

print(ggher)


#percent of years where there's been any spawn over past 75 years
100*round(tapply(x$presabs,list(x$section_name),sum)/
tapply(x$presabs,list(x$section_name),length),2)
tapply(x$SHI,list(x$section_name),mean)
tapply(x$SHI,list(x$section_name),sd)


#could loop through here for video.
x2013 <-subset(x,year==2013)
al1 = get_map(location = c(-135,51.5,-131,55), zoom = 7, maptype = 'terrain')
al1MAP = ggmap(al1)

hmap <-al1MAP+
  geom_point(data = x2013, aes(x = Longitude, y = Latitude,size=SHI2,fill=factor(presabs)),pch=21)+
  geom_text(data = x2013,aes(x = Longitude, y = Latitude,label=section_name),vjust=.1,hjust=-.1)+
  scale_size(range = c(4, 10))+
  ggtitle("herringSpawn2013")


print(hmap)

ggsave("herringSiteMap.pdf")

#would be good to use this to make tabulate number of years or average spawning season but mismatch in sites
xsum<-x2013[,c(1,3,4,5,6)]
xsum[with(xsum,order(names(tapply(x$SHI,list(x$section_name),mean)))),]
names(tapply(x$SHI,list(x$section_name),mean))




########################################################################
############ Estimate Distance Matrix and Spatial Autocor Function
########################################################################

#pull out site and site ID
df <- data.frame(x$section,x$section_name)
df2<-df[!duplicated(df), ]

dist_euc<-as.matrix(read.csv("h_dist_euc.csv")[,-1])
dist_shore<-as.matrix(read.csv("h_dist_shore.csv")[,-1])

colnames(dist_euc)<-df2[,2]
colnames(dist_shore)<-df2[,2]

# 
# #explore correlation function of herring spawn area abundance using GLS
# mod.exp = gls(SHI2 ~ section, correlation=corExp(form=~Latitude+Longitude,nugget=T),data=x2013) 
# mod.gaus = gls(SHI2 ~ section, correlation=corGaus(form=~Latitude+Longitude,nugget=T),data=x2013)
# 
# var.exp <- Variogram(mod.exp, form =~ x2013$Latitude+x2013$Longitude)
# plot(var.exp,main="Exponential",ylim=c(0,1))
# var.gaus <- Variogram(mod.gaus, form =~ x2013$Latitude+x2013$Longitude)
# plot(var.gaus,main="Gaussian",ylim=c(0,1))
# 
# distMat2 <-dist_euc

#blake's distance matrix for coastal swim converted to KM
distMat4<-as.matrix(read.csv("ssl_dist_shore.csv")[,-1]/1000)


########################################################################
############ Prep Matrix for Time Series, time in rows, spawn index colums
########################################################################

# EW: convert this to matrix the long way so it's clear what's going on
years = seq(1940,2013)
nYears = length(years)
nSites = length(df2[,2])

x2 <- x[,c(1,2,3)]
w <- reshape(x2, 
             timevar = "section",
             idvar = c("year"),
             direction = "wide")[,-1]

#replace zeros with NAs
w[w==0] <- NA
#double check that it has time ont he rows and sites on the column
Y= as.matrix(w)
Y = log(Y)


########################################################################
############JAGS CODE to fit model 
########################################################################

jagsscript = cat("
                 model {  
                 # Populations are independent, so the Q matrix is a diagonal. We'll assume
                 # B = 1, and there's no scaling (A) parameters because each time series = 1 state.
                 # Unlike MARSS, we can model the trends (U) as random effects - meaning we'll estimate
                 # a shared mean and sd across populations, as well as the deviations from that
                 Umu ~ dnorm(0,1);
                 Usig ~ dunif(0,100);
                 Utau <- 1/(Usig*Usig);
                 for(i in 1:nSites) {
                 U[i] ~ dnorm(Umu,Utau);
                 }
                 
                 tau ~ dgamma(0.01,0.01);
                 sigma2 <- 1/tau;
                 invEta ~ dgamma(0.01,0.01);
                 eta <- 1/invEta;
                 logtheta ~ dnorm(0,0.01);
                 theta <- exp(logtheta);
                 for(i in 1:nSites) {
                 for(j in 1:nSites) {
                 Q[i,j] <- sigma2 * exp(-theta * distMat4[i,j]) + eta*diag[i,j];
                 }
                 }   
                 # JAGS wants us to use the matrix inverse
                 tauQ[1:nSites,1:nSites] <- inverse(Q[1:nSites,1:nSites]);
                 
                 # Estimate the initial state vector of population abundances
                 for(i in 1:nSites) {
                 X[1,i] ~ dnorm(3,0.01); # vague normal prior 
                 }
                 # Autoregressive process for remaining years
                 for(i in 1:nSites) {zeros[i]<-0;}
                 delta[1,1:nSites] ~ dmnorm(zeros,tauQ[1:nSites,1:nSites]);
                 for(i in 2:nYears) {
                 delta[i,1:nSites] ~ dmnorm(delta[i-1,1:nSites],tauQ[1:nSites,1:nSites]);
                 for(j in 1:nSites) {
                 predX[i,j] <- X[i-1,j] + U[j];
                 X[i,j] <- predX[i,j] + delta[i,j];
                 }
                 }
                 
                 # Observation model
                 tauR ~ dgamma(0.001,0.001);
                 for(i in 1:nYears) {
                 for(j in 1:nSites) {
                 Y[i,j] ~ dnorm(X[i,j],tauR);
                 }
                 }
                 }  
                 
                 ",file="normal_spatialRW.txt")


jags.data = list("diag"=diag(nSites),"Y"=Y, "nYears"=nYears,"nSites"=nSites,"distMat4"=distMat4) # named list

jags.params=c("X","theta","eta","sigma2","U","Umu","Usig","delta","Q") # parameters in the linear regression model
model.loc="normal_spatialRW.txt" # name of the txt file


n.chains = 3
n.burnin=2000
n.thin=10
n.iter=5000

model = jags(jags.data, parameters.to.save=jags.params,
             model.file=model.loc, n.chains = n.chains, n.burnin=n.burnin, n.thin=n.thin, n.iter=n.iter, DIC=TRUE)

attach.jags(model)


#number of recorded mcmc
runL <- n.chains*(n.iter-n.burnin)/n.thin

########################################################################
############Quick Summary of Model Parameters
########################################################################

#look at individual parameter means
model$BUGSoutput$mean$X
model$BUGSoutput$mean$U
model$BUGSoutput$mean$delta
model$BUGSoutput$mean$theta
model$BUGSoutput$mean$Q

#look at each of the outputs by each run 
names(model$BUGSoutput$sims.list)

#look at the performance of the different chains
matplot(model$BUGSoutput$sims.array[,,6])

#consider grep to look at matching
hist(model$BUGSoutput$sims.matrix[,16])
image(model$BUGSoutput$mean$Q)
image(model$BUGSoutput$mean$delta)



#dimmensions of the parameters
nSites
nYears
str(model$BUGSoutput$sims.list)
dim(model$BUGSoutput$sims.array)


########################################################################
############Posterior Distributions
########################################################################

#look at gelman ruben plots, and see if they're close to one, which indicates chains finished in same spot then pool
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
#****
######
colnames(myList[[1]])#names of each of the output 

#####################
############Theta - Slope of the distance decay
#####################
summary(myList[[1]][2112])
#trace plot theta
matplot(as.matrix(data.frame(c(myList[[1]][,2112]),c(myList[[2]][,2112]),c(myList[[3]][,2112]))))


chain<-c(rep("chain1",runL/3),rep("chain2",runL/3),rep("chain3",runL/3))
num <- rep(seq(1:(runL/3)),3)
edf1<-data.frame(theta,chain,num)

ggplot(edf1,aes(y=theta,x=num,group=chain))+
  geom_line(aes(colour=chain))+
  theme_acs()
  
edf<-data.frame(theta)
ggplot(edf,aes(x=theta))+
  geom_bar()+
  theme_acs()+
  geom_vline(xintercept = 0)

#gelmanDiags = gelman.diag(createMcmcList(model),multivariate=TRUE)

#####################
############Umu - Average growth of all populations (static through time)
#####################

chain<-c(rep("chain1",runL/3),rep("chain2",runL/3),rep("chain3",runL/3))
num <- rep(seq(1:(runL/3)),3)
edf1<-data.frame(Umu,chain,num)

ggplot(edf1,aes(y=Umu,x=num,group=chain))+
  geom_line(aes(colour=chain))+
  theme_acs()

edf<-data.frame(Umu)
ggplot(edf,aes(x=Umu))+
  geom_bar()+
  theme_acs()+
  geom_vline(xintercept = 0)

#####################
############Usig
#####################

chain<-c(rep("chain1",runL/3),rep("chain2",runL/3),rep("chain3",runL/3))
num <- rep(seq(1:(runL/3)),3)
edf1<-data.frame(Usig,chain,num)

ggplot(edf1,aes(y=Usig,x=num,group=chain))+
  geom_line(aes(colour=chain))+
  theme_acs()

edf<-data.frame(Usig)
ggplot(edf,aes(x=Usig))+
  geom_bar()+
  theme_acs()+
  geom_vline(xintercept = 0)



#####################
############sigma2 
#####################

chain<-c(rep("chain1",runL/3),rep("chain2",runL/3),rep("chain3",runL/3))
num <- rep(seq(1:(runL/3)),3)
edf1<-data.frame(sigma2,chain,num)

ggplot(edf1,aes(y=sigma2,x=num,group=chain))+
  geom_line(aes(colour=chain))+
  theme_acs()

edf<-data.frame(sigma2)
ggplot(edf,aes(x=sigma2))+
  geom_bar()+
  theme_acs()+
  geom_vline(xintercept = 0)



#####################
############eta -nugget 
#####################

chain<-c(rep("chain1",runL/3),rep("chain2",runL/3),rep("chain3",runL/3))
num <- rep(seq(1:(runL/3)),3)
edf1<-data.frame(eta,chain,num)

ggplot(edf1,aes(y=eta,x=num,group=chain))+
  geom_line(aes(colour=chain))+
  theme_acs()


edf<-data.frame(eta)
ggplot(edf,aes(x=eta))+
  geom_bar()+
  theme_acs()+
  geom_vline(xintercept = 0)



#####################
############U -estiamtes of population growth 
#####################

chain<-c(rep("chain1",runL/3),rep("chain2",runL/3),rep("chain3",runL/3))
num <- rep(seq(1:(runL/3)),3)
colnames(U) <-colnames(myList[[1]])[170:182]
edf1<-data.frame(U,chain,num)

edf1<-melt(edf1,id.vars=c("chain","num"))

ggplot(edf1,aes(y=value,x=num,group=chain))+
  geom_line(aes(colour=chain))+
  theme_acs()+
  facet_wrap(~variable)


ggplot(edf1,aes(x=value))+
  geom_bar()+
  theme_acs()+
  geom_vline(xintercept = 0)+
  facet_wrap(~variable)

#add in a barplot with 95%CI for each population

#####################
############X -estiamtes of states for each pouplation at each time step 
#####################

#this is x number of runs where the output for each run is a matrix of 72 time steps by 13 sites
#could plot out the chains of  

tempmat<-model$BUGSoutput$mean$X
colnames(tempmat) <-c("site1","site2","site3","site4","site4","site6","site7","site8","site9","site10","site11","site12","site13")
temp2<-melt(tempmat)
colnames(temp2) <-c("time","site","X")

ggplot(temp2,aes(x=time,y=site,fill=X))+
  geom_tile()+
  theme_acs()

#yikes what's going on with site 4??? 
#add site names from df2

ggplot(temp2,aes(x=time,y=X,group=site))+
  geom_line(aes(colour=site))+
  theme_acs()

#the below isn't going to work 

chain<-c(rep("chain1",runL/3),rep("chain2",runL/3),rep("chain3",runL/3))
num <- rep(seq(1:(runL/3)),3)


colnames(X) <-colnames(myList[[1]])[185:1146]

edf1<-data.frame(U,chain,num)

edf1<-melt(edf1,id.vars=c("chain","num"))

ggplot(edf1,aes(y=value,x=num,group=chain))+
  geom_line(aes(colour=chain))+
  theme_acs()+
  facet_wrap(~variable)


ggplot(edf1,aes(x=value))+
  geom_bar()+
  theme_acs()+
  geom_vline(xintercept = 0)+
  facet_wrap(~variable)





























