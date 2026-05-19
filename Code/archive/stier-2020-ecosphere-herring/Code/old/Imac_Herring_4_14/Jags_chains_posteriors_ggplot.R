library(ggplot2)
library(reshape2)
library(R2jags)
library(coda)

#I've included some output here which I think should help with the exampel below. 
load("herring_jags_F.RData")

########################################################################
############Quick Summary of Model Parameters
########################################################################

#look at individual parameter means (this is ignoring the different chains)
model$BUGSoutput$mean$X #e.g. #for my data it's 12 sites (columns) and 64 years (rows)
model$BUGSoutput$mean$U
model$BUGSoutput$mean$delta
model$BUGSoutput$mean$theta
model$BUGSoutput$mean$Q
model$BUGSoutput$mean$pdo
model$BUGSoutput$mean$q
model$BUGSoutput$mean$psi
model$BUGSoutput$mean$Pc
model$BUGSoutput$mean$tauR

#list differnet parameters 
names(model$BUGSoutput$sims.list)

#structure of initial output from jags
str(model$BUGSoutput$sims.list)
dim(model$BUGSoutput$sims.array)


#example chains in matplot (want these to be overlapping)
matplot(model$BUGSoutput$sims.array[,,"U[1]"])
matplot(model$BUGSoutput$sims.array[,,"Q[1,1]"])

########################################################################
############Chain Convergence and Posterior Distributions using ggplot
########################################################################

#this is the quick and dirty way to look at your parameters. this should plot each param and the 
#different colored dots represent different chains. Overlapping dots means overlapping chains. 

plot(model)

#reorganize the mcmcm output to make it easier to plot
createMcmcList = function(model) {
  McmcArray = as.array(model$BUGSoutput$sims.array)
  McmcList = vector("list",length=dim(McmcArray)[2])
  for(i in 1:length(McmcList)) McmcList[[i]] = as.mcmc(McmcArray[,i,])
  McmcList = mcmc.list(McmcList)
  return(McmcList)
}

myList<-createMcmcList(model)

#Mylist is a reformatted version of the array that has the individual chains  
myList[[1]] #the number in brackets here refers to the chain number


#names of each of the output variable
colnames(myList[[1]]) 


#there's probably a faster way to do this automatically for all different variables, but so far i've been looking at each 
#parameter individually. In my model the different parameters have different dimmensions

#####################
############PDO Coef  - a single covariate estimate. 
#####################

model$BUGSoutput$sims.array[,,"pdocoef"]
edf1<-melt(model$BUGSoutput$sims.array[,,"pdocoef"])

names(edf1)<-c("num","chain","value")
edf1$chain<-factor(edf1$chain)

#here is a plot of the different chains
ggplot(edf1,aes(y=value,x=num,group=chain))+
  geom_line(aes(colour=chain))+
  theme_acs()

#here is aplot of the posterior distribution
edf<-data.frame(pdocoef)
ggplot(edf,aes(x=pdocoef))+
  geom_bar()+
  theme_acs()+
  geom_vline(xintercept = 0)

ggsave("pdocoef.pdf")


#####################
############U -estiamtes of population growth 
#####################

#here is an example of one where i look at all 12 of the u (pop growth) estimates 

edf1<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="U[1]"):which(colnames(myList[[1]])=="U[12]")]])
names(edf1)<-c("num","chain","response","value")
edf1$chain<-factor(edf1$chain)

ggplot(edf1,aes(y=value,x=num,group=chain))+
  geom_line(aes(colour=chain))+
  theme_acs()+
  facet_wrap(~response)

ggsave("U_chains.pdf")


ggplot(edf1,aes(x=value))+
  geom_bar()+
  theme_acs()+
  geom_vline(xintercept = 0)+
  facet_wrap(~response)

ggsave("U_hist.pdf")


#####################
############X -estiamtes of states for each pouplation at each time step 
#####################

#here's one with loops to plot chains each of the 12 sites for each of the 64 time steps

#means
tempmat<-model$BUGSoutput$mean$X
colnames(tempmat) <-c("site1","site2","site3","site5","site6","site7","site8","site9","site10","site11","site12","site13")
temp2<-melt(tempmat)
colnames(temp2) <-c("time","site","X")

ggplot(temp2,aes(x=time,y=site,fill=X))+
  geom_tile()+
  theme_acs()

#add site names from df2
ggplot(temp2,aes(x=time,y=exp(X),group=site))+
  geom_line(aes(colour=site))+
  theme_acs()

ggsave("X.pdf")

edf1<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="X[1,1]"):which(colnames(myList[[1]])=="X[64,12]")]])


names(edf1)<-c("num","chain","response","value")
edf1$chain<-factor(edf1$chain)


edf1$group<-factor(sort(rep(seq(1:nSites),runL)))
edf1$year<-sort(rep(seq(1:nYears),runL*nSites))

setwd("~/Dropbox/Projects/In Progress/Pinniped_Herring_HG/Code/Figures/Herring/Chains/Herring_X")

for(i in 1:nSites){
  tmp<-subset(edf1,year==i)
  ggplot(tmp,aes(x=num,y=value,group=chain))+
    geom_line(aes(colour=chain))+
    facet_wrap(~group)+
    theme_acs()
  ggsave(paste("chains_time_",i,".pdf"))
  
}


####posterior by site*time combiantions. 
chain<-c(rep("chain1",runL/3),rep("chain2",runL/3),rep("chain3",runL/3))
num <- rep(seq(1:(runL/3)),3)
mx<-melt(X)
mx$chain<-chain
mx$num<-num

setwd("~/Dropbox/Projects/In Progress/Pinniped_Herring_HG/Code/Figures/Posteriors/Herring_X")

for(i in 1:nSites){
tmp<-subset(mx,Var2==i)
ggplot(tmp,aes(x=value))+
  geom_bar()+
  facet_wrap(~Var3)+
  theme_acs()+
  geom_vline(xintercept = 0)
ggsave(paste("time_",i,".pdf"))
  
}



