library(ggplot2)
library(reshape2)
library(gdata)
library(maps)
library(mapproj)
library(ggmap)
library(gplots)
library(R2jags)
library(coda)

#setwd("~/Dropbox/Projects/In Progress/Pinniped_Herring_HG/Code")
#setwd("~/Dropbox/Projects/In Progress/Code")
setwd("~/Desktop/Imac_Herring_Section")
source('multiplot.R')
source('theme_acs.R')
#load('herring_jags.RData')

########################################################################
############ Load Herring Spawn Index, Catch Data, and Distance Matrix
########################################################################

#catch data 
x=read.csv("HG_Spawn_Survey_1940_2013b.csv")
x<- x[c(1,3,13,14,15,16)]
x$SHI2<-log(x$SHI+1)
x$presabs <-ifelse(x$SHI>0,1,0)



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
Y2<-cbind(rowSums(Y[,c(1:4)]),rowSums(Y[,c(5:9)]))

Y = log(Y)
Y2 = log(Y2)

#catch data
c <- read.csv("herring_catch_local.csv")
yr_c<-unique(c$Year)
c$presabs <-ifelse(c$TotalCatch>0,1,0)

#subset out Cartwright Sound (4)-no catch data, Masset (11), Skitigate (22), and Naden Harbor (12) - iffy spawn surveys
c<-subset(c,Section %in% c(1,2,3,5,6,21,23,24,25))

#ctab<-data.frame(tapply(c$TotalCatch,list(c$Year,c$Section),sum)) #all catch
ctab<-data.frame(tapply(c$CatchJan_Apr,list(c$Year,c$Section),sum)) #just spring catch
ctab2<-ctab[-nrow(ctab),]
colnames(ctab2)<-colnames(Y)
ctab2<-as.matrix(ctab2)
ctab2_1<-log(ctab2+1)

#break into east and west side
ctab2_2<-cbind(rowSums(ctab2_1[,c(1:4)]),rowSums(ctab2_1[,c(5:9)]))


#load pdo
pdo<-read.csv("pdo.csv")
pdosummer<-subset(pdo,month %in% c(3,4,5,6)) #average april<-june
pdoxb<-c(tapply(pdo$Value,list(pdo$year),mean))
pdo2<-pdoxb[87:160] #1940-2013
pdo3<-pdo2[11:74] #1950-2013


#distance matrix by coastline
distMat4<-as.matrix(read.csv("h_dist_shore.csv")[,-1]/1000)
distMat5<-distMat4[-c(4,7,8,10),-c(4,7,8,10)]
distMat6<-distMat5[c(4,7),c(4,7)]

years = seq(1950,2013)
nYears = length(years)
nSites = ncol(Y2)

########################################################################
############JAGS CODE to fit model 
########################################################################

#work out the logic for site specific fishing allocation 


jagsscript = cat("
                 model {  
                
                 #####
                 #PRIORS - PROCESS MODEL
                 #####
                 
                 # POPULATION GROWTH: random variable from shared mean and sd across populations
                 #Umu ~ dnorm(0,1); #average population growth
                 #Usig ~ dunif(0,100); 
                 #Utau <- 1/(Usig*Usig); 
                 
                 #COVARIATES
                 pdocoef~dnorm(0,1);
                 
                 #SPATIAL COVARIANCE
                 tau ~ dgamma(0.01,0.01);
                 sigma2 <- 1/tau;
                 theta ~ dunif(-1,1);
                 
                 
                 #####
                 #PRIORS - OBSERVATION MODEL  
                 ####
                 
                 #Variance Terms for Obs Model PRIORS
                 #tauR ~ dgamma(0.001,0.001);
                 tauR ~ dunif(1,100); #this is in variance prior for SHI
                 #psi ~ 0.1 #dunif(0,10) #this is in variance for fishing increase 2nd val for lower var window
                 

                 #LOOP THROUGH TO ESTIMATE Prior for U[i] and Utau
                 for(i in 1:nSites) {
                   U[i] ~ dnorm(0,.1)
                   #U[i] ~ dnorm(Umu,Utau); #this is what you'd want if it were hierarchical pulling from a distribution of U's
                    }
                 
               
                                
                for(i in 1:nYears) {
                  for(j in 1:nSites) {
                Pc[i,j] ~ dbeta(1,1);#Fraction of Catch Observed (beta 1,1 is same as unif 0 1)
                  }
                }

                q ~ dgamma(.02,0.001);  #Fraction of Spawn Observed: Pc


                 #####
                 #SET UP Variance Covariance Matrix Q
                 #####
                 
                #how about in one step. first set the diagonal
                for(i in 1:nSites) {
                      tmat[i,i]<-1
                }

                #then set the off diag
                  for(j in 1:1) {
                      tmat[2,j]<-theta
                      tmat[j,2]<-theta
                    }
                  
                 #make a sigma2 2x2
                 for(i in 1:nSites) {
                   for(j in 1:nSites) {
                     smat[i,j]<-sigma2
                   }
                 }
                     


                #multiply the matrix to get var cov matrix
                
                for(i in 1:nSites){
                  for(j in 1:nSites){
                Q[i,j] <- tmat[i,j]*smat[i,j]
                }
                 }


                  #PRECISION OF Q: JAGS wants us to use the matrix inverse
                 tauQ[1:nSites,1:nSites] <- inverse(Q[1:nSites,1:nSites]);
                 
                 #####
                 #Estimate the initial state vector of population abundances
                 #####
                 
                 for(j in 1:nSites) {
                        X[1,j] ~ dnorm(20,0.1); # vague normal prior for first time step
                        Z[1,j] <- X[1,j]-log(1-Pc[1,j])
                 }

                

                 #NON AUTO REGRESSIVE VARIANCE
                 for(j in 1:nSites) {zeros[j]<-0;}
                 delta[1,1:nSites] ~ dmnorm(zeros,tauQ[1:nSites,1:nSites]);

                   for(i in 2:nYears){
                          delta[i,1:nSites] ~ dmnorm(zeros,tauQ[1:nSites,1:nSites]) # this uses the zeros vector above (0,0)
  
                      for(j in 1:nSites) {
   
                
                 # AUTOREGRESSIVE PROCESS for POPULATION GROWTH
                      
                 #DUMMY VARIAVBLE (dummy) FOR EFFECT OF GROWTH AND PDO
                 dummy[i-1,j] <- X[i-1,j]+U[j]+pdocoef*pdo[i-1]; 
            
                 
                 #SECOND DUMMY VARIABLE (Z) to add in the DELTA parameter - detrended variance
                 Z[i,j] <- dummy[i-1,j]+delta[i,j]; 
                 
                 
                 #ESTIAMTE THE POPULATION STATE (X) by including catch data 
                 X[i,j] <- Z[i,j]+log(1-Pc[i,j]);

                   }
                 }
                 
                 #####
                 # OBSERVATION MODEL  
                 ####
                                
                
                 for(i in 1:nYears) {
                  for(j in 1:nSites) {
                    Y[i,j] ~ dnorm(X[i,j]*q,1/tauR); #obs eq for spawn index 
                    tl[i,j]<-Z[i,j]+log(Pc[i,j])+1
                    ctab[i,j] ~ dnorm(tl[i,j],1/.1)
                    #ctab[i,j] ~ dnorm(tl[i,j],1/psi) #obs equation for catch
                    }
                   }
                  }  
                 
                 ",file="normal_spatialRW_9sites.txt")

#OLD JUNK
#X[i,j] <-log(exp(Z[i,j])-ctab[i,j])     
#exp(Z[i,j]) <- exp(X[i,j])+ctab2[i-1,j]
#add just pdo and take away U 
#predX[i,j] <- X[i-1,j] + pdocoef*pdo[i];
##Y[i,j] ~ dnorm(X[i,j],tauR);

jags.data = list("Y"=Y2, "nYears"=nYears,"nSites"=nSites,"pdo"=pdo3,"ctab"=ctab2_2) # named list

jags.params=c("X","theta","sigma2","U","delta","Q","pdocoef","q","Pc","tauR") # parameters in the linear regression model

model.loc="normal_spatialRW_2sites.txt" # name of the txt file

n.chains = 3
n.burnin=100
n.thin=5
n.iter=1000

#number of recorded mcmc
runL <- n.chains*(n.iter-n.burnin)/n.thin

Inits = NULL

#need to add the inits for the Pc and q params

for(i in 1:n.chains){
  Inits[[i]]    <- list(
    "pdocoef" = runif(1,.05,1),
    "tau" =runif(1,0.05,1),
    "theta" = runif(1,0.05,1),
    "delta" = matrix(runif(1,.05,1),nrow=nYears,ncol=nSites),
    "tauR" = runif(1,1,2),
    "Pc" = matrix(1e-05,nrow=nYears,ncol=nSites), #runif(1,.05,1) #reducing this and the variance on this psi
    "q" = runif(1,0.01,0.999)
    
    ) 
}
    
    
#jags.model.rand.base.both = jags(jags.data, inits = Inits, parameters.to.save= jags.params, model.file=model.loc, 
#                                 n.chains = Nchain, n.burnin = Nburn, n.thin = 1, n.iter = Nburn+Niter, DIC = TRUE) 


model = jags(jags.data, inits=Inits,parameters.to.save=jags.params,
             model.file=model.loc, n.chains = n.chains, n.burnin=n.burnin, n.thin=n.thin, n.iter=n.iter, DIC=TRUE)

attach.jags(model)

save("model","X","sigma2","U","delta","Q","pdo","Pc","q","tauR",file="herring_jags_F_2sites.RData")

#load("herring_jags_F_2sites.RData")

########################################################################
############Quick Summary of Model Parameters
########################################################################
#names of array 

head(model$BUGSoutput$sims.array)

#look at individual parameter means
model$BUGSoutput$mean$X
model$BUGSoutput$mean$U
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
plot(model)

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
#****
######
colnames(myList[[1]])#names of each of the output 

#####################
############PDO Coef 
#####################

summary(myList[[1]][2112])

#trace plot theta
#matplot(as.matrix(data.frame(c(myList[[1]][,2112]),c(myList[[2]][,2112]),c(myList[[3]][,2112]))))

model$BUGSoutput$sims.array[,,"pdocoef"]
edf1<-melt(model$BUGSoutput$sims.array[,,"pdocoef"])

names(edf1)<-c("num","chain","value")
edf1$chain<-factor(edf1$chain)

ggplot(edf1,aes(y=value,x=num,group=chain))+
  geom_line(aes(colour=chain))+
  theme_acs()

edf<-data.frame(pdocoef)
ggplot(edf,aes(x=pdocoef))+
  geom_bar()+
  theme_acs()+
  geom_vline(xintercept = 0)

ggsave("pdocoef.pdf")

#gelmanDiags = gelman.diag(createMcmcList(model),multivariate=TRUE)
model$BUGSoutput$mean$pdo


#####################
############Theta - Covariance
#####################
#trace plot theta
#matplot(as.matrix(data.frame(c(myList[[1]][,2112]),c(myList[[2]][,2112]),c(myList[[3]][,2112]))))

model$BUGSoutput$sims.array[,,"theta"]
edf1<-melt(model$BUGSoutput$sims.array[,,"theta"])

names(edf1)<-c("num","chain","value")
edf1$chain<-factor(edf1$chain)

ggplot(edf1,aes(y=value,x=num,group=chain))+
  geom_line(aes(colour=chain))+
  theme_acs()

edf<-data.frame(theta)
ggplot(edf,aes(x=theta))+
  geom_bar()+
  theme_acs()+
  geom_vline(xintercept = 0)

ggsave("theta.pdf")

#gelmanDiags = gelman.diag(createMcmcList(model),multivariate=TRUE)



#####################
############sigma2 
#####################

model$BUGSoutput$sims.array[,,"sigma2"]
edf1<-melt(model$BUGSoutput$sims.array[,,"sigma2"])

names(edf1)<-c("num","chain","value")
edf1$chain<-factor(edf1$chain)

ggplot(edf1,aes(y=value,x=num,group=chain))+
  geom_line(aes(colour=chain))+
  theme_acs()

edf<-data.frame(sigma2)
ggplot(edf,aes(x=sigma2))+
  geom_bar()+
  theme_acs()+
  geom_vline(xintercept = 0)

ggsave("sig2.pdf")


#####################
############U -estiamtes of population growth 
#####################
model$BUGSoutput$sims.array[,,"U[1]"]


edf1<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="U[1]"):which(colnames(myList[[1]])=="U[2]")]])
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


#add in a barplot with 95%CI for each population

#####################
############X -estiamtes of states for each pouplation at each time step 
#####################
model$BUGSoutput$sims.array[,,"X[1,1]"]

#means
tempmat<-model$BUGSoutput$mean$X
colnames(tempmat) <-c("site1","site2")
temp2<-melt(tempmat)
colnames(temp2) <-c("time","site","X")

ggplot(temp2,aes(x=time,y=site,fill=X))+
  geom_tile()+
  theme_acs()

#add site names from df2
ggplot(temp2,aes(x=time,y=exp(X),group=site))+
  geom_line(aes(colour=site))+
  theme_acs()+
  scale_y_log10()

ggsave("X.pdf")

edf1<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="X[1,1]"):which(colnames(myList[[1]])=="X[64,2]")]])


names(edf1)<-c("num","chain","response","value")
edf1$chain<-factor(edf1$chain)
edf1$group<-factor(sort(rep(seq(1:nSites),runL)))
edf1$year<-sort(rep(seq(1:nYears),runL*nSites))

for(i in 1:nSites){
  tmp<-subset(edf1,year==i)
  ggplot(tmp,aes(x=num,y=value,group=chain))+
    geom_line(aes(colour=chain))+
    facet_wrap(~group)+
    theme_acs()
  ggsave(paste("x_","chains_time_",i,".pdf"))
  
}


####posterior by site*time combiantions. 
chain<-c(rep("chain1",runL/3),rep("chain2",runL/3),rep("chain3",runL/3))
num <- rep(seq(1:(runL/3)),3)
mx<-melt(X)
mx$chain<-chain
mx$num<-num

setwd("~/Dropbox/Projects/In Progress/Pinniped_Herring_HG/Code/Figures/Posteriors/Herring_X")

for(i in 1:nYears){
tmp<-subset(mx,Var2==i)
ggplot(tmp,aes(x=value))+
  geom_bar()+
  facet_wrap(~Var3)+
  theme_acs()+
  geom_vline(xintercept = 0)
ggsave(paste("x_","hist_","time_",i,".pdf"))
  
}




#####################
############Delta -estiamtes of states for each population's change
#####################

#means
tempmat<-model$BUGSoutput$mean$delta
colnames(tempmat) <-c("site1","site2")
temp2<-melt(tempmat)
colnames(temp2) <-c("time","site","delta")

#add site names from df2
ggplot(temp2,aes(x=time,y=site,fill=delta))+
  geom_tile()+
  theme_acs()

ggplot(temp2,aes(x=time,y=delta,group=factor(site)))+
  geom_line(aes(colour=factor(site)))+
  theme_acs()

ggsave("delta.pdf")


##Posterior plots
model$BUGSoutput$sims.array[,,"delta[1,1]"]

edf1<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="delta[1,1]"):which(colnames(myList[[1]])=="delta[64,2]")]])

names(edf1)<-c("num","chain","response","value")
edf1$chain<-factor(edf1$chain)
edf1$group<-factor(sort(rep(seq(1:nSites),runL)))

edf1$year<-sort(rep(seq(1:nYears),runL*nSites))

for(i in 1:nYears){
  tmp<-subset(edf1,year==i)
  ggplot(tmp,aes(x=num,y=value,group=chain))+
    geom_line(aes(colour=chain))+
    facet_wrap(~group)+
    theme_acs()
  ggsave(paste("delta_","chains_time_",i,".pdf"))
  
}

####posterior by site*time combiantions. 
chain<-c(rep("chain1",runL/3),rep("chain2",runL/3),rep("chain3",runL/3))
num <- rep(seq(1:(runL/3)),3)
dx<-melt(delta)
dx$chain<-chain
dx$num<-num

for(i in 1:nYears){
  tmp<-subset(dx,Var2==i)
  ggplot(tmp,aes(x=value))+
    geom_bar()+
    facet_wrap(~Var3)+
    theme_acs()+
    geom_vline(xintercept = 0)
  ggsave(paste("delta_","hist_","time_",i,".pdf"))
  
}


#####################
############Q -estiamtes of states for each population's change
#####################
#means
tempmat<-model$BUGSoutput$mean$Q
cov2cor(tempmat)

colnames(tempmat) <-c("site1","site2")
temp2<-melt(tempmat)
colnames(temp2) <-c("time","site","Q")

#add site names from df2
ggplot(temp2,aes(x=time,y=site,fill=Q))+
  geom_tile()+
  theme_acs()

ggsave("Q.pdf")


setwd("~/Dropbox/Projects/In Progress/Pinniped_Herring_HG/Code/Figures/Herring/Posteriors/Herring_delta")
model$BUGSoutput$sims.array[,,"Q[1,1]"]

edf1<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="Q[1,1]"):which(colnames(myList[[1]])=="Q[2,2]")]])
names(edf1)<-c("num","chain","response","value")
edf1$chain<-factor(edf1$chain)

ggplot(edf1,aes(y=value,x=num,group=chain))+
  geom_line(aes(colour=chain))+
  theme_acs()+
  facet_wrap(~response)

ggsave("Q_chains.pdf")

ggplot(edf1,aes(x=value))+
  geom_bar()+
  theme_acs()+
  geom_vline(xintercept = 0)+
  facet_wrap(~response)

ggsave("Q_hist.pdf")



#####################
############Pc -estiamtes of states for each population's change
#####################

#means
tempmat<-model$BUGSoutput$mean$Pc
colnames(tempmat) <-c("site1","site2")
temp2<-melt(tempmat)
colnames(temp2) <-c("time","site","Pc")

#add site names from df2
ggplot(temp2,aes(x=time,y=site,fill=Pc))+
  geom_tile()+
  theme_acs()

ggplot(temp2,aes(x=time,y=Pc,group=site))+
  geom_line(aes(colour=site))+
  theme_acs()

ggsave("Pc.pdf")


##Posterior plots
model$BUGSoutput$sims.array[,,"Pc[1,1]"]

edf1<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="Pc[1,1]"):which(colnames(myList[[1]])=="Pc[64,2]")]])

names(edf1)<-c("num","chain","response","value")
edf1$chain<-factor(edf1$chain)
edf1$group<-factor(sort(rep(seq(1:2),runL)))

edf1$year<-sort(rep(seq(1:nYears),runL*nSites))


for(i in 1:nYears){
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
px<-melt(Pc)
px$chain<-chain
px$num<-num


for(i in 1:nSites){
  tmp<-subset(px,Var2==i)
  ggplot(tmp,aes(x=value))+
    geom_bar()+
    facet_wrap(~Var3)+
    theme_acs()+
    geom_vline(xintercept = 0)
  ggsave(paste("time_",i,".pdf"))
  
}

