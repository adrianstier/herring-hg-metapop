#PRIORS and Their Distributions 


#make empty vector

#####
#tauR
#####
tauR ~ dunif(1,100); #this is the estimated variance prior for Spawn Index
tr_vec <- seq(1,100,by=1)
tauR_sim<-dunif(tr_vec,min=1,max=100)
plot(tr_vec,tauR_sim,xlab="tauR_sim")


tauR ~ dgamma(1,100); #this is the estimated variance prior for Spawn Index
tr_vec <- seq(1,100,by=1)
tauR_sim<-dunif(tr_vec,min=1,max=100)
plot(tr_vec,tauR_sim,xlab="tauR_sim")


#####
#q
#####
#q ~ dgamma(.02,0.001);  #Fraction of Spawn Observed on spawn surveys estiamted across  sites
qvec<-seq(0,3,by=0.01)
q_sim <-dgamma(qvec,0.02,0.001)
plot(qvec,q_sim)

#####
#psi
#####
#psi ~ 0.1 #dunif(0,10) #this is in variance for fishing set fixed to try to get convergence
psivec<-seq(0,10,by=0.1)
psi_sim<-dunif(psivec,min=1,max=10) 
plot(psivec,psi_sim,xlab="tauR_sim")  ##*** something strange here


#####
#Pc
#####
#Pc[i,j] ~ dunif(0,c_prior[i,j]) #catch fraction estimated as fraction of 
#c prior is listed as max of 0.01 if there's a zero and 0.95 if ther's fishing in that site 

#####
#Umu
#####
#Umu ~ dnorm(0,1) #average population growth
umuvec<-seq(0,2,by=0.01)
umusim<-dnorm(umuvec,0,1)
plot(umuvec,umusim)


#####
#Usig ******* this seems like  too small of a range for var term
#####
#Usig ~ dunif(0,100); #variance in population growth 
usigvec<-seq(0,.01,by=0.001) #doing this 0.01 which is 1/100, or 1/100^2
usig_sim<-dunif(usigvec,min=1,max=10) 
plot(usigvec,usig_sim,xlab="tauR_sim")  ##*** something strange here

Usig ~ dunif(0,100); #variance in population growth 
Utau <- 1/(Usig*Usig);#precision of variance in pop growth

#####
#U ********this could be a place to dig in and impose a uniform prior keeping it from going so big
#####
#U[i] ~ dnorm(Umu,Utau) #each sites got the 
uvec<-seq(0,3,by=0.01)
usim<-dnorm(uvec,median(umusim),median(usig_sim))
usim<-dgamma(uvec,0.8,0.1) #one option would be to encourage the u estimates to stay away from higher values 
plot(uvec,usim)


#####
#pdocoef
#####
#pdocoef~dnorm(0,1); #estimated impact of pdo of herring
pdocoefvec<-seq(0,1,by=0.01)
pdocoef_sim<-dnorm(pdocoefvec,0,100)
plot(pdocoefvec,pdocoef_sim)


#####
#sigma2
#####
sigma2 ~ dgamma(0.01,0.01) #variance 
sigma2vec<-seq(0,2,by=0.01)
sigma2_sim<-dgamma(sigma2vec,.0001,0.001)
plot(sigma2vec,sigma2_sim)

#####
#eta
#####

#invEta ~ dgamma(0.01,0.01) #wiggle on distance decay
#eta <- 1/invEta


#####
#theta
#####
#    Q[i,j] <- sigma2 * exp(-theta * distMat5[i,j]) #no nugget 

#ignoring the weird log thingy
thetavec<-seq(0,1,by=.01)
theta_sim<-dnorm(thetavec,5,1)
plot(thetavec,theta_sim)

dsim<-seq(0,400,1)
thetsim<-exp(-0.001*dsim)
thetasim2<-exp(-0.001*dsim)
plot(dsim, thetsim,ylim=c(0,1))
plot(dsim,thetasim2)

covt<-exp(-theta_sim*thetavec)

plot(thetavec,covt)


theta_sim2<-dgamma(thetavec,1,0.6)
plot(thetavec,theta_sim2)

################
jagsgamma <- function(x, r, mu) {(mu^r*x^(r-1)*exp(-mu*r))/gamma(r)}


p.both.gamma <- function(x, r.jags, mu.jags, ylab = "Density", ...) {
    ## plot the density using the formula of jags
    matplot(x, cbind(jagsgamma(x, r.jags, mu.jags),
                     dgamma(x, shape=r.jags, rate=mu.jags)),
            type="l", lty=1, ylab=ylab, ...)
            
    mtext(substitute(list(r[jags] == R, mu[jags] == M),
                     as.list(formatC(c(R=r.jags, M=mu.jags)))))
    legend("topright", c("jagsgamma", "dgamma"), lty=1, col=1:2, bty = "n")
}

x <- seq(0,1, by=0.1)
# parameters of the gamma
p.both.gamma(x, r.jags = 0.001, mu.jags = 0.001)
p.both.gamma(x, r.jags = 0.001, mu.jags = 0.001,
             log = "xy")
## It seems to work. Both curves are superimposed.

## MM: something in between:
p.both.gamma(x, r.jags = 0.1, mu.jags = 0.5)
p.both.gamma(x, r.jags = 0.1, mu.jags = 0.5, log = "xy")

## But it is not at all with these parameters:

p.both.gamma(x, r.jags = .001, mu.jags = 0.001)


p.both.gamma(x, r.jags = .001, mu.jags = 10)

##################



#LIKELIHOOD FUNCTIONs 
Y[i,j] ~  dnorm(X[i,j]*q,1/tauR) #spawn index 
ctab[i,j] ~ dnorm(tl[i,j],1/.1) #distribution of catch data  

X[1,j] ~ dnorm(20,0.1); # vague normal prior for first time step

delta[i,1:nSites] ~ dmnorm(delta[i-1,1:nSites],tauQ[1:nSites,1:nSites]);

##THINGS TO LOOK INTO

#pdocoef - should likely be lower th
