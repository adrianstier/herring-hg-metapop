library(reshape2)
library(ggplot2)
library(bbmle)

setwd("~/Dropbox/Projects/In Progress/Pinniped_Herring_HG/Code/MARSS 1st Pass")

source('theme_acs.R')
source('multiplot.R')

##These are Preliminary Plots of the Data We have before May 2014 OTP All hands

x=read.csv("all_dat.csv")


######
#Herring Spawn Biomass
######

h_spawn = x[,c(1,19)]
mean(h_spawn$HG_sumharvest,na.rm=T)

ggplot()+
  geom_hline(aes(yintercept=5.866869),colour="grey",size=2)+
  geom_point(data = h_spawn,aes(x=Year,y=HG_spawn_biomass,size=3))+
  geom_line(data = h_spawn,aes(x=Year,y=HG_spawn_biomass))+
  #geom_smooth(data = h_spawn,aes(x=Year,y=HG_spawn_biomass),size=2,colour="black",se=FALSE)+
   theme_acs()+
  labs(x="Year",y="Scaled_Spawn_Biomass")


######
#Herring Catch Biomass
######

h_spawn = x[,c(1,24)]

ggplot()+
  geom_point(data = h_spawn,aes(x=Year,y=HG_sumharvest,size=3))+
  geom_line(data = h_spawn,aes(x=Year,y=HG_sumharvest))+
  #geom_smooth(data = h_spawn,aes(x=Year,y=HG_sumharvest),size=2,colour="black",se=FALSE)+
  theme_acs()+
  labs(x="Year",y="Pooled Catch")





######
#Herring Spawn Biomass Scaled 0 to 1
######

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
  theme_acs()+
  labs(x="Year",y="Scaled_Spawn_Biomass")


#First Describe the mean variance averaging populations across years 

dfcs = data.frame(x$Year,x[,c(19:23)])
dfcs = subset(dfcs,CC_spawn_biomass!="NA")
dfcs = melt(dfcs,id.vars=c("x.Year"))
names(dfcs) = c("Year","Site","Biomass")

xb = tapply(dfcs$Biomass,list(dfcs$Year),mean)
std = tapply(dfcs$Biomass,list(dfcs$Year),sd)
sigma = tapply(dfcs$Biomass,list(dfcs$Year),var)
count = tapply(dfcs$Biomass,list(dfcs$Year),length)

#CV of interannual variation by  stock 
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
  theme_acs()



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
  theme_acs()+
  labs(x="Year",y="Scaled Herring Spawn Ares")


#First Describe the mean variance averaging populations across years 

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
  theme_acs()


hb<-read.csv("humpback.csv")

ggplot(hb,aes(x=Year,y=Amount,ymin=lowerci,ymax=upperci))+
  geom_line(aes(lty=dummy))+
  geom_pointrange(aes(pch=dummy))+
  theme_acs()




######
#Marine Mammal Biomass Scaled 0 to 1
######

##Scale Mammals
humpback01 = (x$Humpbacks - min(x$Humpbacks,na.rm=TRUE))/(max(x$Humpbacks,na.rm=TRUE)-min(x$Humpbacks,na.rm=TRUE))
killerwhale01 = (x$NR_KillerWhale - min(x$NR_KillerWhale,na.rm=TRUE))/(max(x$NR_KillerWhale,na.rm=TRUE)-min(x$NR_KillerWhale,na.rm=TRUE))
furseal01 = (x$fur_seals_all - min(x$fur_seals_all,na.rm=TRUE))/(max(x$fur_seals_all,na.rm=TRUE)-min(x$fur_seals_all,na.rm=TRUE))
harbourseal01 = x$HarbourSeal_relativeAbundanceEulachonSA
stellersealion01 = x$Steller_Eulachon_Reconstructed

df1 = data.frame(x$Year,humpback01,killerwhale01,furseal01,harbourseal01,stellersealion01)
df1 = melt(df1,id.vars=c("x.Year"))
names(df1) = c("Year","Species","Scaled_Abundance")


ggplot()+
  geom_point(data = df1,aes(x=Year,y=Scaled_Abundance,group=Species,colour=Species,size=3))+
  #geom_line(data=df1[!is.na(df1$Scaled_Abundance),],aes(x=Year,y=Scaled_Abundance,group=Species,colour=Species))+
  geom_smooth(data=df1[!is.na(df1$Scaled_Abundance),],aes(x=Year,y=Scaled_Abundance,group=Species,colour=Species),se=F,size=2)+
  #geom_smooth(data = df1,aes(x=Year,y=Scaled_Abundance),size=3,colour="black",se=FALSE)+
  theme_acs()+
    labs(x="Year",y="Scaled_Mammal_Abundance")+
    scale_colour_brewer(palette="Set1")
    
df1b<-subset(df1,Year>1960 & Species!="furseal01")
plmamplot<-ggplot()+
  geom_point(data = df1b,aes(x=Year,y=Scaled_Abundance,group=Species,colour=Species,size=2))+
  #geom_line(data=df1b[!is.na(df1b$Scaled_Abundance),],aes(x=Year,y=Scaled_Abundance,group=Species,colour=Species))+
  geom_smooth(data=df1b[!is.na(df1b$Scaled_Abundance),],aes(x=Year,y=Scaled_Abundance,group=Species,colour=Species),se=F,size=1)+
  #geom_smooth(data = df1,aes(x=Year,y=Scaled_Abundance),size=3,colour="black",se=FALSE)+
  theme_acs()+
    labs(x="Year",y="Scaled Mammal Abundance")+
    scale_colour_brewer(palette="Set1")

ggsave("mamplot.pdf")    
######
#Harbour Seal and herring
######

##Scale Mammals
harbourseal01 = x$HarbourSeal_relativeAbundanceEulachonSA


df2 = data.frame(x$Year,HG01sb,harbourseal01)
df2 = melt(df2,id.vars=c("x.Year"))
names(df2) = c("Year","Species","Scaled_Abundance")


ggplot()+
  geom_point(data = df2,aes(x=Year,y=Scaled_Abundance,group=Species,colour=Species,size=3))+
  geom_line(data=df2[!is.na(df2$Scaled_Abundance),],aes(x=Year,y=Scaled_Abundance,group=Species,colour=Species))+
  theme_acs()+
  labs(x="Year",y="Scaled_Mammal_Abundance")




######
#Eulachon Skeena
######


df2 = data.frame(x$Year,HG01sb,x$Eulachon_Skeena_scaled)
df2 = melt(df2,id.vars=c("x.Year"))
names(df2) = c("Year","Species","Scaled_Abundance")


ggplot()+
  geom_point(data = df2,aes(x=Year,y=Scaled_Abundance,group=Species,colour=Species,size=3))+
  geom_line(data=df2[!is.na(df2$Scaled_Abundance),],aes(x=Year,y=Scaled_Abundance,group=Species,colour=Species))+
  theme_acs()+
  labs(x="Year",y="Scaled_Abundance")





######
#Pinks HG
######

pinksum = x$PINK_Escapement_E + x$PINK_Escapement_W 
pink01 = (pinksum - min(pinksum,na.rm=TRUE))/(max(pinksum,na.rm=TRUE)-min(pinksum,na.rm=TRUE))
pink01E = (x$PINK_Escapement_E - min(x$PINK_Escapement_E,na.rm=TRUE))/(max(x$PINK_Escapement_E,na.rm=TRUE)-min(x$PINK_Escapement_E,na.rm=TRUE))
pink01W = (x$PINK_Escapement_W - min(x$PINK_Escapement_W,na.rm=TRUE))/(max(x$PINK_Escapement_W,na.rm=TRUE)-min(x$PINK_Escapement_W,na.rm=TRUE))


df2 = data.frame(x$Year,HG01sb,pink01)
df2 = melt(df2,id.vars=c("x.Year"))
names(df2) = c("Year","Species","Scaled_Abundance")


df2 = data.frame(x$Year,HG01sb,pink01E)
df2 = melt(df2,id.vars=c("x.Year"))
names(df2) = c("Year","Species","Scaled_Abundance")


df2 = data.frame(x$Year,HG01sb,pink01W)
df2 = melt(df2,id.vars=c("x.Year"))
names(df2) = c("Year","Species","Scaled_Abundance")


ggplot()+
  geom_point(data = df2,aes(x=Year,y=Scaled_Abundance,group=Species,colour=Species,size=3))+
  geom_line(data=df2[!is.na(df2$Scaled_Abundance),],aes(x=Year,y=Scaled_Abundance,group=Species,colour=Species))+
  theme_acs()+
  labs(x="Year",y="Scaled_Salmon_Abundance")


be = data.frame(x$Year,HG01sb,pink01W,x$Even_Odd_Dummy)
subset(be,na.rm=T)
tapply(be$HG01sb,list(be$x.Even_Odd_Dummy),mean,na.rm=TRUE)


######
#Zooplankton
######
df2 = data.frame(x$Year,HG01sb,x[,c(11:15,18)])
df2 = subset(df2,zoop_quality=="g")
df2 = melt(df2,id.vars=c("x.Year","zoop_quality"))
names(df2) = c("Year","zoop_quality","Species","Scaled_Abundance")
df2$hz = c(rep("herring",12),rep("Zooplankton",60))

ggplot()+
  geom_point(data = df2,aes(x=Year,y=Scaled_Abundance,group=Species,colour=hz,size=3,pch=Species))+
  geom_line(data=df2[!is.na(df2$Scaled_Abundance),],aes(x=Year,y=Scaled_Abundance,group=Species,colour=hz))+
  theme_acs()+
  labs(x="Year",y="Scaled_Salmon_Abundance")


######
#PDO
######

pdo01 = (x$PDO_Schweigert_Eulachon - min(x$PDO_Schweigert_Eulachon,na.rm=TRUE))/(max(x$PDO_Schweigert_Eulachon,na.rm=TRUE)-min(x$PDO_Schweigert_Eulachon,na.rm=TRUE))


s1<-ccf(HG01sb,pdo01,10,na.action=na.pass)
s1$acf[,,1]


df2 = data.frame(x$Year,HG01sb,pdo01)
df2 = melt(df2,id.vars=c("x.Year"))
names(df2) = c("Year","Species","Scaled_Abundance")

ggplot()+
  geom_point(data = df2,aes(x=Year,y=Scaled_Abundance,group=Species,colour=Species,size=3))+
  geom_line(data=df2[!is.na(df2$Scaled_Abundance),],aes(x=Year,y=Scaled_Abundance,group=Species,colour=Species,lty=Species))+
  #geom_smooth(data=df2,aes(x=Year,y=Scaled_Abundance,group=Species))+
  theme_acs()+
  labs(x="Year",y="Scaled_Amount")



####"Raw" Values of PDO and Herring

ddr = melt(data.frame(x$Year,x$PDO_Schweigert_Eulachon,x$HG_spawn_biomass),id.vars=c("x.Year"))
names(ddr)=c("Year","Group","Number")

ggplot(data=ddr,aes(x=Year,y=Number))+
  geom_point(aes(colour=Group))+
  geom_line(aes(colour=Group))+
  #geom_point(data = df2,aes(x=Year,y=Scaled_Abundance,group=Species,colour=Species,size=3))+
  #geom_line(data=df2[!is.na(df2$Scaled_Abundance),],aes(x=Year,y=Scaled_Abundance,group=Species,colour=Species))+
  #geom_smooth(data=df2,aes(x=Year,y=Scaled_Abundance,group=Species))+
  theme_acs()+
  labs(x="Year",y="Scaled_Amount")


######
#Fishing
######

hg_harv01 = (x$HG_sumharvest - min(x$HG_sumharvest,na.rm=TRUE))/(max(x$HG_sumharvest,na.rm=TRUE)-min(x$HG_sumharvest,na.rm=TRUE))


df2 = data.frame(x$Year,HG01sb,hg_harv01)
df2 = melt(df2,id.vars=c("x.Year"))
names(df2) = c("Year","Species","Scaled_Abundance")

ggplot()+
  geom_point(data = df2,aes(x=Year,y=Scaled_Abundance,group=Species,colour=Species,size=3))+
  geom_line(data=df2[!is.na(df2$Scaled_Abundance),],aes(x=Year,y=Scaled_Abundance,group=Species,colour=Species))+
  theme_acs()+
  labs(x="Year",y="Scaled Herring Biomass")





######
#Groundfish
######

names(x[,45:49])

##Scale and plot Grondfish

#cod01 = (x$PacificCod - min(x$PacificCod,na.rm=TRUE))/(max(x$PacificCod,na.rm=TRUE)-min(x$PacificCod,na.rm=TRUE))
sablefish01 = (x$sablefish_cpue_table_b8_SA_2011 - min(x$sablefish_cpue_table_b8_SA_2011,na.rm=TRUE))/(max(x$sablefish_cpue_table_b8_SA_2011,na.rm=TRUE)-min(x$sablefish_cpue_table_b8_SA_2011,na.rm=TRUE))
halibut_set01 = (x$Halibut_Area.2b_Setline.Survey.Weight.Per.unit.Effort.WPUE - min(x$Halibut_Area.2b_Setline.Survey.Weight.Per.unit.Effort.WPUE,na.rm=TRUE))/(max(x$Halibut_Area.2b_Setline.Survey.Weight.Per.unit.Effort.WPUE,na.rm=TRUE)-min(x$Halibut_Area.2b_Setline.Survey.Weight.Per.unit.Effort.WPUE,na.rm=TRUE))
halibut_catch01 = (x$Halibut_catch - min(x$Halibut_catch,na.rm=TRUE))/(max(x$Halibut_catch,na.rm=TRUE)-min(x$Halibut_catch,na.rm=TRUE))
arrowtooth01 = x$Arrowtooth_BC_Schweigert_Eulachon

df1 = data.frame(x$Year,sablefish01,halibut_set01,halibut_catch01,arrowtooth01)
df1 = melt(df1,id.vars=c("x.Year"))
names(df1) = c("Year","Species","Scaled_Abundance")


ggplot()+
  geom_point(data = df1,aes(x=Year,y=Scaled_Abundance,group=Species,colour=Species,size=3))+
  geom_line(data=df1[!is.na(df1$Scaled_Abundance),],aes(x=Year,y=Scaled_Abundance,group=Species,colour=Species))+
  #geom_smooth(data = df1,aes(x=Year,y=Scaled_Abundance),size=3,colour="black",se=FALSE)+
  theme_acs()+
  labs(x="Year",y="Scaled_Groundfish_Abundance")








##########
###Other stuff 
##########
###
#Interpolate Code
###

dfr$z <- with(dfr, interp1(x, y, x, "linear"))

######
#Scale Parameters using Z scores 
#####


# mammal_z = (x[,c(61:69)]-apply(x[,c(61:69)],1,mean,na.rm=TRUE))/
#   sqrt(apply(x[,c(61:69)],1,var,na.rm=TRUE))

# mammal_01 = 
# 
# mdf = data.frame(x$Year,mammal_z)
# mdf2 = melt(mdf,id.vars=c("x.Year"))
# names(mdf2) = c("Year","Species","Scaled_Abundance")
# 
# mdf3 = rbind (subset(mdf2,Species =="Humpbacks"),
#               subset(mdf2,Species =="NR_KillerWhale"),
#               subset(mdf2,Species =="Steller_Eulachon_Reconstructed")
#               )
