library(R2jags)
library(ggplot2)
library(reshape2)

#MCMC Output Reorg
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
colnames(myList[[1]]) #each of the params

tauRdf<-melt(model$BUGSoutput$sims.array[,,"tauR"])
names(tauRdf)<-c("num","chain","value")

ggplot(tauRdf,aes(y=value,x=num,group=chain))+
  geom_line(aes(colour=factor(chain)))+
  theme_bw()

#pooling the chains, what 
ggplot(tauRdf,aes(x=value))+
  geom_bar()+
  geom_vline(xintercept = 0,colour="red")+ #add zero line relative to param
  theme_bw()
  

#pull out multiple parameters 
tlist<-model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="U[1]"):which(colnames(myList[[1]])=="U[11]")]]

#lots of good stuff to do with these data looking at interquartile ranges, credile intervals etc. usign stat_summary in ggplot