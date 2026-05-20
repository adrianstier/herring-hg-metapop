# install.packages(c("ggplot2", "reshape2", "gdata", "maps", "mapproj",
#                    "ggmap", "coda", "gridExtra", "Hmisc", "PBSmapping","scales"))

######################################
#TOC
######################################

#1) Sum of Spawn index at arch and stocklet  scale


### ==================
## LOAD PACKAGES  
## ==================  

library(ggplot2)
library(reshape2)
library(gdata)
library(maps)
library(mapproj)
library(ggmap)
library(coda)
library(gridExtra)
library(Hmisc)
library(PBSmapping)
library(scales)
library(ggthemes)
library("plyr")
library("reshape")
library("MuMIn")
library("robustbase")
library("devtools")

# require("rgdal") # requires sp, will use proj.4 if installed

data(nepacLLhigh)
xlim=c(-134.5,-130)
ylim=c(51.75,54.4)

### ==================
## SET DIRECTORY AND LOAD DATA  
## ==================

setwd("~/Dropbox/Projects/In Progress/Herring_Haida_Gwaii/Code")


# source('theme_acs.R') #plotting fcns
source('theme_publication.R')
source('multiplot.R')

### ==================
## SET DIRECTORY AND LOAD DATA  
## ==================


x=read.csv("HG_Spawn_Survey_1940_2015.csv") #spawn data
c <- read.csv("herring_catch_local2015.csv") #catch data
load("diag_equal_design_c_noUsig_2q.RData")

n.chains = 3
n.burnin = 250000
n.thin = 10
n.iter = 500000



#number of recorded mcmc
runL <- n.chains*(n.iter-n.burnin)/n.thin



### ==================
## Years and Sits 
## ==================

years = seq(1950,2015)
nYears = length(years)
nSites = 11


## ==================
## Define Functions 
## ==================

#string modifier
right = function (string, char){
  substr(string,nchar(string)-(char-1),nchar(string))
}


#geometric mean 
gm_mean = function(x, na.rm=TRUE, zero.propagate = FALSE){
  if(any(x < 0, na.rm = TRUE)){
    return(NaN)
  }
  if(zero.propagate){
    if(any(x == 0, na.rm = TRUE)){
      return(0)
    }
    exp(mean(log(x), na.rm = na.rm))
  } else {
    exp(sum(log(x[x > 0]), na.rm=na.rm) / length(x))
  }
}

# getting sigfigs on y axis right
fmt <- function(){
  function(x) format(x,nsmall = 2,scientific = FALSE)
}

#unique expand grid
expand.grid.unique <- function(x, y, include.equals=FALSE)
{
  x <- unique(x)
  y <- unique(y)
  g <- function(i)
  {
    z <- setdiff(y, x[seq_len(i-include.equals)]) 
    if(length(z)) cbind(x[i], z, deparse.level=0)
  }
  do.call(rbind, lapply(seq_along(x), g))
}


createMcmcList = function(model) {
  McmcArray = as.array(model$BUGSoutput$sims.array)
  McmcList = vector("list",length=dim(McmcArray)[2])
  for(i in 1:length(McmcList)) McmcList[[i]] = as.mcmc(McmcArray[,i,])
  McmcList = mcmc.list(McmcList)
  return(McmcList)
}

#reconstruct MCMC ouput
myList<-createMcmcList(model) #mcmc output 


## ==================
## Set up Distance Matrix by Coastline
## ==================

#distance matrix by coastline
distMat4<-as.matrix(read.csv("h_dist_shore.csv")[,-1]/1000)
distMat5<-distMat4[-c(4,7),-c(4,7)]

## ==================
## Define Spawn Data
## ==================

##  Spawn Index

x <- read.csv("HG_Spawn_Survey_1940_2015.csv")
x <- x[c(1,3,13,14,15,16)]
x$presabs <-ifelse(x$SHI>0,1,0)

x2 <- x[,c(1,2,4)]
w <- reshape(x2, 
             timevar   = "section_name",
             idvar     = c("year"),
             direction = "wide")[,-1]

w[w==0] <- NA#replace zeros with NAs
Y= as.matrix(w)
Y = Y[-c(1:10),-c(4,7)] #drop site 4 and 7
Y = log(Y)
logSHI<-Y

ym<-melt(Y)
ym<-data.frame(ym,rep(seq(1:nrow(Y)),ncol(Y)))
names(ym)<-c("crap","site","logSHI","time")

#plot spawn index through time
ggplot(ym,aes(x=time,y=logSHI))+
  geom_point(aes(colour=site))+
  geom_smooth(method="lm")+
  facet_grid(.~site)+
  theme_Publication()

## ==================
##  Define Catch data
## ==================

c <- read.csv("herring_catch_local2015.csv")
yr_c<-unique(c$Year)
c$presabs <-ifelse(c$TotalCatch>0,1,0)

unique(c[,c('Section','Name')]) #look at sections and names

c<-drop.levels(subset(c,Section %in% c(1,2,3,5,6,12,21,22,23,24,25)))#subset out Cartwright Sound (4), Masset (11)
ctab<-data.frame(tapply(c$CatchJan_Apr,list(c$Year,c$Name),sum)) #just spring catch

data.frame(colnames(Y),colnames(ctab)) #mismatch column names
ctab2<-ctab[,c(11,7,8,2,5,6,3,9,1,4,10)] #re order so catch table matches spawn table 
data.frame(colnames(logSHI),colnames(ctab2)) #double check column orders match

colnames(logSHI)<-colnames(ctab2)

ctab2<-as.matrix(ctab2)
logcatch<-log(ctab2+1)


#check that catch and spawn data are same format 
data.frame(colnames(Y),colnames(ctab2))



## ==================
##  MAKE SITE AND SUMMARY TABLE
## ==================

#load in site name and location 
st<-read.csv("sitemeta.csv")
st2<-st[-c(4,7),]

#labels for graph
sitelab2<-unique(x$section_name)[-c(4,7)] #subtract cartwright and masset 
md<-data.frame(st2,sitelab2)
md$altsite<-substr(colnames(Y),5,28)



 pdf(paste("non_spatial_2q",Sys.Date(),".pdf"), width=12,onefile = TRUE)


## ==================
##  FIGURE 1 - MAP AND LOCATION OF SPAWNING SITES
## ==================


#See Map Blake Feist Made 



## ==================
##  FIGURE 2 - SUM OF SPAWN AT LOCAL AND REGIONAL SCALES
## ==================

############ WHOLE ISLAND  numer of spawns, sum of spawn index
x<-subset(x,section %in% c(1,2,3,5,6,12,21,22,23,24,25))

#percent of years where there's been any spawn over past 75 years
#not accurate due to missing data 
100*round(tapply(x$presabs,list(x$section_name),sum)/
            tapply(x$presabs,list(x$section_name),length),2)

tapply(x$SHI,list(x$section_name),mean) #highest average SHI
tapply(x$SHI,list(x$section_name),sd) #most spawn sites

num<-melt(c(rowSums(tapply(x$presabs,list(x$year,x$section_name),sum),na.rm=T)))
num<-data.frame("num"=num[,1],"year"=rownames(num))
num[,2]=as.numeric(as.character(num[,2]))
num$belowave<-ifelse(num$num<median(num$num),1,0)
sum(num$belowave)/length(num$belowave) 

#number spawn sites through time. #61% of years since 1950 sites have been below median number of spawn sites 

ss<-melt(c(rowSums(tapply(x$SHI,list(x$year,x$section_name),sum),na.rm=T)))
ss<-data.frame("sum"=ss[,1],"year"=rownames(ss))
ss[,2]=as.numeric(as.character(ss[,2]))
shi_sum<-ss
shi_sum$belowave<-ifelse(shi_sum$sum>median(shi_sum$sum),0,1)
sum(shi_sum$belowave)/length(shi_sum$belowave) 

#catch data 

ctab3<-melt(ctab2)
ctab3$presabs<-ifelse(ctab3$value>0,1,0)
ctab3$year<-rep(1950:2015,11)
names(ctab3)<-c("year","site","value","presabs","year2")

numc<-melt(tapply(ctab3$presabs,list(ctab3$year),sum))
names(numc)<-c("year","num")
numc$belowave<-ifelse(numc$num<median(numc$num),1,0)
sum(num$belowave)/length(num$belowave) 

sumc<-melt(tapply(ctab3$value,list(ctab3$year),sum))
names(sumc)<-c("year","num")
nzc<-subset(sumc,num>0)
sumc$belowave<-ifelse(sumc$num<median(nzc$num),1,0)
sum(sumc$belowave)/length(sumc$belowave) 

shi_sum<-shi_sum[,c(2,1,3)]
num<-num[,c(2,1,3)]
names(shi_sum)<-c("year","num","belowave")

bb<-rbind(
  numc,
  sumc,
  shi_sum[-c(1:10),], #there are problems withi numc and sumc with number of rows. neeed by year
  num[-c(1:10),])
bb$col<-c(rep("catch",132),rep("spawn",132))
bb$row<-c(rep("number",66),rep("sum",66),rep("sum",66),rep("number",66))
bb$both<-factor(paste(bb$col,bb$row))
bb$both=factor(bb$both,levels(bb$both)[c(4,2,3,1)])

bk<-seq(1950,2020,by=10)

ggplot(bb,aes(x=year,y=num))+
  geom_line(colour="grey")+
  geom_point(aes(colour=factor(belowave)))+
  #geom_hline(yintercept=median(numc$num),lty=2)+
  facet_wrap(~both,scales="free")+
  scale_colour_manual(values = c("dodgerblue","firebrick"))+
  theme(legend.position="none")+
  #scale_y_continuous(limits=c(0,15))+
  scale_x_continuous(limits=c(1950,2015),breaks=bk)+
  theme_Publication()
  

#ggsave("Whole Island Through Time.pdf")

bb2<-subset(bb,col=="spawn" & row =="sum")



############Long Term Sum of Spawn index

breaks <- axTicks(side=2)
ggplot(M,aes(x=X,y=Y)) + geom_line() +
  scale_y_continuous(breaks=breaks) +
  coord_trans(y="log")

breaks <- axTicks(side=2)

base_breaks <- function(n = 10){
  function(x) {
    axisTicks(log10(range(x, na.rm = TRUE)), log = TRUE, n = n)
  }
}

bk2<-c(1000000,2000000)

ggplot(bb2,aes(x=year,y=num))+
  geom_line(colour="grey")+
  geom_point(aes(colour=factor(belowave)),pch=18,size=3)+
  geom_hline(yintercept=median(shi_sum$num),lty=2)+
  scale_colour_manual(values = c("dodgerblue","firebrick"))+
  theme(legend.position="none")+
  #scale_y_continuous(limits=c(0,15))+
  scale_x_continuous(limits=c(1950,2015),breaks=bk)+
  xlab("Year")+
  ylab("Sum of Spawn Index")+
  theme_Publication()
  


# ggsave("AllSites_Sum_SHI.pdf",width=7,height=3, useDingbats=FALSE)


# 
# ############Individual Stocklet SHI 
# 
# xss<-subset(x,SHI>0 & year > 1949)
# xss2<-subset(xss,section_name %in% c("Louscoone Inlet","Juan Perez Sound","Rennell Sound","Skidegate Inlet","Skincuttle Inlet","Englefield Bay"))
# 
# bk2<- c(1950,1970,1990,2010)
# 
# ggher2<-ggplot(xss,aes(x=year,y=SHI,group=section_name))+
#   geom_line(lty=1)+
#   geom_point(shape=21,fill="white")+
#   #scale_y_log10()+
#   theme_acs()+
#   #ggtitle("Herring By Spawn Area")+
#   facet_wrap(~section_name,scales="free_y")+
#   theme(legend.position="none")+
#   scale_y_log10(limits=c(100,1000000),
#                 breaks=c(10^2,10^4,10^6),
#                 labels = trans_format("log10", math_format(10^.x)))+
#   scale_x_continuous(limits=c(1950,2014),breaks=c(1950,1970,1990,2010))
#   
# #  scale_y_continuous(breaks = trans_breaks("log10", function(x) 10^x)), #FIX THIS
# #          labels = trans_format("log10", math_format(10^.x)))
# 
# print(ggher2)
# 
# #Print out individual stocklets one by one  
# library(scales)
# 
# nm<-unique(xss2$section_name)
# for(i in 1:length(nm)){
#   tmp<-subset(xss2,section_name==nm[i])
#   
#   # ggher2<-ggplot(tmp,aes(x=year,y=SHI))+
# ggplot(tmp,aes(x=year,y=SHI))+
# 
#     geom_point()+
#     geom_line(lty=1)+
#     #scale_y_log10()+
#     theme_acs()+
#     #ggtitle("Herring By Spawn Area")+
#     #facet_wrap(~section_name,scales="free_y")+
#     theme(legend.position="none")+
#     scale_x_continuous(limits=c(1950,2014),breaks=bk)+
#     scale_y_log10(limits=c(100,1000000),
#                   labels = trans_format("log10", math_format(10^.x)))
# #     scale_y_continuous(
# #                       breaks = trans_breaks("log10", function(x) 10^x), #FIX THIS
# #                        labels = trans_format("log10", math_format(10^.x)))
# #   
#   
#   # ggsave(paste("SHI",nm[i],".pdf"))
# 
# }
# 
# 


######################################
###PDO Coef Effect
######################################

#load pdo
pdo<-read.csv("pdo.csv")
pdosummer<-subset(pdo,month %in% c(3,4,5,6)) #average april<-june
pdoxb<-c(tapply(pdosummer$Value,list(pdosummer$year),mean))
pdo2<-pdoxb[87:162] #1940-20135
pdo3<-pdo2[11:76] #1950-2015
plot.ts(pdo3)

pdocoef<-melt(model$BUGSoutput$sims.array[,,"pdocoef"])$value

hist(pdocoef)

distpdoci<-smedian.hilow(pdocoef,conf.int=0.95)
distpdoiqr<-smedian.hilow(pdocoef,conf.int=0.5)

pdodf<-data.frame("pdo"=pdo3,
                  "medianci"=distpdoci[1]*pdo3,
                  "maxci"=distpdoci[3]*pdo3,
                  "minci"=distpdoci[2]*pdo3,
                  "maxiqr"=distpdoiqr[3]*pdo3,
                  "miniqr"=distpdoiqr[2]*pdo3
)

pdodf$year<-as.numeric(rownames(pdodf))
pdodf2<-data.frame(site=rep("pdocoef",nrow(pdodf)),pdodf)
pdodf2$hc<-ifelse(pdodf2$medianci>0,"hot","cold")


ggplot(pdodf2,aes(x=site,y=medianci))+
  geom_boxplot()+
  geom_point(aes(colour=medianci))+
  scale_colour_gradient2(low="firebrick",high="dodgerblue")+
  coord_flip()+
  theme_Publication()+
  scale_y_continuous(limits=c(-0.10,0.2),breaks=c(-0.1,0,0.1,0.2))


pdobw<-ggplot(pdodf2,aes(x=site,y=medianci))+
  geom_boxplot()+
  geom_point(aes(colour=medianci))+
  scale_colour_gradient2(low="firebrick",mid="grey",high="dodgerblue")+
  # coord_flip()+
  theme_Publication()+
  scale_y_continuous(limits=c(-0.10,0.2),breaks=c(-0.1,0,0.1,0.2))+
  ylab("PDO Effect")


multiplot(umuplot,pdobw,cols=2)



bk<-seq(1950,2020,by=10)


pdotsgg<-ggplot(pdodf2,aes(x=year,y=medianci))+
  geom_hline(yintercept=0)+
  geom_ribbon(aes(ymin=minci,ymax=maxci),fill="grey70",alpha=0.2)+
  geom_ribbon(aes(ymin=miniqr,ymax=maxiqr),fill="grey")+
  geom_line(lty=2)+
  geom_point(aes(colour=hc))+
  theme_Publication()+
  ylab("PDO Effect (PDO*PDOcoef)")+
  xlab("Year")+
  scale_x_continuous(breaks=bk)


print(pdotsgg)

######################################
###FIGURE 3 - TOTAL AVERAGE BIOMAASS, SCALED BIOMASS, PROP CONTRIBUTION 
######################################
bk<-seq(1950,2015,by=10)

tempmat<-model$BUGSoutput$mean$X
colnames(tempmat)<-colnames(Y)
tempmat<-data.frame(exp(tempmat))
tempmat$year<- 1950:2015
tempmat<-melt(tempmat,id.vars=c("year"))
names(tempmat)<- c("year","site","biomass")


ggplot(tempmat,aes(x=year,y=biomass,colour=site,fill=site))+
  geom_area()+
  ylab("Predicted Herring Biomass")+
  xlab("Time")+
  scale_x_continuous(breaks=bk)+
  theme_Publication()


  
#######################################################


#means
tempmat<-scale(model$BUGSoutput$mean$X)
colnames(tempmat) <- colnames(Y)
temp2<-melt(tempmat)
colnames(temp2) <-c("time","site","x")
#temp2$site<-as.numeric(temp2$site)
temp2$year<-years
temp2$year<-as.numeric(temp2$year)

#drop uncertain sites
temp2<-drop.levels(subset(temp2,site!="SHI.Tasu Sound & Gowgaia Bay"))
temp2<-drop.levels(subset(temp2,site!="SHI.Naden.Harbour"))




t3<-data.frame("x"=tapply(temp2$x,list(temp2$year),mean))
t3$year<-years
t3$year<-as.numeric(t3$year)
t3$site<-12
t3$max<-tapply(temp2$x,list(temp2$time),max)
t3$min<-tapply(temp2$x,list(temp2$time),min)
names(t3)<-c("x","year","site","max","min")

bk<-seq(1950,2015,by=10)

ggplot()+
  geom_ribbon(data=t3,aes(x=year,ymin=min,ymax=max),colour="grey60")+
  geom_line(data=temp2,aes(x=year,y=x,colour=factor(site),lty=factor(site),group=site))+
  geom_line(data=t3,aes(x=year,y=x),colour="white",size=2)+
  geom_vline(xintercept=1967,colour="grey",lty=2)+ #this is the closure of the reduction 
  geom_vline(xintercept=1994,colour="grey",lty=2)+ #this is the big recent closure 
  geom_hline(yintercept=0,colour="grey",lty=1)+
  theme_Publication()+
  scale_x_continuous(breaks=bk)+
  xlab("Year")+
  ylab("Scaled Estimated Total Biomass X")+
  scale_colour_Publication()
  

#just the aveage at the archipelago

ggplot(t3,aes(x=year,y=x))+
  geom_line(size=2)+
  theme_Publication()+
  geom_hline(yintercept=0,lty=2)+
  ylab("Total Herring Biomass")+
  xlab("")



#which populations are above and below long term average 
lta<-subset(temp2,year==2015)
lta$ab<-ifelse(lta$x>0,1,0)

# bold colors for presentation

xscalegg<-ggplot()+
  #geom_ribbon(data=t3,aes(x=year,ymin=min,ymax=max),colour="grey60")+
  geom_hline(yintercept=0,colour="grey")+
  geom_line(data=temp2,aes(x=year,y=x,colour=factor(site),lty=factor(site),group=site),size=1)+
  geom_line(data=t3,aes(x=year,y=x),colour="black",size=3)+
  # geom_vline(xintercept=1967,colour="grey",lty=2)+ #this is the closure of the reduction
  #  geom_vline(xintercept=1994,colour="grey",lty=2)+ #this is the big recent closure
  theme_Publication()+
  scale_x_continuous(breaks=bk)+
  scale_colour_brewer(palette="Spectral")+
  # scale_colour_brewer(colours=rainbow(11))+
  xlab("Year")+
  ylab("Scaled Estimated Total Biomass X")


print(xscalegg)


#need to fix stocklet names
sbst<-subset(temp2,site %in% c("SHI.Skidegate Inlet","SHI.Rennell Sound"))

dpX<-ggplot()+
  #geom_ribbon(data=t3,aes(x=year,ymin=min,ymax=max),colour="grey60")+
  geom_hline(yintercept=0)+
  geom_line(data=sbst,aes(x=year,y=x,colour=factor(site),lty=factor(site),group=site))+
  geom_line(data=t3,aes(x=year,y=x),colour="black",size=2)+
  #geom_line(data=t3,aes(x=year,y=max))+
  #geom_line(data=t3,aes(x=year,y=min))+
  #scale_colour_continuous(low="green",high="red")+
  geom_vline(xintercept=1967,colour="grey",lty=2)+ #this is the closure of the reduction
  geom_vline(xintercept=1994,colour="grey",lty=2)+ #this is the big recent closure
  # theme_acs()+
  scale_x_continuous(breaks=bk)+
  #coord_trans(y="log10")+
  #scale_y_log10(breaks=c(.1,1,10),labels=c(0.1,1,10))+
  xlab("Year")+
  ylab("Scaled Herring Biomass")+
  theme(legend.position="none")
print(dpX)


#plot out individual stocklets with halo confidence intervals 

edf1<-melt(model$BUGSoutput$sims.array[,,"pdocoef"])$value



edf1<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="X[1,1]"):which(colnames(myList[[1]])=="X[66,11]")]])
names(edf1)<-c("num","chain","response","value")
edf1$chain<-factor(edf1$chain)

edf1$group<-factor(sort(rep(seq(1:nSites),runL)))
edf1$year2<-sort(rep(1950:2015,runL*nSites))
edf1$year<-sort(rep(seq(1:nYears),runL*nSites))
edf1$section<-sort(rep(colnames(Y),nYears*runL))


tsmed<-tapply(edf1$value,list(edf1$response),median)
tsupper<-melt(tapply(edf1$value,list(edf1$response),quantile,probs=c(0.95)))
tslower<-melt(tapply(edf1$value,list(edf1$response),quantile,probs=c(0.05)))

xdat<-data.frame(exp(tsmed),exp(tsupper[,2]),exp(tslower[,2]))
colnames(xdat)<-c("median","upper","lower")
xdat$year<-rep(1950:2015,nSites)

secvec<-colnames(Y)
sec<-c()

for(i in 1:11){
  temp<-rep(secvec[i],66)
  sec<-c(sec,temp)
}

xdat$section<-sec

ggplot(xdat,aes(x=year,y=median))+
  geom_hline(yintercept=0)+
  geom_ribbon(aes(ymin=lower,ymax=upper),fill="dodgerblue",alpha=0.2)+
  # geom_ribbon(aes(ymin=miniqr,ymax=maxiqr),fill="grey")+
  geom_line(colour="grey")+
  # geom_point(aes(colour=hc))+
  # theme_acs()+
  ylab("Estimated Biomass")+
  xlab("Year")+
  facet_wrap(~section,scales="free")+
  scale_x_continuous(breaks=bk)



distpdoci<-smedian.hilow(pdocoef,conf.int=0.95)


for(i in 1:nSites){
  tmp<-subset(edf1,year==i)
  gtemp<-ggplot(tmp,aes(x=num,y=value,group=chain))+
    geom_line(aes(colour=chain))+
    facet_wrap(~group)+
    theme_acs()+
    ggtitle(paste("X chains_time_",i))
  
  print(gtemp)
}



x<-melt(model$BUGSoutput$sims.array[,,"pdocoef"])$value

hist(pdocoef)

distpdoci<-smedian.hilow(pdocoef,conf.int=0.95)
distpdoiqr<-smedian.hilow(pdocoef,conf.int=0.5)





##########################################################################
###Figure 4 Population Growth Rates at the Archipelago (Umu) and Stocklet Scale (Ui), PDO EFFECT 
##########################################################################

###Popultaion Productivitys
####Umu and Ui estimates 
Umudf<-melt(model$BUGSoutput$sims.array[,,"Umu"])
Umudf$Var3<-"Umu"
Umudf<-Umudf[,c(1,2,4,3)]
umuci<-smedian.hilow(Umudf$value,conf.int=0.95)
umucia<-smedian.hilow(Umudf$value,conf.int=0.95)
umuci[4]<-"Umu"
names(umuci)<-c("Median","Lower","Upper","ttt")
umudf2<-data.frame(t(data.frame(umuci)))
umudf2$Median<-as.numeric(as.character(umudf2$Median))
umudf2$Lower<-as.numeric(as.character(umudf2$Lower))
umudf2$Upper<-as.numeric(as.character(umudf2$Upper))


umuci2<-quantile(Umudf$value,c(0.05,0.95))


umuplot<-ggplot(umudf2,aes(x=ttt,y=Median,ymin=Lower,ymax=Upper))+
  geom_pointrange()+
  theme_Publication()+
  scale_y_continuous(limits=c(-0.10,0.2),breaks=c(-0.1,0,0.1,0.2))+
  ylab("Intrinsic Growth Rate")

print(umuplot)
#only estmating single population growth rate in this form 

# tlist<-model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="U[1]"):which(colnames(myList[[1]])=="U[11]")]]
# dimnames(tlist)[[3]]<-colnames(Y_car)
# udf<-melt(tlist)
# 
# names(sort(tapply(udf$value,list(udf$Var3),mean),decreasing=T))
# levels(udf$Var3)
# mean(tapply(udf$value,list(udf$Var3),mean))
# 
# 
# udf$Var3=factor(udf$Var3,levels(udf$Var3)[c(11,7,10,2,8,9,3,6,1,4,5)])
# #udf$Var3=substr(udf$Var3,5,28)
# 
# udf2<- data.frame("umed"=sort(tapply(udf$value,list(udf$Var3),median),decreasing=TRUE),
#                   "usd"=tapply(udf$value,list(udf$Var3),median)+tapply(udf$value,list(udf$Var3),sd))
# 
# md<-md[c(11,7,8,5,10,3,4,9,2,1,6),] 
# md$median_ui<-sort(tapply(udf$value,list(udf$Var3),median),decreasing=TRUE)
# md$sd_ui<-tapply(udf$value,list(udf$Var3),median)+tapply(udf$value,list(udf$Var3),sd)
# 
# 
# 
# #udf$Var3=factor(udf$Var3,levels(udf$Var3)[c(11,7,8,5,10,3,4,9,2,1,6)])
# #md<-md[c(11,7,8,5,10,3,4,9,2,1,6),]
# 
# ucomp<-ggplot(udf,aes(x=Var3,y=value))+
#   geom_hline(yintercept=median(Umudf$value),lty=1,colour="grey")+
#   geom_hline(yintercept= umuci2[1],lty=2,colour="grey")+
#   geom_hline(yintercept= umuci2[2],lty=2,colour="grey")+
#   stat_summary(fun.data=median_hilow,lty=3,pch=21,fill="white")+
#   #stat_summary(fun.data=median_hilow,conf.int=0.5)+
#   scale_y_continuous(labels = fmt())+
#   ylab("Population Growth Rate [Ui]")+
#   xlab("")+
#   coord_flip()+
#   theme_acs()+
#   theme(axis.text.x = element_text(angle = 45, hjust = 1),
#         legend.position="none") 
# 
# print(ucomp)
# 
# #pull out values for Blake 
# utab<-ggplot_build(ucomp)$data[[5]]
# utab$stocklet<-levels(udf$Var3)
# 
# 
# sumtab<-tapply(udf$value,list(udf$Var3),IQR)




######################################
###Distance Decay 
######################################

# svec<-seq(1,nSites,by=1)
# 
# covmat<-matrix(NA,11,11)
# 
# #lag0
# for(i in 1:nSites){
#   for(j in 1:nSites){
#     s1<-ccf(Y[,i],Y[,j],0,na.action=na.pass)
#     covmat[i,j]<-s1$acf[,,1]
#   }
# }
# 
# s1<-ccf(Y[,1],Y[,2],0,na.action=na.pass)
# s1$acf[,,1]
# 
# covmat[lower.tri(covmat)] <-NA
# diag(covmat) <- NA
# 
# distMat6 <- distMat5
# 
# distMat6[lower.tri(distMat6)]<-NA
# diag(distMat6) <- NA
# 
# plot(covmat,distMat6)
# 
# ccf_df<-data.frame(melt(covmat),melt(distMat6)[,3])
# names(ccf_df) <- c("site1","site2","cor","distance")
# 
# ggplot(ccf_df,aes(x=distance,y=cor))+
#   geom_point()+
#   geom_smooth(method="lm",se=F,colour="red",size=1)+
#   #geom_smooth()+
#   theme_acs()+
#   xlab("Distance Between Sites")+
#   ylab("Cross Correlation of Spawn Index")+
#   ggtitle("Correlation By as fish swims Distance")
# 

# 
# thetadf<-melt(model$BUGSoutput$sims.array[,,"theta"])
# thetadf$Var3<-"theta"
# thetadf<-thetadf[,c(1,2,4,3)]
# thetaci<-smedian.hilow(thetadf$value,conf.int=0.95)
# 
# dvec<-seq(0,400,by=1)
# tmed<- exp(-dvec/thetaci[1])
# tlower<- exp(-dvec/thetaci[2])
# tupper<- exp(-dvec/thetaci[3])
# 
# thetadf2<-data.frame(dvec,tmed,tlower,tupper)
# names(thetadf2)<- c("distance","median","lower","upper")
# 
# ggplot(thetadf2,aes(x=distance))+
#   geom_ribbon(aes(ymin=lower,ymax=upper),fill="grey70")+
#   geom_line(aes(y=median))+
#   theme_acs()+
#   xlab("Distance (km)")+
#   ylab("Correlation")
# 
# 
# distMat6<-distMat5
# distMat6[lower.tri(distMat6)] <-NA


######################################
###FIGURE 5 FISHING  EFFECTS
######################################

#average estimated proportion caught by fishing 
tpc<-model$BUGSoutput$mean$Pc


#Identify Which Row-Column Combinations Where Catch>0
INDEX      <- NULL  
INDEX.zero <- NULL  
for(i in 1:nrow(logcatch)){
  
  if(length(logcatch[i,][logcatch[i,]>0])>0){ 
    temp   <- data.frame(row = rep(i,length(which(logcatch[i,]>0))),col = which(logcatch[i,]>0))
    INDEX <- rbind(INDEX,temp)
  }
  
  if(length(logcatch[i,][logcatch[i,]==0])>0){ 
    temp.2 <- data.frame(row = rep(i,length(which(logcatch[i,]==0))),col = which(logcatch[i,]==0))
    INDEX.zero <- rbind(INDEX.zero,temp.2)
  }
}


emat <- matrix(0,nrow=nYears,ncol=nSites)

for(i in 1:156){
  
  emat[INDEX[i,1],INDEX[i,2]]<-tpc[i]
  
}


colnames(emat)<-colnames(Y)
pc_tab<-melt(emat)
colnames(pc_tab) <- c("year2","section","pc")
pc_tab$year<-seq(1950,2015,1)

arch<-data.frame(tapply(pc_tab$pc,list(pc_tab$year),mean))
arch$year<-as.numeric(rownames(arch))
names(arch)<-c("pc","year")

pc_tab2<-subset(pc_tab,pc>0)

sec<-data.frame(tapply(pc_tab2$pc,list(pc_tab2$year),mean))
sec$year<-as.numeric(rownames(sec))
names(sec)<-c("pc","year")


fish<-merge(arch,sec,by=("year"),all=TRUE)
colnames(fish)<-c("year","archipelago","stocklet")
fish[is.na(fish)]<-0

fish2<-melt(fish,id.vars="year")
colnames(fish2)<-c("year","var","pc")

bk<-seq(1950,2015,by=10)

#Arhipelago Versus Stocklet 

ggplot(fish2,aes(x=year,y=pc))+
  geom_line(aes(lty=var,colour=var))+
  theme_Publication()+
  scale_y_continuous(limits=c(0,1),breaks=c(0,0.2,0.4,0.6,0.8,1.0))+
  scale_x_continuous(breaks=bk)+
  ylab("Proportion Biomass Caught (F)")


########
#plot by section through time
#######

ggplot(pc_tab,aes(x=year,y=pc))+
  geom_line(aes(colour=section))+
  scale_y_continuous(limits=c(0,1),breaks=c(0,0.5,1.0))+
  facet_wrap(~section,ncol=2)+
  theme(legend.position="none")+
  theme_Publication()
  

# ggsave("section_pc.pdf",width=3,height=9)


#####BOXPLOT by section

secfish<-ggplot(pc_tab2,aes(x=section,y=pc))+
  geom_hline(yintercept=mean(tapply(pc_tab2$pc,list(pc_tab2$section),mean)))+
  geom_boxplot()+
  geom_point()+
  coord_flip()+
  theme_Publication()+
  ylab("Fishing Effect (Pc)")

print(secfish)

tapply(pc_tab2$pc,list(pc_tab2$section),mean)


#fishing by climate - no clear evidence for there beign higher fishing in cold or hot years. 

plot(pdodf2$medianci,fish$stocklet,ylab="Proportion Caught When Fished",xlab="pdo effect")
m1<-lm(fish$stocklet~pdodf2$medianci)
abline(m1)


tempfish<-data.frame(pdodf2$hc,pdodf2$medianci,fish$stocklet)

tapply(tempfish$fish.stocklet,list(tempfish$pdodf2.hc),mean)
tapply(tempfish$fish.stocklet,list(tempfish$pdodf2.hc),sd)

boxplot(fish.stocklet~pdodf2.hc,data=tempfish,ylab="Proportion Caught When Fished")

##########################################
############ Fig 6 Delta -estiamtes of states for each population's change
##########################################

#means
tempmat<-model$BUGSoutput$mean$delta
colnames(tempmat) <- colnames(Y) #<-seq(1,11,1)
temp2<-melt(tempmat)
colnames(temp2) <-c("time","site","delta")
#temp2$site<-as.numeric(temp2$site)
temp2$year<-years
temp2$year<-as.numeric(temp2$year)



temp2<-drop.levels(subset(temp2,site!="SHI.Tasu Sound & Gowgaia Bay"))
temp2<-drop.levels(subset(temp2,site!="SHI.Naden.Harbour"))


# 
#add site names from df2
ggplot(temp2,aes(x=time,y=site,fill=delta))+
  geom_tile()+
  scale_fill_gradient2(low="red",high="dodgerblue")+
  theme_Publication()
# 

#plot average delta by site 

ggplot()+
  geom_boxplot(data=temp2,aes(x=site,y=delta))+
  geom_point(data=temp2,aes(x=site,y=delta))+
  geom_rect(aes(ymin=umucia[2], ymax=umucia[3], xmin=-Inf, xmax=Inf),
           fill="red",alpha=0.2)+
  geom_hline(yintercept=umucia[1],colour="red")+
  # geom_hline(yintercept=umuci[2])+
  # geom_hline(yintercept=umuci[3])+
  geom_hline(yintercept=0,lty=1)+
  coord_flip()+
  theme_Publication()+
  ylab("Process Variation (delta)")

#look at changes in delta among years 
temp2$period<-c(rep("historic_pre1995",45),rep("recent_post1994",21))


ggplot()+
  geom_boxplot(data=temp2,aes(x=site,y=delta))+
  geom_point(data=temp2,aes(x=site,y=delta,colour=period))+
  geom_rect(aes(ymin=umucia[2], ymax=umucia[3], xmin=-Inf, xmax=Inf),
            fill="purple",alpha=0.2)+
  geom_hline(yintercept=umucia[1],colour="purple")+
  # geom_hline(yintercept=umuci[2])+
  # geom_hline(yintercept=umuci[3])+
  geom_hline(yintercept=0,lty=1)+
  coord_flip()+
  theme_Publication()+
  ylab("Process Variation (delta)")



t3<-data.frame("delta"=tapply(temp2$delta,list(temp2$time),mean))
t3$year<-years
t3$year<-as.numeric(t3$year)
t3$site<-12
t3$max<-tapply(temp2$delta,list(temp2$time),max)
t3$min<-tapply(temp2$delta,list(temp2$time),min)
names(t3)<-c("delta","year","site","max","min")


# dts<-ts(c(t3$delta),start=1950,end=2015,frequency=1)
# mppt<-cpt.mean(dts,method="PELT")
# cpts(mppt)
# plot(mppt)


# t3max<-t3[,c(2,3,5)]  
# names(t3max)<-c("year","site","delta")
# t3min<-t3[,c(2,3,4)]  
# names(t3min)<-c("year","site","delta")
# bk<-seq(1950,2015,by=10)

dp<-ggplot()+
  geom_ribbon(data=t3,aes(x=year,ymin=min,ymax=max),colour="grey60")+
  geom_line(data=temp2,aes(x=year,y=delta,colour=factor(site),lty=factor(site),group=site))+
  geom_line(data=t3,aes(x=year,y=delta),colour="white",size=2)+
  geom_hline(yintercept=0)+
  #geom_line(data=t3,aes(x=year,y=max))+
  #geom_line(data=t3,aes(x=year,y=min))+
  #scale_colour_continuous(low="green",high="red")+
  geom_vline(xintercept=1967,colour="grey",lty=2)+ #this is the closure of the reduction 
  geom_vline(xintercept=1994,colour="grey",lty=2)+ #this is the big recent closure 
  theme_Publication()+
  scale_x_continuous(breaks=bk)+
  xlab("Year")+
  ylab("Detrended Population Performance (Delta)")
print(dp)


#subset out and find which date-site combinations there is catch and/or spawn reported

#catch
c.INDEX      <- NULL
c.INDEX.zero <- NULL
for(i in 1:nrow(logcatch)){

  if(length(logcatch[i,][logcatch[i,]>0])>0){
    temp   <- data.frame(row = rep(i,length(which(logcatch[i,]>0))),col = which(logcatch[i,]>0))
    c.INDEX <- rbind(c.INDEX,temp)
  }

  if(length(logcatch[i,][logcatch[i,]==0])>0){
    temp.2 <- data.frame(row = rep(i,length(which(logcatch[i,]==0))),col = which(logcatch[i,]==0))
    c.INDEX.zero <- rbind(c.INDEX.zero,temp.2)
  }
}



#spawn
s.INDEX      <- NULL
s.INDEX.zero <- NULL
for(i in 1:nrow(Y)){

  if(length(Y[i,][Y[i,]>0])>0){
    temp   <- data.frame(row = rep(i,length(which(Y[i,]>0))),col = which(Y[i,]>0))
    s.INDEX <- rbind(s.INDEX,temp)
  }

  if(length(Y[i,][Y[i,]==0])>0){
    temp.2 <- data.frame(row = rep(i,length(which(Y[i,]==0))),col = which(Y[i,]==0))
    s.INDEX.zero <- rbind(s.INDEX.zero,temp.2)
  }
}


cspos<-rbind(c.INDEX,s.INDEX)
cspos2 <- unique(cspos)


tempmat<-model$BUGSoutput$mean$delta
colnames(tempmat) <- colnames(Y)

emat_d <- matrix(0,nrow=nYears,ncol=nSites)

for(i in 1:nrow(cspos2)){

  emat_d[cspos2[i,1],cspos2[i,2]] <- tempmat[cspos2[i,1],cspos2[i,2]]

}


colnames(emat_d)<-colnames(Y)
temp2<-melt(emat_d)
colnames(temp2) <-c("time","site","delta")
temp2$years<-seq(1950,2015,1)
temp2$period<-c(rep("historic_pre1995",45),rep("recent_post1994",21))


temp3 <- subset(temp2,delta!=0)


#add site names from df2
ggplot(temp3,aes(x=time,y=site,fill=delta))+
  geom_tile()+
  scale_fill_gradient2(low="red",high="dodgerblue")+
  theme_Publication()




#
# 
# #plot average delta by site 
# 
# ggplot()+
#   geom_boxplot(data=temp3,aes(x=site,y=delta))+
#   geom_point(data=temp3,aes(x=site,y=delta))+
#   geom_rect(aes(ymin=umuci[2], ymax=umuci[3], xmin=-Inf, xmax=Inf),
#             fill="red",alpha=0.2)+
#   geom_hline(yintercept=umuci[1],colour="red")+
#   # geom_hline(yintercept=umuci[2])+
#   # geom_hline(yintercept=umuci[3])+
#   geom_hline(yintercept=0,lty=1)+
#   coord_flip()+
#   theme_acs()+
#   ylab("Process Variation (delta)")
# 
# #look at changes in delta among years 
# 
# 
# ggplot()+
#   geom_boxplot(data=temp3,aes(x=site,y=delta))+
#   geom_point(data=temp3,aes(x=site,y=delta,colour=period))+
#   geom_rect(aes(ymin=umuci[2], ymax=umuci[3], xmin=-Inf, xmax=Inf),
#             fill="purple",alpha=0.2)+
#   geom_hline(yintercept=umuci[1],colour="purple")+
#   # geom_hline(yintercept=umuci[2])+
#   # geom_hline(yintercept=umuci[3])+
#   geom_hline(yintercept=0,lty=1)+
#   coord_flip()+
#   theme_acs()+
#   ylab("Process Variation (delta)")
# 
# 
# 
# t3<-data.frame("delta"=tapply(temp3$delta,list(temp3$years),mean))
# t3$years<-years
# t3$years<-as.numeric(t3$year)
# t3$site<-12
# t3$max<-tapply(temp3$delta,list(temp3$year),max)
# t3$min<-tapply(temp3$delta,list(temp3$year),min)
# names(t3)<-c("delta","year","site","max","min")
# 
# # dts<-ts(c(t3$delta),start=1950,end=2015,frequency=1)
# # mppt<-cpt.mean(dts,method="PELT")
# # cpts(mppt)
# # plot(mppt)
# 
# 
# # t3max<-t3[,c(2,3,5)]  
# # names(t3max)<-c("year","site","delta")
# # t3min<-t3[,c(2,3,4)]  
# # names(t3min)<-c("year","site","delta")
# # bk<-seq(1950,2015,by=10)
# 
# dp<-ggplot()+
#   geom_ribbon(data=t3,aes(x=years,ymin=min,ymax=max),colour="grey60")+
#   geom_line(data=temp3,aes(x=years,y=delta,colour=factor(site),lty=factor(site),group=site))+
#   geom_line(data=t3,aes(x=years,y=delta),colour="white",size=2)+
#   geom_hline(yintercept=0)+
#   #geom_line(data=t3,aes(x=year,y=max))+
#   #geom_line(data=t3,aes(x=year,y=min))+
#   #scale_colour_continuous(low="green",high="red")+
#   geom_vline(xintercept=1967,colour="grey",lty=2)+ #this is the closure of the reduction 
#   geom_vline(xintercept=1994,colour="grey",lty=2)+ #this is the big recent closure 
#   theme_acs()+
#   scale_x_continuous(breaks=bk)+
#   xlab("Year")+
#   ylab("Detrended Population Performance (Delta)")
# print(dp)



######################################
### RELATIVE CONTRIBUTION CLIMATE Ui AND PDO
######################################
  
#COVARIANCE OF THE RELIZED POPULATION GROWTH 
  
dmat<-model$BUGSoutput$mean$delta
colnames(dmat)<-colnames(Y)
dmat2<- exp(data.frame(dmat+median(Umudf$value)+pdodf$medianci))
dmat2$year<-c(1950:2015)
dmat2$bin<-ifelse(dmat2$year<1995,"1950-1994","1995-2015")

dmat3<-melt(dmat2,id.vars=c("bin","year"))

 
dmat3<-drop.levels(subset(dmat3,variable!="SHI.Tasu.Sound...Gowgaia.Bay"))
dmat3<-drop.levels(subset(dmat3,variable!="SHI.Naden.Harbour"))




ggplot(dmat3,aes(x=year,y=value))+
  geom_line(aes(colour=variable))+
  # geom_point(aes(colour=variable))+
  geom_hline(yintercept=1,colour="grey")+
  # theme_acs()+
  facet_wrap(~variable,scales="free")+
  ylab("Realized Population Growth exp(U+pdoeff+delta)")+
  theme(legend.position="none")
  

stat_sum_single <- function(fun, geom="point", ...) {
  stat_summary(fun.y=fun, geom=geom, size = 1, ...)
}

ggplot(dmat3,aes(x=bin,y=value,group=variable,colour=variable,lty=variable))+
  #stat_summary(fun.data=mean_cl_normal,geom="linerange")+
  #stat_summary(fun.y=mean,geom="point")+
  stat_sum_single(median, geom="line")+
  # theme_acs()+
  # theme(legend.position="none")+
  #facet_wrap(~variable,scales="free")+
  geom_hline(yintercept=1,colour="grey")+
  xlab("Time Period")+
  ylab("Realized Growth Rate")




d <- seq(1950,2015,by=1)

em<- matrix(0,ncol=2,nrow=56) 
em[1,1] <- 1950
em[1,2] <- 1960

for(i in 1:55){
  
  em[i+1,1]<-d[i]+1 
  em[i+1,2]<-d[i]+11
  
}



em2<-em
em2<-cbind(em2,rep(0,56),rep(0,56))

for(y in 1:56){
  
  print(y)
  
  temp<- dmat2[dmat2$year>=em[y,1] & dmat2$year<=em[y,2],]
  temp2<- temp[,-c(1,6,12,13)]

  covmat<-matrix(NA,9,9)
  
  for(i in 1:9){
      for(j in 1:9){
        tmp<-data.frame(temp2[,i],temp2[,j])
        tmp<-tmp[complete.cases(tmp),]
        s1<-ccf(rank(tmp[,1]),rank(tmp[,2]),lag.max=0) 
        covmat[i,j]<-s1$acf[,,1]
      }
  }

  covmat[lower.tri(covmat)] <-NA
  diag(covmat) <- NA

em2[y,3] <-   mean(covmat,na.rm=T)
em2[y,4] <-   sd(covmat,na.rm=T)

}

colnames(em2)<-c("start","finish","mean","sd")

em3<-data.frame(em2)
em4<-melt(em3,id.vars=c("start","finish"))

ggplot(em4,aes(x=start,y=value))+
  # geom_smooth(aes(colour=variable),se=F)+
  # geom_smooth(aes(colour=variable),method="lm")+
  geom_line(aes(colour=variable))+
  theme_Publication()+
  facet_wrap(~variable,ncol=1)+
  xlab("year")+
  ylab("")+
  scale_x_continuous(breaks=bk)
  


sstat<- subset(em4,variable=="mean")
sstat$period<-c(rep("historic_pre1995",44),rep("recent_post1994",12))
res<-tapply(sstat$value,list(sstat$period),mean)

(res[2]-res[1])/res[1]

##########################################
############Delta -estiamtes of states for each population's change
##########################################

#means
tempmat<-model$BUGSoutput$mean$delta
colnames(tempmat) <- colnames(Y) #<-seq(1,11,1)
temp2<-melt(tempmat)
colnames(temp2) <-c("time","site","delta")
#temp2$site<-as.numeric(temp2$site)
temp2$year<-years
temp2$year<-as.numeric(temp2$year)

# 
#add site names from df2
ggplot(temp2,aes(x=time,y=site,fill=delta))+
  geom_tile()+
  scale_fill_gradient2(low="red",high="dodgerblue")+
  theme_Publication()
# 



t3<-data.frame("delta"=tapply(temp2$delta,list(temp2$time),mean))
t3$year<-years
t3$year<-as.numeric(t3$year)
t3$site<-12
t3$max<-tapply(temp2$delta,list(temp2$time),max)
t3$min<-tapply(temp2$delta,list(temp2$time),min)
names(t3)<-c("delta","year","site","max","min")

# dts<-ts(c(t3$delta),start=1950,end=2015,frequency=1)
# mppt<-cpt.mean(dts,method="PELT")
# cpts(mppt)
# plot(mppt)


# t3max<-t3[,c(2,3,5)]  
# names(t3max)<-c("year","site","delta")
# t3min<-t3[,c(2,3,4)]  
# names(t3min)<-c("year","site","delta")
# bk<-seq(1950,2015,by=10)

dp<-ggplot()+
  geom_ribbon(data=t3,aes(x=year,ymin=min,ymax=max),colour="grey60")+
  geom_line(data=temp2,aes(x=year,y=delta,colour=factor(site),lty=factor(site),group=site))+
  geom_line(data=t3,aes(x=year,y=delta),colour="white",size=2)+
  geom_hline(yintercept=0)+
  #geom_line(data=t3,aes(x=year,y=max))+
  #geom_line(data=t3,aes(x=year,y=min))+
  #scale_colour_continuous(low="green",high="red")+
  geom_vline(xintercept=1967,colour="grey",lty=2)+ #this is the closure of the reduction 
  geom_vline(xintercept=1994,colour="grey",lty=2)+ #this is the big recent closure 
  theme_Publication()+
  scale_x_continuous(breaks=bk)+
  xlab("Year")+
  ylab("Detrended Population Performance (Delta)")+
  scale_colour_Publication()
  
print(dp)


#Categorical 

t3$ybin<-c(rep("1Early",18),rep("2After First Closure",27),rep("3After Second Closure",21))

ga<-ggplot(t3,aes(x=ybin,y=delta))+
  stat_summary(fun.data = "mean_sdl", geom = "pointrange",
               colour = "grey60", size = 1) +
  geom_point()+
  geom_hline(yintercept=0)

print(ga)

ggplot_build(ga)



#add pre and post collapse analysis boxplot

temp2$ybin<-c(rep("1Early",18),rep("2After First Closure",27),rep("3After Second Closure",21))

tapply(temp2$delta,list(temp2$ybin),var)


ggplot(temp2,aes(x=ybin,y=delta,colour=site,group=site))+
  stat_summary(fun.data = "mean_sdl", geom = "pointrange",
               size = 1) +
  # stat_summary(fun.data=median_hilow,lty=2)+
  # stat_summary(fun.data=median_hilow,conf.int=0.5)+
  theme_Publication()+
  # scale_y_continuous(limits=c(-1,3),breaks=seq(-1,3,1))+
  ylab("Detrended Population Performance (Delta)")

#just means
# t5<-melt(tapply(temp2$delta,list(temp2$ybin,temp2$site),mean))
# t5$ymax<-melt(tapply(temp2$delta,list(temp2$ybin,temp2$site),mean))[,'value']+melt(tapply(temp2$delta,list(temp2$ybin,temp2$site),sd))[,'value']
# t5$ymin<-melt(tapply(temp2$delta,list(temp2$ybin,temp2$site),mean))[,'value']-melt(tapply(temp2$delta,list(temp2$ybin,temp2$site),sd))[,'value']
# 
# grandmean<-ggplot_build(ga)$data[[1]]
# 
# ggplot(t5,aes(x=Var1,y=value,group=Var2,colour=Var2,ymin=ymin,ymax=ymax,fill=Var2))+
#   #geom_line(position=position_jitter(w=0.02, h=0))+
#   geom_point(position=position_jitter(w=0.02, h=0))+
#   geom_linerange(position=position_jitter(w=0.02, h=0))+
#   geom_hline(data=grandmean,aes(yintercept=y))+  
#   #   geom_ribbon(alpha=0.2)+
#   theme_acs()+
#   theme(legend.position="none")


#define boom and bust years

#whole stock
t3$boom<-ifelse(t3$delta>0,1,0)
t3$bust<-ifelse(t3$delta<0,1,0)

tapply(t3$boom,list(t3$ybin),sum)/tapply(t3$boom,list(t3$ybin),length)
tapply(t3$bust,list(t3$ybin),sum)/tapply(t3$boom,list(t3$ybin),length)



temp2$boom<-ifelse(temp2$delta>0,1,0)
temp2$bust<-ifelse(temp2$delta<0,1,0)

tapply(temp2$boom,list(temp2$ybin,temp2$site),sum)/tapply(temp2$boom,list(temp2$ybin,temp2$site),length)
tapply(temp2$bust,list(temp2$ybin,temp2$site),sum)/tapply(temp2$boom,list(temp2$ybin,temp2$site),length)



#######################################################
#look at mean CCF by estimated biomass 

dmat<-data.frame(model$BUGSoutput$mean$delta)
colnames(dmat)<-colnames(Y)
dmat$year<-seq(1950,2015,by=1)


d <- seq(1950,2015,by=1)

em<- matrix(0,ncol=2,nrow=56) 
em[1,1] <- 1950
em[1,2] <- 1960

for(i in 1:55){
  
  em[i+1,1]<-d[i]+1 
  em[i+1,2]<-d[i]+11
  
}



em2<-em
em2<-cbind(em2,rep(0,56),rep(0,56))

for(y in 1:56){
  
  print(y)
  
  temp<- dmat[dmat$year>=em[y,1] & dmat$year<=em[y,2],]
  temp2<- temp[,-c(1,6,12)]
  
  covmat<-matrix(NA,9,9)
  
  for(i in 1:9){
    for(j in 1:9){
      tmp<-data.frame(temp2[,i],temp2[,j])
      tmp<-tmp[complete.cases(tmp),]
      s1<-ccf(rank(tmp[,1]),rank(tmp[,2]),lag.max=0) 
      covmat[i,j]<-s1$acf[,,1]
    }
  }
  
  covmat[lower.tri(covmat)] <-NA
  diag(covmat) <- NA
  
  em2[y,3] <-   mean(covmat,na.rm=T)
  em2[y,4] <-   sd(covmat,na.rm=T)
  
}

colnames(em2)<-c("start","finish","mean","sd")

em3<-data.frame(em2)
em4<-melt(em3,id.vars=c("start","finish"))

ggplot(em4,aes(x=start,y=value))+
  # geom_smooth(aes(colour=variable),se=F)+
  # geom_smooth(aes(colour=variable),method="lm")+
  geom_line(aes(colour=variable))+
  theme_acs()+
  facet_wrap(~variable,ncol=1)+
  xlab("year")+
  ylab("")+
  scale_x_continuous(breaks=bk)



#######################################################
#Portfolio Effect in a few different ways
#######################################################

#sum estimated across all stocklets

tempmat<-model$BUGSoutput$mean$X
colnames(tempmat)<-colnames(Y)
tempmat<-data.frame(exp(tempmat))
tempmat<-tempmat[,-c(1,6)]
tempmat$year<- 1950:2015
tempmat<-melt(tempmat,id.vars=c("year"))
names(tempmat)<- c("year","site","biomass")

archbiomass <- tapply(tempmat$biomass,list(tempmat$year),sum)


#way 1 - estimate the cross correlation of the subpopulation biomass through time (Xi)

xmat<-data.frame(model$BUGSoutput$mean$X)
colnames(xmat)<-colnames(Y)
xmat$year<-seq(1950,2015,by=1)

#make a matrix with 10 year windows 
yearstring <- seq(1950,2015,by=1)

em<- matrix(0,ncol=2,nrow=56) 
em[1,1] <- 1950
em[1,2] <- 1960

for(i in 1:55){
  
  em[i+1,1]<-yearstring[i]+1 
  em[i+1,2]<-yearstring[i]+11
  
}

em2<-em
em2<-cbind(em2,rep(0,56),rep(0,56))

#loop through each 10 year window estimate the average cross correlation 
for(y in 1:56){
  
  print(y)
  
  temp<- xmat[xmat$year>=em[y,1] & xmat$year<=em[y,2],] #pull out years of interest
  temp2<- temp[,-c(1,6,12)] #subtract naden and tasu and year column
  
  covmat<-matrix(NA,9,9)
  
  for(i in 1:9){
    for(j in 1:9){
      tmp<-data.frame(temp2[,i],temp2[,j])
      tmp<-tmp[complete.cases(tmp),]
      s1<-ccf(rank(tmp[,1]),rank(tmp[,2]),lag.max=0) 
      covmat[i,j]<-s1$acf[,,1]
    }
  }
  
  covmat[lower.tri(covmat)] <-NA
  diag(covmat) <- NA
  
  em2[y,3] <-   mean(covmat,na.rm=T)
  em2[y,4] <-   sd(covmat,na.rm=T)
  
}

colnames(em2)<-c("start","finish","mean","sd")

em3<-data.frame(em2)
em4<-melt(em3,id.vars=c("start","finish"))

ggplot(em4,aes(x=start,y=value))+
  # geom_smooth(aes(colour=variable),se=F)+
  # geom_smooth(aes(colour=variable),method="lm")+
  geom_line(aes(colour=variable))+
  # theme_acs()+
  facet_wrap(~variable,ncol=1)+
  xlab("year")+
  ylab("Cross Correlation of Estimated Biomass 10yr mving window")+
  scale_x_continuous(breaks=bk)



#way 2 & way 3 - estimate how ratio of  archipelago CV to stocklet CV changes through time
#also estimate mean-variance andersen approach 

#load Andersen Package

install.packages("synchrony")
library ("synchrony")

install.packages("ecofolio")
library ("ecofolio")

install.packages(c("plyr", "reshape", "MuMIn", "robustbase", "devtools"))
devtools::install_github("ecofolio", username="seananderson")

library(ecofolio)
vignette("ecofolio")
help(package = "ecofolio")

xmat<-exp(data.frame(model$BUGSoutput$mean$X)) #raw biomass
colnames(xmat)<-colnames(Y)
xmat$year<-seq(1950,2015,by=1)
xmat<-xmat[,-c(1,6)]

xmatlong<-melt(xmat,id.vars="year")
ggplot(xmatlong, aes(year, value, colour = variable)) + geom_line()
fit_taylor(xmat[,-12])
plot_mv(xmat[,-12], show = "linear", ci = TRUE)

pe_mv(xmat[,-12], ci = TRUE)

pe_avg_cv(xmat[,-12], ci = TRUE, boot_reps = 500)

pe_mv(xmat[,-12], type = "linear_robust")

pe_mv(xmat[,-12], type = "quadratic")

##### loop through 10 year moving window analaysis 

xmat<-exp(data.frame(model$BUGSoutput$mean$X)) #raw biomass
colnames(xmat)<-colnames(Y)
xmat$year<-seq(1950,2015,by=1)

#make a matrix with 10 year windows 
yearstring <- seq(1950,2015,by=1)

em<- matrix(0,ncol=2,nrow=56) 
em[1,1] <- 1950
em[1,2] <- 1960

for(i in 1:55){
  
  em[i+1,1]<-yearstring[i]+1 
  em[i+1,2]<-yearstring[i]+11
  
}


em2<-em
em2<-cbind(em2,rep(0,56),rep(0,56),rep(0,56))
cvvec<-rep(0,9)

for(y in 1:56){
  
  print(y)
  
  temp<- xmat[xmat$year>=em[y,1] & xmat$year<=em[y,2],]
  temp2<- temp[,-c(1,6,12)] #subtract tasu, naden, and year column
  cvvec<-rep(0,9)
  
  for(i in 1:9){
    cvvec[i] <- sd(temp2[,i])/mean(temp2[,i]) #cv for each subpop for this subset of time
  }
  
  em2[y,3] <- mean(cvvec) #average cv of subpopulations for that subset of time 
  em2[y,4] <- sd(rowSums(temp2))/mean(rowSums(temp2)) #cv of total archipelago population for that subset of time
  em2[y,5] <- pe_mv(temp2) #throwing weird error here, i think an indexing thing 
}


ratio<- em2
ratio<-data.frame(ratio)
colnames(ratio)<-c("start","finish","subCV","archCV","anders_mv")
ratio$ratio<-ratio$subCV/ratio$archCV


plot(ratio$start,ratio$ratio,type="l",xlab="Start of 10 yr moving window date",ylab="ratio of subpopCV to arch CV")
plot(ratio$start,ratio$anders_mv,type="l",xlab="Start of 10 yr moving window date",ylab="Anderson mean-variance metric")

####### Generally archipelago CV is lower than sub population 
em3<- em2[,-5]
em4<-melt(em3,id.vars=c("start","finish"))


#plot out the different subpopulation and archipelago
ggplot(em4,aes(x=start,y=value))+
  geom_line(aes(colour=variable))+
  xlab("year")+
  ylab("CV")+
  scale_x_continuous(breaks=bk)+
  theme_Publication()

plot(ratio$start,ratio$ratio,type="l")


#way 4 - use metrics described in  Loreau and de Mazancourt (2008) using  using the “synchrony” package in R (Gouhier and Guichard 2014).

###haven't done this yet check Siple et al. and Gouhir and G for details and code. 

#######################################################
##way 5 - look at how CCF of delta changed through time 
#####################

dmat<-data.frame(model$BUGSoutput$mean$delta)
colnames(dmat)<-colnames(Y)
dmat$year<-seq(1950,2015,by=1)


d <- seq(1950,2015,by=1)

em<- matrix(0,ncol=2,nrow=56) 
em[1,1] <- 1950
em[1,2] <- 1960

for(i in 1:55){
  
  em[i+1,1]<-d[i]+1 
  em[i+1,2]<-d[i]+11
  
}



em2<-em
em2<-cbind(em2,rep(0,56),rep(0,56))

for(y in 1:56){
  
  print(y)
  
  temp<- dmat[dmat$year>=em[y,1] & dmat$year<=em[y,2],]
  temp2<- temp[,-c(1,6,12)] #remove tasu and naden 
  
  covmat<-matrix(NA,9,9)
  
  for(i in 1:9){
    for(j in 1:9){
      tmp<-data.frame(temp2[,i],temp2[,j])
      tmp<-tmp[complete.cases(tmp),]
      s1<-ccf(rank(tmp[,1]),rank(tmp[,2]),lag.max=0) 
      covmat[i,j]<-s1$acf[,,1]
    }
  }
  
  covmat[lower.tri(covmat)] <-NA
  diag(covmat) <- NA
  
  em2[y,3] <-   mean(covmat,na.rm=T)
  em2[y,4] <-   sd(covmat,na.rm=T)
  
}

colnames(em2)<-c("start","finish","mean","sd")

em3<-data.frame(em2)
em4<-melt(em3,id.vars=c("start","finish"))

ggplot(em4,aes(x=start,y=value))+
  # geom_smooth(aes(colour=variable),se=F)+
  # geom_smooth(aes(colour=variable),method="lm")+
  geom_line(aes(colour=variable))+
  facet_wrap(~variable,ncol=1)+
  xlab("year")+
  ylab("mean CCF of delta ")+
  scale_x_continuous(breaks=bk)+
  theme_Publication()




#######################################################
##way 6 - look at how CCF of relized pop growth rate (delta+umu+pdo) changed through time 
#####################

dmat<-data.frame(model$BUGSoutput$mean$delta)
dmat<-data.frame(dmat+median(Umudf$value)+pdodf$medianci)

colnames(dmat)<-colnames(Y)
dmat$year<-seq(1950,2015,by=1)


d <- seq(1950,2015,by=1)

em<- matrix(0,ncol=2,nrow=56) 
em[1,1] <- 1950
em[1,2] <- 1960

for(i in 1:55){
  
  em[i+1,1]<-d[i]+1 
  em[i+1,2]<-d[i]+11
  
}


em2<-em
em2<-cbind(em2,rep(0,56),rep(0,56))

for(y in 1:56){
  
  print(y)
  
  temp<- dmat[dmat$year>=em[y,1] & dmat$year<=em[y,2],]
  temp2<- temp[,-c(1,6,12)] #remove tasu and naden 
  
  covmat<-matrix(NA,9,9)
  
  for(i in 1:9){
    for(j in 1:9){
      tmp<-data.frame(temp2[,i],temp2[,j])
      tmp<-tmp[complete.cases(tmp),]
      s1<-ccf(rank(tmp[,1]),rank(tmp[,2]),lag.max=0) 
      covmat[i,j]<-s1$acf[,,1]
    }
  }
  
  covmat[lower.tri(covmat)] <-NA
  diag(covmat) <- NA
  
  em2[y,3] <-   mean(covmat,na.rm=T)
  em2[y,4] <-   sd(covmat,na.rm=T)
  
}

colnames(em2)<-c("start","finish","mean","sd")

em3<-data.frame(em2)
em4<-melt(em3,id.vars=c("start","finish"))

ggplot(em4,aes(x=start,y=value))+
  # geom_smooth(aes(colour=variable),se=F)+
  # geom_smooth(aes(colour=variable),method="lm")+
  geom_line(aes(colour=variable))+
  facet_wrap(~variable,ncol=1)+
  xlab("year")+
  ylab("mean CCF of realized population growth (delta+umu+pdoeff) ")+
  scale_x_continuous(breaks=bk)+
  theme_Publication()


#######################################################
#look at mean CCF by estimated biomass 

xmat<-data.frame(model$BUGSoutput$mean$X)
colnames(xmat)<-colnames(Y)
xmat$year<-seq(1950,2015,by=1)


d <- seq(1950,2015,by=1)

em<- matrix(0,ncol=2,nrow=56) 
em[1,1] <- 1950
em[1,2] <- 1960

for(i in 1:55){
  
  em[i+1,1]<-d[i]+1 
  em[i+1,2]<-d[i]+11
  
}



em2<-em
em2<-cbind(em2,rep(0,56),rep(0,56))

for(y in 1:56){
  
  print(y)
  
  temp<- xmat[xmat$year>=em[y,1] & xmat$year<=em[y,2],]
  temp2<- temp[,-c(1,6,12)]
  
  covmat<-matrix(NA,9,9)
  
  for(i in 1:9){
    for(j in 1:9){
      tmp<-data.frame(temp2[,i],temp2[,j])
      tmp<-tmp[complete.cases(tmp),]
      s1<-ccf(rank(tmp[,1]),rank(tmp[,2]),lag.max=0) 
      covmat[i,j]<-s1$acf[,,1]
    }
  }
  
  covmat[lower.tri(covmat)] <-NA
  diag(covmat) <- NA
  
  em2[y,3] <-   mean(covmat,na.rm=T)
  em2[y,4] <-   sd(covmat,na.rm=T)
  
}

colnames(em2)<-c("start","finish","mean","sd")

em3<-data.frame(em2)
em4<-melt(em3,id.vars=c("start","finish"))

ggplot(em4,aes(x=start,y=value))+
  # geom_smooth(aes(colour=variable),se=F)+
  # geom_smooth(aes(colour=variable),method="lm")+
  geom_line(aes(colour=variable))+
  facet_wrap(~variable,ncol=1)+
  xlab("year")+
  ylab("")+
  scale_x_continuous(breaks=bk)+
  theme_Publication()


#######################################################

# 
# #######CCF Of Deltas. i.e. how similar are populations through all time series and then a subset. 
# ##############################################################################################################################
# #Covariance of Deltas 
# ##############################################################################################################################
# dmat<-model$BUGSoutput$mean$delta
# 
# #late 1967-1971 closed, 4 years later roe fishery began 
# #2005 through 2013 closed 
# #1983 20% harvest rate policy 
# #1994 closure and onward no more than 3000 taken (but 1999 3000 taken in 1999)
# 
# colnames(dmat)<-colnames(Y)
# 
# 
# covmat_a<-matrix(NA,nSites,nSites)
# covmat65<-matrix(NA,nSites,nSites)
# covmat94<-matrix(NA,nSites,nSites)
# covmat13<-matrix(NA,nSites,nSites)
# 
# #lag0
# for(i in 1:11){
#   for(j in 1:11){
#     tmp<-data.frame(dmat[,i],dmat[,j])
#     tmp<-tmp[complete.cases(tmp),]
#     s1<-ccf(rank(tmp[,1]),rank(tmp[,2]),lag.max=0) #i'm removing the rank argumen there because we're interested in absolute CCF channging in difft periods
#     covmat_a[i,j]<-s1$acf[,,1]
#     
#     tmp65<-data.frame(dmat[1:16,i],dmat[1:16,j])
#     tmp65<-tmp65[complete.cases(tmp65),]
#     s1<-ccf(rank(tmp65[,1]),rank(tmp65[,2]),lag.max=0) #i'm removing the rank argumen there because we're interested in absolute CCF channging in difft periods
#     covmat65[i,j]<-s1$acf[,,1]   
#     
#     tmp94<-data.frame(dmat[17:45,i],dmat[17:45,j])
#     tmp94<-tmp94[complete.cases(tmp94),]
#     s1<-ccf(rank(tmp94[,1]),rank(tmp94[,2]),lag.max=0) #i'm removing the rank argumen there because we're interested in absolute CCF channging in difft periods
#     covmat94[i,j]<-s1$acf[,,1]    
#     
#     tmp13<-data.frame(dmat[46:64,i],dmat[46:64,j])
#     tmp13<-tmp94[complete.cases(tmp13),]
#     s1<-ccf(rank(tmp13[,1]),rank(tmp13[,2]),lag.max=0) #i'm removing the rank argumen there because we're interested in absolute CCF channging in difft periods
#     covmat13[i,j]<-s1$acf[,,1]    
#     
#   }
# }
# 
# covmat_a[lower.tri(covmat_a)] <-NA
# diag(covmat_a) <- NA
# 
# covmat65[lower.tri(covmat65)] <-NA
# diag(covmat65) <- NA
# 
# covmat94[lower.tri(covmat94)]<-NA
# diag(covmat94)<-NA
# 
# covmat13[lower.tri(covmat13)]<-NA
# diag(covmat13)<-NA
# 
# colnames(covmat_a)<-colnames(Y_car)
# rownames(covmat_a)<-colnames(Y_car)
# colnames(covmat65)<-colnames(Y_car)
# rownames(covmat65)<-colnames(Y_car)
# colnames(covmat94)<-colnames(Y_car)
# rownames(covmat94)<-colnames(Y_car)
# colnames(covmat13)<-colnames(Y_car)
# rownames(covmat13)<-colnames(Y_car)
# 
# 
# cdf<-melt(covmat_a)
# cdf65<-melt(covmat65)
# cdf94<-melt(covmat94)
# cdf13<-melt(covmat13)
# 
# 
# #plot all covmats 
# ggdh<-ggplot(cdf,aes(x=value,fill=..x..))+
#   geom_histogram(colour="black")+
#   geom_vline(xintercept=0,lty=2)+
#   scale_x_continuous(limits=c(-1,1))+
#   scale_fill_gradient2(low="dodgerblue",high="firebrick")+
#   ylab("Covariance of Deltas")+
#   theme_acs()
# 
# print(ggdh)
# 
# # ggsave("Delta_Covariance_Histogram_allyears.pdf",ggdh)
# 
# 
# #All different groups
# ggcctile<-ggplot(cdf,aes(x=Var1,y=Var2,fill=value,colour=value))+
#   geom_tile()+
#   scale_fill_gradient2(low="dodgerblue",high="firebrick")+
#   scale_colour_gradient2(low="dodgerblue",high="firebrick")+
#   theme_acs()+
#   theme(axis.text.x = element_text(angle = 45, hjust = 1),
#         legend.position="top")+
#   xlab("")+
#   ylab("")
# 
# print(ggcctile)
# 
# # ggsave("Delta_Covariance_Tile_allyears.pdf",ggcctile)
# 
# #combine and look at shift in distribution of covariance matrices
# mdist<-data.frame("value"=tapply(cdf_comp2$value,list(cdf_comp2$variable),mean,na.rm=T),"variable"=unique(cdf_comp2$variable))
# 
# cdf_comp<-data.frame(cdf,cdf65$value,cdf94$value,cdf13$value)
# colnames(cdf_comp)<-c("Site1","Site2","all","a1950to1965","b1966to1994","c1995to213")
# cdf_comp2<-melt(cdf_comp,id.vars=c("Site1","Site2"))
# 
# ggdcdf<-ggplot(cdf_comp2,aes(x=value,fill=..x..))+
#   geom_vline(data=mdist,aes(xintercept=value))+
#   geom_vline(xintercept=0,lty=2)+
#   geom_histogram(colour="black")+
#   scale_x_continuous(limits=c(-1,1))+
#   scale_fill_gradient2(low="dodgerblue",high="firebrick")+
#   ylab("Temporal Covariance of Deltas")+
#   theme_acs()+
#   facet_grid(variable~.)+
#   xlab("Cross Correlation of Time Series")
# 
# 
# print(ggdcdf)
# # ggsave("Delta_CCF_Time_Periods.pdf",ggdcdf)
# 
# 
# ggcctile<-ggplot(cdf_comp2,aes(x=Site1,y=Site2,fill=value,colour=value))+
#   geom_tile()+
#   scale_fill_gradient2(low="dodgerblue",high="firebrick")+
#   scale_colour_gradient2(low="dodgerblue",high="firebrick")+
#   theme_acs()+
#   theme(axis.text.x = element_text(angle = 45, hjust = 1),
#         legend.position="top")+
#   xlab("")+
#   ylab("")+
#   facet_grid(variable~.)
# 
# print(ggcctile)
# 
# # ggsave("delta_tile_by_time.pdf",ggcctile)
# 
# dbw<-ggplot(cdf_comp2,aes(x=variable,y=value))+
#   geom_boxplot()+
#   geom_point(aes(x=variable,y=value,colour=value))+
#   scale_colour_gradient2(low="dodgerblue",high="firebrick")+
#   theme_acs()+
#   xlab("Time Period")+
#   ylab("Temporal Covariance of Deltas")
# 
# print(dbw)


dev.off()


# ggsave("deltaBW_bytime.pdf",dbw)







# 
# 
# 
# 
# pcmat<-model$BUGSoutput$mean$Pc
# dmat<-model$BUGSoutput$mean$delta
# colnames(dmat)<-colnames(Y)
# 
# 
# pdo<-read.csv("pdo.csv")
# pdosummer<-subset(pdo,month %in% c(3,4,5,6)) #average april<-june
# pdoxb<-c(tapply(pdosummer$Value,list(pdosummer$year),mean))
# pdo2<-pdoxb[87:162] #1940-20135
# pdo3<-pdo2[11:76] #1950-2015
# 
# hist(pdocoef)
# 
# distpdoci<-smedian.hilow(pdocoef,conf.int=0.95)
# distpdoiqr<-smedian.hilow(pdocoef,conf.int=0.5)
# 
# pdodf<-data.frame("pdo"=pdo3,
#                   "medianci"=distpdoci[1]*pdo3,
#                   "maxci"=distpdoci[3]*pdo3,
#                   "minci"=distpdoci[2]*pdo3,
#                   "maxiqr"=distpdoiqr[3]*pdo3,
#                   "miniqr"=distpdoiqr[2]*pdo3
# )
# 
# 
# dtotal<-c()
# for(i in 1:nrow(dmat)){
#   t<-dmat[i,]
#   dtotal[i]<-median(t)
# }
# 
# 
# median(U)
# 
# compdf<-data.frame("Umu_delta"=exp(dtotal+model$BUGSoutput$mean$Umu),
#                    "Umu_pdo"=exp(pdodf$medianci+model$BUGSoutput$mean$Umu),
#                    "Umu_delta_pdo"=exp(c(dtotal+pdodf$medianci+model$BUGSoutput$mean$Umu)),
#                    "pdoeff" = exp(pdodf$medianci),
#                    "year"=years)
# 
# 
# 
# 
# 
# 
# # 
# # 
# #JS's Version
# # compdf2<-melt(compdf,id.vars=c("year"))
# # compdf3<-subset(compdf2,variable!="pdoeff")
# # ggplot(compdf3,aes(x=year,y=value))+
# #   geom_line(aes(colour=variable))+
# #   geom_hline(yintercept=exp(model$BUGSoutput$mean$Umu),colour="grey")+
# #   geom_hline(yintercept=c(1),lty=2)+
# #   theme_acs()+
# #   ylab("Population Growth Rate")+
# #   ggtitle("Archipelago Scale")
# # # 
# # 
# # 
# ###
# #Stocklet Scale Relative Contribution
# ###
# 
# 
# dmat<-model$BUGSoutput$mean$delta
# colnames(dmat)<-colnames(Y)
# pdos<-pdodf$medianci
# 
# umupdo<-matrix(0,nrow=nrow(dmat),ncol=ncol(dmat))
# umudelta<-matrix(0,nrow=nrow(dmat),ncol=ncol(dmat))
# umudeltapdo<-matrix(0,nrow=nrow(dmat),ncol=ncol(dmat))
# pdoeff<-matrix(0,nrow=nrow(dmat),ncol=ncol(dmat))
# 
# colnames(umupdo)=colnames(Y)
# colnames(umudelta)=colnames(Y)
# colnames(umudeltapdo)=colnames(Y)
# colnames(pdoeff)=colnames(Y)
# 
# for(i in 1:ncol(dmat)){
# 
#   umupdo[,i]<-exp(pdos+ustring[i])
#   umudelta[,i]<-exp(dmat[,i]+ustring[i])
#   umudeltapdo[,i]<-exp(dmat[,i]+pdos+ustring[i])
#   pdoeff[,i]<-exp(pdos)
# 
# }
# 
# dt<-rbind(umupdo,umudelta,umudeltapdo,pdoeff)
# dt<-data.frame(dt)
# names(dt)<-colnames(dmat)
# dt$type<-c(rep("umupdo",nrow(dmat)),
#            rep("umudelta",nrow(dmat)),
#            rep("umudeltapdo",
#                nrow(dmat)),rep("pdoeff",nrow(dmat))
#            )
# 
# dt$year<-rep(1950:2015,4)
# dt2<-melt(dt,id.vars=c("type","year"))
# 
# #print into single PDF
# 
# #js additive approach- stocklet
# pdf(paste("Climate_ProcessVar_ShiftinTime",Sys.Date(),".pdf"), width=12,onefile = TRUE)
# 
# dt2b<-subset(dt2,type!="pdoeff")
# ggplot(dt2b,aes(x=year,y=value))+
#   geom_line(aes(colour=type))+
#   geom_hline(yintercept=1,colour="grey")+
#   theme_acs()+
#   facet_wrap(~variable,scales="free")+
#   scale_colour_discrete(name="Pop Growth",
#                    labels=c("Ui+delta", "Ui+delta+pdoeff", "Ui+pdoeff"))+
#   ggtitle("Pop Growth by Stocklet")+
#   ylab("Population Growth Rate")
# # 
# 
# #DOTPLOT WHERE GREY LINE IS Pos or Neg GROWTH
# 
# dt3<-subset(dt2,type %in% c("umudelta","umudeltapdo"))
# 
# 
# ggplot(dt3,aes(x=year,y=value))+
#   #geom_line(aes(colour=type))+
#   geom_point(aes(colour=type))+
#   geom_line(aes(group = year))+
#   geom_hline(yintercept=1,colour="grey")+
#   theme_acs()+
#   facet_wrap(~variable,scales="free")+
#   scale_colour_discrete(name="Pop Growth",
#                         labels=c("Ui+delta", "Ui+delta+pdoeff"))+
#   ggtitle("Pop Growth by Stocklet")+
#   ylab("Population Growth Rate")
# 
# #just recent years
# dt4<-subset(dt3,year>1995)
# 
# ggplot(dt4,aes(x=year,y=value))+
#   #geom_line(aes(colour=type))+
#   geom_point(aes(colour=type))+
#   geom_line(aes(group = year))+
#   geom_hline(yintercept=1,colour="grey")+
#   theme_acs()+
#   facet_wrap(~variable,scales="free")+
#   scale_colour_discrete(name="Pop Growth",
#                         labels=c("Ui+delta", "Ui+delta+pdoeff"))+
#   ggtitle("Recent Pop Growth by Stocklet  (1995-present)")+
#   ylab("Population Growth Rate")
# 
# 
# #just recent years
# dt5<-subset(dt3,year>1950 & year<1975)
# 
# ggplot(dt5,aes(x=year,y=value))+
#   #geom_line(aes(colour=type))+
#   geom_point(aes(colour=type))+
#   geom_line(aes(group = year))+
#   geom_hline(yintercept=1,colour="grey")+
#   theme_acs()+
#   facet_wrap(~variable,scales="free")+
#   scale_colour_discrete(name="Pop Growth",
#                         labels=c("Ui+delta", "Ui+delta+pdoeff"))+
#   ggtitle("Recent Pop Growth by Stocklet  (1950-1995)")+
#   ylab("Population Growth Rate")
# 
# sk<-subset(dt3,variable=="SHI.Skidegate Inlet")
# 
# sk2 <- reshape(sk, 
#              timevar = "type",
#              idvar = c("year"),
#              direction = "wide")
# 
# names(sk2)<-c("year","site","umudelta","site2","umudeltapdo")
# sk2$proppdo<-1-(sk2$umudelta/sk2$umudeltapdo)
# sk2$test<-(sk2$umudeltapdo-sk2$umudelta)
# 
# which(sk2$umudeltapdo >1 & sk2$umudelta<1)
# which(sk2$umudelta >1 & sk2$umudeltapdo<1)
# 
# #43,48, 49,51,52,58,59
# 
# 
# #biplot
# 
# #reshaps data to wide format
# dt5<-subset(dt2,type %in% c("umudelta","pdoeff"))
# 
# dtw <- reshape(dt5, 
#              timevar = "type",
#              idvar = c("year","variable"),
#              direction = "wide")
# 
# yf<-c(rep("50s",10),rep("60s",10),rep("70s",10),rep("80s",10),rep("90s",10),rep("00s",16))
# dtw$yf<-factor(yf)
# dtw$yf=factor(dtw$yf,levels=c("50s","60s","70s","80s","90s","00s"))
# dtw$year2<-right(dtw$year,2)
#   
# 
# ggplot(dtw,aes(x=value.pdoeff,y=value.umudelta,label=year2,group=yf))+
#   # geom_line(aes(x=value.pdoeff,y=value.umudelta,colour=yf))+
#   # geom_point(aes(colour=yf,pch=yf))+
#   geom_text(aes(colour=yf,size=1))+
#   geom_hline(yintercept=c(1),colour="grey",lty=2)+
#   geom_vline(xintercept=c(1),colour="grey",lty=2)+
#   theme_acs()+
#   facet_wrap(~variable,scales="free")+
#   scale_colour_discrete(name="Decade")+
#   ggtitle("Decadal Impacts of Climate")+
#   ylab("Population Growth From PDO")+
#   xlab("Pop Growth without PDO")
# 
# # 
# # dt6<-melt(dtw,id.vars=c("year","variable","yf"))
# # colnames(dt6)<-c("year","site","yf","type","value")
# # ggplot(dt6,aes(x=yf,y=value,colour=type))+
# #     stat_summary(fun.data=mean_cl_normal,position=position_dodge(0.95),geom="linerange")+ 
# #     stat_summary(fun.y=mean,position=position_dodge(width=0.95),geom="point")+
# #   geom_hline(yintercept=c(1),colour="grey",lty=2)+
# #   theme_acs()+
# #   facet_wrap(~site,scales="free")
# 
# #average out and look at two time periods in barplot doesn't help much
# 
# dt3$bin<-ifelse(dt3$year<1995,"1950-1994","2001-2015")
# dt3b<-subset(dt3,type=="umudeltapdo")
# 
# ggplot(dt3b,aes(x=bin,y=value))+
#   stat_summary(fun.data=mean_cl_normal,position=position_dodge(0.95),geom="linerange")+ 
#   stat_summary(fun.y=mean,position=position_dodge(width=0.95),geom="point")+
#   theme_acs()+
#   facet_wrap(~variable,scales="free")+
#   geom_hline(yintercept=1,colour="grey")+
#   xlab("Time Period")+
#   ylab("Realized Growth Rate")+
#   ggtitle("Stocklet Specific Realized Growth Historically and Recently")
#   
# 
# dev.off()
# 
# 
# 
# 
# 
# 
# 
# 
# 
# stat_sum_df <- function(fun, geom="crossbar", ...) {
#   stat_summary(fun.data=fun, colour="red", geom=geom, width=0.2, ...)
# }
# 
# stat_sum_single <- function(fun, geom="point", ...) {
#   stat_summary(fun.y=fun, geom=geom, size = 1, ...)
# }
# 
# ggplot(dt3b,aes(x=bin,y=value,group=variable))+
#   stat_summary(fun.data=mean_cl_normal,position=position_dodge(0.95),geom="linerange")+ 
#   stat_summary(fun.y=mean,position=position_dodge(width=0.95),geom="point")+
#   stat_sum_single(mean, geom="line")+
#   theme_acs()+
#   facet_wrap(~variable,scales="free")+
#   geom_hline(yintercept=1,colour="grey")+
#   xlab("Time Period")+
#   ylab("Realized Growth Rate")+
#   ggtitle("Stocklet Specific Realized Growth Historically and Recently")
# 
# 
# ggplot(dt3b,aes(x=bin,y=value,group=variable))+
#   stat_summary(fun.data=mean_cl_normal,position=position_dodge(0.95),geom="linerange")+ 
#   stat_summary(fun.y=mean,position=position_dodge(width=0.95),geom="point")+
#   stat_sum_single(mean, geom="line")+
#   theme_acs()+
#   facet_wrap(~variable,scales="free")+
#   geom_hline(yintercept=1,colour="grey")+
#   xlab("Time Period")+
#   ylab("Realized Growth Rate")+
#   ggtitle("Stocklet Specific Realized Growth Historically and Recently")
# 
# ###Stocklets interaction plot
# 
# ggplot(dt3b,aes(x=bin,y=value,group=variable,colour=variable,lty=variable))+
#   #stat_summary(fun.data=mean_cl_normal,geom="linerange")+ 
#   #stat_summary(fun.y=mean,geom="point")+
#   stat_sum_single(mean, geom="line")+
#   theme_acs()+
#   # theme(legend.position="none")+
#   #facet_wrap(~variable,scales="free")+
#   geom_hline(yintercept=1,colour="grey")+
#   xlab("Time Period")+
#   ylab("Realized Growth Rate")
# 


