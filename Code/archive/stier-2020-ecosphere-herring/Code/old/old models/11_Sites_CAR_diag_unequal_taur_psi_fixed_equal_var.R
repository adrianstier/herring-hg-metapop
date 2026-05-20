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
library(PBSmapping)

data(nepacLLhigh)#load the map data

setwd("~/Dropbox/Projects/In Progress/Herring_Haida_Gwaii/Code")
#setwd("~/Dropbox/Projects/In Progress/Code")
#setwd("~/Desktop/Herring_Substock")
source('multiplot.R')
source('theme_acs.R')

########################################################################
############ Load Herring Spawn Index, Catch Data, and Distance Matrix
########################################################################

# 
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

#replace zeros with NAs
w[w==0] <- NA

#double check that it has time ont he rows and sites on the column
Y= as.matrix(w)

#subset out Cartwright Sound (4)-no catch data
Y = Y[-c(1:10),-c(4)] #drop site 4 since we have no catch data for Cartwright, Masset because there are so few points

#Log index, 
Y = log(Y)

Y_car<- Y[,c(9,10,11,8,12,5,1,4,3,2,7,6)]
Y_car<-Y_car[,c(1:11)]#subset out Masset inslet - limited data 


ym<-melt(Y_car)
ym<-data.frame(ym,rep(seq(1:nrow(Y_car)),ncol(Y_car)))
names(ym)<-c("crap","site","logSHI","time")

ggplot(ym,aes(x=time,y=logSHI))+
         geom_point(aes(colour=site))+
         geom_smooth(method="lm")+
         facet_grid(.~site)+
         theme_acs()

#labels for graph
sitelab<-paste(rep("Section",12),as.character(unique(x$section))[-4])
sitelab2<-unique(x$section_name)[-c(4,7)]
sl<-data.frame(sitelab,sitelab2)

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
c <- read.csv("herring_catch_local2015.csv")
#namecheck<-data.frame("spawnindex"=unique(x[,c(3,4)])[-4,],"catch"=unique(c[,c(11,12)])[-c(13,14),])

#num unique sites
length(unique(c$Section))
#names of unique sites
unique(c$Name)

yr_c<-unique(c$Year)
c$presabs <-ifelse(c$TotalCatch>0,1,0)

#subset out Cartwright Sound (4) 
c<-subset(c,Section %in% c(1,2,3,5,6,11,12,21,22,23,24,25))

#ctab<-data.frame(tapply(c$TotalCatch,list(c$Year,c$Section),sum)) #all catch
ctab<-data.frame(tapply(c$CatchJan_Apr,list(c$Year,c$Section),sum)) #just spring catch
ctab2<-ctab#[-nrow(ctab),]


ctab2_1_car<-ctab2[,c(9,10,11,8,12,5,1,4,3,2,7,6)] #car model
ctab2_1_car<-ctab2_1_car[,c(1:11)]


colnames(ctab2_1_car)<-colnames(Y_car)
ctab2_1_car <-log(ctab2_1_car+1)
ctab2_1_car<-as.matrix(ctab2_1_car)


#double check that names of catch and spawn match up

#make a prior matrix that sets the upper bound of the uniform distribution for prior Pc to be 0.95 when it's a non-zero and 0.01 when it's zero
ncol(ctab2_1_car)
nrow(ctab2_1_car)
nonz<-which(ctab2_1_car>0)
c_prior<-matrix(0.000001,nrow=nrow(ctab2_1_car),ncol=ncol(ctab2_1_car))

for(i in 1:length(nonz)){
  c_prior[nonz[i]]<-0.95
}

#load pdo
pdo<-read.csv("pdo.csv")
pdosummer<-subset(pdo,month %in% c(3,4,5,6)) #average march<-june
pdoxb<-c(tapply(pdosummer$Value,list(pdosummer$year),mean))
pdo2<-pdoxb[87:162] #1940-2015
pdo3<-pdo2[11:76] #1950-2013

#distance matrix by coastline
# distMat4<-as.matrix(read.csv("h_dist_shore.csv")[,-1]/1000)
# distMat5<-distMat4[-c(4),-c(4)]


#########
#CCF for all sites
#########
 
Y2<-Y_car

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

#covmat[lower.tri(covmat)] <-NA
#diag(covmat) <- NA

colnames(covmat)<-colnames(Y_car[,-12])
rownames(covmat)<-colnames(Y_car[,-12])

cdf<-melt(covmat)

#All different groups
ggplot(cdf,aes(x=Var1,y=Var2,fill=value,colour=value))+
  geom_tile()+
  scale_fill_gradient(low="dodgerblue",high="firebrick")+
  scale_colour_gradient(low="dodgerblue",high="firebrick")+
  theme_acs()+
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position="top")+
  xlab("")+
  ylab("")

# ggsave(paste("CCF_11_Sites_Pairwise_tile",Sys.Date(),".pdf"))



####
#Covariance Matrix Input for CAR model
###

### MAKE SPATIAL MATRIX
H	<-	matrix(0,nSites,nSites)

H[2,1]		<- 	1
H[(nSites-1),nSites]	<-	1
for(i in 2:(nSites-1)){
  H[(i+1),i]	<- 1
  H[(i-1),i]	<- 1
}

#H[1,nSites] <-1
#H[nSites,1] <-1

EIG <-	eigen(H)	

IDEN	<-	diag(nSites)
muZeros = rep(0, nSites)

# DEFINE LIMITS ON spatial correlation parameter
PHI.max	<-	EIG$values[1]^(-1)
PHI.min	<-	EIG$values[nSites]^(-1)


#write test to see if added variable sigma 2 makes sense
tau2Inv_t<-matrix(0,ncol=nSites,nrow=nSites)

for(i in 1:nSites){
  tau2Inv_t[i,i] <- 0.1
}

#Q_t<-solve(tau2Inv_t)%*%(IDEN - phi_t*H)
# phi_t<-0.5
# 
# Q_t <- solve(IDEN - phi_t*H) %*% tau2Inv_t
# solve(Q_t)

########################################################################
############JAGS CODE to fit model  CAR 11 SITES (NO MASSET)
########################################################################

#Begin JAGS code
jagsscript = cat("
                 model {  
                
##########################
#OBSERVATION MODEL PRIORS and LIKLIHOODs
##########################

#tauR ~ dunif(1000,1001); #this is the estimated variance prior for Spawn Index
q ~ dnorm(0,1);  #(Log q) Fraction of Spawn Observed on spawn surveys estiamted across all sites

# psi ~ dgamma(10,1) #variance on fishing
#psi ~ dunif(0,10) #this is in variance for fishing set fixed to try to get convergence

for(i in 1:nYears) {
  for(j in 1:nSites) {

    Y[i,j] ~  dnorm(X[i,j]+q,1/1000); #obs eq for spawn index. a normal pull with meam Xq LIKELIHOOD STATEMENT ****

    tl[i,j]<-Z[i,j]+log(Pc[i,j]) #total biomass (tl) is qual to to estimated biomass pre catch  (Z) + catch (Pc) 
    
   #ctab[i,j] ~ dnorm(tl[i,j],1/psi) #distribution of catch data  LIKELIHOOD STATEMENT with variance****
   ctab[i,j] ~ dnorm(tl[i,j],1/.1) #distribution of catch data  LIKELIHOOD STATEMENT ****
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

# VARIANCE AND COVARIANCE ESTIMATES
#########################################################################################################

phi  	~ dunif(PHI.min+1e-6,PHI.max-1e-6) #modifier of cov param

#loop through and creat vector of inverse variance estimates for nSites

#for(i in 1:nSites) {
#  tau2[i] ~ dgamma(0.01,0.01); #this is for sd in cov matrix
#}

tau2 ~ dgamma(0.01,0.01)

for(i in 1:nSites){ 
  for(j in 1:nSites){
		M[i,j]<-tau2*IDEN[i,j]
}}

Qinv<-inverse(M)%*%(IDEN - phi * H)


#########################################################################################################

# Estimate the initial state vector of population abundances

zeta<-10
zeta2<-zeta*zeta

for(j in 1:nSites) {
      X[1,j] ~ dnorm(10,1/zeta2); # vague normal prior for first time step
      Z[1,j] <- X[1,j]+log(1-Pc[1,j])
  }

# Initial Values for Delta
for(j in 1:nSites) {zeros[j]<-0;}
delta[1,1:nSites] ~ dmnorm(zeros,Qinv[1:nSites,1:nSites]); 

# change in pop through time that's uniqe to site/time
for(i in 2:nYears) {
        delta[i,1:nSites] ~ dmnorm(zeros,Qinv[1:nSites,1:nSites]); 
  
   for(j in 1:nSites) {

      #fishing by site and global pdo estimates and U estimates 
      Z[i,j] <- X[i-1,j]+U[j]+pdocoef*pdo[i-1]+delta[i-1,j] #*** is this correct? not delta[i-1,j]
      
      #Estimate the state X with catch by site 
      X[i,j] <-Z[i,j]+log(1-Pc[i,j]);

  }
 }
} 
 ",file="normal_spatialRW_11sites_CAR_equalvar_2015_fixedpsi_fixedTauR.txt")


#data going into the model
jags.data = list("Y"=Y_car, "nYears"=nYears,"nSites"=nSites,"pdo"=pdo3,"ctab"=ctab2_1_car,"c_prior"=c_prior,"H"=H,"IDEN"=IDEN,"PHI.min"=PHI.min,"PHI.max"=PHI.max) # named list

jags.params=c("X","U","Umu","Usig","tau2","phi","delta","Qinv","Z","pdocoef","q","Pc") # parameters in the linear model


model.loc="normal_spatialRW_11sites_CAR_equalvar_2015_fixedpsi_fixedTauR.txt" # name of the txt file

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
    "Pc" = matrix(1e-07,nrow=nYears,ncol=nSites),
    "q" = 0 #runif(1,0.01,0.999)
 
    ) 
}
    

#tauR = runif(1,1,2),


model = jags(jags.data, inits=inits,parameters.to.save=jags.params,
            model.file=model.loc, n.chains = n.chains, n.burnin=n.burnin, n.thin=n.thin, n.iter=n.iter, DIC=TRUE)

attach.jags(model)

# timer.start <- proc.time()
# (run.time.in.min <- round(((proc.time()-timer.start)/60)["elapsed"], 0))

mDIC<-model$BUGSoutput$DIC 
pD<-model$BUGSoutput$pD
devi<-model$BUGSoutput$deviance

save("model","mDIC","X","U","Umu","Usig","Z","delta","Qinv","phi","pdo","pdocoef","Pc","q","tau2",file="herring_jags_F_11sites_equal_var_CAR_2015_fixedPsi_fixedTauR.RData")

load("herring_jags_F_11sites_equal_var_CAR_2015_fixedPsi_fixedTauR.RData")

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
  
  setwd("~/Dropbox/Projects/In Progress/Herring_Haida_Gwaii/Code") 
  
                   
  
  pdf(paste("11sites_CAR_UNequalvar_Chains_Posteriors_1950_2015_psi_dunif_fixedtauR",Sys.Date(),".pdf"), width=8.5,height=11,onefile = TRUE)
  
  #############
  #Predicted versus Observed Biomass 
  ############
  
  
  # plot(model)
  
  #acual data 
  names(Y_car) #log shi 
  y2<-data.frame("time"=seq(1,nYears,1),Y_car)
  mm2 <- melt(y2,id.vars<-"time")
  names(mm2) <- c("time","site","shi")
  
  mms<-scale(Y_car) 
  mms<-data.frame("year"=seq(1950,2015,1),mms)
  mms <- melt(mms,id.vars<-"year")
  names(mms) <- c("year","site","shi")
  
  mms2<-subset(mms,shi!="NA")
  
  #adjust by converting y to biomass through q
  mm2$b<-mm2$shi-median(q)
  
  #means
  tempmat<-model$BUGSoutput$mean$X
  colnames(tempmat) <-sitelab2
  temp2<-melt(tempmat)
  colnames(temp2) <-c("time","site","X")
  
  #temp3<-reshape(temp2,timevar = "site",idvar=c("time"),direction="wide")[,-1]
  
  mm3<-data.frame(mm2[,-4],temp2[,'X']+median(q))
  names(mm3)<-c("time","site","observed","predicted")
  mm4<-melt(mm3,id.vars<-c("time","site"))
  mm4$value2<- exp(mm4$value)
  
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
  
#   
#   ggplot(data=obs,aes(x=time,y=value2,colour=factor(site)))+
#     geom_point()+
#     geom_line()+
#     #facet_wrap(~site,scales="free_y")+
#     theme_acs()+
#     theme(legend.position="none")+
#     ggtitle("SpawnIndex") 
#   
#   
#   obs2<-subset(obs,site %in% c("SHI.Laskeek.Bay","SHI.Louscoone.Inlet"))
#   ggplot()+
#     #geom_line(data=pred,aes(x=time,y=value2,colour=factor(site)))+
#     geom_point(data=obs2,aes(x=time,y=value2,colour=factor(site)))+
#     geom_line(data=obs2,aes(x=time,y=value2,colour=factor(site)),lty=2)+
#     facet_wrap(~site,scales="free_y")+
#     theme_acs()+
#     theme(legend.position="none")+
#     
#     ggtitle("Predicted X and Observed SHI")
#   
#   obs3<-subset(obs,site %in% c("SHI.Laskeek.Bay","SHI.Juan.Perez.Sound"))
#   
#   ggplot()+
#     #geom_line(data=pred,aes(x=time,y=value2,colour=factor(site)))+
#     geom_point(data=obs3,aes(x=time,y=value2,colour=factor(site)))+
#     geom_line(data=obs3,aes(x=time,y=value2,colour=factor(site)),lty=2)+
#     facet_wrap(~site,scales="free_y")+
#     theme_acs()+
#     theme(legend.position="none")+
#     
#     ggtitle("Predicted X and Observed SHI")
#   
#   
#   mm5<-subset(mm4,variable=="predicted")
#   
#   ggplot(mm5,aes(x=time,y=value2))+
#     geom_line(aes(colour=factor(site)))+
#     facet_wrap(~site,scales="free_y")+
#     theme_acs()+
#     theme(legend.position="none")+
#     
#     ggtitle("predicted X")
#   
#   
#   
  
  
  
#   #############
#   #Predicted Catch 
#   ############
#   
#   #Observed Catch
#   c2<-data.frame("time"=seq(1,nYears,1),ctab2_1_car/Y_car) #this isn't entirely right, because we're saying there's some unobserved biomass (Z)
#   cc2 <- melt(c2,id.vars<-"time")
#   names(cc2) <- c("time","site","catch")
#   
#   #means of predicted catch
#   tempmat<-model$BUGSoutput$mean$Pc
#   colnames(tempmat) <-sitelab2
#   temp2<-melt(tempmat)
#   colnames(temp2) <-c("time","site","Pc")
#   
#   #temp3<-reshape(temp2,timevar = "site",idvar=c("time"),direction="wide")[,-1]
#   
#   cc3<-data.frame(cc2,temp2[,'Pc'])
#   names(cc3)<-c("time","site","observed","predicted")
#   cc4<-melt(cc3,id.vars<-c("time","site"))
#   
#   ggplot(cc4,aes(x=time,y=value,group=variable))+
#     geom_line(aes(colour=factor(site),lty=variable))+
#     facet_wrap(~site,scales="free_y")+
#     theme_acs()+
#     theme(legend.position="none")+
#     
#     ggtitle("Predicted Fishing Rate")
#   
  
  ####Umu and Ui estimates 
  Umudf<-melt(model$BUGSoutput$sims.array[,,"Umu"])
  Umudf$Var3<-"Umu"
  Umudf<-Umudf[,c(1,2,4,3)]
  umuci<-smedian.hilow(Umudf$value,conf.int=0.95)
  umuci2<-quantile(Umudf$value,c(0.05,0.95))
  
  tlist<-model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="U[1]"):which(colnames(myList[[1]])=="U[11]")]]
  dimnames(tlist)[[3]]<-colnames(Y_car)
  udf<-melt(tlist)
  
  ucomp<-data.frame("carmean"=tapply(udf$value,list(udf$Var3),mean),"carsd"=tapply(udf$value,list(udf$Var3),sd))
  ucomp$site<-rownames(ucomp)
  #write.csv(ucomp,"CarUest.csv")
  
  ucomp<-ggplot(udf,aes(x=Var3,y=value,colour=Var3))+
  	geom_hline(yintercept=median(Umudf$value),lty=2)+
  	geom_hline(yintercept= umuci2[1],lty=1,colour="grey")+
  	geom_hline(yintercept= umuci2[2],lty=1,colour="grey")+
  	stat_summary(fun.data=median_hilow,lty=2)+
  	# stat_summary(fun.data=median_hilow,conf.int=0.5)+
  	coord_flip()+
  	theme_acs()+
    theme(legend.position="none")+
    
  	ylab("Population Growth Rate [U]")+
  	xlab("Site Specific Population Growth")+
  	ggtitle("Populaiton Growth")
  
  print(ucomp)
  
  
  #######
  #Print Chains and Histograms
  ######
  
  qdf<-melt(model$BUGSoutput$sims.array[,,"q"])
  pdodf<-melt(model$BUGSoutput$sims.array[,,"pdocoef"])
  Umudf<-melt(model$BUGSoutput$sims.array[,,"Umu"])
  Usigdf<-melt(model$BUGSoutput$sims.array[,,"Usig"])
  # tauRdf<-melt(model$BUGSoutput$sims.array[,,"tauR"])
  phidf<-melt(model$BUGSoutput$sims.array[,,"phi"])
  tau2df<-melt(model$BUGSoutput$sims.array[,,"tau2"])

  # psidf<-melt(model$BUGSoutput$sims.array[,,"psi"])
  
  slist<-list(qdf,pdodf,Umudf,Usigdf,phidf,tau2df)
  nm<-c("q","pdocoef","Umu","Usig","phi","tau2")
  i=2
  
  
  for(i in 1:length(slist)){
    temp<-slist[[i]]
    names(temp)<-c("num","chain","value")
  
  gtemp<-ggplot(temp,aes(y=value,x=num,group=chain))+
        geom_line(aes(colour=factor(chain)))+
        theme_acs()+
        ggtitle(nm[i])+
        theme(legend.position="none")
  
  
  gtemp2<-ggplot(temp,aes(value))+
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
  names(udf)<-c("num","chain","response","value")
  udf$chain<-factor(udf$chain)
  udf$section2<-as.character(
          sort(
            # rep(unique(x$section),(nrow(udf)/nSites))
            rep(colnames(Y_car),(nrow(udf)/nSites))
            
                )
          )
  
  
  gtemp<- ggplot(udf,aes(y=value,x=num,group=chain))+
    geom_line(aes(colour=chain))+
    theme_acs()+
    facet_wrap(~section2,scales="free")+
    theme(legend.position="none")+
    ggtitle("U Chains")
  
  
  gtemp2<-ggplot(udf,aes(x=value))+
    geom_histogram()+
    theme_acs()+
    geom_vline(xintercept = 0)+
    facet_wrap(~section2,scales="free")+
    ggtitle("U Histogram")
  
  grid.arrange(gtemp,gtemp2,nrow=2, heights=c(1.2,1.2))
  
  
  
  
  #####################
  ############tau2 -estiamtes of states for each pouplation at each time step 
  #####################
  
  
# sdf<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="tau2[1]"):which(colnames(myList[[1]])=="tau2[11]")]])
# 
# names(sdf)<-c("num","chain","response","value")
# sdf$chain<-factor(sdf$chain)
# sdf$section2<-as.character(
#   sort(
#     # rep(unique(x$section),(nrow(udf)/nSites))
#     rep(colnames(Y_car),(nrow(udf)/nSites))
#     
#   )
# )
# 
# 
# 
# gtemp<- ggplot(sdf,aes(y=value,x=num,group=chain))+
#   geom_line(aes(colour=chain))+
#   theme_acs()+
#   facet_wrap(~section2,scales="free")+
#   theme(legend.position="none")+
#   ggtitle("tau2 Chains")
# 
# 
# gtemp2<-ggplot(sdf,aes(value))+
#   geom_histogram()+
#   theme_acs()+
#   geom_vline(xintercept = 0,lty=2)+
#   facet_wrap(~section2,scales="free")+
#   ggtitle("tau2 Histogram")
# 
# grid.arrange(gtemp,gtemp2,nrow=2, heights=c(1.2,1.2))
# 
# 

  
  
  #####################
  ############X -estiamtes of states for each pouplation at each time step 
  #####################
  
  edf1<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="X[1,1]"):which(colnames(myList[[1]])=="X[66,11]")]])
  names(edf1)<-c("num","chain","response","value")
  edf1$chain<-factor(edf1$chain)
  
  edf1$group<-factor(sort(rep(seq(1:nSites),runL)))
  edf1$year<-sort(rep(seq(1:nYears),runL*nSites))
  
  
  
  
  for(i in 1:nSites){
    tmp<-subset(edf1,year==i)
    gtemp<-ggplot(tmp,aes(x=num,y=value,group=chain))+
      geom_line(aes(colour=chain))+
      facet_wrap(~group,scales="free")+
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
  gt<-ggplot(tmp,aes(value))+
    geom_histogram()+
    facet_wrap(~Var3,scales="free")+
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
  colnames(tempmat) <-sitelab
  temp2<-melt(tempmat)
  colnames(temp2) <-c("time","site","delta")
  # 
#   #add site names from df2
#    ggplot(temp2,aes(x=time,y=site,fill=delta))+
#      geom_tile()+
#      theme_acs()
#   # 
#   dp<-ggplot(temp2,aes(x=time,y=delta,group=factor(site)))+
#      geom_line(aes(colour=factor(site)))+
#      theme_acs()
#   print(dp)
  
  ##Posterior plots
  model$BUGSoutput$sims.array[,,"delta[1,1]"]
  
  edf1<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="delta[1,1]"):which(colnames(myList[[1]])=="delta[66,11]")]])
  
  names(edf1)<-c("num","chain","response","value")
  edf1$chain<-factor(edf1$chain)
  edf1$group<-factor(sort(rep(seq(1:nSites),runL)))
  
  edf1$year<-sort(rep(seq(1:nYears),runL*nSites))
  
  
  for(i in 1:nYears){
    tmp<-subset(edf1,year==i)
   dcg<- ggplot(tmp,aes(x=num,y=value,group=chain))+
      geom_line(aes(colour=chain))+
      facet_wrap(~group,scales="free")+
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
    dhg<-ggplot(tmp,aes(value))+
      geom_histogram()+
      facet_wrap(~Var3.scales="free")+
      theme_acs()+
      geom_vline(xintercept = 0)+
    ggtitle(paste("Delta Posterior time_",i,".pdf"))
    
    print(dhg)
    
  }
  
  
  #####################
  ############Q -estiamtes of states for each population's change
  #####################
  #means
#   tempmat<-model$BUGSoutput$mean$Qinv
#   colnames(tempmat) <-colnames(Y_car)
#   rownames(tempmat) <-colnames(Y_car)
#   
#   cdf<-melt(tempmat)
#   
#   #All different groups
#   qmat<-ggplot(cdf,aes(x=Var1,y=Var2,fill=value,colour=value))+
#     geom_tile()+
#     scale_fill_gradient(low="dodgerblue",high="firebrick")+
#     scale_colour_gradient(low="dodgerblue",high="firebrick")+
#     theme_acs()+
#     theme(axis.text.x = element_text(angle = 45, hjust = 1),
#           legend.position="top")+
#     xlab("")+
#     ylab("")
#   
#   print(qmat)
#   
#   
#   
#   temp2<-melt(tempmat)
#   colnames(temp2) <-c("time","site","Qinv")
#   
#   
#   edf1<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="Qinv[1,1]"):which(colnames(myList[[1]])=="Qinv[11,11]")]])
#   names(edf1)<-c("num","chain","response","value")
#   edf1$chain<-factor(edf1$chain)
#   
#   qcg<-ggplot(edf1,aes(y=value,x=num,group=chain))+
#     geom_line(aes(colour=chain))+
#     theme_acs()+
#     facet_wrap(~response,ncol=11,scales="free_y")+
#     ggtitle("Q Chains")
#   
#   print(qcg)
#   
#   qhg<-ggplot(edf1,aes(value))+
#     geom_histogram()+
#     theme_acs()+
#     geom_vline(xintercept = 0)+
#     facet_wrap(~response,ncol=11)+
#     ggtitle("Q Posterior")
#   
#   print(qhg)
  
  
  
  #####################
  ############Pc -estiamtes of states for each population's change
  #####################
  
  #means
  tempmat<-model$BUGSoutput$mean$Pc
  colnames(tempmat) <-sitelab
  temp2<-melt(tempmat)
  colnames(temp2) <-c("time","site","F")
#   
#   #add site names from df2
#   pcall<-ggplot(temp2,aes(x=time,y=factor(site),fill=F))+
#     geom_tile()+
#     theme_acs()+
#     ggtitle("F Through Time and Across Sites")
#   
#   print(pcall)
#   # ggplot(temp2,aes(x=time,y=Pc,group=site))+
#   #   geom_line(aes(colour=site))+
#   #   theme_acs()
#   
  
  
  ##Posterior plots
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
      facet_wrap(~group,scales="free")+
      theme_acs()+
      ggtitle(paste("F_chains_time_",i,".pdf"))
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
      facet_wrap(~Var3,scales="free")+
      theme_acs()+
      geom_vline(xintercept = 0)+
      ggtitle(paste("F_ Posteriors time_",i,".pdf"))
    print(pcg)
  }
  
  
  dev.off()
  

