
n=4

vc.mat <- matrix(NA,n+1,n+1)

for(i in 1:n){
  
  vc.mat[i,i] <- "sigma2"
  
  for(j in (i+1):n){
    
    vc.mat[i,j] <- "cov"
    vc.mat[j,i] <- "cov"
    
  }
  
  
}

vc.mat


#acs modified - still not working



vc.mat <- matrix(NA,nSites,nSites)


for(i in 1:nSites){
  for(j in 1:nSites){

ifelse(i==j,vc.mat[i,j]<-sigmat2,
           vc.mat[i,j]<-theta
       )

  }
}