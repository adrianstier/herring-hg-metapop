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
  
  #Data Simulation
  setwd("~/Dropbox/Projects/In Progress/Pinniped_Herring_HG/Code")
  #setwd("~/Desktop/Imac_Herring_4_14")
  #setwd("/Users/AdrianStierMBP2015/Dropbox/Projects/In Progress/pinniped_herring_hg/Imac_Herring_4_14")
  source('multiplot.R')
  source('theme_acs.R')
  
  ########################################################################################################################
  #INPUT REAL DATA TO USE WHEN SIMULATING FAKE DATA 
  ########################################################################################################################
  
  
  ######
  #load pdo
  ######
  
  pdo<-read.csv("pdo.csv")
  pdosummer<-subset(pdo,month %in% c(3,4,5,6)) #average april<-june
  pdoxb<-c(tapply(pdo$Value,list(pdo$year),mean))
  pdo2<-pdoxb[87:160] #1940-2013
  pdo3<-pdo2[11:74] #1950-2013
  
  ######
  #distance matrix by coastline
  ######
  
  distMat4<-as.matrix(read.csv("h_dist_shore.csv")[,-1]/1000)
  distMat5<-distMat4[-c(4,7,8,10),-c(4,7,8,10)]
  
  
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
    geom_line(aes(colour=site))+
    facet_wrap(~site)+
    theme_acs()
  
  
  aveSHI<- tapply(ym$logSHI,list(ym$site),mean,na.rm=TRUE)
  sdSHI<- tapply(ym$logSHI,list(ym$site),mean,na.rm=TRUE)
  
  svec<-unique(ym$site)
  
  
  
  #####
  #Load catch data
  #####
  
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
  
  
  ########################################################################################################################
  #PARAMS FOR FAKE DATA 
  ########################################################################################################################
  set.seed(10)
  nYears<-64
  nSites<-9
  
  
  #I'll go through and define each of these
  # pdocoef_sim
  # uvec
  # Pc_sim
  # c_prior_sim
  # sigma2_sim
  # theta_sim
  # Q_sim
  # delta_sim
  # xmat
  # tauR_sim
  
  
  ######
  #Strength of PDO effect - **pdocoef** 
  ######
  pdocoef_sim<- 0 #pdo coefficient
  
  
  ######
  #Population Growth - **U** Vec Estimate Slope time series for 9 Sites 
  ######
  
  umat<-matrix(nrow=length(svec),ncol=2)
  rownames(umat)<-svec
  
  for(i in 1:length(svec)){
    temp<-subset(ym,site==svec[i])
    m1<-lm(temp$logSHI~temp$time)
    umat[i,1]<-coef(m1)[2]
    umat[i,2]<-summary(m1)$coef[4]
  }
  
  umat<-data.frame(umat)
  colnames(umat)<-c("slope","slopeSE")   
  
  #make U's hierarchical 
  Umu_sim<-mean(umat[,1])
  Usig_sim<-0#sd(umat[,1])
  
  uvec<-rnorm(nSites,Umu_sim,Usig_sim)
  
  
  
  ######
  #Catch Data: Fraction of Catch at Each site-time combiantion - **Pc** and Prior for Pc c_prior
  ######
  
  #make up some fishing impacts by proportion ranging from 0 to 1 
  Pc_sim<-matrix(NA,nrow=nYears,ncol=nSites)
  
  #some fishing every year 
  #for(i in 1:nrow(xmat)){
  #	for(j in 1:ncol(xmat)){
  #	Pc_sim[i,j]<-runif(1,0,0.1)
  #		
  #	}
  #}
  
  #Base the values on level of fishing 
  
  for(i in 1:nYears){
  	for(j in 1:nSites){	
  	Pc_sim[i,j]<-ifelse(ctab[i,j]>0,
  		runif(1,0,0), #turn up/down fishing here
  		0
  		)
  	}
  }
  
  #
  #make a prior matrix that sets the upper bound of the uniform distribution for prior Pc to be 0.95 when it's a non-zero and 0.01 when it's zero
  ncol(Pc_sim)
  nrow(Pc_sim)
  nonz<-which(Pc_sim>0)
  c_prior_sim<-matrix(0.01,nrow=nrow(Pc_sim),ncol=ncol(Pc_sim))
  
  for(i in 1:length(nonz)){
    c_prior_sim[nonz[i]]<-0.95
  }
  
  
  
  ######
  #Variance and Spatial Covariance *sigma2*, *theta*, *delta*, *Q*
  ######
  
  sigma2_sim<-0 #variance
  theta_sim<-0 #distance decay for spatial covariance
  
  #error term in vriance - covariance matrix
  Q_sim<-matrix(NA,ncol=nSites,nrow=nSites) #q matrix
  for(i in 1:nSites) {
    for(j in 1:nSites) {
  Q_sim[i,j] <- sigma2_sim*exp(-theta_sim*distMat5[i,j])
  }}
  
  #simulate error with multivariate normal distribution 
  zero_sim<-rep(0,nSites)
  delta_sim<-mvrnorm(1,zero_sim,Q_sim)
  
  for(i in 2:nYears){
      delta_sim<-rbind(delta_sim,mvrnorm(1,zero_sim,Q_sim))
    }
  
  ####
  #Spawn Biomass X* and Spawn Biomass Plus Catch Z*
  ####
  
  #Create an Empty Matrix of Data for pre fishing data
  zmat<-matrix(nrow= nYears,ncol= nSites)
  #make a tab X, which should be the amount of fish - fishing effects
  xmat<-matrix(NA,nrow<-nYears,ncol=nSites)
  
  #STARTING VALUES
  #change starting values to be average of SHI time series
  for(i in 1:nSites){
    zmat[1,i]<-rnorm(1,aveSHI[i],1)+delta_sim[1,i]
    xmat[1,i]<-zmat[1,i]+
      ifelse(abs(log(1-Pc_sim[1,i]))>zmat[1,i],-zmat[1,i],
      log(1-Pc_sim[1,i])
      )
  }
  
  
  ####
  #Simulate a  Model with autoregressive random walk, PDO, and autocorrelated erorrs
  ####
  
  for(j in 1:ncol(zmat)){
    for(i in 2:nrow(zmat)){
      zmat[i,j]<-xmat[i-1,j]+rnorm(1,uvec[j],0)+pdocoef_sim*pdo3[i]+delta_sim[i,j] #sigma2
      xmat[i,j]<-zmat[i,j]+
        ifelse(abs(log(1-Pc_sim[i,j]))>zmat[i,j],-zmat[i,j],
               log(1-Pc_sim[i,j]))
  
    }
  }
  
  #calculate amount of fish caught on log scale for simulated catch data
  #zmat is log scale number of fish before catch, xmat is number after 
  ctab_sim<-zmat-xmat
  ctab_sim[ctab_sim==-Inf] <- 0
  
  # ctab_sim2<-matrix(NA,ncol=ncol(zmat),nrow=nrow(zmat))
  # 
  # for(i in 1:ncol(zmat)){
  #   for(j in 1:nrow(zmat)){
  #     ctab_sim2[j,i]<-zmat[j,i]+
  #       ifelse(abs(log(Pc_sim[j,i]))>zmat[j,i],0,
  #              log(Pc_sim[j,i]))
  #     }
  #   }
  
  
  mm<-melt(xmat)
  mm$value2<-exp(mm$value)
  
  ggplot(mm,aes(x=Var1,y=value,group=factor(Var2)))+
    geom_line(aes(colour=factor(Var2)))+
    facet_wrap(~Var2,scales="free_y")+
    theme_acs()
  
  
  #Q modification 
  q_sim<-1
  tauR_sim<-100
  
  xmat<-xmat*q_sim
  
  
  
  ########################################################################
  ############JAGS CODE to fit model 
  ########################################################################
  
  
  #Begin JAGS code
  jagsscript = cat("
                   model {  
                  
  ##########################
  #OBSERVATION MODEL PRIORS and LIKLIHOODs
  ##########################
  #psi ~ 0.1 #dunif(0,10) #this is in variance for fishing set fixed to try to get convergence
  
  tauR ~ dunif(99,1001)#dunif(1,100); #this is the estimated variance prior for Spawn Index
  q ~ dunif(0.99,1.01)#dgamma(.02,0.001);  #Fraction of Spawn Observed on spawn surveys estiamted across all sites
  
  for(i in 1:nYears) {
    for(j in 1:nSites) {
      Y[i,j] ~  dnorm(X[i,j]*q,1/tauR); #obs eq for spawn index. a normal pull with meam Xq LIKELIHOOD STATEMENT ****
      
      tl[i,j]<-Z[i,j]+log(Pc[i,j]) #total biomass (tl) is equal to to estimated biomass (Z - log scale) + log of catch fraciton (Pc) 
      
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
  Usig ~ dunif(0,100)#dunif(0,100); #variance in population growth 
  Usig2<-Usig*Usig
  
  for(i in 1:nSites) {
    U[i] ~ dnorm(Umu,1/Usig2) #for each site U set as random variable prior 
  }
  
  #COVARIATE
  pdoz2<-100 #1
  
  pdocoef~dnorm(0,1/pdoz2); #estimated impact of pdo of herring
  
  #VARINCE SPATIAL VARIANCE AND COVARIANCE
  sigma2 ~ dunif(0,0.1)#dgamma(0.01,0.01) #variance 
  
  theta ~ dunif(0,0.1) #dunif(0.01,0.99)
  
  #eta ~ dgamma(0.01,0.01) #wiggle on distance decay
  #logtheta ~ dnorm(0,0.01) #rate of distance decay
  #theta <- exp(logtheta)
  #theta ~ dgamma(1.2,0.6)
  
  
  #variance covariance matrix, and Precision matrix inverse for Q
  for(i in 1:nSites) {
  for(j in 1:nSites) {
      #Q[i,j] <- sigma2 * exp(-theta * distMat5[i,j]) + eta*diag[i,j];
      Q[i,j] <- sigma2 * exp(-theta * distMat5[i,j]) #no nugget 
  
    }
  }   
  
  tauQ[1:nSites,1:nSites] <- inverse(Q[1:nSites,1:nSites]);
  
  
  # Estimate the initial state vector of population abundances
  
  zeta<-10
  zeta2<-zeta*zeta
  
  for(j in 1:nSites) {
        X[1,j] ~ dnorm(10,1/zeta2); # vague normal prior for first time step
        Z[1,j] <- X[1,j]+log(1-Pc[1,j])
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
  Z[i,j] <- X[i-1,j]+U[j]+pdocoef*pdo[i-1]+delta[i,j]
  
  #Estimate the state X with catch by site 
  X[i,j] <-Z[i,j]+log(1-Pc[i,j]);
  
  
    }
   }
  } 
   ",file="normal_spatialRW_9sites.txt")
  
  
  #data going into the model
  jags.data = list("Y"=Y, "nYears"=nYears,"nSites"=nSites,"distMat5"=distMat5,"pdo"=pdo3,"ctab"=ctab_sim,"c_prior"=c_prior_sim) # named list
  jags.data.p = list("Y", "nYears","nSites","distMat5","pdo","ctab_sim","c_prior") # named list
  
  
  
  jags.params=c("X","theta","sigma2","U","Umu","Usig","delta","Q","pdocoef","q","Pc","tauR") # parameters in the linear model
  
  #jags.params=c("X","theta","eta","sigma2","U","Umu","Usig","delta","Q","pdocoef","q","Pc","tauR") #old
  
  model.loc="normal_spatialRW_9sites.txt" # name of the txt file
  
  n.chains = 3
  n.burnin=5000
  n.thin=5
  n.iter=10000
  
  #number of recorded mcmc
  runL <- n.chains*(n.iter-n.burnin)/n.thin
  
  inits = NULL
  
  #need to add the inits for the Pc and q params
  
  for(i in 1:n.chains){
    inits[[i]]    <- list(
      "Umu" = runif(1,0,0.2), #alt just make it a little lower? 0.5 seems more realisitc
      "Usig" = runif(1,0,0.1),#runif(1,.05,1),
      "pdocoef" = runif(1,-0.1,0.1),#runif(1,-1,1),
      #"tau" =runif(1,0.05,1),
      #"invEta" = runif(1,1,10),
      "theta" = 0,#runif(1,0,0.1),#runif(1,0,1),
      "delta" = matrix(runif(1,0,0.1),nrow=nYears,ncol=nSites), #matrix(runif(1,.05,1),nrow=nYears,ncol=nSites),
      "tauR" = runif(1,99,100),#runif(1,0,0.1),#runif(1,1,2),
      "Pc" = matrix(1e-05,nrow=nYears,ncol=nSites), #runif(1,.05,1) #reducing this and the variance on this psi
      #"psi" = runif(1,0,1.5),
      "q" = runif(1,0.99,1.01)
      
      ) 
  }
      
      
  
  model = jags(jags.data, inits=inits,parameters.to.save=jags.params,
              model.file=model.loc, n.chains = n.chains, n.burnin=n.burnin, n.thin=n.thin, n.iter=n.iter, DIC=TRUE)
  
  timer.start <- proc.time()
  
  
  attach.jags(model)
  
  (run.time.in.min <- round(((proc.time()-timer.start)/60)["elapsed"], 0))
  
  
  # 
  # model.p = list(jags.data.p, inits=inits,parameters.to.save=jags.params,
  #              model.file=model.loc, n.chains = 3, n.burnin=n.burnin, n.thin=n.thin, n.iter=n.iter, DIC=TRUE)
  # 
  # mod.fit <- do.call(jags.parallel,model.p) 
  
  
  
  save("model","X","theta","sigma2","U","Umu","Usig","delta","Q","pdo","pdocoef","q","tauR",file="herring_jags_F_9sites_simulate_w_fishing_nospatial_autocor_hardprior_nopdo.RData")
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
  
  pc.df<-data.frame(Pc_sim[,9],model$BUGSoutput$mean$Pc[,9])
  
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
  #myList[[1]] #the number here refers to the chain number
  
  #######
  #PLOT ALL OUTPUT IN 1 BIG PDF
  ######
  
  setwd("~/Dropbox/Projects/In Progress/Pinniped_Herring_HG/Code/Figures") 
  
  
  pdf(paste("Simulated_Chains and Posteriors_spatialauto_NOFISHING",Sys.Date(),".pdf"), onefile = TRUE)
  
  #############
  #Predicted versus Observed -----need to consider the q metric here. 
  ############
  
  #acual data 
  mm2 <- mm[,-4]
  names(mm2) <- c("time","site","shi")
  #pull out the x data 
  
  model$BUGSoutput$sims.array[,,"X[1,1]"]
  
  #means
  tempmat<-model$BUGSoutput$mean$X*median(q) #this is adjusting given the estimated Q
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
  
  sim_df1<-data.frame(nm,
    c(q_sim,
    pdocoef_sim,
    theta_sim,
    Umu_sim,
    Usig_sim,
    tauR_sim,
    sigma2_sim
    )
  )
  names(sim_df1)<-c("param","value")
  
  for(i in 1:length(slist)){
    temp<-slist[[i]]
    names(temp)<-c("num","chain","value")
  
  sim<-as.numeric(subset(sim_df1,param==nm[i])[2])
    
    gtemp<-ggplot(temp,aes(y=value,x=num,group=chain))+
      geom_line(aes(colour=factor(chain)))+
      geom_hline(yintercept=sim,lty=2)+
      theme_acs()+
      ggtitle(nm[i])+
      theme(legend.position="none")
    
    gtemp2<-ggplot(temp,aes(x=value))+
      geom_bar()+
      theme_acs()+
      geom_vline(xintercept = 0,colour="red")+
      geom_vline(yintercept=sim,lty=2)+
      ggtitle(nm[i])
    
    
    grid.arrange(gtemp,gtemp2,nrow=2, heights=c(1.2,1.2))
  }
  
  
  #####################
  ############U -estiamtes of states for each pouplation at each time step 
  #####################
  
  uvec
  
  udf<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="U[1]"):which(colnames(myList[[1]])=="U[9]")]])
  
  udf<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="U[1]"):which(colnames(myList[[1]])=="U[9]")]])
  names(udf)<-c("num","chain","response","value")
  udf$chain<-factor(udf$chain)
  
  uvec2<-data.frame(value=uvec,response=unique(udf$response))
  
  gtemp<- ggplot(udf,aes(y=value,x=num,group=chain))+ 
    geom_line(aes(colour=chain))+
    theme_acs()+
    facet_wrap(~response)+
    geom_hline(data=uvec2,aes(yintercept=value),lty=2)+
    theme(legend.position="none")+
    ggtitle("U Chains")
  
  
  gtemp2<-ggplot(udf,aes(x=value))+
    geom_bar()+
    theme_acs()+
    geom_vline(xintercept = 0)+
    geom_vline(data=uvec2,aes(xintercept=value),lty=2)+
    facet_wrap(~response)+
    ggtitle("U Histogram")
  
  grid.arrange(gtemp,gtemp2,nrow=2, heights=c(1.2,1.2))
  
  
  
  ####Umu and Ui estimates 
  Umudf<-melt(model$BUGSoutput$sims.array[,,"Umu"])
  Umudf$Var3<-"Umu"
  Umudf<-Umudf[,c(1,2,4,3)]
  umuci<-smedian.hilow(Umudf$value,conf.int=0.95)
  umuci2<-quantile(Umudf$value,c(0.05,0.95))
  
  udf<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="U[1]"):which(colnames(myList[[1]])=="U[9]")]])
  
  ucomp<-ggplot(udf,aes(x=Var3,y=value,colour=Var3))+
    geom_hline(yintercept=median(Umudf$value),lty=2)+
    geom_hline(yintercept= umuci2[1],lty=1,colour="grey")+
    geom_hline(yintercept= umuci2[2],lty=1,colour="grey")+
    stat_summary(fun.data=median_hilow,lty=2)+
    stat_summary(fun.data=median_hilow,conf.int=0.5)+
    coord_flip()+
    theme_acs()+
    ylab("Population Growth Rate [U]")+
    xlab("Site Specific Population Growth")+
    ggtitle("Populaiton Growth -dist decay model")
  
  print(ucomp)
  
  
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
    temp_prior<-data.frame(prior=xmat[i,],group=factor(seq(1:nSites)))
    
    gtemp<-ggplot(tmp,aes(x=num,y=value,group=chain))+
      geom_hline(data=temp_prior,aes(yintercept=prior),lty=2)+
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
    temp_prior<-data.frame(prior=xmat[i,],Var3=factor(seq(1:nSites)))
    
    gt<-ggplot(tmp,aes(x=value))+
      geom_bar()+
      facet_wrap(~Var3)+
      theme_acs()+
      geom_vline(xintercept = 0,colour="red")+
      geom_vline(data=temp_prior,aes(xintercept=prior),lty=2)+
      ggtitle(paste("X Posterior time_",i))
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
  
  # #add site names from df2
  # ggplot(temp2,aes(x=time,y=site,fill=delta))+
  #   geom_tile()+
  #   theme_acs()
  
  delta_time<-ggplot(temp2,aes(x=time,y=delta,group=factor(site)))+
    geom_line(aes(colour=factor(site)))+
    theme_acs()
  
  print(delta_time)
  
  
  ##Posterior plots
  model$BUGSoutput$sims.array[,,"delta[1,1]"]
  
  edf1<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="delta[1,1]"):which(colnames(myList[[1]])=="delta[64,9]")]])
  
  names(edf1)<-c("num","chain","response","value")
  edf1$chain<-factor(edf1$chain)
  edf1$group<-factor(sort(rep(seq(1:nSites),runL)))
  
  edf1$year<-sort(rep(seq(1:nYears),runL*nSites))
  
  
  for(i in 1:nYears){
    tmp<-subset(edf1,year==i)
    temp_prior<-data.frame(prior=delta_sim[i,],group=factor(seq(1:nSites)))
    dcg<- ggplot(tmp,aes(x=num,y=value,group=chain))+
      geom_line(aes(colour=chain))+
      geom_hline(data=temp_prior,aes(yintercept=prior),lty=2)+
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
    temp_prior<-data.frame(prior=delta_sim[i,],Var3=factor(seq(1:nSites)))
    
    dhg<-ggplot(tmp,aes(x=value))+
      geom_bar()+
      facet_wrap(~Var3)+
      theme_acs()+
      geom_vline(xintercept = 0,colour="red")+
      geom_vline(data=temp_prior,aes(xintercept=prior),lty=2)+
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
  
  
  pc_time<-ggplot(temp2,aes(x=time,y=Pc,group=site))+
    geom_line(aes(colour=site))+
    theme_acs()
  
  print(pc_time)
  
  pc_ave<-ggplot(temp2, aes(x=site, y=Pc)) +
    stat_summary(colour="black",fun.y = mean, geom = "bar", position=position_dodge(width =0.9))+
    stat_summary(fun.data = mean_cl_normal, geom = "linerange",position=position_dodge(width =0.9))+
    ylab("Pc")+
    theme_acs()+
    ggtitle("Average Pc")+
    theme(legend.position="top",axis.title.x = element_blank(),axis.text.x=element_text(angle=90))
  
  print(pc_ave)
  
  ##Posterior plots
  model$BUGSoutput$sims.array[,,"Pc[1,1]"]
  
  edf1<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="Pc[1,1]"):which(colnames(myList[[1]])=="Pc[64,9]")]])
  
  names(edf1)<-c("num","chain","response","value")
  edf1$chain<-factor(edf1$chain)
  edf1$group<-factor(sort(rep(seq(1:9),runL)))
  
  edf1$year<-sort(rep(seq(1:nYears),runL*nSites))
  
  
  for(i in 1:nYears){
    tmp<-subset(edf1,year==i)
    temp_prior<-data.frame(prior=Pc_sim[i,],group=factor(seq(1:nSites)))
    pccg<-ggplot(tmp,aes(x=num,y=value,group=chain))+
      geom_line(aes(colour=chain))+
      facet_wrap(~group)+
      geom_hline(data=temp_prior,aes(yintercept=prior),lty=2)+
      theme_acs()+
    ggtitle(paste("Pc_chains_time_",i,".pdf"))
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
    temp_prior<-data.frame(prior=Pc_sim[i,],Var3=factor(seq(1:nSites)))
    
    pcg<-ggplot(tmp,aes(x=value))+
      geom_bar()+
      facet_wrap(~Var3)+
      theme_acs()+
      geom_vline(xintercept = 0,colour="red")+
      geom_vline(data=temp_prior,aes(xintercept=prior),lty=2)+
      ggtitle(paste("Pc Posteriors time_",i,".pdf"))
    print(pcg)
  }
  
  
  dev.off()
  
