setwd("~/Dropbox/Projects/In Progress/Pinniped_Herring_HG/Code/MARSS 1st Pass")

library(ggplot2)
library(MARSS)

x=read.csv("all_dat.csv")

###################################################
###Pinks and PDO 1950-2008
###################################################

####There are a number of possible models
#Start simple with herring and zooplankton with climate covariate
#herring - pinks 

########
### Pick Herring Data and Covariate(s)
########
hp = x[,c(1,5,60,19,54)]
hp = subset(hp,Year>1950)
hp = subset(hp,Year<2009)

her.dat = log(t(hp[,4:5]))

########
### Plot
########

matplot(hp[,1],log(hp[,c(4:5)]),
        ylab="log count",xlab="Year",type="l",
        lwd=3,bty="L",col="black")
legend("topright",c("Pink Salmon","HerringSpawnBiomass"), lty=c(1,2), bty="n")

########
### Z score herring and salmon data 
########
#if missing values are in the data, they should be NAs
z.her.dat=(her.dat-apply(her.dat,1,mean,na.rm=TRUE))/
  sqrt(apply(her.dat,1,var,na.rm=TRUE))


########
### fit.model 2, R and U set to "zero"
########

# her.model.2=list(Z="identity",
#                  B="unconstrained",
#                  Q="diagonal and unequal",
#                  R="zero",
#                  U="zero")
# 
# h.2=MARSS(z.her.dat, model=her.model.2)
# 
# ########
# ### Look at B matrix for Herring and Salmon
# ########
# 
# h.B=coef(h.2,type="matrix")$B
# rownames(h.B)=colnames(h.B)=rownames(her.dat)
# print(h.B, digits=2)


########
### pull out climate and even odd covariates
########

clim.dat=t(hp[,2:3])
#z.score.clim.dat=(clim.dat-apply(clim.dat,1,mean,na.rm=TRUE))/ #this may not be necessary given they're already scaled
  #sqrt(apply(clim.dat,1,var,na.rm=TRUE))

her.model.3=list(Z="identity",
                    B="unconstrained",
                    Q="diagonal and unequal",
                    R="diagonal and unequal", 
                    U="zero",
                    C="unconstrained",
                 #C=matrix(list("NPGO_Sal","NPGO","PDO_Sal","PDO"),2,2),
                    c=clim.dat)

#give these different names that refer

h.3=MARSS(z.her.dat, model=her.model.3)
MARSSparamCIs(h.3) 

 h.B=coef(h.3,type="matrix")$B
 rownames(h.B)=colnames(h.B)=rownames(her.dat)
 print(h.B, digits=2)


# cor.fun=function(x, y){text(0.5,0.5,format(cor(x,y),digits=2),cex=2)}
# pairs(t(z.score.clim.dat),lower.panel=cor.fun)


########
### Add observation ERROR
########

her.model.4=list(Z="identity",
                 B="unconstrained",
                 Q="diagonal and unequal",
                 R="diagonal and unequal",
                 U="zero",
                 C=matrix(list(0,"NPGO",
                               0,"PDO"),2,2),
                 c=z.score.clim.dat)

#R still going to 0 even with covariates
h.4=MARSS(z.royale.dat.2, model=her.model.4)

#Look at what happens if we artificially add noise
bad.data=z.royale.dat.2+matrix(rnorm(104,0,sqrt(.2)),2,52)
#Fish 507: Why did I have to z-score again?
z.bad.data=(bad.data-apply(bad.data,1,mean,na.rm=TRUE))/
  sqrt(apply(bad.data,1,var,na.rm=TRUE))
kem.bad=MARSS(bad.data, model=royale.model.4)




########
### Long Term Analysis: 1950ish to 2008, Fishing, PDO, Herring, Salmon, Mammals 
########

setwd("/Users/adrianstier/Dropbox/Projects/In Progress/NOAA Postdoc/JFS Projects/presentations/EcosysChar - OTP All Hands May/MARSS 1st Pass")
x=read.csv("all_dat.csv")

hlong = x[,c(1,5,19:28,64,65,68,69)]
hlong = subset(hlong,Year>1950)
hlong = subset(hlong,Year<2009)


her.dat = log(t(hlong[,c(3)]))

### Z score herring data 
#if missing values are in the data, they should be NAs
z.her.dat=(her.dat-apply(her.dat,1,mean,na.rm=TRUE))/
  sqrt(apply(her.dat,1,var,na.rm=TRUE))


cov.dat=t(hlong[,c(2,8,14,15)])

z.score.cov.dat=(cov.dat-apply(cov.dat,1,mean,na.rm=TRUE))/sqrt(apply(cov.dat,1,var,na.rm=TRUE))

her.model.4=list(Z="identity",
                 B="unconstrained",
                 Q="diagonal and unequal",
                 R="diagonal and unequal", 
                 U="zero",
                 C="unconstrained",
                 #C=matrix(list("NPGO_Sal","NPGO","PDO_Sal","PDO"),2,2),
                 c=cov.dat)

h.4=MARSS(z.her.dat, model=her.model.4)
MARSSparamCIs(h.4)




########
### Examing Autocorrelation among Herring Populations at Large Scale using Q Matrix
########
hlong = x[,c(1,5,19:28,64,65,68,69)]
hlong = subset(hlong,Year>1950)
hlong = subset(hlong,Year<2009)

her.dat = log(t(hlong[,c(3:7)]))

### Z score herring data 
#if missing values are in the data, they should be NAs
z.her.dat=(her.dat-apply(her.dat,1,mean,na.rm=TRUE))/
  sqrt(apply(her.dat,1,var,na.rm=TRUE))


#all populations same 
h.5=MARSS(her.dat, model=list(Z=factor(rep(1,5)),Q="unconstrained"))
h.5$AICc #554.0084

#all populations different 
h.6=MARSS(her.dat, model=list(Z=factor(1:5),Q="unconstrained"))
h.6$AICc #519.0532

h.6Q=coef(h.6,type="matrix")$Q
rownames(h.6Q)= colnames(h.6Q)=rownames(her.dat)
print(h.6Q, digits=2)

#h6bcAIC= MARSSaic(h.6,output = c("AICbp")) #Bootstrapped AIC

MARSSparamCIs(h.6) # confidence limits on parameter estimates


###Add PDO as a Covariate that operates on all populations 


cov.dat=t(hlong[,2])
z.score.cov.dat=(cov.dat-apply(cov.dat,1,mean,na.rm=TRUE))/sqrt(apply(cov.dat,1,var,na.rm=TRUE))


her.model.c=list(Z=factor(1:5),
                 B="unconstrained",
                 Q="unconstrained",
                 R="diagonal and unequal", 
                 U="zero",
                 C="unconstrained",
                 #C=matrix(list("NPGO_Sal","NPGO","PDO_Sal","PDO"),2,2),
                 c=cov.dat)

h.4c=MARSS(her.dat, model=her.model.c)



###################################################
###Zooplankton and Herring in HG
###################################################



########
### Pick Herring Data and Covariate(s)
########
zh = x[,c(1,11:19)]
zh = subset(zh,zoop_quality=="g")



borcop01 = (zh$BorealShelfCopepods - min(zh$BorealShelfCopepods,na.rm=TRUE))/(max(zh$BorealShelfCopepods,na.rm=TRUE)-min(zh$BorealShelfCopepods,na.rm=TRUE))
subarcop01 = (zh$SubarcticCopepods - min(zh$SubarcticCopepods,na.rm=TRUE))/(max(zh$SubarcticCopepods,na.rm=TRUE)-min(zh$SubarcticCopepods,na.rm=TRUE))
scop01 = (zh$SubarcticCopepods - min(zh$SubarcticCopepods,na.rm=TRUE))/(max(zh$SubarcticCopepods,na.rm=TRUE)-min(zh$SubarcticCopepods,na.rm=TRUE))
schaet01 = (zh$SouthernChaetognaths - min(zh$SouthernChaetognaths,na.rm=TRUE))/(max(zh$SouthernChaetognaths,na.rm=TRUE)-min(zh$SouthernChaetognaths,na.rm=TRUE))
nchaet01 = (zh$NorthernChaetognaths - min(zh$NorthernChaetognaths,na.rm=TRUE))/(max(zh$NorthernChaetognaths,na.rm=TRUE)-min(zh$NorthernChaetognaths,na.rm=TRUE))
thsp01 = (zh$THYspR - min(zh$THYspR,na.rm=TRUE))/(max(zh$THYspR,na.rm=TRUE)-min(zh$THYspR,na.rm=TRUE))
eupa01 = (zh$EUPpaR - min(zh$EUPpaR,na.rm=TRUE))/(max(zh$EUPpaR,na.rm=TRUE)-min(zh$EUPpaR,na.rm=TRUE))


#her.dat = t(data.frame(log(zh[,10]),borcop01,subarcop01,scop01,schaet01,nchaet01,thsp01,eupa01))
her.dat = t(data.frame(log(zh[,10]),thsp01))

z.her.dat=(her.dat-apply(her.dat,1,mean,na.rm=TRUE))/
  sqrt(apply(her.dat,1,var,na.rm=TRUE))


########
### Plot
########
zh = subset(zh,zoop_quality=="g")

matplot(zh[,1],zh[,c(7,10)],
        ylab="log count",xlab="Year",type="l",
        lwd=3,bty="L",col="black")
legend("topright",c("ThSp","HerringSpawnBiomass"), lty=c(1,2), bty="n")


her.model.z=list(Z="identity",
                 B="unconstrained",
                 Q="diagonal and unequal",
                 R="diagonal and unequal", 
                 U="zero",
                 C="zero"
                 #C=matrix(list("NPGO_Sal","NPGO","PDO_Sal","PDO"),2,2),
                 )

#give these different names that refer

h.z=MARSS(z.her.dat, model=her.model.z)
MARSSparamCIs(h.z) 

h.B=coef(h.z,type="matrix")$B
rownames(h.B)=colnames(h.B)=rownames(her.dat)
print(h.B, digits=2)


# cor.fun=function(x, y){text(0.5,0.5,format(cor(x,y),digits=2),cex=2)}
# pairs(t(z.score.clim.dat),lower.panel=cor.fun)





###################################################
###Herring 1990-2010
###################################################



########
### Pick Herring Data and Covariate(s)
########

h90 = x[,c(1,5,16,19,24,43,68)]
h90 = subset(h90,Year>1989)
h90 = subset(h90,Year<2006)

her.dat = t(data.frame(log(h90[,4]),h90$THYspR))

z.her.dat=(her.dat-apply(her.dat,1,mean,na.rm=TRUE))/
  sqrt(apply(her.dat,1,var,na.rm=TRUE))

z.her.dat=(z.her.dat-apply(z.her.dat,2,mean,na.rm=TRUE))/
  sqrt(apply(z.her.dat,2,var,na.rm=TRUE))



cov.dat=t(h90[,c(2,5:7)])

z.score.cov.dat=(cov.dat-apply(cov.dat,2,mean,na.rm=TRUE))/
  sqrt(apply(cov.dat,2,var,na.rm=TRUE))

her.model.90=list(Z="identity",
                 B="unconstrained",
                 Q="diagonal and unequal",
                 R="diagonal and unequal", 
                 U="zero",
                 #C="unconstrained",
                 C=matrix(list("PDO_Schweigert_Eulachon","HG_sumharvest",
                               "Eulachon_Skeena_scaled","HarbourSeal_relativeAbundanceEulachonSA"),4,2),
                 c=z.score.cov.dat)

h.90=MARSS(her.dat, model=her.model.90)
MARSSparamCIs(h.90) 

h.B=coef(h.90,type="matrix")$B
rownames(h.B)=colnames(h.B)=rownames(her.dat)
print(h.B, digits=2)













