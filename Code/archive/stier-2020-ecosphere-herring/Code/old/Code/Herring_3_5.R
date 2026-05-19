
library(ggplot2)
library(reshape2)
library(gdata)
library(maps)
library(mapproj)
library(ggmap)
library(gplots)
library(R2jags)
library(coda)

setwd("~/Dropbox/Projects/In Progress/Pinniped_Herring_HG/Code")
#setwd("~/Dropbox/Projects/In Progress/Code")
#setwd("~/Desktop/Code_SSL")
source('theme_acs.R')
source('multiplot.R')
#load('herring_jags.RData')

########################################################################
############ Load Herring Data
########################################################################
x=read.csv("HG_Spawn_Survey_1940_2013b.csv")
x<- x[c(1,3,13,14,15,16)]
x$SHI2<-log(x$SHI+1)
x$presabs <-ifelse(x$SHI>0,1,0)

########################################################################
############ plot herrring time series by site 
########################################################################

#number of sites: 13
length(unique(x$section))
length(unique(x$section_name))

#setwd("~/Dropbox/Projects/In Progress/Code")


#plot out all the time series for each major region
ggher<-ggplot(x,aes(x=year,y=SHI,group=section_name))+
        geom_point(aes(colour=section_name))+
        geom_line(aes(colour=section_name))+
        #scale_y_log10()+
        theme_acs()+
        ggtitle("Herring By Spawn Area")
  

print(ggher)
ggsave("herringSubstocks.pdf")


ggher2<-ggplot(x,aes(x=year,y=SHI,group=section_name))+
  geom_point(aes(colour=section_name))+
  geom_line(aes(colour=section_name))+
  #scale_y_log10()+
  theme_acs()+
  ggtitle("Herring By Spawn Area")+
  facet_wrap(~section_name,scales="free")+
  theme(legend.position="none")

print(ggher2)
ggsave("herringSubstocks_facet1.pdf",width=10,height=8)

ggher3<-ggplot(x,aes(x=year,y=SHI,group=section_name))+
  geom_point(aes(colour=section_name))+
  geom_line(aes(colour=section_name))+
  #scale_y_log10()+
  theme_acs()+
  ggtitle("Herring By Spawn Area")+
  facet_wrap(~section_name)

print(ggher3)
ggsave("herringSubstocks_facet2.pdf")

#could loop through here for video.
x2013 <-subset(x,year==2013)
al1 = get_map(location = c(-135,51.5,-131,55), zoom = 7, maptype = 'terrain')
al1MAP = ggmap(al1)

hmap <-al1MAP+
  geom_point(data = x2013, aes(x = Longitude, y = Latitude,size=SHI2,fill=factor(presabs)),pch=21)+
  geom_text(data = x2013,aes(x = Longitude, y = Latitude,label=section_name),vjust=.1,hjust=-.1,size=4)+
  scale_size(range = c(4, 10))+
  ggtitle("herringSpawn2013")


print(hmap)

ggsave("herringSiteMap.pdf")

########################################################################
############ Spawn Map by Site
########################################################################

#blended with time series
yr<-unique(x$year)
ss<-melt(c(rowSums(tapply(x$SHI,list(x$year,x$section_name),sum),,na.rm=T)))
ss<-data.frame("sum"=ss[,1],"year"=rownames(ss))
ss[,2]=as.numeric(as.character(ss[,2]))
shi_sum<-ss

for(i in 1:length(yr)){
  temp <- subset(x,year==yr[i])
  temp2<- subset(temp,SHI>0)
  cm<-data.frame("Latitude"=colMeans(temp2[,c(5,6)])[1],"Longitude"=colMeans(temp2[,c(5,6)])[2]) #plot centroid mean of lat long
  
  ggtemp <-al1MAP+
    geom_point(data = temp, aes(x = Longitude, y = Latitude,size=SHI2,fill=factor(presabs)),pch=21)+
    geom_point(data=cm,aes(x=Longitude,y=Latitude),colour="purple",pch=17,size=3)+
    geom_text(data = temp,aes(x = Longitude, y = Latitude,label=section_name),vjust=.1,hjust=-.1,size=2)+
    scale_size(range = c(4, 10))+
    ggtitle(paste(yr[i],"_herringspawn"))+
    theme(legend.position="none")

  ggsum<-ggplot(shi_sum,aes(x=year,y=sum))+
    geom_line()+
    ylab("sum of spawn index")+
    xlab("year")+
    theme_acs()+
    geom_vline(xintercept=yr[i],colour="red")
  
  
  jpeg(filename = paste(yr[i],"_herringspawn.png"),width = 800, height = 480,)
  multiplot(ggtemp,ggsum,cols=2)
  dev.off()
}

########################################################################
############ Plot number of spawns, mean spawn size, and 
########################################################################


#percent of years where there's been any spawn over past 75 years
100*round(tapply(x$presabs,list(x$section_name),sum)/
            tapply(x$presabs,list(x$section_name),length),2)

tapply(x$SHI,list(x$section_name),mean) #highest average catch
tapply(x$SHI,list(x$section_name),sd) #reliable spawn sites

num<-melt(c(rowSums(tapply(x$presabs,list(x$year,x$section_name),sum),,na.rm=T)))
num<-data.frame("num"=num[,1],"year"=rownames(num))
num[,2]=as.numeric(as.character(num[,2]))

#number spawn sites through time

ggss<-ggplot(num,aes(x=year,y=num))+
  geom_line()+
  ylab("num spawn sites")+
  xlab("year")+
  theme_acs()

print(ggss)

ss<-melt(c(rowSums(tapply(x$SHI,list(x$year,x$section_name),sum),,na.rm=T)))
ss<-data.frame("sum"=ss[,1],"year"=rownames(ss))
ss[,2]=as.numeric(as.character(ss[,2]))
shi_sum<-ss

ggsum<-ggplot(shi_sum,aes(x=year,y=sum))+
  geom_line()+
  ylab("sum of spawn index")+
  xlab("year")+
  theme_acs()


pc<- data.frame("year"=ss[,2],"pc"=ss[,1]/num[,1])

ggpc<-ggplot(pc,aes(x=year,y=pc))+
  geom_line()+
  ylab("spawn area per site out")+
  xlab("year")+
  theme_acs()

pdf("herring_sums.pdf",width=3)
multiplot(ggss,ggsum,ggpc)
dev.off() 




########################################################################
############ plot herrring catch time series by site 
########################################################################

setwd("~/Dropbox/Projects/In Progress/Pinniped_Herring_HG/Code")
c <- read.csv("herring_catch_local.csv")
yr_c<-unique(c$Year)
c$presabs <-ifelse(c$TotalCatch>0,1,0)
c<-subset(c,Section %in% c(1,2,3,5,6,11,12,21,22,23,24,25)) #remove sites that are offshore or don't have data for

#number of sites with catch data: 12
length(unique(c$Section))
length(unique(c$Name))

#plot out all the time series for each major region
ggher<-ggplot(c,aes(x=Year,y=TotalCatch,group=Name))+
  geom_point(aes(colour=Name))+
  geom_line(aes(colour=Name))+
  theme_acs()+
  ggtitle("Catch By Spawn Area")

print(ggher)
ggsave("Catch_herringSubstocks.pdf")


ggher2<-ggplot(c,aes(x=Year,y=TotalCatch,group=Name))+
  geom_point(aes(colour=Name))+
  geom_line(aes(colour=Name))+
  #scale_y_log10()+
  theme_acs()+
  ggtitle("Catch Herring By Spawn Area")+
  facet_wrap(~Name,scales="free")+
  theme(legend.position="none")

print(ggher2)




ggsave("Catch_herringSubstocks_facet1.pdf",width=10,height=8)

ggher3<-ggplot(c,aes(x=Year,y=TotalCatch,group=Name))+
  geom_point(aes(colour=Name))+
  #geom_line(aes(colour=Name))+
  scale_y_log10()+
  theme_acs()+
  ggtitle("Herring By Spawn Area")+
  facet_wrap(~Name)

print(ggher3)
ggsave("Catch_herringSubstocks_facet2.pdf")

x2013 <-subset(c,Year==2013)
al1 = get_map(location = c(-135,51.5,-131,55), zoom = 7, maptype = 'terrain')
al1MAP = ggmap(al1)

hmap <-al1MAP+
  geom_point(data = x2013, aes(x = Longitude, y = Latitude,size=TotalCatch,fill=factor(presabs)),pch=21)+
  geom_text(data = x2013,aes(x = Longitude, y = Latitude,label=Name),vjust=.1,hjust=-.1,size=4)+
  scale_size(range = c(4, 10))+
  ggtitle("herringSpawn2013")


print(hmap)

ggsave("herringSiteMap.pdf")

########################################################################
############ Maps of Catch Data By Site
########################################################################
c <- read.csv("herring_catch_local.csv")
yr_c<-unique(c$Year)
c$presabs <-ifelse(c$TotalCatch>0,1,0)
c<-subset(c,Section %in% c(1,2,3,5,6,11,12,21,22,23,24,25)) #remove sites that are offshore or don't have data for

#calculate sum of catch by year
sc<-melt(c(rowSums(tapply(c$TotalCatch,list(c$Year,c$Name),sum),,na.rm=T)))
sc<-data.frame("sum"=sc[,1],"year"=rownames(sc))
sc[,2]=as.numeric(as.character(sc[,2]))
c_sum<-sc


al1 = get_map(location = c(-135,51.5,-131,55), zoom = 7, maptype = 'terrain')
al1MAP = ggmap(al1)

for(i in 1:length(yr_c)){
  temp <- subset(c,Year==yr_c[i])
  temp2<- subset(temp,TotalCatch>0)
  cm<-data.frame("Latitude"=colMeans(temp2[,c(13,14)])[1],"Longitude"=colMeans(temp2[,c(13,14)])[2]) #plot centroid
  
  ggtemp <-al1MAP+
    geom_point(data = temp, aes(x = Longitude, y = Latitude,size=TotalCatch,fill=factor(presabs)),pch=21)+
    geom_point(data=cm,aes(x=Longitude,y=Latitude),colour="purple",pch=17,size=3)+
    geom_text(data = temp,aes(x = Longitude, y = Latitude,label=Name),vjust=.1,hjust=-.1,size=2)+
    scale_size_continuous(limits=c(0,8000),range=c(4,10))+
    ggtitle(paste(yr_c[i],"_herringcatch"))+
    theme(legend.position="none")
  
  ggsum<-ggplot(c_sum,aes(x=year,y=sum))+
    geom_line()+
    ylab("sum of spawn index")+
    xlab("year")+
    theme_acs()+
    geom_vline(xintercept=yr_c[i],colour="red")
  
  
  jpeg(filename = paste(yr_c[i],"_commercialcatch.png"),width = 800, height = 480,)
  multiplot(ggtemp,ggsum,cols=2)
  dev.off()
}

########################################################################
############ Number of Sections Fished
########################################################################

#calculate sum of catch by year
tapply(c$presabs,list(c$Name),sum)
with(subset(c,presabs==1),tapply(TotalCatch,list(Name),length))
with(subset(c,presabs==1),tapply(TotalCatch,list(Name),mean))

#how many sites are being fished 
#scaling things by effort or catch seems necessary

mdf8<-data.frame("Num Sites Fished"=with(subset(c,presabs==1),
                                         tapply(presabs,list(Year),length)
))

mdf8$year<-rownames(mdf8)
mdf8$year<-as.numeric(mdf8$year)
ggplot(mdf8,aes(x=year,y=Num.Sites.Fished))+
  geom_line()+
  theme_acs()


########################################################################
############ Plot number of catches, mean spawn size, and 
########################################################################
x2 <-x[,c(1:6)]
c2<-c[,c(1,3,10,11,12,13,14)]
names(c2)<-c("year","TotalCatch","SOK","section","section_name","Latitude","Longitude")
mdf <- merge(x2,c2)
mdf2<-melt(mdf,id.vars=c("year","section","section_name","Latitude","Longitude"))
mdf2$value<-as.numeric(mdf2$value)
mdf2<-subset(mdf2,variable!="SOK")

ggplot(mdf2,aes(x=year,y=value,group=variable))+
  geom_line(aes(colour=variable))+
  geom_point(aes(colour=variable))+
  facet_grid(variable~section_name,scales="free")+
  theme_acs()

#subset for levin
mdf3<- subset(mdf2, section_name %in% c("Skidegate Inlet",
                                        "Cumshewa Inlet",
                                        "Louscoone Inlet",
                                        "Juan Perez Sound",
                                        "Skincuttle Inlet",
                                        "Laskeek Bay"))

mdf3$section_name <- factor(mdf3$section_name, levels = c("Juan Perez Sound",
                                                          "Skincuttle Inlet",
                                                          "Laskeek Bay",
                                                          "Skidegate Inlet",
                                                          "Cumshewa Inlet",
                                                          "Louscoone Inlet"
)
)


ggplot(mdf3,aes(x=year,y=value))+
  geom_line(aes(colour=section_name))+
  geom_point(aes(colour=section_name))+
  facet_grid(variable~section_name,scales="free")+
  theme_acs()

ggsave("Catch_herringSubstocks_6focal.pdf",width=10,height=8)


mdf4<-subset(mdf3,variable=="TotalCatch")
mdf5<-subset(mdf3,variable=="SHI")

gg_catch<-ggplot(mdf4,aes(x=year,y=value))+
  geom_line(aes(colour=section_name),lty=2)+
  geom_point(aes(colour=section_name),pch=21)+
  facet_wrap(~section_name,scales="free",ncol=6)+
  theme_acs()+
  theme(legend.position="none")


gg_shi<-ggplot(mdf5,aes(x=year,y=value))+
  geom_line(aes(colour=section_name))+
  geom_point(aes(colour=section_name))+
  facet_wrap(~section_name,scales="free",ncol=6)+
  theme_acs()+
  theme(legend.position="none")

multiplot(gg_shi,gg_catch)

mdf6<-mdf3[!duplicated(mdf3[3:5]),]
mdf6$presabs<-1

al1 = get_map(location = c(-134,51.5,-131,55), zoom = 7, maptype = 'satellite')
al1MAP = ggmap(al1)
print(al1MAP)

jpeg(filename = "6focal herringspawn.jpg",width = 1000, height = 680,qual=100)

al1MAP+
  geom_point(data = mdf6, aes(x = Longitude, y = Latitude),size=3,colour="red")+
  geom_text(data = mdf6,aes(x = Longitude, y = Latitude,label=section_name),colour="white",vjust=.1,hjust=-.1,size=3)+
  ggtitle("6 Focal Sits")+
  theme(legend.position="none")+
  theme_acs()

dev.off()

mdf7<-data.frame("year"=unique(mdf$year),
                 "cumulative catch"=cumsum(tapply(mdf$TotalCatch,list(mdf$year),sum)),
                 "SpawnIndex"=tapply(mdf$SHI,list(mdf$year),sum)
)

mdf7b<-melt(mdf7,id.vars=c("year"))
ggplot(mdf7b,aes(x=year,y=value))+
  geom_line(aes(colour=variable))+
  facet_grid(variable~.,scales="free")+
  theme_acs()+
  theme(legend.position="none")


########################################################################
############ Estimate Distance Matrix and Spatial Autocor Function
########################################################################
setwd("~/Dropbox/Projects/In Progress/Pinniped_Herring_HG/Code")

# #pull out site and site ID
# df <- data.frame(x$section,x$section_name)
# df2<-df[!duplicated(df), ]
# 
# dist_euc<-as.matrix(read.csv("h_dist_euc.csv")[,-1])
# dist_shore<-as.matrix(read.csv("h_dist_shore.csv")[,-1])
# 
# colnames(dist_euc)<-df2[,2]
# colnames(dist_shore)<-df2[,2]

#blake's distance matrix for coastal swim converted to KM
distMat4<-as.matrix(read.csv("h_dist_shore.csv")[,-1]/1000)
distMat5<-distMat4[-4,-4]

########################################################################
############ Prep Matrix for Time Series, time in rows, spawn index colums
########################################################################
years = seq(1950,2013)
nYears = length(years)
nSites = 12

x2 <- x[,c(1,2,3)]
w <- reshape(x2, 
             timevar = "section",
             idvar = c("year"),
             direction = "wide")[,-1]

#replace zeros with NAs
w[w==0] <- NA

#double check that it has time ont he rows and sites on the column
Y= as.matrix(w)
Y = Y[-c(1:10),-4] #drop site 4 since we have no catch data 
#Y = Y/0.5 #q coefficient to turn into biomass
Y = log(Y)
#load covariates
setwd("~/Dropbox/Projects/In Progress/Pinniped_Herring_HG/Code")
pdo<-read.csv("pdo.csv")
pdosummer<-subset(pdo,month %in% c(3,4,5,6)) #average april<-june
pdoxb<-c(tapply(pdo$Value,list(pdo$year),mean))
pdo2<-pdoxb[87:160] #1940-2013
pdo3<-pdo2[11:74] #1950-2013
pdo4<-pdo3[27:64] #7

#ctab<-data.frame(tapply(c$TotalCatch,list(c$Year,c$Section),sum)) #all catch
ctab<-data.frame(tapply(c$CatchJan_Apr,list(c$Year,c$Section),sum)) #just spring catch
ctab2<-ctab[-nrow(ctab),]
colnames(ctab2)<-colnames(Y)
ctab2<-as.matrix(ctab2)
ctab2_1<-log(ctab2+1)
############Subset Data to look only at recent sites
# 
# Y<-Y[-c(1:26),]
# years = seq(1976,2013)
# nYears = length(years)
# nSites = 12
#pdo4
#ctab3<-ctab2[-c(1:26),]
#ctab3_1<-log(ctab3+1)
#test to make sure the problem is the catch matrix 
#ctab3<-matrix(0,nrow(ctab3),ncol(ctab3))

#look at whether there are any times when fishing is greater than estmates SSB 
ydf<-data.frame(exp(Y)-ctab2_1)
ydf<-melt(t(ydf))
ydf$year<-sort(rep(seq(1950,2013,by=1),nSites))


ggplot(ydf,aes(x=value))+
  geom_bar()+
  facet_wrap(~Var1,scales="free")+
  geom_vline(xintercept=0,colour="red")+
  theme_acs()

ggplot(ydf,aes(x=year,y=Var1,fill=value))+
  geom_tile()+
  theme_acs()+
  scale_fill_gradient2(limits=c(-40000,2000000)) #this isn't working well 

########################################################################
############JAGS CODE to fit model 
########################################################################

#work out the logic for site specific fishing allocation 


jagsscript = cat("
                 model {  
                
                 # POPULATION GROWTH: random variable from shared mean and sd across populations
                 Umu ~ dnorm(0,1); #average population growth
                 Usig ~ dunif(0,100); 
                 Utau <- 1/(Usig*Usig); 
                 
                 for(i in 1:nSites) {
                 U[i] ~ dnorm(Umu,Utau);
                 }

                 #COVARIATES
                 pdocoef~dnorm(0,1);
                 
                 #SPATIAL COVARIANCE
                 tau ~ dgamma(0.01,0.01);
                 sigma2 <- 1/tau;
                 invEta ~ dgamma(0.01,0.01);
                 eta <- 1/invEta;
                 logtheta ~ dnorm(0,0.01);
                 theta <- exp(logtheta);
                 
                 for(i in 1:nSites) {
                  for(j in 1:nSites) {
                      Q[i,j] <- sigma2 * exp(-theta * distMat5[i,j]) + eta*diag[i,j];
                 }
                 }   
                 
                 # JAGS wants us to use the matrix inverse
                 tauQ[1:nSites,1:nSites] <- inverse(Q[1:nSites,1:nSites]);
                 
                 
                 # Estimate the initial state vector of population abundances
                 for(j in 1:nSites) {
                        X[1,j] ~ dnorm(20,0.1); # vague normal prior for first time step
                        Z[1,j] <- X[1,j]-log(1-Pc[1,j])
                 }

                

                 # AUTOREGRESSIVE PROCESS for remaining years
                 for(j in 1:nSites) {zeros[j]<-0;}
                        delta[1,1:nSites] ~ dmnorm(zeros,tauQ[1:nSites,1:nSites]);
                 
                 for(i in 2:nYears) {
                        delta[i,1:nSites] ~ dmnorm(delta[i-1,1:nSites],tauQ[1:nSites,1:nSites]);
                  for(j in 1:nSites) {
  
                 
                 #fishing by site and global pdo estimates and U estimates 
                 dummy[i-1,j] <- X[i-1,j]+U[j]+pdocoef*pdo[i-1]; 
            
                 
                 #make second dummy variable Z to add in the delta param
                 Z[i,j] <- dummy[i-1,j]+delta[i,j]; 
                 
                 
                 #Estimate the state X with catch by site 
                 
                 X[i,j] <-Z[i,j]+log(1-Pc[i,j]);

                 
                   }
                 }
                 
                 # OBSERVATION MODEL  
                 
                 #Variance Terms for Obs Model PRIORS
                 #tauR ~ dgamma(0.001,0.001);
                 tauR ~ dunif(1,100); #this is in variance prior for SHI
                 #psi ~ 0.1 #dunif(0,10) #this is in variance for fishing increase 2nd val for lower var window
                
                for(i in 1:nYears) {
                  for(j in 1:nSites) {
                Pc[i,j] ~ dbeta(1,1);#Fraction of Spawn Observed 
                  }
                }

                q ~ dgamma(.02,0.001);  #Fraction of Catch Observed: Pc

                 




                 for(i in 1:nYears) {
                  for(j in 1:nSites) {
                    Y[i,j] ~ dnorm(X[i,j]*q,1/tauR); #obs eq for spawn index 
                    tl[i,j]<-Z[i,j]+log(Pc[i,j])+1
                    ctab[i,j] ~ dnorm(tl[i,j],1/.1)
                    #ctab[i,j] ~ dnorm(tl[i,j],1/psi) #obs equation for catch
                    }
                   }
                  }  
                 
                 ",file="normal_spatialRW.txt")

#OLD JUNK
#X[i,j] <-log(exp(Z[i,j])-ctab[i,j])     
#exp(Z[i,j]) <- exp(X[i,j])+ctab2[i-1,j]
#add just pdo and take away U 
#predX[i,j] <- X[i-1,j] + pdocoef*pdo[i];
##Y[i,j] ~ dnorm(X[i,j],tauR);

jags.data = list("diag"=diag(nSites),"Y"=Y, "nYears"=nYears,"nSites"=nSites,"distMat5"=distMat5,"pdo"=pdo3,"ctab"=ctab2_1) # named list

jags.params=c("X","theta","eta","sigma2","U","Umu","Usig","delta","Q","pdocoef","q","Pc","tauR") # parameters in the linear regression model

# jags.params=c("X","theta","eta","sigma2","U","Umu","Usig","delta","Q","pdocoef","q","Pc","psi","tauR") # parameters in the linear regression model
model.loc="normal_spatialRW.txt" # name of the txt file

#tried 35000, trying 350000
n.chains = 3
n.burnin=200000
n.thin=1000
n.iter=350000

#number of recorded mcmc
runL <- n.chains*(n.iter-n.burnin)/n.thin

Inits = NULL

#need to add the inits for the Pc and q params

for(i in 1:n.chains){
  Inits[[i]]    <- list(
    "Umu" = runif(1,1,2),
    "Usig" = runif(1,.05,1),
    "pdocoef" = runif(1,.05,1),
    "tau" =runif(1,0.05,1),
    "invEta" = runif(1,1,10),
    "logtheta" = runif(1,1,10),
    "delta" = matrix(runif(1,.05,1),nrow=nYears,ncol=nSites),
    "tauR" = runif(1,1,2),
    "Pc" = matrix(1e-05,nrow=nYears,ncol=nSites), #runif(1,.05,1) #reducing this and the variance on this psi
    #"psi" = runif(1,0,1.5),
    "q" = runif(1,0.01,0.999)
    
    ) 
}
    
    
#jags.model.rand.base.both = jags(jags.data, inits = Inits, parameters.to.save= jags.params, model.file=model.loc, 
#                                 n.chains = Nchain, n.burnin = Nburn, n.thin = 1, n.iter = Nburn+Niter, DIC = TRUE) 


model = jags(jags.data, inits=Inits,parameters.to.save=jags.params,
             model.file=model.loc, n.chains = n.chains, n.burnin=n.burnin, n.thin=n.thin, n.iter=n.iter, DIC=TRUE)

attach.jags(model)

save("model","X","theta","eta","sigma2","U","Umu","Usig","delta","Q","pdo","Pc","q","tauR",file="herring_jags_F.RData")

#save("model","X","theta","eta","sigma2","U","Umu","Usig","delta","Q","pdo","Pc","q","psi","tauR",file="herring_jags_F.RData")

#load("herring_jags_F.RData")
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


hist(model$BUGSoutput$mean$Pc)


#look at each of the outputs by each run 
names(model$BUGSoutput$sims.list)

#look at the performance of the different chains
matplot(model$BUGSoutput$sims.array[,,6])

#consider grep to look at matching
hist(model$BUGSoutput$sims.matrix[,16])
image(model$BUGSoutput$mean$Q)
image(model$BUGSoutput$mean$delta)



#dimmensions of the parameters
nSites
nYears
str(model$BUGSoutput$sims.list)
dim(model$BUGSoutput$sims.array)


#example
matplot(model$BUGSoutput$sims.array[,,"U[1]"])
matplot(model$BUGSoutput$sims.array[,,"Q[1,1]"])
model$BUGSoutput$sims.array[,,Q][,,]


########################################################################
############Chain Convergence and Posterior Distributions
########################################################################

setwd("~/Dropbox/Projects/In Progress/Pinniped_Herring_HG/Code/Figures/Herring")

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
############Theta - Slope of the distance decay
#####################

summary(myList[[1]][2112])


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
############Umu - Average growth of all populations (static through time)
#####################


model$BUGSoutput$sims.array[,,"Umu"]
edf1<-melt(model$BUGSoutput$sims.array[,,"Umu"])

names(edf1)<-c("num","chain","value")
edf1$chain<-factor(edf1$chain)

ggplot(edf1,aes(y=value,x=num,group=chain))+
  geom_line(aes(colour=chain))+
  theme_acs()

edf<-data.frame(Umu)
ggplot(edf,aes(x=Umu))+
  geom_bar()+
  theme_acs()+
  geom_vline(xintercept = 0)

ggsave("Umu.pdf")

#####################
############Usig
#####################

model$BUGSoutput$sims.array[,,"Usig"]
edf1<-melt(model$BUGSoutput$sims.array[,,"Usig"])

names(edf1)<-c("num","chain","value")
edf1$chain<-factor(edf1$chain)

ggplot(edf1,aes(y=value,x=num,group=chain))+
  geom_line(aes(colour=chain))+
  theme_acs()

edf<-data.frame(Usig)
ggplot(edf,aes(x=Usig))+
  geom_bar()+
  theme_acs()+
  geom_vline(xintercept = 0)

ggsave("Usig.pdf")



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
############eta -nugget 
#####################

model$BUGSoutput$sims.array[,,"eta"]
edf1<-melt(model$BUGSoutput$sims.array[,,"eta"])

names(edf1)<-c("num","chain","value")
edf1$chain<-factor(edf1$chain)

ggplot(edf1,aes(y=value,x=num,group=chain))+
  geom_line(aes(colour=chain))+
  theme_acs()

edf<-data.frame(eta)
ggplot(edf,aes(x=eta))+
  geom_bar()+
  theme_acs()+
  geom_vline(xintercept = 0)

ggsave("eta.pdf")


#####################
############U -estiamtes of population growth 
#####################
model$BUGSoutput$sims.array[,,"U[1]"]


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


#add in a barplot with 95%CI for each population

#####################
############X -estiamtes of states for each pouplation at each time step 
#####################
model$BUGSoutput$sims.array[,,"X[1,1]"]

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




#####################
############Delta -estiamtes of states for each population's change
#####################

#means
tempmat<-model$BUGSoutput$mean$delta
colnames(tempmat) <-c("site1","site2","site3","site5","site6","site7","site8","site9","site10","site11","site12","site13")
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

edf1<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="delta[1,1]"):which(colnames(myList[[1]])=="delta[64,12]")]])

names(edf1)<-c("num","chain","response","value")
edf1$chain<-factor(edf1$chain)
edf1$group<-factor(sort(rep(seq(1:nSites),runL)))

edf1$year<-sort(rep(seq(1:nYears),runL*nSites))

setwd("~/Dropbox/Projects/In Progress/Pinniped_Herring_HG/Code/Figures/Herring/Chains/Herring_delta")

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
dx<-melt(delta)
dx$chain<-chain
dx$num<-num

setwd("~/Dropbox/Projects/In Progress/Pinniped_Herring_HG/Code/Figures/Posteriors/Herring_delta")

for(i in 1:nSites){
  tmp<-subset(dx,Var2==i)
  ggplot(tmp,aes(x=value))+
    geom_bar()+
    facet_wrap(~Var3)+
    theme_acs()+
    geom_vline(xintercept = 0)
  ggsave(paste("time_",i,".pdf"))
  
}


#####################
############Q -estiamtes of states for each population's change
#####################
#means
tempmat<-model$BUGSoutput$mean$Q
cov2cor(tempmat)

colnames(tempmat) <-c("site1","site2","site3","site5","site6","site7","site8","site9","site10","site11","site12","site13")
temp2<-melt(tempmat)
colnames(temp2) <-c("time","site","Q")

#add site names from df2
ggplot(temp2,aes(x=time,y=site,fill=Q))+
  geom_tile()+
  theme_acs()

ggsave("Q.pdf")


setwd("~/Dropbox/Projects/In Progress/Pinniped_Herring_HG/Code/Figures/Herring/Posteriors/Herring_delta")
model$BUGSoutput$sims.array[,,"Q[1,1]"]

edf1<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="Q[1,1]"):which(colnames(myList[[1]])=="Q[12,12]")]])
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
colnames(tempmat) <-c("site1","site2","site3","site4","site4","site6","site7","site8","site9","site10","site11","site12","site13")
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

edf1<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="Pc[1,1]"):which(colnames(myList[[1]])=="Pc[64,12]")]])

names(edf1)<-c("num","chain","response","value")
edf1$chain<-factor(edf1$chain)
edf1$group<-factor(sort(rep(seq(1:12),runL)))

edf1$year<-sort(rep(seq(1:nYears),runL*nSites))

setwd("~/Dropbox/Projects/In Progress/Pinniped_Herring_HG/Code/Figures/Herring/Chains/Herring_delta")

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

setwd("~/Dropbox/Projects/In Progress/Pinniped_Herring_HG/Code/Figures/Posteriors/Herring_delta")

for(i in 1:nSites){
  tmp<-subset(px,Var2==i)
  ggplot(tmp,aes(x=value))+
    geom_bar()+
    facet_wrap(~Var3)+
    theme_acs()+
    geom_vline(xintercept = 0)
  ggsave(paste("time_",i,".pdf"))
  
}







########################################################################
########################################################################
########################################################################
####################Graveyard###########################################
########################################################################
########################################################################
########################################################################
########################################################################







########################################################################
############ Maps of SOK By Site
########################################################################
csok <- read.csv("herring_catch_local.csv")
yr_c<-unique(csok$Year)
csok$presabs <-ifelse(csok$SOK>0,1,0)
csok<-subset(csok,Section %in% c(1,2,3,5,6,11,12,21,22,23,24,25)) #remove sites that are offshore or don't have data for

#calculate sum of catch by year
sc<-melt(c(rowSums(tapply(csok$SOK,list(csok$Year,csok$Name),sum),,na.rm=T)))
sc<-data.frame("sum"=sc[,1],"year"=rownames(sc))
sc[,2]=as.numeric(as.character(sc[,2]))
c_sum<-sc


al1 = get_map(location = c(-135,51.5,-131,55), zoom = 7, maptype = 'terrain')
al1MAP = ggmap(al1)

for(i in 1:length(yr_c)){
  temp <- subset(c,Year==yr_c[i])
  temp2<- subset(temp,SOK>0)
  cm<-data.frame("Latitude"=colMeans(temp2[,c(13,14)])[1],"Longitude"=colMeans(temp2[,c(13,14)])[2]) #plot centroid
  
  ggtemp <-al1MAP+
    geom_point(data = temp, aes(x = Longitude, y = Latitude,size=SOK,fill=factor(presabs)),pch=21)+
    geom_point(data=cm,aes(x=Longitude,y=Latitude),colour="purple",pch=17,size=3)+
    geom_text(data = temp,aes(x = Longitude, y = Latitude,label=Name),vjust=.1,hjust=-.1,size=2)+
    scale_size_continuous(limits=c(0,850),range=c(4,10))+
    ggtitle(paste(yr_c[i],"_SOK"))+
    theme(legend.position="none")
  
  ggsum<-ggplot(c_sum,aes(x=year,y=sum))+
    geom_line()+
    ylab("sum of SOK harvest")+
    xlab("year")+
    theme_acs()+
    geom_vline(xintercept=yr_c[i],colour="red")
  
  
  jpeg(filename = paste(yr_c[i],"_SOK.png"),width = 800, height = 480,)
  multiplot(ggtemp,ggsum,cols=2)
  dev.off()
}
