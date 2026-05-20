library(ggplot2)
library(bbmle)
library(MARSS)

setwd("/Users/adrianstier/Dropbox/Projects/In Progress/NOAA Postdoc/JFS Projects/presentations/EcosysChar - OTP All Hands May/MARSS 1st Pass")
x=read.csv("all_dat.csv")

plot(x$Year,rowSums(x[,19:23]),type="l",xlab="Year",ylab="Estimated BC Biomass")

stocks<-x[,c(1,19:23)]
s2<-melt(stocks,id.vars="Year")

ggplot(s2,aes(x=Year,y=value))+
  geom_line(aes(colour=variable))+
  theme_acs()

######
#This code begins to explore the different herring populations at Large 5 stock scales
#Also explored are the local Haid Gwaii Stocks
#First plotting some time series, then exploring the importance of covariates
#Also included here are the 
#
#
######

###################################################################
###############################
# LARGE SCALE 5 MAJOR BC STOCKS
###############################
###################################################################


###Pull out and Scale the Data 0 to 1 for comparable plots

coast_spawn = x[,c(19:23)]

HG01sb = (coast_spawn$HG_spawn_biomass - min(coast_spawn$HG_spawn_biomass,na.rm=TRUE))/(max(coast_spawn$HG_spawn_biomass,na.rm=TRUE)-min(coast_spawn$HG_spawn_biomass,na.rm=TRUE))
PRD01sb = (coast_spawn$PRD_spawn_biomass - min(coast_spawn$PRD_spawn_biomass,na.rm=TRUE))/(max(coast_spawn$PRD_spawn_biomass,na.rm=TRUE)-min(coast_spawn$PRD_spawn_biomass,na.rm=TRUE))
CC01sb = (coast_spawn$CC_spawn_biomass - min(coast_spawn$CC_spawn_biomass,na.rm=TRUE))/(max(coast_spawn$CC_spawn_biomass,na.rm=TRUE)-min(coast_spawn$CC_spawn_biomass,na.rm=TRUE))
SOG01sb = (coast_spawn$SOG_spawn_biomass - min(coast_spawn$SOG_spawn_biomass,na.rm=TRUE))/(max(coast_spawn$SOG_spawn_biomass,na.rm=TRUE)-min(coast_spawn$SOG_spawn_biomass,na.rm=TRUE))
WCVI01sb = (coast_spawn$WCVI_spawn_biomass - min(coast_spawn$WCVI_spawn_biomass,na.rm=TRUE))/(max(coast_spawn$WCVI_spawn_biomass,na.rm=TRUE)-min(coast_spawn$WCVI_spawn_biomass,na.rm=TRUE))

hf_sb = data.frame(x$Year,HG01sb,PRD01sb,CC01sb,SOG01sb,WCVI01sb)
df_sb = melt(hf_sb,id.vars=c("x.Year"))
names(df_sb) = c("Year","Species","Scaled_Abundance")

ggplot()+
  geom_point(data = df_sb,aes(x=Year,y=Scaled_Abundance,group=Species,colour=Species),size=3)+
  #geom_smooth(data = df_sb,aes(x=Year,y=Scaled_Abundance,group=Species,colour=Species),se=FALSE)+
  geom_line(data = df_sb,aes(x=Year,y=Scaled_Abundance,group=Species,colour=Species))+
  #geom_smooth(data = df_sb,aes(x=Year,y=Scaled_Abundance),size=3,colour="black",se=FALSE)+
  theme(
    text = element_text(colour="black"),
    line = element_line(colour="black",size=1),
    axis.text = element_text(colour="black",size=14),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    panel.background = element_rect(fill = NA,colour = "black",size=2),
    axis.text.x=element_text(angle = 0),
    strip.background = element_rect(fill="black"),
    strip.text = element_text(colour="white",size=12)
  )+
  labs(x="Year",y="Scaled_Spawn_Biomass")



########
### Examing Autocorrelation among Herring Populations at Large Scale using Q Matrix
########

hlong = x[,c(1,5,19:28,64,65,68,69,85)]
hlong = subset(hlong,Year>1950)
hlong = subset(hlong,Year<2009)

#Pull out the 5 major stocks, log them and transpose
her.dat = log(t(hlong[,c(3:7)]))

### Z score herring data 
#if missing values are in the data, they should be NAs
z.her.dat=(her.dat-apply(her.dat,1,mean,na.rm=TRUE))/
  sqrt(apply(her.dat,1,var,na.rm=TRUE))


#all populations same 
# h.5=MARSS(her.dat, model=list(Z=factor(rep(1,5)),Q="unconstrained"))
# h.5$AICc #554.0084

#all populations different 
h.6=MARSS(her.dat,model=list(Z=factor(seq(1,5)),Q="unconstrained"))
h.6Q=coef(h.6,type="matrix")$Q
rownames(h.6Q)= colnames(h.6Q)=rownames(her.dat)
print(h.6Q, digits=2) #looking at the diagonal, it looks like there's more var in HG than other stocks


cov.dat=t(hlong[,17])
z.score.cov.dat=(cov.dat-apply(cov.dat,1,mean,na.rm=TRUE))/sqrt(apply(cov.dat,1,var,na.rm=TRUE))

her.model.c=list(Z=factor(rep(1,5)),
                 B="unconstrained",
                 Q="unconstrained",
                 R="diagonal and unequal", 
                 U="zero",
                 C="unconstrained",
                 #C=matrix(list("NPGO_Sal","NPGO","PDO_Sal","PDO"),2,2),
                 c=cov.dat)

#all populations different 
h.6=MARSS(her.dat, model=her.model.c)
h.6$AICc #519.0532


#h6bcAIC= MARSSaic(h.6,output = c("AICbp")) #Bootstrapped AIC
MARSSparamCIs(h.6) # confidence limits on parameter estimates


###Add PDO as a Covariate that operates on all populations, not doing z score 
cov.dat=t(hlong[,c(8,17)])
z.score.cov.dat=(cov.dat-apply(cov.dat,1,mean,na.rm=TRUE))/sqrt(apply(cov.dat,1,var,na.rm=TRUE))
z.score.cov.dat=(cov.dat-apply(cov.dat,2,mean,na.rm=TRUE))/sqrt(apply(cov.dat,2,var,na.rm=TRUE))


her.model.c=list(Z=factor(1:5),
                 B="identity",
                 Q="unconstrained",
                 R="diagonal and unequal", 
                 U="unequal",
                 #C="unconstrained",
                 #C=matrix(list("HG_sumharvest","PDO_ymean"),2,1)
                 c=cov.dat)

h.6Qc=MARSS(her.dat, model=her.model.c)
MARSSparamCIs(h.6Qc)

##Pull out and tabulate Q matrix
h.bigQ=coef(h.6Qc,type="matrix")$Q
rownames(h.bigQ)= rownames(her.dat)
colnames(h.bigQ)=rownames(her.dat)
print(h.bigQ, digits=2) 



####Plot out different PDO Month Data Suggests July/Aug are key - eyeball not quantitative
pdo01 = (x$PDO_Schweigert_Eulachon - min(x$PDO_Schweigert_Eulachon,na.rm=TRUE))/(max(x$PDO_Schweigert_Eulachon,na.rm=TRUE)-min(x$PDO_Schweigert_Eulachon,na.rm=TRUE))
pdo01b = (x$PDO_ymean - min(x$PDO_ymean,na.rm=TRUE))/(max(x$PDO_ymean,na.rm=TRUE)-min(x$PDO_ymean,na.rm=TRUE))
pdo01jan = (x$PDO_JAN - min(x$PDO_JAN,na.rm=TRUE))/(max(x$PDO_JAN,na.rm=TRUE)-min(x$PDO_JAN,na.rm=TRUE))
pdo01feb = (x$PDO_FEB - min(x$PDO_FEB,na.rm=TRUE))/(max(x$PDO_FEB,na.rm=TRUE)-min(x$PDO_FEB,na.rm=TRUE))
pdo01mar = (x$PDO_MAR - min(x$PDO_MAR,na.rm=TRUE))/(max(x$PDO_MAR,na.rm=TRUE)-min(x$PDO_MAR,na.rm=TRUE))
pdo01apr = (x$PDO_APR - min(x$PDO_APR,na.rm=TRUE))/(max(x$PDO_APR,na.rm=TRUE)-min(x$PDO_APR,na.rm=TRUE))
pdo01may = (x$PDO_MAY - min(x$PDO_MAY,na.rm=TRUE))/(max(x$PDO_MAY,na.rm=TRUE)-min(x$PDO_MAY,na.rm=TRUE))
pdo01jun = (x$PDO_JUN - min(x$PDO_JUN,na.rm=TRUE))/(max(x$PDO_JUN,na.rm=TRUE)-min(x$PDO_JUN,na.rm=TRUE))
pdo01jul = (x$PDO_JUL - min(x$PDO_JUL,na.rm=TRUE))/(max(x$PDO_JUL,na.rm=TRUE)-min(x$PDO_JUL,na.rm=TRUE))
pdo01aug = (x$PDO_AUG - min(x$PDO_AUG,na.rm=TRUE))/(max(x$PDO_AUG,na.rm=TRUE)-min(x$PDO_AUG,na.rm=TRUE))
pdo01sep = (x$PDO_SEP - min(x$PDO_SEP,na.rm=TRUE))/(max(x$PDO_SEP,na.rm=TRUE)-min(x$PDO_SEP,na.rm=TRUE))
pdo01oct = (x$PDO_OCT - min(x$PDO_OCT,na.rm=TRUE))/(max(x$PDO_OCT,na.rm=TRUE)-min(x$PDO_OCT,na.rm=TRUE))
pdo01nov = (x$PDO_NOV - min(x$PDO_NOV,na.rm=TRUE))/(max(x$PDO_NOV,na.rm=TRUE)-min(x$PDO_NOV,na.rm=TRUE))
pdo01dec = (x$PDO_DEC - min(x$PDO_DEC,na.rm=TRUE))/(max(x$PDO_DEC,na.rm=TRUE)-min(x$PDO_DEC,na.rm=TRUE))


df2 = data.frame(x$Year,HG01sb,pdo01b)
df2 = melt(df2,id.vars=c("x.Year"))
names(df2) = c("Year","Species","Scaled_Abundance")

ggplot()+
  geom_point(data = df2,aes(x=Year,y=Scaled_Abundance,group=Species,colour=Species,size=3))+
  geom_line(data=df2[!is.na(df2$Scaled_Abundance),],aes(x=Year,y=Scaled_Abundance,group=Species,colour=Species))+
  #geom_smooth(data=df2,aes(x=Year,y=Scaled_Abundance,group=Species))+
  theme(
    text = element_text(colour="black"),
    line = element_line(colour="black",size=1),
    axis.text = element_text(colour="black",size=14),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    panel.background = element_rect(fill = NA,colour = "black",size=2),
    axis.text.x=element_text(angle = 0),
    strip.background = element_rect(fill="black"),
    strip.text = element_text(colour="white",size=12)
  )+
  labs(x="Year",y="Scaled_Amount")






########
### How does the variance scale with the mean for the Large Scale Populations? 
########

#First Describe the mean variance averaging populations across years 

dfcs = data.frame(x$Year,x[,c(19:23)])
dfcs = subset(dfcs,CC_spawn_biomass!="NA")
dfcs = melt(dfcs,id.vars=c("x.Year"))
names(dfcs) = c("Year","Site","Biomass")

xb = tapply(dfcs$Biomass,list(dfcs$Year),mean)
std = tapply(dfcs$Biomass,list(dfcs$Year),sd)
sigma = tapply(dfcs$Biomass,list(dfcs$Year),var)
count = tapply(dfcs$Biomass,list(dfcs$Year),length)

#mean CV of inTERannual variation by  stock 
mean(tapply(dfcs$Biomass,list(dfcs$Site),mean)/tapply(dfcs$Biomass,list(dfcs$Site),sd))

#plot mean-var
df = data.frame(xb,sigma)
df$xb=as.numeric(df$xb)
df$sigma=as.numeric(df$sigma)
df$year = rownames(df)
df_2002 = subset(df,year<2003)

#fit with mle2 
m1a <- mle2(sigma~dnorm(mean = a*xb^b,sd = sd(df$sigma)),
            start = list(a=0.5346,b=2.0587),
            method = "L-BFGS-B",
            lower=c(a = 0, b = 0), 
            #upper=c(a = 0.25,b =4),
            data=df_2002
)

summary(m1a)
pp = profile(m1a)
confint(pp)

#fit with nls
m1b <- nls(sigma~a*xb^b,start=list(a=0.53463,b=2.05875),data=df_2002)
summary(m1b)

scale_func <- function(x) {a*x^b}
a=0.5346
b=2.0587

#r2 
1-(deviance(m1b)/sum((df$sigma-mean(df$sigma))^2))


ggplot(df_2002,aes(x=xb,y=sigma))+
  geom_point(size=3)+
  stat_function(fun = scale_func)+
  scale_x_continuous("Mean Abundance Across 5 Stocks")+
  scale_y_continuous("Variance Abundance Across 5 Stocks")+
  geom_text(data = NULL, x = 10, y = 2500, label = "a= 0.07+/- 0.09341, b= 2.65 +/- 0.35563,r2 = .62")+
  theme(
    text = element_text(colour="black",size=12),
    line = element_line(colour="black",size=1),
    axis.ticks = element_line(colour="black"),
    axis.text = element_text(colour="black"),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    panel.background = element_rect(fill = NA,colour = "black",size=1),
    axis.text.x=element_text(angle = 0),
    strip.background = element_rect(fill="black"),
    strip.text.y = element_text(colour="white")
  )




###################################################################
###############################
# LOCAL HG STOCKS
###############################
###################################################################



####################
#HG Stocks Local 
####################

df2 = data.frame(
  x$Year,
  s101 = (x[,29] - min(x[,29],na.rm=TRUE))/(max( x[,29],na.rm=TRUE)-min( x[,29],na.rm=TRUE)),
  s201 = (x[,30] - min(x[,30],na.rm=TRUE))/(max( x[,30],na.rm=TRUE)-min( x[,30],na.rm=TRUE)),
  s301 = (x[,31] - min(x[,31],na.rm=TRUE))/(max( x[,31],na.rm=TRUE)-min( x[,31],na.rm=TRUE)),
  s401 = (x[,32] - min(x[,32],na.rm=TRUE))/(max( x[,32],na.rm=TRUE)-min( x[,32],na.rm=TRUE)),
  s501 = (x[,33] - min(x[,33],na.rm=TRUE))/(max( x[,33],na.rm=TRUE)-min( x[,33],na.rm=TRUE)),
  s601 = (x[,34] - min(x[,34],na.rm=TRUE))/(max( x[,34],na.rm=TRUE)-min( x[,34],na.rm=TRUE)),
  s1101 = (x[,35] - min(x[,35],na.rm=TRUE))/(max( x[,35],na.rm=TRUE)-min( x[,35],na.rm=TRUE)),
  s1201 = (x[,36] - min(x[,36],na.rm=TRUE))/(max( x[,36],na.rm=TRUE)-min( x[,36],na.rm=TRUE)),
  s1301 = (x[,37] - min(x[,37],na.rm=TRUE))/(max( x[,37],na.rm=TRUE)-min( x[,37],na.rm=TRUE)),
  s2201 = (x[,38] - min(x[,38],na.rm=TRUE))/(max( x[,38],na.rm=TRUE)-min( x[,38],na.rm=TRUE)),
  s2301 = (x[,39] - min(x[,39],na.rm=TRUE))/(max( x[,39],na.rm=TRUE)-min( x[,39],na.rm=TRUE)),
  s2401 = (x[,40] - min(x[,40],na.rm=TRUE))/(max( x[,40],na.rm=TRUE)-min( x[,40],na.rm=TRUE)),
  s2501 = (x[,41] - min(x[,41],na.rm=TRUE))/(max( x[,41],na.rm=TRUE)-min( x[,41],na.rm=TRUE)) )



df2 = melt(df2,id.vars=c("x.Year"))
names(df2) = c("Year","Species","Scaled_Abundance")

ggplot()+
  geom_point(data = df2,aes(x=Year,y=Scaled_Abundance,group=Species,colour=Species,size=3))+
  geom_line(data=df2[!is.na(df2$Scaled_Abundance),],aes(x=Year,y=Scaled_Abundance,group=Species,colour=Species))+
  theme(
    text = element_text(colour="black"),
    line = element_line(colour="black",size=1),
    axis.text = element_text(colour="black",size=14),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    panel.background = element_rect(fill = NA,colour = "black",size=2),
    axis.text.x=element_text(angle = 0),
    strip.background = element_rect(fill="black"),
    strip.text = element_text(colour="white",size=12)
  )+
  labs(x="Year",y="Scaled Herring Spawn Ares")



#First Pass at MARSS Analysis 1950-2002 lots of zeros, adding a small number for the log transformation 

hlocal = data.frame(x$Year,x[,c(29:41,85)])
hlocal = subset(hlocal,x.Year>1950)
hlocal = subset(hlocal,x.Year<2003)

#Pull out the 5 major stocks, log them and transpose
her.dat = log(t(hlocal[,c(2:14)]+1))

### Z score herring data 
#if missing values are in the data, they should be NAs
z.her.dat=(her.dat-apply(her.dat,1,mean,na.rm=TRUE))/
  sqrt(apply(her.dat,1,var,na.rm=TRUE))


#all populations same 
h.loc1=MARSS(her.dat, model=list(Z=factor(rep(1,13)),Q="unconstrained"))
h.loc1$AICc #3877.411

#all populations different fits better with lower AICc 
h.loc2=MARSS(z.her.dat, model=list(Z=factor(1:13),Q="unconstrained"))
h.loc2$AICc #3802.464

h.loc2Q=coef(h.loc2,type="matrix")$Q
rownames(h.loc2Q)= colnames(h.loc2Q)=rownames(her.dat)
print(h.loc2Q, digits=2) 

#h6bcAIC= MARSSaic(h.6,output = c("AICbp")) #Bootstrapped AIC
MARSSparamCIs(h.loc2) # confidence limits on parameter estimates


###Add Fishing as a Covariate that operates on all populations 
cov.dat=t(hlocal[,15])
z.score.cov.dat=(cov.dat-apply(cov.dat,1,mean,na.rm=TRUE))/sqrt(apply(cov.dat,1,var,na.rm=TRUE))

her.model.c=list(Z=factor(1:13),
                 B="identity",
                 Q="diagonal and equal",
                 R="diagonal and equal", 
                 U="equal", #not zero unless population is stable 
                 C="unconstrained",
                 #C=matrix(list("NPGO_Sal","NPGO","PDO_Sal","PDO"),2,2),
                 c=z.score.cov.dat)

h.loc3=MARSS(her.dat, model=her.model.c)
MARSSparamCIs(h.loc3)

#estimate B matrix by tuning down the Q and U matrices 


########
### How does the variance scale with the mean for the LOCAL  Populations? 
########


dfcs_hg = data.frame(x$Year,x[,c(29:41)])
dfcs_hg = subset(dfcs_hg,dfcs_hg[,2]!="NA")
dfcs_hg = melt(dfcs_hg,id.vars=c("x.Year"))
names(dfcs_hg) = c("Year","Site","Biomass")
dfcs_hg = subset(dfcs_hg,Year>1950)

#CV of interannual variation by sub stock 
mean(tapply(dfcs_hg$Biomass,list(dfcs_hg$Site),mean)/tapply(dfcs_hg$Biomass,list(dfcs_hg$Site),sd))


xb = tapply(dfcs_hg$Biomass,list(dfcs_hg$Year),mean)
std = tapply(dfcs_hg$Biomass,list(dfcs_hg$Year),sd)
sigma = tapply(dfcs_hg$Biomass,list(dfcs_hg$Year),var)
count = tapply(dfcs_hg$Biomass,list(dfcs_hg$Year),length)

#plot mean-var
df_hg = data.frame(xb,sigma)
#df_hg$xb=as.numeric(df_hg$xb)
#df$sigma=as.numeric(df$sigma)


#fit with mle2 
m1a <- mle2(sigma~dnorm(mean = a*xb^b,sd = sd(df_hg$sigma)),
            start = list(a=3.4214e+01,b=1.7859),
            #method = "L-BFGS-B",
            #lower=c(a = 0, b = 0), 
            #upper=c(a = 5,b =4),
            data=df_hg
)

summary(m1a)
pp = profile(m1a)
plot(pp)
confint(pp)


#fit with nls
m1b <- nls(sigma~a*xb^b,start=list(a=2.2303e+02,b=1.6346e+00),data=df_hg)
summary(m1b)

scale_func <- function(x) {a*x^b}
a=34.2138
b=1.7859
  
#r2 
1-(deviance(m1b)/sum((df$sigma-mean(df$sigma))^2))

ggplot(df_hg,aes(x=xb,y=sigma))+
  geom_point(size=3)+
  stat_function(fun = scale_func)+
  scale_x_continuous("Mean Abundance Across HG Stocks")+
  scale_y_continuous("Variance Abundance Across HG Stocks")+
  #geom_text(data = NULL, x = 10, y = 2500, label = "a= 0.07+/- 0.09341, b= 2.65 +/- 0.35563,r2 = .62")+
  theme(
    text = element_text(colour="black",size=12),
    line = element_line(colour="black",size=1),
    axis.ticks = element_line(colour="black"),
    axis.text = element_text(colour="black"),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    panel.background = element_rect(fill = NA,colour = "black",size=1),
    axis.text.x=element_text(angle = 0),
    strip.background = element_rect(fill="black"),
    strip.text.y = element_text(colour="white")
  )




