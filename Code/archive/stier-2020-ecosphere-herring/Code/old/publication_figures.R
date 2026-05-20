#Turn Model Output into Maps
library(ggplot2)
library(reshape2)
library(gdata)
library(maps)
library(mapproj)
library(ggmap)
library(spatstat)
library(ape)
library(bbmle)
library(hotspots)
library(coda)
library(scales)
library(gridExtra)
library(Hmisc)
library(changepoint)

##########################################################################
###Upload Data 
##########################################################################

setwd("~/Dropbox/Projects/In Progress/Herring_Haida_Gwaii/Code")

x=read.csv("HG_Spawn_Survey_1940_2013b.csv") #spawn data
c <- read.csv("herring_catch_local.csv") #catch data

load("diagonal_equal_design_c_DDspatial_noUsig_no_eta.Rdata")
source('theme_acs.R')
source('multiplot.R')

##########################################################################
###Upload Functions 
##########################################################################

#string modifier
right = function (string, char){
  substr(string,nchar(string)-(char-1),nchar(string))
}



#write geometric mean function
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

#function for getting sigfigs on y axis right
fmt <- function(){
  function(x) format(x,nsmall = 2,scientific = FALSE)
}


#organize mcmc output 
createMcmcList = function(model) {
  McmcArray = as.array(model$BUGSoutput$sims.array)
  McmcList = vector("list",length=dim(McmcArray)[2])
  for(i in 1:length(McmcList)) McmcList[[i]] = as.mcmc(McmcArray[,i,])
  McmcList = mcmc.list(McmcList)
  return(McmcList)
}


##########################################################################
###Modify Data
##########################################################################

myList<-createMcmcList(model) #mcmc output 

#modify spawn data 
x<- x[c(1,3,13,14,15,16)]
x$SHI2<-log(x$SHI+1)
x$presabs <-ifelse(x$SHI>0,1,0)

years = seq(1950,2015)
nYears = length(years)
nSites = 11

x2 <- x[,c(1,2,4)]
w <- reshape(x2, 
             timevar = "section_name",
             idvar = c("year"),
             direction = "wide")[,-1]

#replace zeros with NAs
w[w==0] <- NA

#double check that it has time ont he rows and sites on the column
Y= as.matrix(w)
Y2<-Y

#subset out Cartwright Sound (4)-no catch data, Masset (7) four data points
Y = Y[-c(1:10),-c(4,7)] #drop site 4 since we have no catch data for Cartwright

#Y = Y/0.5 #q coefficient to turn into biomass
Y = log(Y)


##############################################################################################################################
#####FOR CAR MODEL ONLY 

# 
x=read.csv("HG_Spawn_Survey_1940_2013b.csv")
x<- x[c(1,3,13,14,15,16)]
x$SHI2<-log(x$SHI+1)
x$presabs <-ifelse(x$SHI>0,1,0)

years = seq(1950,2013)
nYears = length(years)
nSites = 11

x2 <- x[,c(1,2,4)]
w <- reshape(x2, 
             timevar = "section_name",
             idvar = c("year"),
             direction = "wide")[,-1]

#replace zeros with NAs
w[w==0] <- NA

#double check that it has time ont he rows and sites on the column
Y= as.matrix(w)

#subset out Cartwright Sound (4)-no catch data
Y = Y[-c(1:10),-c(4)] #drop site 4 since we have no catch data for Cartwright, Masset because there are so few points

#Y = Y/0.5 #q coefficient to turn into biomass
Y = log(Y)

Y_car<- Y[,c(9,10,11,8,12,5,1,4,3,2,7,6)]
Y_car<-Y_car[,c(1:11)]#subset out Masset inslet - limited data 
##############################################################################################################################


#subset out Cartwright Sound (4)-no catch data
Y2<-Y2[-c(1:10),-c(4)] #drop site 4 since we have no catch data for Cartwright, Masset because there are so few points
Y2<-Y2[,c(9,10,11,8,12,5,1,4,3,2,7,6)]
Y2<-Y2[,c(1:11)]#subset out Massetxw inslet - limited data 

svec<-seq(1,nSites,by=1)

covmat<-matrix(NA,nSites,nSites)

#lag0
for(i in 1:11){
  for(j in 1:11){
    tmp<-data.frame(Y2[,i],Y2[,j])
    tmp<-tmp[complete.cases(tmp),]
    s1<-ccf(rank(tmp[,1]),rank(tmp[,2]),lag.max=0)
    covmat[i,j]<-s1$acf[,,1]
  }
}

covmat[lower.tri(covmat)] <-NA
diag(covmat) <- NA

colnames(covmat)<-colnames(Y2)
rownames(covmat)<-colnames(Y2)

cdf<-melt(covmat)
# cdf$Var1<-substr(cdf$Var1,5,28)
# cdf$Var2<-substr(cdf$Var2,5,28)


ggplot(cdf,aes(x=value,fill=..x..))+
  geom_histogram(colour="black")+
  geom_vline(xintercept=0,lty=2)+
  scale_x_continuous(limits=c(-1,1))+
  scale_fill_gradient2(low="dodgerblue",high="firebrick")+
  ylab("Covariance")+
  theme_acs()



#All different groups
ggplot(cdf,aes(x=Var1,y=Var2,fill=value,colour=value))+
  geom_tile()+
  scale_fill_gradient2(low="dodgerblue",high="firebrick")+
  scale_colour_gradient2(low="dodgerblue",high="firebrick")+
  theme_acs()+
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position="top")+
  xlab("")+
  ylab("")



#catch data
#namecheck<-data.frame("spawnindex"=unique(x[,c(3,4)])[-4,],"catch"=unique(c[,c(11,12)])[-c(13,14),])

#num unique sites
length(unique(c$Section))
#names of unique sites
unique(c$Name)

yr_c<-unique(c$Year)
c$presabs <-ifelse(c$TotalCatch>0,1,0)

#subset out Cartwright Sound (4)
c<-subset(c,Section %in% c(1,2,3,5,6,12,21,22,23,24,25))

#ctab<-data.frame(tapply(c$TotalCatch,list(c$Year,c$Section),sum)) #all catch
ctab<-data.frame(tapply(c$CatchJan_Apr,list(c$Year,c$Section),sum)) #just spring catch
ctab2<-ctab[-nrow(ctab),]

#double check column names
data.frame(colnames(Y),colnames(ctab2))

colnames(ctab2)<-colnames(Y)
ctab2<-as.matrix(ctab2)
ctab2_1<-log(ctab2+1)

#model details 
years = seq(1950,2013)
nYears = length(years)
nSites = 11

n.chains = 3
n.burnin=8000
n.thin=5
n.iter=10000

#number of recorded mcmc
runL <- n.chains*(n.iter-n.burnin)/n.thin

#load in site name and location 
st<-read.csv("sitemeta.csv")
st2<-st[-c(4,7),]

#labels for graph
sitelab2<-unique(x$section_name)[-c(4,7)]
md<-data.frame(st2,sitelab2)
md$altsite<-substr(colnames(Y_car),5,28)

##########################################################################
###Figure 1 While island Spawn, Map of HG, and 
##########################################################################



########################################################################
############ WHOLE ISLAND  numer of spawns, sum of spawn index
########################################################################
x<-subset(x,section %in% c(1,2,3,5,6,12,21,22,23,24,25))

#percent of years where there's been any spawn over past 75 years
#not accurate due to missing data 
100*round(tapply(x$presabs,list(x$section_name),sum)/
            tapply(x$presabs,list(x$section_name),length),2)

tapply(x$SHI,list(x$section_name),mean) #highest average SHI
tapply(x$SHI,list(x$section_name),sd) #most spawn sites

num<-melt(c(rowSums(tapply(x$presabs,list(x$year,x$section_name),sum),,na.rm=T)))
num<-data.frame("num"=num[,1],"year"=rownames(num))
num[,2]=as.numeric(as.character(num[,2]))
num$belowave<-ifelse(num$num<median(num$num),1,0)
sum(num$belowave)/length(num$belowave) 

#number spawn sites through time. #61% of years since 1950 sites have been below median number of spawn sites 

ss<-melt(c(rowSums(tapply(x$SHI,list(x$year,x$section_name),sum),,na.rm=T)))
ss<-data.frame("sum"=ss[,1],"year"=rownames(ss))
ss[,2]=as.numeric(as.character(ss[,2]))
shi_sum<-ss
shi_sum$belowave<-ifelse(shi_sum$sum>median(shi_sum$sum),0,1)
sum(shi_sum$belowave)/length(shi_sum$belowave) 

ctab3<-melt(ctab2)
ctab3$presabs<-ifelse(ctab3$value>0,1,0)
numc<-melt(tapply(ctab3$presabs,list(ctab3$Var1),sum))
names(numc)<-c("year","num")
numc$belowave<-ifelse(numc$num<median(numc$num),1,0)
sum(num$belowave)/length(num$belowave) 

sumc<-melt(tapply(ctab3$value,list(ctab3$Var1),sum))
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
shi_sum[-c(1:10),],
num[-c(1:10),])
bb$col<-c(rep("catch",128),rep("spawn",128))
bb$row<-c(rep("number",64),rep("sum",64),rep("sum",64),rep("number",64))
bb$both<-factor(paste(bb$col,bb$row))
bb$both=factor(bb$both,levels(bb$both)[c(4,2,3,1)])

bk<-seq(1950,2015,by=10)

ggplot(bb,aes(x=year,y=num))+
  geom_line(colour="grey")+
  geom_point(aes(colour=factor(belowave)))+
  #geom_hline(yintercept=median(numc$num),lty=2)+
  theme_acs()+
  facet_wrap(~both,scales="free")+
  scale_colour_manual(values = c("dodgerblue","firebrick"))+
  theme(legend.position="none")+
  #scale_y_continuous(limits=c(0,15))+
  scale_x_continuous(limits=c(1950,2014),breaks=bk)

ggsave("Whole Island Through Time.pdf")

bb2<-subset(bb,col=="spawn" & row =="sum")


#####
#Long Term Sum of Spawn index
#####

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
  theme_acs()+
  scale_colour_manual(values = c("dodgerblue","firebrick"))+
  theme(legend.position="none")+
  #scale_y_continuous(limits=c(0,15))+
  scale_x_continuous(limits=c(1950,2014),breaks=bk)+
  xlab("Year")+
  ylab("Sum of Spawn Index")
#+
#   scale_y_continuous(trans = log_trans(), breaks = base_breaks(),
#                     labels = prettyNum)  
  
#   scale_y_continuous(
#                      breaks = breaks = trans_breaks("log10", function(x) 10^x), 
#                      labels = trans_format("log10", math_format(10^.x)))



ggsave("AllSites_Sum_SHI.pdf",width=7,height=3, useDingbats=FALSE)



########################################################################
############Individual Stocklet SHI 
########################################################################
xss<-subset(x,SHI>0 & year > 1949)
xss2<-subset(xss,section_name %in% c("Louscoone Inlet","Juan Perez Sound","Rennell Sound","Skidegate Inlet","Skincuttle Inlet","Englefield Bay"))

# 
# nm<-unique(xss2$section_name)
# for(i in 1:length(nm)){
#   tmp<-subset(xss2,section_name==nm[i])
#   
#   ggher2<-ggplot(tmp,aes(x=year,y=SHI))+
#     geom_point()+
#     geom_line(lty=1)+
#     #scale_y_log10()+
#     theme_acs()+
#     #ggtitle("Herring By Spawn Area")+
#     #facet_wrap(~section_name,scales="free_y")+
#     theme(legend.position="none")+
#     scale_x_continuous(limits=c(1950,2014),breaks=bk)
# #     scale_y_continuous(
# #                       breaks = trans_breaks("log10", function(x) 10^x), #FIX THIS
# #                        labels = trans_format("log10", math_format(10^.x)))
# #   
#   
#   ggsave(paste("SHI",nm[i],".pdf"))
# 
# }

ggher2<-ggplot(xss2,aes(x=year,y=SHI,group=section_name))+
  geom_line(lty=1)+
  geom_point(shape=21,fill="white")+
  #scale_y_log10()+
  theme_acs()+
  #ggtitle("Herring By Spawn Area")+
  facet_wrap(~section_name,scales="free_y")+
  theme(legend.position="none")+
  scale_x_continuous(limits=c(1950,2014),breaks=bk)+
  scale_y_continuous(breaks = trans_breaks("log10", function(x) 10^x), #FIX THIS
                labels = trans_format("log10", math_format(10^.x)))

print(ggher2)



########################################################################
############Individual Stocklet SHI 
########################################################################


#plot general HG map
library(PBSmapping)
library(ggplot2)

#load the data
data(nepacLLhigh)

xlim=c(-134.5,-130)
ylim=c(51.75,54.4)

#using the PBS package
# plotMap(nepacLLhigh, xlim=xlim, ylim=ylim,
#         col="gainsboro",plt=c(.08,.99,.08,.99))

#using ggplot

ggplot() +
  geom_polygon(data=nepacLLhigh,aes(X,Y,group=PID),
               fill = "darkseagreen",color="grey50") +
  coord_map(xlim=xlim,ylim=ylim) +
  labs(y="",x="") +
  theme_acs()



##########################################################################
###Figure 2 While island Spawn, Map of HG, and  Individual Stocklet Productivity (Ui) Relative to the Mean (Umu)
##########################################################################

###Popultaion Productivity
####Umu and Ui estimates 
Umudf<-melt(model$BUGSoutput$sims.array[,,"Umu"])
Umudf$Var3<-"Umu"
Umudf<-Umudf[,c(1,2,4,3)]
umuci<-smedian.hilow(Umudf$value,conf.int=0.95)
umuci2<-quantile(Umudf$value,c(0.05,0.95))

tlist<-model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="U[1]"):which(colnames(myList[[1]])=="U[11]")]]
dimnames(tlist)[[3]]<-colnames(Y_car)
udf<-melt(tlist)

names(sort(tapply(udf$value,list(udf$Var3),mean),decreasing=T))
levels(udf$Var3)
mean(tapply(udf$value,list(udf$Var3),mean))


udf$Var3=factor(udf$Var3,levels(udf$Var3)[c(11,7,10,2,8,9,3,6,1,4,5)])
#udf$Var3=substr(udf$Var3,5,28)

udf2<- data.frame("umed"=sort(tapply(udf$value,list(udf$Var3),median),decreasing=TRUE),
           "usd"=tapply(udf$value,list(udf$Var3),median)+tapply(udf$value,list(udf$Var3),sd))

md<-md[c(11,7,8,5,10,3,4,9,2,1,6),] 
md$median_ui<-sort(tapply(udf$value,list(udf$Var3),median),decreasing=TRUE)
md$sd_ui<-tapply(udf$value,list(udf$Var3),median)+tapply(udf$value,list(udf$Var3),sd)



#udf$Var3=factor(udf$Var3,levels(udf$Var3)[c(11,7,8,5,10,3,4,9,2,1,6)])
#md<-md[c(11,7,8,5,10,3,4,9,2,1,6),]

ucomp<-ggplot(udf,aes(x=Var3,y=value))+
  geom_hline(yintercept=median(Umudf$value),lty=2)+
  geom_hline(yintercept= umuci2[1],lty=1,colour="grey")+
  geom_hline(yintercept= umuci2[2],lty=1,colour="grey")+
  stat_summary(fun.data=median_hilow,lty=3,pch=21,fill="white")+
  stat_summary(fun.data=median_hilow,conf.int=0.5)+
  scale_y_continuous(labels = fmt())+
  ylab("Population Growth Rate [Ui]")+
  xlab("")+
  coord_flip()+
  theme_acs()+
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position="none")  +
  scale_y_continuous(limits=c(-0.1,0.6))
  

print(ucomp)


sumtab<-tapply(udf$value,list(udf$Var3),IQR)

humandf<-
  
c1<-c(53.26614,-131.991208)
c2<-c(54.012960, -132.146977)
hdf<-data.frame(rbind(c1,c2))
hdf$sitelab2<-c("Skidegate","Masset")
names(hdf)<-c("Latitude","Longitude","sitelab2")


########################################################################
############MAP Population Productivity (size) and fishing pressure (colour)
########################################################################
#reular site map
hmap <-ggplot()+
  geom_polygon(data=nepacLLhigh,aes(X,Y,group=PID),
               fill = "grey50",color="black") + #darkseagreen
  coord_map(xlim=xlim,ylim=ylim) +
  labs(y="",x="") +
  geom_point(data = hdf, aes(x=Longitude,y=Latitude),colour="red",fill="red",size=20,pch=16,alpha=0.5)+
  geom_point(data = md, aes(x = Longitude, y = Latitude),size=5,colour="dodgerblue",fill="dodgerblue",pch=23)+
  geom_text(data = md,aes(x = Longitude, y = Latitude,label=sitelab2),size=4,vjust=.1,hjust=-.1)+
  #   scale_colour_gradient2(midpoint=0.2)+
  #ggtitle("Pop Growth Estimates")+
  theme_acs()+
  theme(legend.position="right")+
  xlab("Longitude")+
  ylab("Latitutde")

print(hmap)


#reular site map
hmap <-ggplot()+
  geom_polygon(data=nepacLLhigh,aes(X,Y,group=PID),
               fill = "grey50",color="black") + #darkseagreen
  coord_map(xlim=xlim,ylim=ylim) +
  labs(y="",x="") +
 # geom_point(data = hdf, aes(x=Longitude,y=Latitude),colour="red",fill="red",size=20,pch=16,alpha=0.5)+
  geom_point(data = md, aes(x = Longitude, y = Latitude,colour=sitelab2,fill=sitelab2),size=5,pch=23)+
  geom_text(data = md,aes(x = Longitude, y = Latitude,label=sitelab2),size=4,vjust=.1,hjust=-.1)+
  #   scale_colour_gradient2(midpoint=0.2)+
  #ggtitle("Pop Growth Estimates")+
  theme_acs()+
  theme(legend.position="right")+
  xlab("Longitude")+
  ylab("Latitutde")

print(hmap)



hmap <-ggplot()+
  geom_polygon(data=nepacLLhigh,aes(X,Y,group=PID),
               fill = "grey50",color="black") + #darkseagreen
  coord_map(xlim=xlim,ylim=ylim) +
  labs(y="",x="") +
  geom_point(data = md, aes(x = Longitude, y = Latitude,size=median_ui,colour=median_ui))+
  geom_text(data = md,aes(x = Longitude, y = Latitude,label=sitelab2),size=2,vjust=.1,hjust=-.1)+
  #   scale_colour_gradient2(midpoint=0.2)+
  scale_colour_gradient2(low="#FF754C",high="#19FFC0",midpoint=mean(md$median_ui))+
  scale_size(range = c(2, 8),name="Pop. Growth Rate")+
  #ggtitle("Pop Growth Estimates")+
  theme_acs()+
  theme(legend.position="right")+
  xlab("Longitude")+
  ylab("Latitutde")

print(hmap)


grid.arrange(ucomp,hmap,ncol=2, heights=c(1.2,1.2))

p = rectGrob()
grid.arrange(hmap, arrangeGrob(pcgg2,ucomp,heights=c(2/4, 2/4), ncol=1), ncol=2)




########################################################################
############Covariance: Productivity and Geographic Distance
########################################################################

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



#distance matrix by coastline
distMat4<-as.matrix(read.csv("h_dist_shore.csv")[,-1]/1000)
distMat5<-distMat4[-c(4,7),-c(4,7)]
distMatcar<-distMat5[c(8,9,10,7,11,5,1,4,3,2,6),c(8,9,10,7,11,5,1,4,3,2,6)]


distMate<-as.matrix(read.csv("h_dist_euc.csv")[,-1]/1000)
distMate2<-distMate[-c(4,7),-c(4,7)]
distMatecar<-distMate2[c(8,9,10,7,11,5,1,4,3,2,6),c(8,9,10,7,11,5,1,4,3,2,6)]


###############

u<-md$median_ui
u<-u[c(3,8,5,2,1,4,10,7,6,9,11)]


# emat<-matrix(NA,nrow=100,ncol=1)
# cb<-seq(1:11)


dd<-expand.grid.unique(seq(1:11),seq(1:11))
ddn<-expand.grid.unique(names(u),names(u))
emat<-matrix(NA,nrow=nrow(dd),ncol=3)

for(i in 1:nrow(dd)){
  tmp<-dd[i,]
  emat[i,1]<-distMatcar[tmp[1],tmp[2]]
  emat[i,2]<-distMatecar[tmp[1],tmp[2]]
  emat[i,3]<- u[tmp[1]] - u[tmp[2]]
}

dd2<-data.frame(dd,ddn,emat)
names(dd2)<-c("site1","site2","site1n","site2n","distance_fish","distance_bird","udiff")
# dd2$site1n=factor(dd2$site1n,levels(dd2$site1n)[c(8,1,4,3,9,5,10,2,7,6)])
# dd2$site2n=factor(dd2$site2n,levels(dd2$site2n)[c(names(u))])


dd3<-melt(dd2,id.vars=c("site1","site2","site1n","site2n","udiff"))

udd<-ggplot(dd3,aes(x=value,y=udiff))+
  geom_point()+
  geom_smooth(method="lm",se=F,colour="black")+
  theme_acs()+
  facet_wrap(~variable,scales="free")+
  xlab("Distance")+
  ylab("Difference in median productivity (Ui-Ui)")

ggsave("Udiff_byDistance.pdf",udd)

####absolute value of difference in Ui

covmat<-matrix(NA,nSites,nSites)

#lag0
for(i in 1:11){
  for(j in 1:11){
    covmat[i,j]<-(u[i]-u[j])
  }
}

covmat[lower.tri(covmat)] <-NA
diag(covmat)<-NA

colnames(covmat)<-names(u)
rownames(covmat)<- names(u)

udiffm<-melt(covmat)
##################


#All different groups
udabs<-ggplot(udiffm,aes(x=Var1,y=Var2,fill=value,colour=value))+
  geom_tile()+
  scale_fill_gradient(low="white",high="orange")+
  scale_colour_gradient(low="white",high="orange")+
  theme_acs()+
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position="top")+
  xlab("")+
  ylab("")

ggsave("udiff_matrix.pdf",udabs)

uihg<-ggplot(udiffm,aes(x=value,fill=..x..))+
  geom_histogram(colour="black")+
  geom_vline(xintercept=0,lty=1)+
  geom_vline(xintercept=umuci[1],lty=2)+
  scale_x_continuous(limits=c(-1,1))+
  scale_fill_gradient2(low="dodgerblue",high="firebrick")+
  ylab("Difference in Pop. Growth Rate [delta Ui]")+
  theme_acs()

ggsave("udiff_hist.pdf",uihg)


#####################
############tau2 -estiamtes of states for each pouplation at each time step 
#####################

sdf<-model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="tau2[1]"):which(colnames(myList[[1]])=="tau2[11]")]]
dimnames(sdf)[[3]]<-colnames(Y_car)
sdf<-melt(sdf)
names(sdf)<-c("num","chain","response","value")
sdf$chain<-factor(sdf$chain)
#sdf$section2<-as.character(sort(rep(unique(x$section)[-c(4,7)],nrow(sdf)/nSites)))


gtemp<- ggplot(sdf,aes(y=value,x=num,group=chain))+
  geom_line(aes(colour=chain))+
  theme_acs()+
  facet_wrap(~response)+
  theme(legend.position="none")+
  ggtitle("tau2 Chains")


gtemp2<-ggplot(sdf,aes(x=value))+
  geom_bar()+
  theme_acs()+
  geom_vline(xintercept = 0,lty=2)+
  facet_wrap(~response)+
  ggtitle("tau2 Histogram")

grid.arrange(gtemp,gtemp2,nrow=2, heights=c(1.2,1.2))

sdf$response=factor(sdf$response,levels(sdf$response)[c(11,7,10,2,8,9,3,6,1,4,5)])


scomp<-ggplot(sdf,aes(x=response,y=value))+
#   geom_hline(yintercept=median(Umudf$value),lty=2)+
#   geom_hline(yintercept= umuci2[1],lty=1,colour="grey")+
#   geom_hline(yintercept= umuci2[2],lty=1,colour="grey")+
  stat_summary(fun.data=median_hilow,lty=3,pch=21,fill="white")+
  stat_summary(fun.data=median_hilow,conf.int=0.5)+
  scale_y_continuous(labels = fmt())+
  ylab("Within Population Variance [Sigma2]")+
  xlab("")+
  coord_flip()+
  theme_acs()+
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position="none")  

print(scomp)
ggsave("Sigma2_AllSites.pdf",scomp)

#IQR for U and Sigma2
udat<-ggplot_build(ucomp)$data[[5]]
sdat<-ggplot_build(scomp)$data[[2]]

combd<-data.frame(udat,sdat)[,c(1,3,4,5,9,10,11)]
colnames(combd)<-c("site","umed","xmax","xmin","smed","ymax","ymin")
combd<-combd[with(combd, order(-umed)), ]
combd$site<-md$Name

uisigmai<-ggplot(data = combd,aes(x = umed,y = smed,colour=site)) + 
  geom_point() + 
  geom_errorbar(aes(ymin = ymin,ymax = ymax)) + 
  geom_errorbarh(aes(xmin = xmin,xmax = xmax))+
  #geom_smooth(colour="black",se=F,method="lm")+
  theme_acs()+
  xlab("Population Growth Rate [Ui]")+
  ylab("Population Variance [Sigma2i]")

print(uisigmai)
ggsave("Productivity-Variance.pdf",uisigmai)

#############################
##CV: Estimate the coefficient of variation for the entire population and for each stocklet 
#############################
umudf<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="Umu")]])
usigdf<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="Usig")]])
pairdf<-data.frame("GrandMean"=umudf[,3],"GrandVar"=usigdf[,3],"chain"=usigdf[,2])

ggplot(pairdf,aes(x=GrandMean,y=GrandVar,colour=factor(chain)))+
  geom_point()+
  theme_acs()

grandcv<-data.frame("param"=rep("GrandCV",nrow(pairdf)),"CV"=pairdf$GrandVar/pairdf$GrandMean)

ggplot(grandcv,aes(x=param,y=CV))+
  stat_summary(fun.data=median_hilow,lty=2)+
  stat_summary(fun.data=median_hilow,conf.int=0.5)+
  theme_acs()

#by stocklet

combd$cv<-combd$smed/combd$umed

#without error bars
ggplot(combd,aes(x=site,y=cv))+
  geom_bar(stat="identity")+
  coord_flip()+
  theme_acs()



sdf2<-model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="tau2[1]"):which(colnames(myList[[1]])=="tau2[11]")]]
dimnames(sdf2)[[3]]<-colnames(Y_car)
sdf2<-melt(sdf2)

udf2<-model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="U[1]"):which(colnames(myList[[1]])=="U[11]")]]
dimnames(udf2)[[3]]<-colnames(Y_car)
udf2<-melt(udf2)

slist<-unique(udf2$Var3)

cdf<-sdf2
cdf$value2<-udf2[,'value']
cdf$cv<-cdf$value/cdf$value2

names(cdf)<-c("iter","chain","site","sd","mean","cv")

ggplot(cdf,aes(x=site,y=cv))+
  #stat_summary(fun.data=median_hilow,lty=2)+
  stat_summary(fun.data=median_hilow,conf.int=0.5)+
  coord_flip()+
  theme_acs()


########################################################################
############PDO Coef Effect
########################################################################

#load pdo
pdo<-read.csv("pdo.csv")
pdosummer<-subset(pdo,month %in% c(3,4,5,6)) #average april<-june
pdoxb<-c(tapply(pdo$Value,list(pdo$year),mean))
pdo2<-pdoxb[87:160] #1940-2013
pdo3<-pdo2[11:74] #1950-2013

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

smedian.hilow(pdodf$medianci)

pdodf$year<-as.numeric(rownames(pdodf))


pdotsgg<-ggplot(pdodf,aes(x=year,y=medianci))+
  geom_hline(yintercept=0)+
  geom_ribbon(aes(ymin=minci,ymax=maxci),fill="blue",alpha=0.2)+
  geom_ribbon(aes(ymin=miniqr,ymax=maxiqr),fill="grey")+
  geom_point()+
  geom_line(lty=2)+
  theme_acs()+
  ylab("PDO Effect (PDO*PDOcoef)")+
  xlab("Year")

md$Name2<-c("Skincuttle","Juan Perez","Skidegate","Louscoone","Laskeek","Rennell","Englefield","Cumshewa","Port Louis","Tasu","Naden")

pdog<-ggplot(pdodf,aes(x=medianci,fill=..x..))+
        geom_histogram(colour="black")+
        geom_vline(xintercept=0,lty=1)+
        geom_vline(xintercept=umuci[1],lty=2)+
        geom_vline(xintercept=umuci[2],lty=1,colour="grey")+
        geom_vline(xintercept=umuci[3],lty=1,colour="grey")+
        geom_text(data=md,aes(x=median_ui,y=0,label=Name2),angle=45)+
        #geom_vline(xintercept=md$median_ui,colour="grey",lty=2)+
        #scale_x_continuous(limits=c(-1,1))+
        scale_fill_gradient2(low="firebrick",high="dodgerblue")+
        xlab("PDO Effect (PDO*PDOcoef")+
        ylab("Frequency")+
        theme_acs()
print(pdog)

ggsave("PdoHistogram.pdf",pdog)

pdodf2<-data.frame(site=rep("pdocoef",nrow(pdodf)),pdodf)

ggplot(pdodf2,aes(x=site,y=medianci))+
  geom_boxplot()+
  geom_point(aes(colour=medianci))+
  scale_colour_gradient2(low="firebrick",high="dodgerblue")+
  coord_flip()+
  theme_acs()+
  scale_y_continuous(limits=c(-0.10,0.4),breaks=c(-0.1,0,0.1,0.2,0.3,0.4))


head(pdodf)

pdoprop<-emat<-matrix(0,ncol=nrow(md),nrow=nrow(pdodf))
for(i in 1:nrow(md)){
  pdoprop[,i]<-100*(pdodf$medianci/(pdodf$medianci+u[i]))
  
}
pdoprop<-data.frame(pdoprop)
names(pdoprop)<-names(u)
pdoprop$years<-years
pdoprop2<-melt(pdoprop,id.vars="years")
names(pdoprop2)<-c("years","Site","PropImportance")

pdoper<-ggplot(pdoprop2,aes(x=years,y=PropImportance))+
  geom_line(aes(colour=Site))+
  facet_wrap(~Site,scales="free_y")+
  theme_acs()+
  ylab("Percent of PDO driven Productivity (pdoeff/(ui+pdoeff)")
print(pdoper)

ggsave("PdoContribution.pdf",pdoper)


#effect size back of envelope
#overall
pdorange<-(median(pdocoef)*range(pdo3))
medumu<-median(Umu)

pdorange/medumu



########################################################################
############Predicted Catch Through Time At Different Sites ------FIGURE 2
########################################################################

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


ggplot(fish2,aes(x=year,y=pc))+
  geom_line(aes(lty=var,colour=var))+
  theme_acs()+
  scale_y_continuous(limits=c(0,1),breaks=c(0,0.2,0.4,0.6,0.8,1.0))+
  scale_x_continuous(breaks=bk)+
  ylab("Proportion Biomass Caught (F)")




##Posterior plots
edf1<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="Pc[1]"):which(colnames(myList[[1]])=="Pc[156]")]])

names(edf1)<-c("num","chain","response","value")
edf1$chain<-factor(edf1$chain)
#edf1$group<-factor(sort(rep(seq(1:11),runL)))
#edf1$year<-sort(rep(seq(1:nYears),runL*nSites))
names(edf1)<-c("num","chain","response","pc","section","year")



########
#plot by section through time
#######

pc_tab

ggplot(pc_tab,aes(x=year,y=pc))+
  geom_line(aes(colour=section))+
  theme_acs()+
  scale_y_continuous(limits=c(0,1),breaks=c(0,0.5,1.0))+
  facet_wrap(~section,ncol=2)+
  theme(legend.position="none")

ggsave("section_pc.pdf",width=3,height=9)

  

# zdf1<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="Z[1,1]"):which(colnames(myList[[1]])=="Z[64,11]")]])
# 
# names(zdf1)<-c("num","chain","response","value")
# zdf1$chain<-factor(zdf1$chain)
# zdf1$group<-factor(sort(rep(seq(1:11),runL)))
# zdf1$year<-sort(rep(seq(1:nYears),runL*nSites))
# names(zdf1)<-c("num","chain","response","pc","section","year")

tpc<-model$BUGSoutput$mean$Pc
zpc<-model$BUGSoutput$mean$Z
xpc<-model$BUGSoutput$mean$X


bcatch<-exp(zpc)*tpc
colnames(bcatch)<-colnames(Y_car)
colnames(ctab2_1_car)<-colnames(Y_car)

pcd<-data.frame(melt(bcatch),
           melt(ctab2_1_car)
)
names(pcd)<-c("year","site1","estimated","site2","reported")

pcd2<-melt(pcd,id.vars=c("year","site1","site2"))

pcgg<-ggplot(pcd2,aes(x=year,y=value))+
  geom_line(aes(colour=variable,lty=variable))+
  theme_acs()+
  facet_wrap(~site1,scales="free_y")


ggsave("catch_estimated_reported.pdf",pcgg)


########
#plot by section through time
#######

edf2<-droplevels(subset(edf1,pc>0.011))

edf3<-tapply(edf1$pc,list(edf1$year,edf1$section),mean)
edf3<-melt(edf3)
names(edf3)<-c("year","section","pc")
edf3<-subset(edf3,pc!="NA")
edf3$section<-factor(edf3$section)
edf3$section=factor(edf3$section,levels(edf3$section)[seq(1:11)])


ggplot(edf3,aes(x=year,y=pc))+
  geom_line(aes(colour=section))+
  theme_acs()+
  scale_y_continuous(limits=c(0,1),breaks=c(0,0.5,1.0))+
  facet_grid(section~.)+
  theme(legend.position="none")

ggsave("section_pc.pdf",width=3,height=9)

# ggplot(edf1,aes(x=year,y=pc,colour=factor(section)))+
#   #geom_hline(yintercept=median(Umudf$value),lty=2)+
#   #geom_hline(yintercept= umuci2[1],lty=1,colour="grey")+
#   #geom_hline(yintercept= umuci2[2],lty=1,colour="grey")+
#   geom_line(data=edf3,aes(x=year,y=pc,colour=factor(section)))+
#   #stat_summary(fun.data=median_hilow,lty=2)+
#   stat_summary(fun.data=median_hilow,conf.int=0.5)+
#   scale_y_continuous(limits=c(0,1),breaks=c(0,0.5,1.0))+
#   facet_grid(section~.)+
#   theme_acs()+
#   theme(legend.position="none")



#plot of whole island through time


#means of predicted catch
tempmat<-model$BUGSoutput$mean$Pc
colnames(tempmat) <-substr(colnames(Y_car),5,28)
tempmat<-data.frame(tempmat)
tempmat$year<-years
temp2<-melt(tempmat,id.vars="year")
colnames(temp2) <-c("time","site","Pc")
temp3<-subset(temp2,Pc>0.11)

tmp4<-tapply(temp3$Pc,list(temp3$time))

gmdf<-tapply(temp3$Pc,list(temp3$time),median)
gmdf<-data.frame("Pc"=gmdf,"time"=as.numeric(as.character(rownames(gmdf))))

gmdfa<-tapply(temp2$Pc,list(temp2$time),mean)
gmdfa<-data.frame("Pc"=gmdfa,"time"=as.numeric(as.character(rownames(gmdfa))))
gmdfa$max<-tapply(temp2$Pc,list(temp2$time),mean)+tapply(temp2$Pc,list(temp2$time),sd)
gmdfa$min<-tapply(temp2$Pc,list(temp2$time),mean)-tapply(temp2$Pc,list(temp2$time),sd)


gmdf2<-data.frame(tapply(temp3$Pc,list(temp3$time,temp3$site),median),as.numeric(as.character(rownames(gmdf))))
colnames(gmdf2)<-c(levels(temp3$site),"time")
gmdf2<-melt(gmdf2,id.vars="time")
colnames(gmdf2)<-c("time","site","Pc")

gmdf3<-subset(gmdf2,Pc!="NA")
gmdf3<-subset(gmdf2,site %in% c("Skidegate.Inlet","Juan.Perez.Sound","Skincuttle.Inlet"))

bk<-seq(1950,2013,by=10)

ff<-data.frame("Pc"=colSums(tapply(temp3$Pc,list(temp3$site,temp3$time),length),na.rm=T)/11,"time"=gmdf$time)

pcwi<-ggplot(temp3,aes(x=time,y=Pc))+
#   geom_smooth(method="lm",colour="black",se=F)+
  geom_hline(yintercept=0.2,colour="grey",lty=2)+
  geom_line(data=gmdf,aes(x=time,y=Pc))+
  geom_line(data=gmdfa,aes(x=time,y=Pc),colour="red")+
  geom_line(data=ff,aes(x=time,y=Pc),colour="green")+
#   geom_ribbon(data=gmdfa,aes(x=time,ymin=min,ymax=max),colour="grey60")+
  stat_summary(fun.data=median_hilow,lty=2)+
  scale_x_continuous(breaks=bk)+
  theme_acs()+
  theme(legend.position="none")+
  scale_y_continuous(limits=c(0,1))+
  ylab("Catch Rate (Pc)")+
  xlab("Year")

print(pcwi)

ggsave("Catch_Whole_Island.pdf",pcwi)

#use gmdf2 for all sites (but it's a mess I"m warning you...)

pcwi2<-ggplot(temp3,aes(x=time,y=Pc))+
  geom_point(data=gmdf3,aes(x=time,y=Pc,colour=site))+
  geom_line(data=gmdf3,aes(x=time,y=Pc,colour=site))+
  geom_line(data=gmdf,aes(x=time,y=Pc))+
  #stat_summary(fun.data=median_hilow,lty=2)+
  scale_x_continuous(breaks=bk)+
  theme_acs()+
  theme(legend.position="none")

print(pcwi2)

ggsave("Catch_Whole_Island_majorstocklets.pdf",pcwi2)


#all years 
sort(tapply(temp2$Pc,list(temp2$site),median))


#Fraction of years where fishing happened, 
sort(tapply(temp3$Pc,list(temp3$site),length)/64)
sort(tapply(temp3$Pc,list(temp3$site),median))
sort(tapply(temp3$Pc,list(temp3$site),mean))

# 
# pcsiteg<-ggplot(temp3,aes(x=site,y=Pc))+
# #   geom_hline(yintercept=median(Umudf$value),lty=2)+
# #   geom_hline(yintercept= umuci2[1],lty=1,colour="grey")+
# #   geom_hline(yintercept= umuci2[2],lty=1,colour="grey")+
#   stat_summary(fun.data=median_hilow,lty=3,pch=21,fill="white")+
#   stat_summary(fun.data=median_hilow,conf.int=0.5)+
#   scale_y_continuous(labels = fmt())+
#   ylab("Population Growth Rate [Ui]")+
#   xlab("")+
#   coord_flip()+
#   theme_acs()+
#   theme(axis.text.x = element_text(angle = 45, hjust = 1),
#         legend.position="none")  
# 
# print(pcsiteg)


#####BOXPLOT
#temp3$site=factor(temp3$site,levels(temp3$site)[c(11,7,8,5,10,3,4,9,2,1,6)])
# temp3$site=factor(temp3$site,levels(temp3$site)[c(5,4,8,6,1,2,3,7,9,10,11)])
temp3$site=factor(temp3$site,levels(temp3$site)[c(11,10,9,7,3,2,1,6,8,4,5)])

mean(tapply(temp3$Pc,list(temp3$site),mean))


pcgg2<-ggplot(temp3,aes(x=site,y=Pc))+
  geom_hline(yintercept=mean(tapply(temp3$Pc,list(temp3$site),mean)))+
  geom_boxplot(data=temp3,aes(x=site,y=Pc))+
  geom_point()+
  coord_flip()+
  theme_acs()+
  ylab("Fishing Effect (Pc)")

print(pcgg2)




########
#plot productivity versus fishing in a few different ways
#######

md<-md[c(11,9,6,10,5,8,3,4,7,2,1),]

md$pcgm<-as.numeric(tapply(temp3$Pc,list(temp3$site),gm_mean))
md$pcm<-as.numeric(tapply(temp3$Pc,list(temp3$site),median))
md$pcsd<-as.numeric(tapply(temp3$Pc,list(temp3$site),sd))
md$pcsum<-as.numeric(tapply(temp3$Pc,list(temp3$site),sum))
md$nfish<-as.numeric(tapply(temp3$Pc,list(temp3$site),length)/64)
md$percap<-as.numeric(md$pcm/md$nfish)

########################################################################
############MAP Population Productivity (size) and fishing pressure (colour)
########################################################################

pcmap <-ggplot()+
  geom_polygon(data=nepacLLhigh,aes(X,Y,group=PID),
               fill = "grey50",color="black") + #darkseagreen
  coord_map(xlim=xlim,ylim=ylim) +
  labs(y="",x="") +
  geom_point(data = md, aes(x = Longitude, y = Latitude,size=nfish,colour=pcm))+
  geom_text(data = md,aes(x = Longitude, y = Latitude,label=sitelab2),size=2,vjust=.1,hjust=-.1)+
  #   scale_colour_gradient2(midpoint=0.2)+
  #   scale_colour_gradient2(low="#006662",high="#B23E00",midpoint=mean(md$pcm))+
  scale_colour_gradient(low="yellow",high="red",name="Fishing Strength")+
  scale_size(range = c(2, 8),name="Fishing Freq")+
  #ggtitle("Pop Growth Estimates")+
  theme_acs()+
  theme(legend.position="right")+
  xlab("Longitude")+
  ylab("Latitutde")

print(pcmap)


grid.arrange(pcgg2,pcmap,ncol=2, heights=c(1.2,1.2))


# md2<-md[,c(6,7,9,11,12)]
# md2<-data.frame("sitelab2"=md2[,1],round(md2[,2:5],2))
# mfish<-melt(,id.vars=c("sitelab2","median_ui"))

####CORRELATION WITH Geometric MEAN PC and PRODUCTIVITY 
gmgg<-ggplot(md,aes(x=median_ui,y=pcgm,label=sitelab2))+
  geom_point(aes(colour=sitelab2),size=3)+
  geom_text(vjust=.1,hjust=.5,size=3)+
  geom_smooth(method="lm",se=FALSE,colour="black")+
  theme_acs()+
  theme(legend.position="none")+
  ylab("Fishing Effect (geometric mean Pc)")+
  xlab("Population Growth Rate (Ui)")

####CORRELATION WITH MEAN PC and PRODUCTIVITY 
medgg<-ggplot(md,aes(x=median_ui,y=pcm,label=sitelab2))+
  geom_point(aes(colour=sitelab2),size=3)+
  geom_text(vjust=.1,hjust=.5,size=3)+
  geom_smooth(method="lm",se=FALSE,colour="black")+
  theme_acs()+
  theme(legend.position="none")+
  ylab("Fishing Effect (Median Pc)")+
  xlab("Population Growth Rate (Ui)")

####CORRELATION WITH SUM PC and PRODUCTIVITY 
pcsgg<-ggplot(md,aes(x=median_ui,y=pcsum,label=sitelab2))+
  geom_point(aes(colour=sitelab2),size=3)+
  geom_text(vjust=.1,hjust=.5,size=3)+
  geom_smooth(method="lm",se=FALSE,colour="black")+
  theme_acs()+
  theme(legend.position="none")+
  ylab("Fishing Effect (sum of Pc)")+
  xlab("Population Growth Rate (Ui)")

####CORRELATION WITH SUM PC and PRODUCTIVITY 
propgg<-ggplot(md,aes(x=median_ui,y=nfish,label=sitelab2))+
  geom_point(aes(colour=sitelab2),size=3)+
  geom_text(vjust=.1,hjust=.5,size=3)+
  geom_smooth(method="lm",se=FALSE,colour="black")+
  theme_acs()+
  theme(legend.position="none")+
  ylab("Fishing Effect (Prop of years fished)")+
  xlab("Population Growth Rate (Ui)")

multiplot(gmgg,medgg,pcsgg,propgg,cols=2)
  
##plot for entire stock 

tpc<-model$BUGSoutput$mean$Pc
zpc<-model$BUGSoutput$mean$Z
xpc<-model$BUGSoutput$mean$X

colnames(tpc)<-colnames(Y_car)
colnames(zpc)<-colnames(Y_car)
colnames(xpc)<-colnames(Y_car)

pccomp<-data.frame(melt(zpc),melt(tpc))
colnames(pccomp)<-c("Year","Site","Z","Year2","Site2","Pc")

pcdf<-data.frame(
  "zave"=tapply(pccomp$Z,list(pccomp$Site),mean),
  "Pcave"=tapply(pccomp$Pc,list(pccomp$Site),mean)
)

pcdf$site=rownames(pcdf)

#all years - postivie correlation including zeros
ggplot(pcdf,aes(x=zave,y=Pcave,colour=site))+
  geom_point()+
  theme_acs()+
  geom_smooth(method="lm",se=F,colour="black")
  

#for each year-site
pdf(paste("PC-x by year",Sys.Date(),".pdf"), width=8,onefile = TRUE)

for(i in 1:length(years)){
  tmp<-subset(pccomp,Year==i)

  gt<-ggplot(tmp,aes(x=Z,y=Pc))+
    geom_point()+
    geom_smooth(method="lm",se=F,colour="black")+
    scale_y_continuous(limits=c(0,1))+  
    theme_acs()+
    ggtitle(paste("Fishing-Biomass Relationship",1949+i))+
    xlab("Estimated Biomass Before Fishing (Z)")+
    ylab("Estimated Fishing Effect (Pc)")
  
  print(gt)
}

dev.off()


##############################################################################################################################
#Covariance of Fishing Effects 
##############################################################################################################################
pcmat<-model$BUGSoutput$mean$Pc
colnames(pcmat)<-colnames(Y_car)

covmat<-matrix(NA,nSites,nSites)

#lag0
for(i in 1:11){
  for(j in 1:11){
    tmp<-data.frame(pcmat[,i],pcmat[,j])
    tmp<-tmp[complete.cases(tmp),]
    tmp<-subset(tmp,tmp[,1]>0.011 | tmp[,2]>0.011) #subset out zeros in one or both columns 
    s1<-ccf(rank(tmp[,1]),rank(tmp[,2]),lag.max=0)
    covmat[i,j]<-s1$acf[,,1]
  }
}

covmat[lower.tri(covmat)] <-NA
diag(covmat) <- NA

colnames(covmat)<-colnames(Y_car)
rownames(covmat)<-colnames(Y_car)

cdf<-melt(covmat)
# cdf$Var1<-substr(cdf$Var1,5,28)
# cdf$Var2<-substr(cdf$Var2,5,28)

#reorder so that there in the same order as distMat5
#c(7,10,9,8,6,5,)

ggplot(cdf,aes(x=value,fill=..x..))+
  geom_histogram(colour="black")+
  geom_vline(xintercept=0,lty=2)+
  scale_x_continuous(limits=c(-1,1))+
  scale_fill_gradient2(low="dodgerblue",high="firebrick")+
  ylab("Covariance of Fishing Effect (Pc)")+
  theme_acs()



#All different groups
ggplot(cdf,aes(x=Var1,y=Var2,fill=value,colour=value))+
  geom_tile()+
  scale_fill_gradient2(low="dodgerblue",high="firebrick")+
  scale_colour_gradient2(low="dodgerblue",high="firebrick")+
  theme_acs()+
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position="top")+
  xlab("")+
  ylab("")




##########################################
############Delta -estiamtes of states for each population's change
##########################################

#means
tempmat<-model$BUGSoutput$mean$delta
colnames(tempmat) <- colnames(Y_car) #<-seq(1,11,1)
temp2<-melt(tempmat)
colnames(temp2) <-c("time","site","delta")
#temp2$site<-as.numeric(temp2$site)
temp2$year<-years
temp2$year<-as.numeric(temp2$year)

# 
#add site names from df2
ggplot(temp2,aes(x=time,y=site,fill=delta))+
  geom_tile()+
  theme_acs()
# 

t3<-data.frame("delta"=tapply(temp2$delta,list(temp2$time),mean))
t3$year<-years
t3$year<-as.numeric(t3$year)
t3$site<-12
t3$max<-tapply(temp2$delta,list(temp2$time),max)
t3$min<-tapply(temp2$delta,list(temp2$time),min)
names(t3)<-c("delta","year","site","max","min")

dts<-ts(c(t3$delta),start=1950,end=2013,frequency=1)
mppt<-cpt.mean(dts,method="PELT")
cpts(mppt)
plot(mppt)


# t3max<-t3[,c(2,3,5)]  
# names(t3max)<-c("year","site","delta")
# t3min<-t3[,c(2,3,4)]  
# names(t3min)<-c("year","site","delta")
# bk<-seq(1950,2015,by=10)

dp<-ggplot()+
  geom_ribbon(data=t3,aes(x=year,ymin=min,ymax=max),colour="grey60")+
  geom_line(data=temp2,aes(x=year,y=delta,colour=factor(site),lty=factor(site),group=site))+
  geom_line(data=t3,aes(x=year,y=delta),colour="white",size=2)+
  #geom_line(data=t3,aes(x=year,y=max))+
  #geom_line(data=t3,aes(x=year,y=min))+
  #scale_colour_continuous(low="green",high="red")+
  geom_vline(xintercept=1967,colour="grey",lty=2)+ #this is the closure of the reduction 
  geom_vline(xintercept=1994,colour="grey",lty=2)+ #this is the big recent closure 
  theme_acs()+
  scale_x_continuous(breaks=bk)+
  xlab("Year")+
  ylab("Detrended Population Performance (Delta)")
print(dp)


#Categorical 

t3$ybin<-c(rep("1Early",18),rep("2After First Closure",27),rep("3After Second Closure",19))

ga<-ggplot(t3,aes(x=ybin,y=delta))+
  stat_summary(fun.data = "mean_sdl", geom = "pointrange",
               colour = "grey60", size = 1, mult = 1) +
  geom_point()+
  theme_acs()

#add pre and post collapse analysis boxplot

temp2$ybin<-c(rep("1Early",18),rep("2After First Closure",27),rep("3After Second Closure",19))

ggplot(temp2,aes(x=ybin,y=delta,colour=site,group=site))+
  stat_summary(fun.data = "mean_sdl", geom = "pointrange",
               size = 1, mult = 1) +
  stat_summary(fun.data=median_hilow,lty=2)+
  stat_summary(fun.data=median_hilow,conf.int=0.5)+
  theme_acs()+
  scale_y_continuous(limits=c(-1,3),breaks=seq(-1,3,1))+
  ylab("Detrended Population Performance (Delta)")

#just means
t5<-melt(tapply(temp2$delta,list(temp2$ybin,temp2$site),mean))
t5$ymax<-melt(tapply(temp2$delta,list(temp2$ybin,temp2$site),mean))[,'value']+melt(tapply(temp2$delta,list(temp2$ybin,temp2$site),sd))[,'value']
t5$ymin<-melt(tapply(temp2$delta,list(temp2$ybin,temp2$site),mean))[,'value']-melt(tapply(temp2$delta,list(temp2$ybin,temp2$site),sd))[,'value']

grandmean<-ggplot_build(ga)$data[[1]]

ggplot(t5,aes(x=Var1,y=value,group=Var2,colour=Var2,ymin=ymin,ymax=ymax,fill=Var2))+
  #geom_line(position=position_jitter(w=0.02, h=0))+
  geom_point(position=position_jitter(w=0.02, h=0))+
  geom_linerange(position=position_jitter(w=0.02, h=0))+
  geom_hline(data=grandmean,aes(yintercept=y))+  
#   geom_ribbon(alpha=0.2)+
  theme_acs()+
  theme(legend.position="none")


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



#######CCF Of Deltas. i.e. how similar are populations through all time series and then a subset. 
##############################################################################################################################
#Covariance of Deltas 
##############################################################################################################################
dmat<-model$BUGSoutput$mean$delta

#late 1967-1971 closed, 4 years later roe fishery began 
#2005 through 2013 closed 
#1983 20% harvest rate policy 
#1994 closure and onward no more than 3000 taken (but 1999 3000 taken in 1999)

colnames(dmat)<-colnames(Y_car)


covmat_a<-matrix(NA,nSites,nSites)
covmat65<-matrix(NA,nSites,nSites)
covmat94<-matrix(NA,nSites,nSites)
covmat13<-matrix(NA,nSites,nSites)

#lag0
for(i in 1:11){
  for(j in 1:11){
    tmp<-data.frame(dmat[,i],dmat[,j])
    tmp<-tmp[complete.cases(tmp),]
    s1<-ccf(rank(tmp[,1]),rank(tmp[,2]),lag.max=0) #i'm removing the rank argumen there because we're interested in absolute CCF channging in difft periods
    covmat_a[i,j]<-s1$acf[,,1]
    
    tmp65<-data.frame(dmat[1:16,i],dmat[1:16,j])
    tmp65<-tmp65[complete.cases(tmp65),]
    s1<-ccf(rank(tmp65[,1]),rank(tmp65[,2]),lag.max=0) #i'm removing the rank argumen there because we're interested in absolute CCF channging in difft periods
    covmat65[i,j]<-s1$acf[,,1]   
    
    tmp94<-data.frame(dmat[17:45,i],dmat[17:45,j])
    tmp94<-tmp94[complete.cases(tmp94),]
    s1<-ccf(rank(tmp94[,1]),rank(tmp94[,2]),lag.max=0) #i'm removing the rank argumen there because we're interested in absolute CCF channging in difft periods
    covmat94[i,j]<-s1$acf[,,1]    
    
    tmp13<-data.frame(dmat[46:64,i],dmat[46:64,j])
    tmp13<-tmp94[complete.cases(tmp13),]
    s1<-ccf(rank(tmp13[,1]),rank(tmp13[,2]),lag.max=0) #i'm removing the rank argumen there because we're interested in absolute CCF channging in difft periods
    covmat13[i,j]<-s1$acf[,,1]    
        
  }
}

covmat_a[lower.tri(covmat_a)] <-NA
diag(covmat_a) <- NA

covmat65[lower.tri(covmat65)] <-NA
diag(covmat65) <- NA

covmat94[lower.tri(covmat94)]<-NA
diag(covmat94)<-NA

covmat13[lower.tri(covmat13)]<-NA
diag(covmat13)<-NA

colnames(covmat_a)<-colnames(Y_car)
rownames(covmat_a)<-colnames(Y_car)
colnames(covmat65)<-colnames(Y_car)
rownames(covmat65)<-colnames(Y_car)
colnames(covmat94)<-colnames(Y_car)
rownames(covmat94)<-colnames(Y_car)
colnames(covmat13)<-colnames(Y_car)
rownames(covmat13)<-colnames(Y_car)


cdf<-melt(covmat_a)
cdf65<-melt(covmat65)
cdf94<-melt(covmat94)
cdf13<-melt(covmat13)


#plot all covmats 
ggdh<-ggplot(cdf,aes(x=value,fill=..x..))+
  geom_histogram(colour="black")+
  geom_vline(xintercept=0,lty=2)+
  scale_x_continuous(limits=c(-1,1))+
  scale_fill_gradient2(low="dodgerblue",high="firebrick")+
  ylab("Covariance of Deltas")+
  theme_acs()

ggsave("Delta_Covariance_Histogram_allyears.pdf",ggdh)


#All different groups
ggcctile<-ggplot(cdf,aes(x=Var1,y=Var2,fill=value,colour=value))+
  geom_tile()+
  scale_fill_gradient2(low="dodgerblue",high="firebrick")+
  scale_colour_gradient2(low="dodgerblue",high="firebrick")+
  theme_acs()+
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position="top")+
  xlab("")+
  ylab("")

ggsave("Delta_Covariance_Tile_allyears.pdf",ggcctile)

#combine and look at shift in distribution of covariance matrices
mdist<-data.frame("value"=tapply(cdf_comp2$value,list(cdf_comp2$variable),mean,na.rm=T),"variable"=unique(cdf_comp2$variable))

cdf_comp<-data.frame(cdf,cdf65$value,cdf94$value,cdf13$value)
colnames(cdf_comp)<-c("Site1","Site2","all","a1950to1965","b1966to1994","c1995to213")
cdf_comp2<-melt(cdf_comp,id.vars=c("Site1","Site2"))

ggdcdf<-ggplot(cdf_comp2,aes(x=value,fill=..x..))+
  geom_vline(data=mdist,aes(xintercept=value))+
  geom_vline(xintercept=0,lty=2)+
  geom_histogram(colour="black")+
  scale_x_continuous(limits=c(-1,1))+
  scale_fill_gradient2(low="dodgerblue",high="firebrick")+
  ylab("Temporal Covariance of Deltas")+
  theme_acs()+
  facet_grid(variable~.)+
  xlab("Cross Correlation of Time Series")

ggsave("Delta_CCF_Time_Periods.pdf",ggdcdf)


ggcctile<-ggplot(cdf_comp2,aes(x=Site1,y=Site2,fill=value,colour=value))+
  geom_tile()+
  scale_fill_gradient2(low="dodgerblue",high="firebrick")+
  scale_colour_gradient2(low="dodgerblue",high="firebrick")+
  theme_acs()+
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position="top")+
  xlab("")+
  ylab("")+
  facet_grid(variable~.)

ggsave("delta_tile_by_time.pdf",ggcctile)

dbw<-ggplot(cdf_comp2,aes(x=variable,y=value))+
         geom_boxplot()+
         geom_point(aes(x=variable,y=value,colour=value))+
         scale_colour_gradient2(low="dodgerblue",high="firebrick")+
         theme_acs()+
         xlab("Time Period")+
         ylab("Temporal Covariance of Deltas")
  
ggsave("deltaBW_bytime.pdf",dbw)

########################################################################
############Relative Contribution of Climate and other stuff out there we don't get (delta)
#######################################################################

pcmat<-model$BUGSoutput$mean$Pc
dmat<-model$BUGSoutput$mean$delta
colnames(dmat)<-colnames(Y_car)

colnames(U)<-colnames(Y_car)
umat<-melt(U)
tapply(umat$value,list(umat$Var2),median)

pdo<-read.csv("pdo.csv")
pdosummer<-subset(pdo,month %in% c(3,4,5,6)) #average april<-june
pdoxb<-c(tapply(pdo$Value,list(pdo$year),mean))
pdo2<-pdoxb[87:160] #1940-2013
pdo3<-pdo2[11:74] #1950-2013

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


dtotal<-rowSums(dmat)
median(U)

compdf<-data.frame("delta"=dtotal,"pdo"=pdodf$medianci,"year"=years)
compdf<-melt(compdf,id.vars=c("year"))

ggplot(compdf,aes(x=year,y=value))+
  geom_line(aes(colour=variable))+
  geom_hline(yintercept=median(U),colour="grey")+
  geom_hline(yintercept=median(U))+
  theme_acs()

########################################################################
############Scaled X portfolio plot 
#######################################################################

#means
tempmat<-scale(model$BUGSoutput$mean$X)
colnames(tempmat) <- colnames(Y_car) #<-seq(1,11,1)
temp2<-melt(tempmat)
colnames(temp2) <-c("time","site","x")
#temp2$site<-as.numeric(temp2$site)
temp2$year<-years
temp2$year<-as.numeric(temp2$year)

# 
#add site names from df2
ggplot(temp2,aes(x=time,y=site,fill=x))+
  geom_tile()+
  theme_acs()
# 

t3<-data.frame("x"=tapply(temp2$x,list(temp2$year),mean))
t3$year<-years
t3$year<-as.numeric(t3$year)
t3$site<-12
t3$max<-tapply(temp2$x,list(temp2$time),max)
t3$min<-tapply(temp2$x,list(temp2$time),min)
names(t3)<-c("x","year","site","max","min")

bk<-seq(1950,2015,by=10)

dpX<-ggplot()+
  geom_ribbon(data=t3,aes(x=year,ymin=min,ymax=max),colour="grey60")+
  geom_line(data=temp2,aes(x=year,y=x,colour=factor(site),lty=factor(site),group=site))+
  geom_line(data=t3,aes(x=year,y=x),colour="white",size=2)+
  #geom_line(data=t3,aes(x=year,y=max))+
  #geom_line(data=t3,aes(x=year,y=min))+
  #scale_colour_continuous(low="green",high="red")+
  geom_vline(xintercept=1967,colour="grey",lty=2)+ #this is the closure of the reduction 
  geom_vline(xintercept=1994,colour="grey",lty=2)+ #this is the big recent closure 
  theme_acs()+
  scale_x_continuous(breaks=bk)+
  #coord_trans(y="log10")+
  #scale_y_log10(breaks=c(.1,1,10),labels=c(0.1,1,10))+
  xlab("Year")+
  ylab("Scaled Estimated Total Biomass X")
print(dpX)

multiplot(dp,dpX)

sbst<-subset(temp2,site %in% c("SHI.Skidegate Inlet","SHI.Rennell Sound")
             
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
               theme_acs()+
               scale_x_continuous(breaks=bk)+
               #coord_trans(y="log10")+
               #scale_y_log10(breaks=c(.1,1,10),labels=c(0.1,1,10))+
               xlab("Year")+
               ylab("Scaled Herring Biomass")+
               theme(legend.position="none")
             print(dpX)

#facet by site

xscalegg<-ggplot()+
  #geom_ribbon(data=t3,aes(x=year,ymin=min,ymax=max),colour="grey60")+
  geom_hline(yintercept=0,colour="grey")+
  geom_line(data=temp2,aes(x=year,y=x,colour=factor(site),lty=factor(site),group=site))+
  geom_line(data=t3,aes(x=year,y=x),colour="black",size=2)+
 # geom_vline(xintercept=1967,colour="grey",lty=2)+ #this is the closure of the reduction 
#  geom_vline(xintercept=1994,colour="grey",lty=2)+ #this is the big recent closure 
  theme_acs()+
  scale_x_continuous(breaks=bk)+
  xlab("Year")+
  ylab("Scaled Estimated Total Biomass X")



#COVARIANCE OF PREDICTED STOCK BIOMASS
xmat<-model$BUGSoutput$mean$X
colnames(xmat)<-colnames(Y_car)

covmat<-matrix(NA,nSites,nSites)

#lag0
for(i in 1:11){
  for(j in 1:11){
    tmp<-data.frame(xmat[,i],xmat[,j])
    tmp<-tmp[complete.cases(tmp),]
    tmp<-subset(tmp,tmp[,1]>0.011 | tmp[,2]>0.011) #subset out zeros in one or both columns 
    s1<-ccf(rank(tmp[,1]),rank(tmp[,2]),lag.max=0)
    covmat[i,j]<-s1$acf[,,1]
  }
}


covmat[lower.tri(covmat)] <-NA
diag(covmat) <- NA

colnames(covmat)<-colnames(Y_car)
rownames(covmat)<-colnames(Y_car)

cdf<-melt(covmat)
# cdf$Var1<-substr(cdf$Var1,5,28)
# cdf$Var2<-substr(cdf$Var2,5,28)

#reorder so that there in the same order as distMat5
#c(7,10,9,8,6,5,)

xccfgg<-ggplot(cdf,aes(x=value,fill=..x..))+
  geom_histogram(colour="black")+
  geom_vline(xintercept=0,lty=2)+
  #scale_x_continuous(limits=c(-1,1))+
  scale_fill_gradient2(low="dodgerblue",high="firebrick")+
  ylab("Frequency")+
  xlab("Pairwise Cross Correlaiton of Estimated States")+
  theme_acs()



#All different groups
ggplot(cdf,aes(x=Var1,y=Var2,fill=value,colour=value))+
  geom_tile()+
  scale_fill_gradient2(low="dodgerblue",high="firebrick")+
  scale_colour_gradient2(low="dodgerblue",high="firebrick")+
  theme_acs()+
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position="top")+
  xlab("")+
  ylab("")


multiplot(xscalegg,xccfgg)



#####################
############phi -estiamtes of states for each pouplation at each time step 
#####################
phidf<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="phi")]])

names(phidf)<-c("num","chain","value")
phidf$chain<-factor(phidf$chain)


gtemp<- ggplot(phidf,aes(y=value,x=num,group=chain))+
  geom_line(aes(colour=chain))+
  theme_acs()+
  theme(legend.position="none")+
  ggtitle("Phi Chains")


gtemp2<-ggplot(phidf,aes(x=value))+
  geom_bar()+
  theme_acs()+
  geom_vline(xintercept = 0,lty=2)+
  ggtitle("Phi Histogram")

grid.arrange(gtemp,gtemp2,nrow=2, heights=c(1.2,1.2))


########################################################################
############Density Depdnence Delta Versus X
#######################################################################
dmat<-model$BUGSoutput$mean$delta
xmat<-model$BUGSoutput$mean$X

#All Sites Summed
tmp<-data.frame("x"=rowSums(xmat),"delta"=rowSums(dmat))
tmp$year<-years
ggplot(tmp,aes(x=x,y=delta))+
  geom_text(aes(label=year),colour="grey")+
  geom_point(size=3)+
  geom_smooth(method="lm",se=F,colour="black")+
  theme_acs()+
  ylab("Sum of Detrended Population Fluctuation (Sum Delta-t)")+
  xlab("Sum of Estiamted Biomass at Time t (Sum X-t)")

tmpnolag<-data.frame("x"=tmp[,1],"delta"=tmp[,2])
tmplag<-data.frame("x"=tmp[c(1:61),1],"delta"=tmp[c(4:64),2])

ggplot(tmplag,aes(x=x,y=delta))+
  geom_point()+
  geom_smooth(method="lm")+
  theme_acs()+
  ggtitle("all sites")


#individual sections listed out
colnames(dmat) <-colnames(Y_car)
# dmat2<-melt(dmat[4:64,])
dmat2<-melt(dmat)

colnames(dmat2) <-c("time","site","delta")

colnames(xmat) <-colnames(Y_car)
# xmat2<-melt(xmat[1:61,])
xmat2<-melt(xmat)

colnames(xmat2) <-c("time","site","X")

xd<-data.frame(dmat2,"X"=xmat2$X)

ggplot(xd,aes(x=X,y=delta,colour=site))+
  geom_point()+
  geom_smooth(method="lm",se=F)+
  facet_wrap(~site,scales="free")+
  theme_acs()+
  theme(legend.position="none")+
  ylab("Detrended Population Fluctuation (Delta-t)")+
  xlab("Estiamted Biomass at Time t after Fishing (X-t)")






