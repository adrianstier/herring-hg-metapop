setwd("/Users/ole_shelton/Documents/Science/Active projects/Bayesian Model Selection/Simulations")

##### WRITE A 1-D simulation for eelgrass on the shoreline and then estimate it with JAGS code
library(R2jags)
library(coda)
library(MCMCpack)
load.module("glm")
load.module("bugs")

#CHAIN INFO FOR ALL 
	NCHAIN	<-	3
	Nburn	<-	5000
	Niter	<-	5000

output.all	<-	NULL

 set.seed(2) #<- to make plots 
##########################################################################################
for(XXX in 1:1){		################################ Loop over independent simulations
##########################################################################################

LETTER  <-	"E-base"
NAME	<-	paste(LETTER,XXX,sep="")

### Set up a matrix of observations
ID		<-	1:100
N		<- length(ID)

WAVE	<-	3 + 4 * ID - 0.095 * ID^2 + 0.0006 *ID^3
BETA	<-	-0.2
ALPHA	<-	5

EEL		<-	ALPHA + WAVE * BETA

plot(WAVE~ID)
plot(EEL~ID)

DIST	<- matrix(0,length(ID),length(ID))
for(i in 1:N){
	DIST[,i] <- abs(ID[i] - ID)
}

SIGMA	<-	4	
RANGE	<- 	15

theta 	 <- 0#rnorm(N, sd=0.05)
psi.true <- mvrnorm(1, mu=rep(0,N), Sigma=SIGMA * exp(-DIST*(RANGE^(-1))))
logit 	 <- EEL + theta + psi.true
prob  	 <- exp(logit) / (1 + exp(logit))

trials.true	<-	rnbinom(N,mu=8,size=5)
trials		<- trials.true
y 			<- rbinom(n=N, size=trials, prob=prob)

y[trials == 0]		<-	NA
trials[trials==0]	<-	1

hold.out.trials	<- round(0.1*sum(trials.true))
new.trials 		<- rnbinom(N,mu=hold.out.trials/100,size=2)
y.hold.out		<- rbinom(n=N, size=new.trials, prob=prob)

DAT		<-	data.frame(cbind(ID,y,trials.true,trials))
DAT.2	<-	data.frame(cbind(DAT,WAVE))

par(mfrow=c(3,1))
plot(ID,psi.true)
plot(ID,prob)
plot(ID,y/trials)

H	<-	matrix(0,N,N)
H[2,1]		<- 	1
H[(N-1),N]	<-	1
for(i in 2:(N-1)){
	H[(i+1),i]	<- 1
	H[(i-1),i]	<- 1
}
EIG <-	eigen(H)	

PHI.max	<-	EIG$values[1]^(-1)
PHI.min	<-	EIG$values[N]^(-1)

#   write.csv(DAT.2,file="A- Ord Logit Regress dat.csv",row.names=F)
##########################################################################################
##########################################################################################
##########################################################################################
##########################################################################################
##########################################################################################
##########################################################################################
##########################################################################################
##########################################################################################
##########################################################################################
##########################################################################################
##########################################################################################
##########################################################################################
library(R2jags)

nCov	<-	1
### MAKE SPATIAL MATRIX
H	<-	matrix(0,N,N)
H[2,1]		<- 	1
H[(N-1),N]	<-	1
for(i in 2:(N-1)){
	H[(i+1),i]	<- 1
	H[(i-1),i]	<- 1
}
EIG <-	eigen(H)	

IDEN	<-	diag(N)
muZeros = rep(0, N)

# DEFINE LIMITS ON spatial correlation parameter
PHI.max	<-	EIG$values[1]^(-1)
PHI.min	<-	EIG$values[N]^(-1)


##########################################################################################
##### RUN NON-SPATIAL MODEL WITH COVARIATES
jagsscript = cat("
model {
	alpha ~ dnorm(0,0.01); # overall intercept
   # priors on regression covariates
   for(i in 1:nCov) {
	  	betas[i] ~ dnorm(0,0.01); 
   }

# 	tau2Inv ~ dgamma(0.01,0.01)
# 	phi		~ dunif(PHI.min+1e-6,PHI.max-1e-6)
 
   for(j in 1:N) {
	    logit(p[j]) <- alpha + betas[1]*WAVE[j] 
    	y[j] ~ dbinom(p[j],trials[j]);
   }    
    
}", file="jags_dummy1.txt")

  jags.data     = list("N", "y", "trials", "nCov","WAVE")
  jags.params   =c("betas","alpha","p")
  model.loc		=c("jags_dummy1.txt")

  	jags.model.cov.non.spatial = jags(jags.data, inits = NULL, parameters.to.save= jags.params, model.file=model.loc, 
  						n.chains = 3, n.burnin = Nburn, n.thin = 1, n.iter = Nburn+Niter, DIC = TRUE)  
 	attach.jags(jags.model.cov.non.spatial, overwrite=TRUE)

##########################################################################################
##### RUN SPATIAL MODEL WITH COVARIATES
jagsscript = cat("
model {
	alpha ~ dnorm(0,0.01); # overall intercept
   # priors on regression covariates
   for(i in 1:nCov) {
	  	betas[i] ~ dnorm(0,0.01); 
   }

	tau2Inv ~ dgamma(0.01,0.01)
	phi		~ dunif(PHI.min+1e-6,PHI.max-1e-6)

	psi		~ dmnorm(muZeros,((tau2Inv)^(-1))*inverse(IDEN - phi * H))
	
   for(j in 1:N) {
	    logit(p[j]) <- alpha + betas[1]*WAVE[j] + psi[j]
    	y[j] ~ dbinom(p[j],trials[j]);
   }    
}", file="jags_dummy1.txt")

  jags.data     = list("N", "y", "trials","H", "nCov", "muZeros","PHI.min","PHI.max","IDEN","WAVE")
  jags.params   =c("betas","alpha","phi","tau2Inv","psi")
  model.loc		=c("jags_dummy1.txt")

  	jags.model.cov = jags(jags.data, inits = NULL, parameters.to.save= jags.params, model.file=model.loc, 
  						n.chains = NCHAIN, n.burnin = Nburn, n.thin = 1, n.iter = Nburn+Niter, DIC = TRUE)  
 	attach.jags(jags.model.cov, overwrite=TRUE)

##########################################################################################
##### RUN MODEL WITHOUT COVARIATES
jagsscript = cat("
model {
	alpha ~ dnorm(0,0.01); # overall intercept
   # priors on regression covariates
#    for(i in 1:nCov) {
# 	  	betas[i] ~ dnorm(0,0.01); 
#    }

	tau2Inv ~ dgamma(0.01,0.01)
	phi		~ dunif(PHI.min+1e-6,PHI.max-1e-6)

  	psi		~ dmnorm(muZeros,((tau2Inv)^(-1))*inverse(IDEN - phi * H))
	
   for(j in 1:N) {
	    logit(p[j]) <- alpha + psi[j]
    	y[j] ~ dbinom(p[j],trials[j]);
   }    
}", file="jags_dummy2.txt")


  jags.data     = list("N", "y", "trials","H", "muZeros","PHI.min","PHI.max","IDEN")
  jags.params   =c("alpha","phi","tau2Inv","psi")
  model.loc		=c("jags_dummy2.txt")


  	jags.model.base = jags(jags.data, inits = NULL, parameters.to.save= jags.params, model.file=model.loc, 
  						n.chains = NCHAIN, n.burnin = Nburn, n.thin = 1, n.iter = Nburn+Niter, DIC = TRUE)  
 	attach.jags(jags.model.base, overwrite=TRUE)
##########################################################################################
##### PARSE POSTERIOR
##########################################################################################

	post.cov.non.sp		<-	as.data.frame(jags.model.cov.non.spatial$BUGSoutput$sims.matrix)
	param.cov.non.sp	<-	post.cov.non.sp[,c("alpha","betas","deviance")]
	p.cov.non.sp		<-  as.data.frame(post.cov.non.sp[which(substr(colnames(post.cov.non.sp),1,1)=="p")])
	colnames(p.cov.non.sp)	<-	paste("p.",1:100,sep="")

	post.cov	<-	as.data.frame(jags.model.cov$BUGSoutput$sims.matrix)
	param.cov	<-	post.cov[,c("alpha","betas","phi","tau2Inv","deviance")]
	psi.cov		<-  as.data.frame(post.cov[which(substr(colnames(post.cov),1,3)=="psi")])
	colnames(psi.cov)	<-	paste("psi.",1:100,sep="")

	post.base	<-	as.data.frame(jags.model.base$BUGSoutput$sims.matrix)
	param.base	<-	post.base[,c("alpha","phi","tau2Inv","deviance")]
	psi.base	<-  as.data.frame(post.base[which(substr(colnames(post.base),1,3)=="psi")])
	colnames(psi.base)	<-	paste("psi.",1:100,sep="")
##########################################################################################
# Diagnostics
##########################################################################################
pdf(file=paste(NAME,"Toy Model base.pdf"),onefile=T)

	par(mfrow=c(5,2),mar=c(4,4,0.5,0.5))

	for(i in 1:ncol(param.base)){
		plot(param.base[,i],pch=".",ylab=colnames(param.base)[i])
		acf(param.base[,i])
	}

	THESE	<-	sort(round(runif(9,1,max(ID))))
	par(mfrow=c(3,3),mar=c(4,4,0.5,0.5))
	
	for(i in 1:9){
		plot(psi.base[,THESE[i]],pch=".",ylab=colnames(psi.base)[THESE[i]])
	}
	for(i in 1:9){
		acf(psi.base[,THESE[i]],ylab=colnames(psi.base)[THESE[i]])
	}

	
	## Marginals
	par(mfrow=c(3,2),mar=c(3,4,1.5,0.5))
	for(i in 1:ncol(param.base)){
		hist(param.base[,i],pch=".",ylab=colnames(param.base)[i],xlab="",main=colnames(param.base)[i])
	}

	par(mfrow=c(3,3),mar=c(3,4,1.5,0.5))
	for(i in 1:9){
		hist(psi.base[,THESE[i]],pch=".",ylab=colnames(psi.base)[THESE[i]],xlab="",main=colnames(psi.base)[THESE[i]])
	}

	par(mfrow=c(2,1))
	hist(colMeans(psi.base),main="Dist mean Psi")

# 	pairs(cbind(param.base,psi.base[,c(THESE)]),pch=".")

dev.off()

###################################
pdf(file=paste(NAME,"Toy Model cov.pdf"),onefile=T)

	par(mfrow=c(5,2),mar=c(4,4,0.5,0.5))

	for(i in 1:ncol(param.cov)){
		plot(param.cov[,i],pch=".",ylab=colnames(param.cov)[i])
		acf(param.cov[,i])
	}

	THESE	<-	sort(round(runif(9,1,max(ID))))
	par(mfrow=c(3,3),mar=c(4,4,0.5,0.5))
	
	for(i in 1:9){
		plot(psi.cov[,THESE[i]],pch=".",ylab=colnames(psi.cov)[THESE[i]])
	}
	for(i in 1:9){
		acf(psi.cov[,THESE[i]],ylab=colnames(psi.cov)[THESE[i]])
	}

	## Marginals
	par(mfrow=c(3,2),mar=c(3,4,1.5,0.5))
	for(i in 1:ncol(param.cov)){
		hist(param.cov[,i],pch=".",ylab=colnames(param.cov)[i],xlab="",main=colnames(param.cov)[i])
	}

	par(mfrow=c(3,3),mar=c(3,4,1.5,0.5))
	for(i in 1:9){
		hist(psi.cov[,THESE[i]],pch=".",ylab=colnames(psi.cov)[THESE[i]],xlab="",main=colnames(psi.cov)[THESE[i]])
	}

	par(mfrow=c(2,1))
	hist(colMeans(psi.cov),main="Dist mean Psi")

# 	pairs(cbind(param.cov,psi.cov[,c(THESE)]),pch=".")

dev.off()

###################################
pdf(file=paste(NAME,"Toy Model cov nonspatial.pdf"),onefile=T)

	par(mfrow=c(5,2),mar=c(4,4,0.5,0.5))

	for(i in 1:ncol(param.cov.non.sp)){
		plot(param.cov.non.sp[,i],pch=".",ylab=colnames(param.cov.non.sp)[i])
		acf(param.cov.non.sp[,i])
	}

	THESE	<-	sort(round(runif(9,1,max(ID))))
	par(mfrow=c(3,3),mar=c(4,4,0.5,0.5))
	
	## Marginals
	par(mfrow=c(3,2),mar=c(3,4,1.5,0.5))
	for(i in 1:ncol(param.cov.non.sp)){
		hist(param.cov.non.sp[,i],pch=".",ylab=colnames(param.cov.non.sp)[i],xlab="",main=colnames(param.cov.non.sp)[i])
	}

# 	pairs(cbind(param.cov,psi.cov[,c(THESE)]),pch=".")

dev.off()

##########################################################################################
# Calculate Predictive Distribution for each point
##########################################################################################
# jags.model.cov$BUGSoutput
# jags.model.base$BUGSoutput

#COV.MOD
# pD = 77.6 and DIC = 327.4
#BASE.MOD
# pD = 73.6 and DIC = 314.1

#Predictive Dist for Cov Non-spatial 
	pred.cov.non.sp		<-	p.cov.non.sp 

	pred.summary.cov.non.sp				<- rbind(colMeans(pred.cov.non.sp),apply(pred.cov.non.sp,2,var),
										as.matrix(apply(pred.cov.non.sp,2,quantile,probs=c(0.025,0.25,0.5,0.75,0.975))))
	rownames(pred.summary.cov.non.sp) 	<- c("Mean","Var","x.025","x.25","Median","x.75","x.975")
	pred.summary.cov.non.sp				<-	data.frame(t(pred.summary.cov.non.sp))
	pred.summary.cov.non.sp$ID			<-	ID

#Predictive Dist for Base 
	A			<- psi.base + param.base$alpha
	pred.base	<-	exp(A) / (1+exp(A))

	pred.summary.base	<- rbind(colMeans(pred.base),apply(pred.base,2,var),as.matrix(apply(pred.base,2,quantile,probs=c(0.025,0.25,0.5,0.75,0.975))))
	rownames(pred.summary.base) <- c("Mean","Var","x.025","x.25","Median","x.75","x.975")
	pred.summary.base	<-	data.frame(t(pred.summary.base))
	pred.summary.base$ID	<-	ID

#Predictive Dist for Cov
	A			<- psi.cov + param.cov$alpha + param.cov$betas %*% t(WAVE)
	pred.cov	<-	exp(A) / (1+exp(A))

	pred.summary.cov	<- rbind(colMeans(pred.cov),apply(pred.cov,2,var),as.matrix(apply(pred.cov,2,quantile,probs=c(0.025,0.25,0.5,0.75,0.975))))
	rownames(pred.summary.cov) <- c("Mean","Var","x.025","x.25","Median","x.75","x.975")
	pred.summary.cov	<-	data.frame(t(pred.summary.cov))
	pred.summary.cov$ID	<-	ID

##########################################################################################
# CALCULATE D_m = G_m + P_m
##########################################################################################
Gm.base	<- sum(DAT$y*(pred.summary.base$Mean - 1)^2 + (DAT$trials.true-DAT$y)*(pred.summary.base$Mean - 0)^2,na.rm=T)
Gm.cov	<- sum(DAT$y*(pred.summary.cov$Mean - 1)^2 + (DAT$trials.true-DAT$y)*(pred.summary.cov$Mean - 0)^2,na.rm=T)
Gm.cov.non.sp	<- sum(DAT$y*(pred.summary.cov.non.sp$Mean - 1)^2 +
						(DAT$trials.true-DAT$y)*(pred.summary.cov.non.sp$Mean - 0)^2,na.rm=T)

Pm.base	<-	sum(apply(pred.base,2,var) * DAT$y + apply(1-pred.base,2,var) * (DAT$trials.true-DAT$y),na.rm=T)
Pm.cov	<-	sum(apply(pred.cov,2,var) * DAT$y + apply(1-pred.cov,2,var) * (DAT$trials.true-DAT$y),na.rm=T)
Pm.cov.non.sp	<-	sum(apply(pred.cov.non.sp,2,var) * DAT$y + apply(1-pred.cov.non.sp,2,var) * (DAT$trials.true-DAT$y),na.rm=T)

# c(Gm.base,Gm.cov,Pm.base,Pm.cov)

Dm = data.frame(matrix(c("base","cov","cov.non.sp"),3,1));colnames(Dm)[1]<-"site"
Dm$value <-	c(Gm.base + Pm.base,Gm.cov + Pm.cov,Gm.cov.non.sp + Pm.cov.non.sp)

##########################################################################################
# CALCULATE Log-Score Full Score 
##########################################################################################

# A1 				<-  log(t(pred.base)) * DAT$y + log(t(1-pred.base)) * (DAT$trials.true-DAT$y)
# LS.each.base	<-	mean(colSums(A1,na.rm=T)  / sum(DAT$trials.true))
B1				<-	log(rowMeans(t(pred.base))) * DAT$y + log(rowMeans(t(1-pred.base))) * (DAT$trials.true-DAT$y)
LS.base			<-	sum(B1,na.rm=T) / sum(DAT$trials.true)

# A2 				<-  log(t(pred.cov)) * DAT$y + log(t(1-pred.cov)) * (DAT$trials.true-DAT$y)
# LS.each.cov		<-	mean(colSums(A2,na.rm=T) / sum(DAT$trials.true))
B2				<-	log(rowMeans(t(pred.cov))) * DAT$y + log(rowMeans(t(1-pred.cov))) * (DAT$trials.true-DAT$y)
LS.cov			<-	sum(B2,na.rm=T) / sum(DAT$trials.true)

# A3 				<-  log(t(pred.cov.non.sp)) * DAT$y + log(t(1-pred.cov.non.sp)) * (DAT$trials.true-DAT$y)
# LS.each.cov.non.sp	<-	mean(colSums(A3,na.rm=T) / sum(DAT$trials.true))
B3				<-	log(rowMeans(t(pred.cov.non.sp))) * DAT$y + log(rowMeans(t(1-pred.cov.non.sp))) * (DAT$trials.true-DAT$y)
LS.cov.non.sp	<-	sum(B3,na.rm=T) / sum(DAT$trials.true)


LS.base
LS.cov
LS.cov.non.sp


par(mfrow=c(3,1))
# hist(colSums(A1,na.rm=T)/ sum(DAT$trials.true),breaks=1000)
# hist(colSums(A2,na.rm=T)/ sum(DAT$trials.true),breaks=1000)
# hist(colSums(A3,na.rm=T)/ sum(DAT$trials.true),breaks=1000)

##########################################################################################
# CALCULATE Log-Score Cross Validation for new 10% simulated from the same model
##########################################################################################
# A1 				<-  log(t(pred.base)) * y.hold.out + log(t(1-pred.base)) * (new.trials - y.hold.out)
# LS.cv.base		<-	mean(colSums(A1,na.rm=T)  / sum(new.trials))
B1				<-	log(rowMeans(t(pred.base))) *  y.hold.out + log(rowMeans(t(1-pred.base))) * (new.trials - y.hold.out)
LS.cv.base	<-	sum(B1,na.rm=T) / sum(new.trials)

# A2 				<-  log(t(pred.cov)) * y.hold.out + log(t(1-pred.cov)) * (new.trials - y.hold.out)
# LS.cv.cov		<-	mean(colSums(A2,na.rm=T)  / sum(new.trials))
B2				<-	log(rowMeans(t(pred.cov))) * y.hold.out + log(rowMeans(t(1-pred.cov))) * (new.trials - y.hold.out)
LS.cv.cov		<-	sum(B2,na.rm=T) / sum(new.trials)

# A3 					<-  log(t(pred.cov.non.sp)) * y.hold.out + log(t(1-pred.cov.non.sp)) * (new.trials - y.hold.out)
# LS.cv.cov.non.sp	<-	mean(colSums(A3,na.rm=T)  / sum(new.trials))
B3					<-	log(rowMeans(t(pred.cov.non.sp))) * y.hold.out + log(rowMeans(t(1-pred.cov.non.sp))) * (new.trials - y.hold.out)
LS.cv.cov.non.sp	<-	sum(B3,na.rm=T) / sum(new.trials)


LS.cv.cov.non.sp
LS.cv.cov
LS.cv.base

# LS.cv.cov.non.sp.2
# LS.cv.cov.2
# LS.cv.base.2
# 
##########################################################################################
# CALCULATE WAIC
##########################################################################################

# BASE model
B				<-	log(rowMeans(t(pred.base))) * DAT$y + log(rowMeans(t(1-pred.base))) * (DAT$trials.true-DAT$y)
lppd.base		<-	sum(B,na.rm=T) #/ sum(DAT$trials.true)
pWAIC.1.base	<-	2*sum(
						(log(rowMeans(t(pred.base),na.rm=T)) - rowMeans(log(t(pred.base)),na.rm=T)) * DAT$y +
						(log(rowMeans(t(1-pred.base),na.rm=T)) - rowMeans(log(t(1-pred.base)),na.rm=T)) * (DAT$trials.true-DAT$y)
						,na.rm=T)

pWAIC.2.base	<-	sum(apply(log(pred.base),2,var) * DAT$y + apply(log(1-pred.base),2,var) * (DAT$trials.true-DAT$y),na.rm=T)

WAIC.1.base		<- -2 * lppd.base + 2 * pWAIC.1.base
WAIC.2.base		<- -2 * lppd.base + 2 * pWAIC.2.base

# WAIC.1.base
# WAIC.2.base

# COV model
B				<-	log(rowMeans(t(pred.cov))) * DAT$y + log(rowMeans(t(1-pred.cov))) * (DAT$trials.true-DAT$y)
lppd.cov		<-	sum(B,na.rm=T) #/ sum(DAT$trials.true)
pWAIC.1.cov		<-	2*sum(
						(log(rowMeans(t(pred.cov),na.rm=T)) - rowMeans(log(t(pred.cov)),na.rm=T)) * DAT$y +
						(log(rowMeans(t(1-pred.cov),na.rm=T)) - rowMeans(log(t(1-pred.cov)),na.rm=T)) * (DAT$trials.true-DAT$y)
					,na.rm=T)

pWAIC.2.cov		<-	sum(apply(log(pred.cov),2,var) * DAT$y + apply(log(1-pred.cov),2,var) * (DAT$trials.true-DAT$y),na.rm=T)

WAIC.1.cov		<- -2 * lppd.cov + 2 *pWAIC.1.cov
WAIC.2.cov		<- -2 * lppd.cov + 2 *pWAIC.2.cov

# COV non spatial model
B				<-	log(rowMeans(t(pred.cov.non.sp))) * DAT$y + log(rowMeans(t(1-pred.cov.non.sp))) * (DAT$trials.true-DAT$y)
lppd.cov.non.sp		<-	sum(B,na.rm=T) #/ sum(DAT$trials.true)
pWAIC.1.cov.non.sp	<-	2*sum(
							(log(rowMeans(t(pred.cov.non.sp),na.rm=T)) - rowMeans(log(t(pred.cov.non.sp)),na.rm=T)) * DAT$y +
							(log(rowMeans(t(1-pred.cov.non.sp),na.rm=T)) - rowMeans(log(t(1-pred.cov.non.sp)),na.rm=T)) * (DAT$trials.true-DAT$y)
						,na.rm=T)

pWAIC.2.cov.non.sp	<-	sum(apply(log(pred.cov.non.sp),2,var) * DAT$y + apply(log(1-pred.cov.non.sp),2,var) * (DAT$trials.true-DAT$y),na.rm=T)

WAIC.1.cov.non.sp		<- -2 * lppd.cov.non.sp + 2 *pWAIC.1.cov.non.sp
WAIC.2.cov.non.sp		<- -2 * lppd.cov.non.sp + 2 *pWAIC.2.cov.non.sp

##########################################################################################
###Summary of model selection criteria 
##########################################################################################
output	<-	data.frame(rbind(c(mean(jags.model.base$BUGSoutput$sims.matrix[,'deviance']), jags.model.base$BUGSoutput$pD, jags.model.base$BUGSoutput$DIC,
				Gm.base,Pm.base,Gm.base + Pm.base,
				LS.cv.base,#LS.each.base,
				LS.base,
				lppd.base,pWAIC.1.base,pWAIC.2.base,WAIC.1.base,WAIC.2.base),
			c(mean(jags.model.cov$BUGSoutput$sims.matrix[,'deviance']), jags.model.cov$BUGSoutput$pD, jags.model.cov$BUGSoutput$DIC,
				Gm.cov,Pm.cov,Gm.cov + Pm.cov,
				LS.cv.cov,#LS.each.cov,
 				LS.cov,
				lppd.cov,pWAIC.1.cov,pWAIC.2.cov,WAIC.1.cov,WAIC.2.cov),
			c(mean(jags.model.cov.non.spatial$BUGSoutput$sims.matrix[,'deviance']), jags.model.cov.non.spatial$BUGSoutput$pD, jags.model.cov.non.spatial$BUGSoutput$DIC,
				Gm.cov.non.sp,Pm.cov.non.sp,Gm.cov.non.sp + Pm.cov.non.sp,
				LS.cv.cov.non.sp,#LS.each.cov.non.sp,
				LS.cov.non.sp,
				lppd.cov.non.sp,pWAIC.1.cov.non.sp,pWAIC.2.cov.non.sp,WAIC.1.cov.non.sp,WAIC.2.cov.non.sp)))



 colnames(output)	<- c("dev","pD","DIC","Gm","Pm","Dm","LS.CV",#"LS.each",
								"LS","lppd","pW.1","pW.2","WAIC.1","WAIC.2")
output$Model		<-	c("base","cov","cov.non.spatial")
output$trials		<- sum(trials.true)
output$hold.out		<- sum(new.trials)

output$NAME		<-	NAME
output.all		<-	rbind(output.all,output)
# output.all
write.csv(output.all,file=paste(LETTER, "Compare models.csv"))

##########################################################################################
##########################################################################################
##########################################################################################
### MAKE SOME PLOTS OF PREDICTIONS VS. OBSERVATIONS
##########################################################################################
##########################################################################################
##########################################################################################

pdf(file=paste(NAME,"Compare Models.pdf"),onefile=T)

par(mfrow=c(1,1),mar=c(1,1,1,1))

plot(1:5,1:5,type="n",xlab="",ylab="",axes=F)
text(paste("Model:",NAME),x=1,y=4.5,pos=4)
text(paste("Burn-in = ",Nburn),x=1,y=4.2,pos=4)
text(paste("Final Iter = ",Niter),x=1,y=4,pos=4)
# text(paste("Thinning = ",THINNING),x=1,y=3.8,pos=4)
# text(paste("Retained Samples = ",iter/THINNING),x=1,y=3.6,pos=4)
text(paste("N = ",sum(trials.true)),x=1,y=3.4,pos=4)
text(paste("N.hold.out = ",sum(new.trials)),x=1,y=3.2,pos=4)
text(paste("Spatial Variance = ",SIGMA),x=1,y=2.8,pos=4)
text(paste("Spatial Range = ",RANGE),x=1,y=2.6,pos=4)

par(mfrow=c(5,1),mar=c(4,4,2,1))
	plot(ID,psi.true)
	plot(ID,prob)
	plot(ID,y/trials.true)
	plot(ID,trials.true)
	plot(ID,new.trials)

par(mfrow=c(4,1),mar=c(4,4,2,1))
 y.lim=c(0,1)
 plot(ID,pred.summary.cov.non.sp$Median,col=3,ylim=y.lim,pch=21,cex=0.8,bg=3,ylab="")
 par(new=T)
 plot(ID,prob,ylim=y.lim,pch=21,cex=0.8,ylab="",lwd=1.5)
 par(new=T)
 plot(DAT$ID,DAT$y/DAT$trials,ylim=y.lim,pch="x",cex=0.8,ylab="",xlab="",lwd=1.5,)
 arrows(x0=ID,x1=ID,
 		y0=pred.summary.cov.non.sp$x.025,
 		y1=pred.summary.cov.non.sp$x.975,col=3,length=0)
 title("Non Spatial Covariate Model")


 y.lim=c(0,1)
 plot(ID,pred.summary.base$Median,col=4,ylim=y.lim,pch=21,cex=0.8,bg=4,ylab="",lwd=1.5)
 par(new=T)
 plot(ID,prob,ylim=y.lim,pch=21,cex=0.8,ylab="",lwd=1.5)
 par(new=T)
 plot(DAT$ID,DAT$y/DAT$trials,ylim=y.lim,pch="x",cex=0.8,ylab="",xlab="",lwd=1.5)
 arrows(x0=ID,x1=ID,
 		y0=pred.summary.base$x.025,
 		y1=pred.summary.base$x.975,col=4,length=0)
 title("Spatial Model")
 
 y.lim=c(0,1)
 plot(ID,pred.summary.cov$Median,col=2,ylim=y.lim,pch=21,cex=0.8,bg=2,ylab="")
 par(new=T)
 plot(ID,prob,ylim=y.lim,pch=21,cex=0.8,ylab="",lwd=1.5)
 par(new=T)
 plot(DAT$ID,DAT$y/DAT$trials,ylim=y.lim,pch="x",cex=0.8,ylab="",xlab="",lwd=1.5,)
 arrows(x0=ID,x1=ID,
 		y0=pred.summary.cov$x.025,
 		y1=pred.summary.cov$x.975,col=2,length=0)
 title("Spatial Covariate Model")
 
 y.lim=c(0,1)
 plot(ID,pred.summary.base$Median,col=4,ylim=y.lim,pch=21,cex=0.8,bg=4,ylab="",lwd=1.5)
 par(new=T)
 plot(ID,pred.summary.cov$Median,col=2,ylim=y.lim,pch=21,cex=0.8,bg=2,ylab="",lwd=1.5)
 par(new=T)
 plot(ID,pred.summary.cov.non.sp$Median,col=3,ylim=y.lim,pch=21,cex=0.8,bg=3,ylab="")
 par(new=T)
 plot(ID,prob,ylim=y.lim,pch=21,cex=0.8,ylab="",lwd=1.5)
 par(new=T)
 plot(DAT$ID,DAT$y/DAT$trials,ylim=y.lim,pch="x",cex=0.8,ylab="",xlab="",lwd=1.5)
##########################################################################################
##########################################################################################

width.base <- pred.summary.base$x.975 - pred.summary.base$x.025
width.cov  <- pred.summary.cov$x.975 - pred.summary.cov$x.025

x.lim=c(0,0.6)
plot(width.base,width.cov,xlim=x.lim,ylim=x.lim)
abline(0,1,lty=2)

##########################################################################################
##########################################################################################
## Compare Predictions from Base and Covariate Models
##########################################################################################
##########################################################################################

par(mfrow=c(1,1),mar=c(5,5,0.5,0.5))
plot(x=pred.summary.base$Median,y=pred.summary.cov$Median,col=1,ylim=y.lim,pch=21,cex=0.8,bg=1,
		ylab="Covariate Model",xlab="Base Model")
abline(0,1,lty=2)
arrows( y0=pred.summary.cov$Median,
		y1=pred.summary.cov$Median,
		x0=pred.summary.base$x.025,
		x1=pred.summary.base$x.975,col=1,length=0)
arrows( x0=pred.summary.base$Median,
		x1=pred.summary.base$Median,
		y0=pred.summary.cov$x.025,
		y1=pred.summary.cov$x.975,col=1,length=0)

# par(mfrow=c(2,1),mar=c(5,5,0.5,0.5))
#  	plot(pred.summary.base$Median,LS.base)
#  	plot(pred.summary.cov$Median,LS.each.base)
 
#  par(mfrow=c(1,1),mar=c(5,5,0.5,0.5))
#  	plot(LS.each.base,LS.each.cov)
#  	abline(0,1,lty=2)

dev.off()

}


setwd("/Users/ole_shelton/Documents/Science/Active projects/Bayesian Model Selection")
write.csv(param.cov.non.sp,file=paste(LETTER,"param.cov.non.sp.csv"),row.names=F)
write.csv(param.cov,file=paste(LETTER,"param.cov.csv"),row.names=F)
write.csv(param.base,file=paste(LETTER,"param.base.csv"),row.names=F)

write.csv(pred.summary.cov,file=paste(LETTER,"pred.cov.csv"),row.names=F)
write.csv(pred.summary.cov.non.sp,file=paste(LETTER,"pred.cov.non.sp.csv"),row.names=F)
write.csv(pred.summary.base,file=paste(LETTER,"pred.base.csv"),row.names=F)
