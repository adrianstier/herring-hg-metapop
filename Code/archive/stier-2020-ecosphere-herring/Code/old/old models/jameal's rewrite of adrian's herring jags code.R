#Begin JAGS code
jagsscript = cat("
                 model {  
                 
                 ##########################
                 #OBSERVATION MODEL PRIORS and LIKELIHOODs
                 ##########################
                 
                 tauR ~ dunif(1,100); #this is the estimated variance prior for Spawn Index
                 q ~ dgamma(.02,0.001);  #Fraction of Spawn Observed on spawn surveys estiamted across all sites
                 #psi ~ dunif(0,100) #this is in variance for fishing set fixed to try to get convergence
                 
                 for(i in 1:nYears) {
                 for(j in 1:nSites) {
                 E[i,j] ~  dnorm(X[i,j]+q,1/tauR); #obs eq for spawn index. a normal pull with meam Xq LIKELIHOOD STATEMENT ****
                 
                 C_bookeeping[i,j]<-Z[i,j]+log(F[i,j]) # C_bookeeping is equal to to estimated total biomass (Z) pre catch + log of the proportion of Z in the catch (F) 
                 
                 # C[i,j] ~ dnorm(C_bookeeping[i,j],1/psi) #distribution of catch data  LIKELIHOOD STATEMENT ****
                 C[i,j] ~ dnorm(C_bookeeping[i,j],1/.1) #distribution of catch data  LIKELIHOOD STATEMENT ****
                 
                 }
                 }
                 
                 for(i in 1:nYears) {
                 for(j in 1:nSites) {
                 F[i,j] ~ dunif(0,f_prior[i,j]) #dbeta(1,1) #Fraction of Spawn Caught for each site, f_prior sets the hard variance for catch=0
                 }
                 }
                 
                 ##########################
                 #PROCESS MODEL PRIORS
                 ##########################