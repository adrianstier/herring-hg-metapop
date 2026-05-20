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
library(Hmisc)

setwd("~/Dropbox/Projects/In Progress/Herring_Haida_Gwaii/Code")
#setwd("~/Dropbox/Projects/In Progress/Code")
#setwd("~/Desktop/Herring_Section")
source('multiplot.R')
source('theme_acs.R')

########################################################################
############ Load Herring Spawn Index, Catch Data, and Distance Matrix
########################################################################

# 
x=read.csv("HG_Spawn_Survey_1940_2013b.csv")
x<- x[c(1,3,13,14,15,16)]
x$SHI2<-log(x$SHI+1)
x$presabs <-ifelse(x$SHI>0,1,0)

years = seq(1950,2013)
nYears = length(years)
nSites = 11

x2 <- x[,c(1,2,4)]
w <- reshape(x2, 
             timevar = "section_name",
             idvar = c("year"),
             direction = "wide")[,-1]

#replace zeros with NAs
w[w==0] <- NA

#double check that it has time ont he rows and sites on the column
Y= as.matrix(w)

#subset out Cartwright Sound (4)-no catch data
Y = Y[-c(1:10),-c(4,7)] #drop site 4 since we have no catch data for Cartwright

#Y = Y/0.5 #q coefficient to turn into biomass
Y = log(Y)


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

#catch data
c <- read.csv("herring_catch_local.csv")
#namecheck<-data.frame("spawnindex"=unique(x[,c(3,4)])[-4,],"catch"=unique(c[,c(11,12)])[-c(13,14),])


#num unique sites
length(unique(c$Section))
#names of unique sites
unique(c$Name)

yr_c<-unique(c$Year)
c$presabs <-ifelse(c$TotalCatch>0,1,0)

#subset out Cartwright Sound (4) and masset (11)
c<-subset(c,Section %in% c(1,2,3,5,6,12,21,22,23,24,25))

#ctab<-data.frame(tapply(c$TotalCatch,list(c$Year,c$Section),sum)) #all catch
ctab<-data.frame(tapply(c$CatchJan_Apr,list(c$Year,c$Section),sum)) #just spring catch
ctab2<-ctab[-nrow(ctab),]

#double check column names
data.frame(colnames(Y),colnames(ctab2))

colnames(ctab2)<-colnames(Y)
ctab2<-as.matrix(ctab2)
ctab2_1<-log(ctab2+1)

#double check that names of catch and spawn match up

#make a prior matrix that sets the upper bound of the uniform distribution for prior Pc to be 0.95 when it's a non-zero and 0.01 when it's zero
ncol(ctab2_1)
nrow(ctab2_1)
nonz<-which(ctab2_1>0)
c_prior<-matrix(0.000001,nrow=nrow(ctab2_1),ncol=ncol(ctab2_1))


for(i in 1:length(nonz)){
  c_prior[nonz[i]]<-0.95
}

#load pdo
pdo<-read.csv("pdo.csv")
pdosummer<-subset(pdo,month %in% c(3,4,5,6)) #average april<-june
pdoxb<-c(tapply(pdo$Value,list(pdo$year),mean))
pdo2<-pdoxb[87:160] #1940-2013
pdo3<-pdo2[11:74] #1950-2013

#distance matrix by coastline
distMat4<-as.matrix(read.csv("h_dist_shore.csv")[,-1]/1000)
distMat5<-distMat4[-c(4,7),-c(4,7)]


#########
#CCF for all sites
#########

Y2<-Y

svec<-seq(1,nSites,by=1)

covmat<-matrix(NA,nSites,nSites)

#lag0
for(i in 1:11){
  for(j in 1:11){
    tmp<-data.frame(Y2[,i],Y2[,j])
    tmp<-tmp[complete.cases(tmp),]
    s1<-ccf(rank(tmp[,1]),rank(tmp[,2]),lag.max=0)
    covmat[i,j]<-s1$acf[,,1]
  }
}

covmat[lower.tri(covmat)] <-NA
diag(covmat) <- NA

distMat6 <- distMat5

distMat6[lower.tri(distMat6)]<-NA
diag(distMat6) <- NA

plot(covmat,distMat6)

ccf_df<-data.frame(melt(covmat),melt(distMat6)[,3])
names(ccf_df) <- c("site1","site2","cor","distance")

ggplot(ccf_df,aes(x=distance,y=cor))+
  geom_point()+
  geom_smooth(method="lm",se=F,colour="red",size=1)+
  #geom_smooth()+
  theme_acs()+
  xlab("Distance Between Sites")+
  ylab("Cross Correlation")+
  ggtitle("Correlation By as fish swims Distance, ignore Masset inlet")

#ggsave(paste("CCF_11_Sites_FishSwims",Sys.Date(),".pdf"))

f1<-lm(cor~distance,data=ccf_df)
summary(f1)
mean(ccf_df$cor,na.rm=T)

cdf<-melt(covmat)
boxplot(cdf$value)

#########
#CCF for all sites relative to PDO would be good too
#########



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
 ",file="normal_spatialRW_11sites_DiagEqual_v2_psi_free.txt")


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

setwd("~/Dropbox/Projects/In Progress/Herring_Haida_Gwaii/Code/Figures") 


                   

pdf(paste("Chains and Posteriors_11sites_DiagEqual_v2_Psifree",Sys.Date(),".pdf"), onefile = TRUE)

#############
#Predicted versus Observed Biomass 
############

#labels for graph
sitelab<-paste(rep("Section",11),as.character(unique(x$section))[-c(4,7)])
sitelab2<-unique(x$section_name)[-c(4,7)]
data.frame(sitelab,sitelab2)

plot(model)

#acual data 
y2<-data.frame("time"=seq(1,nYears,1),Y)
mm2 <- melt(y2,id.vars<-"time")
names(mm2) <- c("time","site","shi")

#adjust by converting y to biomass through q
  mm2$b<-mm2$shi-median(q) #ignore this, it's the other way of transforming shi
  
  #means
  tempmat<-model$BUGSoutput$mean$X
  colnames(tempmat) <-sitelab2
  temp2<-melt(tempmat)
  colnames(temp2) <-c("time","site","X")
  
  jsdf<- data.frame(temp2,"shi"=mm2$shi)  
  
  ggplot(jsdf,aes(x=shi,y=X,colour=site))+
    geom_point()+
    geom_abline(slope=1,intercept=0,lty=2)+
    facet_wrap(~site,scales="free")+
    theme_acs()
  #temp3<-reshape(temp2,timevar = "site",idvar=c("time"),direction="wide")[,-1]
  
  mm3<-data.frame(mm2[,-4],temp2[,'X']+median(q)) #subset out b
  names(mm3)<-c("time","site","observed","predicted")
  mm4<-melt(mm3,id.vars<-c("time","site"))
  mm4$value2<- exp(mm4$value) #arithmetic
  
  obs<-subset(mm4,variable=="observed")
  pred<-subset(mm4,variable=="predicted")
  
  ggplot()+
    geom_line(data=pred,aes(x=time,y=value,colour=factor(site)))+
    geom_point(data=obs,aes(x=time,y=value,colour=factor(site)))+
    facet_wrap(~site,scales="free_y")+
    theme_acs()+
    theme(legend.position="none")+
    ggtitle("Predicted (line) and Observed Spawning Biomass (dots)")+
    xlab("Time (years)")+
    ylab("Log Spawning Biomass")
  
  

  
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
	stat_summary(fun.data=median_hilow,lty=2)+
	#stat_summary(fun.data=median_hilow,conf.int=0.5)+
	coord_flip()+
	theme_acs()+
	    theme(legend.position="none")+

	ylab("Population Growth Rate [U]")+
	xlab("Site Specific Population Growth")+
	ggtitle("Populaiton Growth -dist decay model")

print(ucomp)


#######
#Print Chains and Histograms
######

qdf<-melt(model$BUGSoutput$sims.array[,,"q"])
psidf<-melt(model$BUGSoutput$sims.array[,,"psi"])
pdodf<-melt(model$BUGSoutput$sims.array[,,"pdocoef"])
#thetadf<-melt(model$BUGSoutput$sims.array[,,"theta"])
Umudf<-melt(model$BUGSoutput$sims.array[,,"Umu"])
Usigdf<-melt(model$BUGSoutput$sims.array[,,"Usig"])
tauRdf<-melt(model$BUGSoutput$sims.array[,,"tauR"])
sigma2df<-melt(model$BUGSoutput$sims.array[,,"sigma2[1]"])

slist<-list(qdf,psidf,pdodf,Umudf,Usigdf,tauRdf,sigma2df)
nm<-c("q","psi","pdocoef","Umu","Usig","tauR","sigma2")



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


#####################
############U -estiamtes of states for each pouplation at each time step 
#####################


udf<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="U[1]"):which(colnames(myList[[1]])=="U[11]")]])


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






#####################
############X -estiamtes of states for each pouplation at each time step 
#####################

edf1<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="X[1,1]"):which(colnames(myList[[1]])=="X[64,11]")]])
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
  geom_histogram()+
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
colnames(tempmat) <-colnames(Y)
temp2<-melt(tempmat)
colnames(temp2) <-c("time","site","delta")
# 
#add site names from df2
 ggplot(temp2,aes(x=time,y=site,fill=delta))+
   geom_tile()+
   theme_acs()
# 
dp<-ggplot(temp2,aes(x=time,y=delta,group=factor(site)))+
   geom_line(aes(colour=factor(site)))+
   theme_acs()
print(dp)

##Posterior plots
model$BUGSoutput$sims.array[,,"delta[1,1]"]

edf1<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="delta[1,1]"):which(colnames(myList[[1]])=="delta[64,11]")]])

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

#means
tempmat<-model$BUGSoutput$mean$Pc
colnames(tempmat) <-sitelab
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

edf1<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="Pc[1,1]"):which(colnames(myList[[1]])=="Pc[64,11]")]])

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
    geom_histogram()+
    facet_wrap(~Var3)+
    theme_acs()+
    geom_vline(xintercept = 0)+
    ggtitle(paste("Pc Posteriors time_",i,".pdf"))
  print(pcg)
}




dev.off()


