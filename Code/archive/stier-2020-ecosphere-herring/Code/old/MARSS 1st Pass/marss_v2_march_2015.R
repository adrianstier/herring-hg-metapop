########################################################################
############ Load Packages
########################################################################

library(MARSS)
library(ggplot2)
library(pracma)

########################################################################
############ Load Data
########################################################################
setwd("~/Dropbox/Projects/In Progress/Pinniped_Herring_HG/Code/MARSS 1st Pass")

#pdo
pdo<-read.csv("pdo.csv")
pdotab<-subset(pdo,month %in% c(3,4,5,6)) #average april<-june

#seals
ssl<-read.csv("stellers_dec15_2014.csv")
ssl<-subset(ssl,Region_small=="HaidaGwaii")
rowSums(ssl[,c(7:19)],na.rm=T)
c(1971,1973,1977,1982,1987,1992,1994,1998,2002,2006,2008,2010,2013)
write.csv(colSums(ssl[,c(7:19),],na.rm=T),"sealsums.csv")

#herring
herring<-read.csv("HG_Spawn_Survey_1940_2013b.csv")[c(1,3,13,14,15,16)]
htab<-tapply(herring$SHI,list(herring$year),sum)
htab2<-tapply(herring$SHI,list(herring$year,herring$section),sum)

#fishing
fishing<-read.csv("fishing.csv")
names(fishing)<-c("year","catch","stock")
tapply(fishing$catch,list(fishing$year),sum)

ggplot(fishing,(aes(x=year,y=catch,group=stock)))+
  geom_point(aes(colour=stock))+
  geom_line(aes(colour=stock))+
  facet_grid(stock~.,scales="free")+
  theme_acs()+
  theme(legend.position="none")


x<-read.csv("all.csv")

#z.score spawn data
dat = t(x[,18])
the.mean = apply(dat,1,mean,na.rm=TRUE)
the.sigma = sqrt(apply(dat,1,var,na.rm=TRUE))
dat = (dat-the.mean)*(1/the.sigma)

covariates<-t(x[,c(2,3,4)])
  
# z.score the covariates
the.mean = apply(covariates,1,mean,na.rm=TRUE)
the.sigma = sqrt(apply(covariates,1,var,na.rm=TRUE))
covariates = (covariates-the.mean)*(1/the.sigma)

nmat <- cbind("year"=x$year,"herring"=t(dat),t(covariates))
colnames(nmat)<-c("year","shi","SSL","pdo","catch")
tsdf<-ts(nmat)
plot.ts(nmat[,c("shi","SSL","pdo","catch")])

dfnmat<-data.frame(nmat)
dfnmat$SSL2 <- with(dfnmat, interp1(year, SSL, year, "linear"))
dfmat<-melt(dfnmat,id.vars=c("year"))

ggplot(dfmat,aes(x=year,y=value,group=variable))+
  geom_line(aes(colour=variable))+
  theme_acs()

dfmat2<-subset(dfmat,variable!="SSL")

ggplot(dfmat2,aes(x=year,y=value,group=variable))+
  geom_line(aes(colour=variable))+
  #geom_smooth(aes(colour=variable))+
  geom_point(aes(colour=variable))+
  facet_grid(variable~.)+
  theme_acs()+
  theme(legend.position="none")+
  ylab("z-score amount")

###################################################
###################################################
###################################################
###First with the whole time series climate and pdo  
###################################################
###################################################
###################################################


###################################################
### Observation Model only, basically multiple regression 
###################################################
Q = U = x0 = "zero"; B = Z = "identity"
d = covariates[2:3,]
A = "zero"
D = "unconstrained"
y = dat # to show relationship between dat & the equation
model.list = list(B=B,U=U,Q=Q,Z=Z,A=A,D=D,d=d,x0=x0)
kem = MARSS(y, model=model.list)
MARSSparamCIs(kem)



###################################################
### just a process model with AR 
###################################################
R = A = U = "zero"; B = Z = "identity"
Q = "equalvarcov"
C = "unconstrained"
model.list = list(B=B,U=U,Q=Q,Z=Z,A=A,R=R,C=C,c=covariates[2:3,])
kem = MARSS(dat, model=model.list)
MARSSparamCIs(kem)


###################################################
### process and obsevation model -lowest AIC 
###################################################

C = c = A = U = "zero"; Z = "identity"
B = "diagonal and unequal"
Q = "equalvarcov"
D = "unconstrained"
d=covariates[2:3,]
R = matrix(0.01)
x0 = "unequal"
tinitx=1
model.list = list(B=B,U=U,Q=Q,Z=Z,A=A,R=R,D=D,d=d,C=C,c=c,x0=x0,tinitx=tinitx)
kem = MARSS(dat, model=model.list)

MARSSparamCIs(kem)
mci<-MARSSparamCIs(kem)

df<-data.frame(rbind(
pdo<-c(-0.0262, -0.185421, 0.133),
catch<-c( 0.0683, -0.067567, 0.204)
))
names(df)<-c("mean","uci","lci")
df$covariate<-c("pdo","commercial harvest")

ggplot(df,aes(x=covariate,y=mean,ymin=lci,ymax=uci,colour=covariate))+
  geom_linerange()+
  geom_point(size=4)+
  geom_hline(yintercept=0,lty=2)+
  theme_acs()+
  theme(legend.position="none")+
  ylab("MARSS Coefficient Estiamte")+
  xlab("Coeffient")
  

###################################################
###################################################
###################################################
###time series 1978-present climate,pdo, seals (linear interp)
###################################################
###################################################
###################################################

#look at just 1978 onward with a linear interpolation for seals 
dat78<-dat[39:74]
covariates78<-covariates[,39:74]
covariates78[1,]<-with(dfnmat, interp1(year, SSL, year, "linear"))[39:74]

###################################################
### process and obsevation model
###################################################

C = c = A = U = "zero"; Z = "identity"
B = "diagonal and unequal"
Q = "equalvarcov"
D = "unconstrained"
d=covariates78
R = matrix(0.01)
x0 = "unequal"
tinitx=1
model.list = list(B=B,U=U,Q=Q,Z=Z,A=A,R=R,D=D,d=d,C=C,c=c,x0=x0,tinitx=tinitx)
kem = MARSS(dat78, model=model.list)

MARSSparamCIs(kem)
mci<-MARSSparamCIs(kem)

df2<-data.frame(rbind(
  pdo<-c(-0.1094, -0.345, 0.126),
  catch<-c( 0.0021, NA, NA),
  SSL<-c(0.0674,-0.512,0.646)
))
names(df2)<-c("mean","uci","lci")
df2$covariate<-c("pdo","commercial harvest","SSL")

ggplot(df2,aes(x=covariate,y=mean,ymin=lci,ymax=uci,colour=covariate))+
  geom_linerange()+
  geom_point(size=4)+
  geom_hline(yintercept=0,lty=2)+
  theme_acs()+
  theme(legend.position="none")+
  ylab("MARSS Coefficient Estiamte")+
  xlab("Coeffient")



###################################################
###################################################
###################################################
###consider all populaitions for both time chunks need to look into this more
###################################################
###################################################
###################################################

#z.score spawn data
dat_ss = t(x[,5:17])
the.mean = apply(dat_ss,1,mean,na.rm=TRUE)
the.sigma = sqrt(apply(dat_ss,1,var,na.rm=TRUE))
dat = (dat_ss-the.mean)*(1/the.sigma)


C = c = A = U = "zero"; Z = "identity"
B = "identity"
Q = "diagonal and unequal"
D = "unequal"
d=covariates[2:3,]
R = "identity"
x0 = "unequal"
tinitx=1
model.list = list(B=B,U=U,Q=Q,Z=Z,A=A,R=R,D=D,d=d,C=C,c=c,x0=x0,tinitx=tinitx)
kem = MARSS(dat_ss, model=model.list)

MARSSparamCIs(kem)
mci<-MARSSparamCIs(kem)

###################################################
###################################################
###################################################
###DFA quickly
###################################################
###################################################
###################################################

Z.vals = list(
  "z11",  0  ,  0  ,
  "z21","z22",  0  ,
  "z31","z32","z33",
  "z41","z42","z43",
  "z51","z52","z53",
  "z61","z62","z62",
  "z71","z72","z73",
  "z81","z82","z83",
  "z91","z92","z93",
  "z10","z102","z103",
  "z11","z112","z113",
  "z121","z122","z123",
  "z131","z132","z133")

N.ts = dim(dat)[1]
Z = matrix(Z.vals, nrow=N.ts, ncol=3, byrow=TRUE)
Q = B = diag(1,3)
R= "diagonal and unequal"
x0 = U = matrix(0, nrow=3, ncol=1)
A = matrix(0, nrow=6, ncol=1)
x0 = U = A = "zero"
V0 = diag(5,3)

dfa.model = list(Z=Z, A="zero", R=R, B=B, U=U, Q=Q, x0=x0, V0=V0)
cntl.list = list(maxit=50)
kemz.3 = MARSS(dat, model=dfa.model, control=cntl.list)
H.inv = varimax(coef(kemz.3, type="matrix")$Z)$rotmat
Z.rot = coef(kemz.3, type="matrix")$Z %*% H.inv
trends.rot = solve(H.inv) %*% kemz.3$states
plot(trends.rot)
