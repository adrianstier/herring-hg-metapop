
######################################
#TOC
######################################

#1) Sum of Spawn index at arch and stocklet  scale

######################################
#LOAD PACKAGES
######################################
  
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
# require("rgdal") # requires sp, will use proj.4 if installed
require("maptools")

data(nepacLLhigh)
xlim=c(-134.5,-130)
ylim=c(51.75,54.4)

######################################
#SET DIRECTORY AND LOAD DATA 
######################################
setwd("~/Dropbox/Projects/In Progress/Herring_Haida_Gwaii/Code")

x=read.csv("HG_Spawn_Survey_1940_2015.csv") #spawn data
c <- read.csv("herring_catch_local2015.csv") #catch data

n.chains = 3
n.burnin=8000
n.thin=5
n.iter=10000


#number of recorded mcmc
runL <- n.chains*(n.iter-n.burnin)/n.thin

#make plotting a little easier
load("herring_jags_F_11sites_UNequal_var_CAR_2015_v5.RData")
#v4 is the one with psi bouncing around
#v5 fixes psi but changes q to the additive form

#make plotting a little easier
source('theme_acs.R')
source('multiplot.R')

######################################
### FUNCTION TO MANIPULATE MCMC OUTPUT
######################################

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

#use this on the mcmc output
myList<-createMcmcList(model) #mcmc output 


######################################
### MODIFY RAW SPAWN DATA 
######################################

years = seq(1950,2015)
nYears = length(years)
nSites = 11

#distance matrix by coastline and by euclidian distance
distMat4<-as.matrix(read.csv("h_dist_shore.csv")[,-1]/1000)
distMat5<-distMat4[-c(4,7),-c(4,7)]
distMatcar<-distMat5[c(8,9,10,7,11,5,1,4,3,2,6),c(8,9,10,7,11,5,1,4,3,2,6)]

distMate<-as.matrix(read.csv("h_dist_euc.csv")[,-1]/1000)
distMate2<-distMate[-c(4,7),-c(4,7)]
distMatecar<-distMate2[c(8,9,10,7,11,5,1,4,3,2,6),c(8,9,10,7,11,5,1,4,3,2,6)]

#spawn data 
x<- x[c(1,3,13,14,15,16)] #just spawn data
x$SHI2<-log(x$SHI+1) #log with a little extra
x$presabs <-ifelse(x$SHI>0,1,0) #estimate presence-absence
x2 <- x[,c(1,2,4)] #subset again

#reshaps data to wide format
w <- reshape(x2, 
             timevar = "section_name",
             idvar = c("year"),
             direction = "wide")[,-1]

#replace zeros with NAs
w[w==0] <- NA

#double check that it has time on the rows and sites on the column
Y= as.matrix(w)
Y2<-Y
#subset out Cartwright Sound (4)-no catch data
Y2<-Y2[-c(1:10),-c(4)] #drop site 4 since we have no catch data for Cartwright, Masset because there are so few points
Y2<-Y2[,c(9,10,11,8,12,5,1,4,3,2,7,6)]
Y2<-Y2[,c(1:11)]#subset out Massetxw inslet - limited data 


##do this for the CAR model format too
#subset out Cartwright Sound (4)-no catch data, Masset (7) four data points
Y = Y[-c(1:10),-c(4,7)] #drop site 4 since we have no catch data for Cartwright

#Y Log SPAWN INDEX
Y = log(Y)


#car model reconfigure 

#double check that it has time ont he rows and sites on the column
Yc= as.matrix(w)

#subset out Cartwright Sound (4)-no catch data
Yc = Yc[-c(1:10),-c(4)] #drop site 4 since we have no catch data for Cartwright, Masset because there are so few points

#Y = Y/0.5 #q coefficient to turn into biomass
Yc = log(Yc)

Y_car<- Yc[,c(9,10,11,8,12,5,1,4,3,2,7,6)]
Y_car<-Y_car[,c(1:11)]#subset out Masset inslet - limited data 


######################################
### MODIFY RAW CATCH DATA 
######################################

#catch data
length(unique(c$Section))
#names of unique sites
unique(c$Name)

yr_c<-unique(c$Year)
c$presabs <-ifelse(c$TotalCatch>0,1,0)

#subset out Cartwright Sound (4)
c<-subset(c,Section %in% c(1,2,3,5,6,11,12,21,22,23,24,25))

#ctab<-data.frame(tapply(c$TotalCatch,list(c$Year,c$Section),sum)) #all catch
ctab<-data.frame(tapply(c$CatchJan_Apr,list(c$Year,c$Section),sum)) #just spring catch
ctab2<-ctab

ctab2_1_car<-ctab2[,c(9,10,11,8,12,5,1,4,3,2,7,6)] #car model
ctab2_1_car<-ctab2_1_car[,c(1:11)]

#double check column names

colnames(ctab2_1_car)<-colnames(Y2)
ctab2_1_car <-as.matrix(ctab2_1_car)
ctab2_1_car <-log(ctab2_1_car+1)

data.frame(colnames(Y2),colnames(ctab2_1_car))




######################################
### MAKE SITE AND SUMMARY TABLE
######################################

#load in site name and location 
st<-read.csv("sitemeta.csv")
st2<-st[-c(4,7),]

#labels for graph
sitelab2<-unique(x$section_name)[-c(4,7)]
md<-data.frame(st2,sitelab2)
md$altsite<-substr(colnames(Y_car),5,28)

######################################
###FIGURE 1 - MAP AND LOCATION OF SPAWNING SITES
######################################

c1<-c(53.26614,-131.991208)
c2<-c(54.012960, -132.146977)
hdf<-data.frame(rbind(c1,c2))
hdf$sitelab2<-c("Skidegate","Masset")
names(hdf)<-c("Latitude","Longitude","sitelab2")



# 
# #load up the polygons from Blake F.
# setwd("~/Desktop/management_sections")
# gpclibPermit()
# shp.poly <- readOGR(dsn=".", layer="management_sections_bc_dig_watershed_polys_tmer")
# shp.poly@data$id = rownames(shp.poly@data)
# f.shp.poly <-fortify(shp.poly,region="SECTION_NO")
# 
# 
# utmcoor<-SpatialPoints(cbind(utmdata$X,utmdata$Y), proj4string=CRS("+proj=utm +zone=30"))
# #utmdata$X and utmdata$Y are corresponding to UTM Easting and Northing, respectively.
# #zone= UTM zone
# # converting
# longlatcoor<-spTransform(utmcoor,CRS("+proj=longlat"))
# 
# 
# 
# t<-f.shp.poly[,c(1,2)]
# names(t)<-c("X","Y")
# attr(t,"zone")<-6
# convUL(t)
# 
# #polygons alone 
# ggplot(f.shp.poly) + 
#   aes(long,lat,group=group,fill=id) + 
#   geom_polygon() +
#   # geom_path(color="white") +
#   coord_equal()
# 
#   
# 
# hmap <-ggplot()+
#   geom_polygon(data=nepacLLhigh,aes(X,Y,group=PID),
#                fill = "grey50",color="black") + #darkseagreen
#   geom_polygon(data=f.shp.poly,aes(long,lat,group=group,fill=id)) +
#   coord_map(xlim=xlim,ylim=ylim) +
#   labs(y="",x="") +
#   geom_point(data = hdf, aes(x=Longitude,y=Latitude),colour="red",fill="red",size=20,pch=16,alpha=0.5)+
#   geom_point(data = md, aes(x = Longitude, y = Latitude),size=5,colour="dodgerblue",fill="dodgerblue",pch=23)+
#   geom_text(data = md,aes(x = Longitude, y = Latitude,label=sitelab2),size=4,vjust=.1,hjust=-.1)+
#   #   scale_colour_gradient2(midpoint=0.2)+
#   #ggtitle("Pop Growth Estimates")+
#   theme_acs()+
#   theme(legend.position="right")+
#   xlab("Longitude")+
#   ylab("Latitutde")
# 
# print(hmap)



######################################
###FIGURE 2 - SUM OF SPAWN AT LOCAL AND REGIONAL SCALES
######################################

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

ctab3<-melt(ctab2[,-5])
ctab3$presabs<-ifelse(ctab3$value>0,1,0)
ctab3$year<-rep(1950:2015,11)
names(ctab3)<-c("site","value","presabs","year")

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
  theme_acs()+
  facet_wrap(~both,scales="free")+
  scale_colour_manual(values = c("dodgerblue","firebrick"))+
  theme(legend.position="none")+
  #scale_y_continuous(limits=c(0,15))+
  scale_x_continuous(limits=c(1950,2015),breaks=bk)

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
  theme_acs()+
  scale_colour_manual(values = c("dodgerblue","firebrick"))+
  theme(legend.position="none")+
  #scale_y_continuous(limits=c(0,15))+
  scale_x_continuous(limits=c(1950,2015),breaks=bk)+
  xlab("Year")+
  ylab("Sum of Spawn Index")


ggsave("AllSites_Sum_SHI.pdf",width=7,height=3, useDingbats=FALSE)



############Individual Stocklet SHI 

xss<-subset(x,SHI>0 & year > 1949)
xss2<-subset(xss,section_name %in% c("Louscoone Inlet","Juan Perez Sound","Rennell Sound","Skidegate Inlet","Skincuttle Inlet","Englefield Bay"))

bk2<- c(1950,1970,1990,2010)

ggher2<-ggplot(xss,aes(x=year,y=SHI,group=section_name))+
  geom_line(lty=1)+
  geom_point(shape=21,fill="white")+
  #scale_y_log10()+
  theme_acs()+
  #ggtitle("Herring By Spawn Area")+
  facet_wrap(~section_name,scales="free_y")+
  theme(legend.position="none")+
  scale_y_log10(limits=c(100,1000000),
                breaks=c(10^2,10^4,10^6),
                labels = trans_format("log10", math_format(10^.x)))+
  scale_x_continuous(limits=c(1950,2014),breaks=c(1950,1970,1990,2010))
  
#  scale_y_continuous(breaks = trans_breaks("log10", function(x) 10^x)), #FIX THIS
#          labels = trans_format("log10", math_format(10^.x)))

print(ggher2)

#Print out individual stocklets one by one  
library(scales)

nm<-unique(xss2$section_name)
for(i in 1:length(nm)){
  tmp<-subset(xss2,section_name==nm[i])
  
  ggher2<-ggplot(tmp,aes(x=year,y=SHI))+
    geom_point()+
    geom_line(lty=1)+
    #scale_y_log10()+
    theme_acs()+
    #ggtitle("Herring By Spawn Area")+
    #facet_wrap(~section_name,scales="free_y")+
    theme(legend.position="none")+
    scale_x_continuous(limits=c(1950,2014),breaks=bk)+
    scale_y_log10(limits=c(100,1000000),
                  labels = trans_format("log10", math_format(10^.x)))
#     scale_y_continuous(
#                       breaks = trans_breaks("log10", function(x) 10^x), #FIX THIS
#                        labels = trans_format("log10", math_format(10^.x)))
#   
  
  ggsave(paste("SHI",nm[i],".pdf"))

}










######################################
###FIGURE 3 - TOTAL AVERAGE BIOMAASS, SCALED BIOMASS, PROP CONTRIBUTION 
######################################

####Area Plot

tempmat<-scale(model$BUGSoutput$mean$X)
colnames(tempmat) <- colnames(Y_car) #<-seq(1,11,1)
temp2<-melt(tempmat)
colnames(temp2) <-c("time","site","x")
#temp2$site<-as.numeric(temp2$site)
temp2$year<-years
temp2$year<-as.numeric(temp2$year)



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


#just the aveage

ggplot(t3,aes(x=year,y=x))+
  geom_line(size=2)+
  theme_acs()+
  geom_hline(yintercept=0,lty=2)+
  ylab("Total Herring Biomass")+
  xlab("")


#which populations are above and below long term average 
lta<-subset(temp2,year==2015)
lta$ab<-ifelse(lta$x>0,1,0)

dpX<-ggplot()+
  geom_ribbon(data=t3,aes(x=year,ymin=min,ymax=max),colour="grey60")+
  geom_line(data=temp2,aes(x=year,y=x,colour=factor(site),lty=factor(site),group=site))+
  geom_line(data=t3,aes(x=year,y=x),colour="white",size=2)+
  #geom_line(data=t3,aes(x=year,y=max))+
  #geom_line(data=t3,aes(x=year,y=min))+
  #scale_colour_continuous(low="green",high="red")+
  geom_vline(xintercept=1967,colour="grey",lty=2)+ #this is the closure of the reduction 
  geom_vline(xintercept=1994,colour="grey",lty=2)+ #this is the big recent closure 
  geom_hline(yintercept=0)+
  theme_acs()+
  scale_x_continuous(breaks=bk)+
  #coord_trans(y="log10")+
  #scale_y_log10(breaks=c(.1,1,10),labels=c(0.1,1,10))+
  xlab("Year")+
  ylab("Scaled Estimated Total Biomass (B)")+
  theme(legend.position="none")
print(dpX)




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
  geom_line(data=temp2,aes(x=year,y=x,colour=factor(site),lty=factor(site),group=site),size=1)+
  geom_line(data=t3,aes(x=year,y=x),colour="black",size=3)+
  # geom_vline(xintercept=1967,colour="grey",lty=2)+ #this is the closure of the reduction 
  #  geom_vline(xintercept=1994,colour="grey",lty=2)+ #this is the big recent closure 
  theme_acs()+
  scale_x_continuous(breaks=bk)+
  scale_colour_brewer(palette="Spectral")+
  # scale_colour_brewer(colours=rainbow(11))+
  xlab("Year")+
  ylab("Scaled Estimated Total Biomass X")


print(xscalegg)







##########################################################################
###Figure 4 Population Growth Rates at the Archipelago (Umu) and Stocklet Scale (Ui), PDO EFFECT 
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
  geom_hline(yintercept=median(Umudf$value),lty=1,colour="grey")+
  geom_hline(yintercept= umuci2[1],lty=2,colour="grey")+
  geom_hline(yintercept= umuci2[2],lty=2,colour="grey")+
  stat_summary(fun.data=median_hilow,lty=3,pch=21,fill="white")+
  #stat_summary(fun.data=median_hilow,conf.int=0.5)+
  scale_y_continuous(labels = fmt())+
  ylab("Population Growth Rate [Ui]")+
  xlab("")+
  coord_flip()+
  theme_acs()+
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position="none") 

print(ucomp)

#pull out values for Blake 
utab<-ggplot_build(ucomp)$data[[5]]
utab$stocklet<-levels(udf$Var3)


sumtab<-tapply(udf$value,list(udf$Var3),IQR)

  

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

ggplot(pdodf2,aes(x=site,y=medianci))+
  geom_boxplot()+
  geom_point(aes(colour=medianci))+
  scale_colour_gradient2(low="firebrick",high="dodgerblue")+
  coord_flip()+
  theme_acs()+
  scale_y_continuous(limits=c(-0.10,0.4),breaks=c(-0.1,0,0.1,0.2,0.3,0.4))


######################################
###FIGURE 5 FISHING  EFFECTS
######################################

#get all fishing data from 1950-2015
edf1<-melt(model$BUGSoutput$sims.array[,,colnames(myList[[1]])[which(colnames(myList[[1]])=="Pc[1,1]"):which(colnames(myList[[1]])=="Pc[66,11]")]])

names(edf1)<-c("num","chain","response","value")
edf1$chain<-factor(edf1$chain)
edf1$group<-factor(sort(rep(seq(1:11),runL)))
edf1$year<-sort(rep(seq(1:nYears),runL*nSites))

#means of predicted catch across all mcmc iterations
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

#stocklet effects include zeros 
stef<-tapply(temp3$Pc,list(temp3$time),median)
stef2<-data.frame("pc"=stef,"time"=as.numeric(as.character(names(stef))))
zvec<-data.frame("pc"=rep(0,length(1950:2015)),"time"=c(1950:2015))
z2<-merge(stef2,zvec,by="time",all.y=TRUE)
z3<-z2
z3[is.na(z3 <- z2)] <- 0
z3<-z3[,-3]
names(z3)<-c("time","Pc")

bk<-seq(1950,2015,by=10)



#Fishing Frequency 
ff<-data.frame("Pc"=colSums(tapply(temp3$Pc,list(temp3$site,temp3$time),length),na.rm=T)/11,"time"=gmdf$time)
z4<-merge(ff,zvec,by="time",all.y=TRUE)
z5 <- z4
z5[is.na(z5 <- z4)] <- 0
z5<-z5[,-3]
names(z3)<-c("time","Pc")

pcwi<-ggplot(temp3,aes(x=time,y=Pc))+
  #   geom_smooth(method="lm",colour="black",se=F)+
  geom_hline(yintercept=0.2,colour="grey",lty=2)+
  geom_line(data=z3,aes(x=time,y=Pc))+
  #geom_line(data=gmdf,aes(x=time,y=Pc))+
  geom_line(data=gmdfa,aes(x=time,y=Pc),colour="firebrick",lty=2)+
  geom_line(data=z5,aes(x=time,y=Pc),colour="lightblue",size=2)+
  #   geom_ribbon(data=gmdfa,aes(x=time,ymin=min,ymax=max),colour="grey60")+
  #stat_summary(fun.data=median_hilow,lty=2)+
  scale_x_continuous(breaks=bk)+
  theme_acs()+
  theme(legend.position="none")+
  scale_y_continuous(limits=c(0,1))+
  ylab("Proportion Biomass Caught (F)")+
  xlab("Year")

print(pcwi)


#all years 
sort(tapply(temp2$Pc,list(temp2$site),median))


#Fraction of years where fishing happened, 
sort(tapply(temp3$Pc,list(temp3$site),length)/66)
sort(tapply(temp3$Pc,list(temp3$site),median))
sort(tapply(temp3$Pc,list(temp3$site),mean))


pcsiteg<-ggplot(temp3,aes(x=site,y=Pc))+
#   geom_hline(yintercept=median(Umudf$value),lty=2)+
#   geom_hline(yintercept= umuci2[1],lty=1,colour="grey")+
#   geom_hline(yintercept= umuci2[2],lty=1,colour="grey")+
  stat_summary(fun.data=median_hilow,lty=3,pch=21,fill="white")+
  stat_summary(fun.data=median_hilow,conf.int=0.5)+
  scale_y_continuous(labels = fmt())+
  ylab("Fishing Rate [Ui]")+
  xlab("")+
  coord_flip()+
  theme_acs()+
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position="none")  

print(pcsiteg)

#pull out values for Blake 
pctab<-ggplot_build(pcsiteg)$data[[2]]
pctab$stocklet<-levels(temp3$site)

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




######################################
###FIGURE 6 RELATIVE CONTRIBUTION CLIMATE Ui AND PDO
######################################

pcmat<-model$BUGSoutput$mean$Pc
dmat<-model$BUGSoutput$mean$delta
colnames(dmat)<-colnames(Y_car)

colnames(U)<-colnames(Y_car)
umat<-melt(U)

#estiamte each site's median 
tapply(umat$value,list(umat$Var2),median)

pdo<-read.csv("pdo.csv")
pdosummer<-subset(pdo,month %in% c(3,4,5,6)) #average april<-june
pdoxb<-c(tapply(pdo$Value,list(pdo$year),mean))
pdo2<-pdoxb[87:162] #1940-2013
pdo3<-pdo2[11:76] #1950-2013

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


dtotal<-c()
for(i in 1:nrow(dmat)){
  t<-dmat[i,]
  dtotal[i]<-median(t)
}


median(U)

compdf<-data.frame("Umu_delta"=exp(dtotal+median(Umu)),
                   "Umu_pdo"=exp(pdodf$medianci+median(Umu)),
                   "Umu_delta_pdo"=exp(c(dtotal+pdodf$medianci+median(Umu))),
                   "pdoeff" = exp(pdodf$medianci),
                   "year"=years)


#JS's Version
compdf2<-melt(compdf,id.vars=c("year"))
compdf3<-subset(compdf2,variable!="pdoeff")
ggplot(compdf3,aes(x=year,y=value))+
  geom_line(aes(colour=variable))+
  geom_hline(yintercept=exp(median(Umu)),colour="grey")+
  geom_hline(yintercept=c(1),lty=2)+
  theme_acs()+
  ylab("Population Growth Rate")+
  ggtitle("Archipelago Scale")



###
#Stocklet Scale Relative Contribution 
###


dmat<-model$BUGSoutput$mean$delta
colnames(dmat)<-colnames(Y_car)
pdos<-pdodf$medianci
ustring<-tapply(umat$value,list(umat$Var2),median)

umupdo<-matrix(0,nrow=nrow(dmat),ncol=ncol(dmat))
umudelta<-matrix(0,nrow=nrow(dmat),ncol=ncol(dmat))
umudeltapdo<-matrix(0,nrow=nrow(dmat),ncol=ncol(dmat))
pdoeff<-matrix(0,nrow=nrow(dmat),ncol=ncol(dmat))

colnames(umupdo)=colnames(Y_car)
colnames(umudelta)=colnames(Y_car)
colnames(umudeltapdo)=colnames(Y_car)
colnames(pdoeff)=colnames(Y_car)

for(i in 1:ncol(dmat)){
  
  umupdo[,i]<-exp(pdos+ustring[i])
  umudelta[,i]<-exp(dmat[,i]+ustring[i])
  umudeltapdo[,i]<-exp(dmat[,i]+pdos+ustring[i])
  pdoeff[,i]<-exp(pdos)
  
}

dt<-rbind(umupdo,umudelta,umudeltapdo,pdoeff)
dt<-data.frame(dt)
names(dt)<-colnames(dmat)
dt$type<-c(rep("umupdo",nrow(dmat)),
           rep("umudelta",nrow(dmat)),
           rep("umudeltapdo",
               nrow(dmat)),rep("pdoeff",nrow(dmat))
           )

dt$year<-rep(1950:2015,4)
dt2<-melt(dt,id.vars=c("type","year"))

#print into single PDF 

#js additive approach- stocklet
pdf(paste("Climate_ProcessVar_ShiftinTime",Sys.Date(),".pdf"), width=12,onefile = TRUE)

dt2b<-subset(dt2,type!="pdoeff")
ggplot(dt2b,aes(x=year,y=value))+
  geom_line(aes(colour=type))+
  geom_hline(yintercept=1,colour="grey")+
  theme_acs()+
  facet_wrap(~variable,scales="free")+
  scale_colour_discrete(name="Pop Growth",
                   labels=c("Ui+delta", "Ui+delta+pdoeff", "Ui+pdoeff"))+
  ggtitle("Pop Growth by Stocklet")+
  ylab("Population Growth Rate")


#DOTPLOT WHERE GREY LINE IS Pos or Neg GROWTH

dt3<-subset(dt2,type %in% c("umudelta","umudeltapdo"))


ggplot(dt3,aes(x=year,y=value))+
  #geom_line(aes(colour=type))+
  geom_point(aes(colour=type))+
  geom_line(aes(group = year))+
  geom_hline(yintercept=1,colour="grey")+
  theme_acs()+
  facet_wrap(~variable,scales="free")+
  scale_colour_discrete(name="Pop Growth",
                        labels=c("Ui+delta", "Ui+delta+pdoeff"))+
  ggtitle("Pop Growth by Stocklet")+
  ylab("Population Growth Rate")

#just recent years
dt4<-subset(dt3,year>1995)

ggplot(dt4,aes(x=year,y=value))+
  #geom_line(aes(colour=type))+
  geom_point(aes(colour=type))+
  geom_line(aes(group = year))+
  geom_hline(yintercept=1,colour="grey")+
  theme_acs()+
  facet_wrap(~variable,scales="free")+
  scale_colour_discrete(name="Pop Growth",
                        labels=c("Ui+delta", "Ui+delta+pdoeff"))+
  ggtitle("Recent Pop Growth by Stocklet  (1995-present)")+
  ylab("Population Growth Rate")


#just recent years
dt5<-subset(dt3,year>1950 & year<1975)

ggplot(dt5,aes(x=year,y=value))+
  #geom_line(aes(colour=type))+
  geom_point(aes(colour=type))+
  geom_line(aes(group = year))+
  geom_hline(yintercept=1,colour="grey")+
  theme_acs()+
  facet_wrap(~variable,scales="free")+
  scale_colour_discrete(name="Pop Growth",
                        labels=c("Ui+delta", "Ui+delta+pdoeff"))+
  ggtitle("Recent Pop Growth by Stocklet  (1950-1995)")+
  ylab("Population Growth Rate")

sk<-subset(dt3,variable=="SHI.Skidegate Inlet")

sk2 <- reshape(sk, 
             timevar = "type",
             idvar = c("year"),
             direction = "wide")

names(sk2)<-c("year","site","umudelta","site2","umudeltapdo")
sk2$proppdo<-1-(sk2$umudelta/sk2$umudeltapdo)
sk2$test<-(sk2$umudeltapdo-sk2$umudelta)

which(sk2$umudeltapdo >1 & sk2$umudelta<1)
which(sk2$umudelta >1 & sk2$umudeltapdo<1)

#43,48, 49,51,52,58,59


#biplot

#reshaps data to wide format
dt5<-subset(dt2,type %in% c("umudelta","pdoeff"))

dtw <- reshape(dt5, 
             timevar = "type",
             idvar = c("year","variable"),
             direction = "wide")

yf<-c(rep("50s",10),rep("60s",10),rep("70s",10),rep("80s",10),rep("90s",10),rep("00s",16))
dtw$yf<-factor(yf)
dtw$yf=factor(dtw$yf,levels=c("50s","60s","70s","80s","90s","00s"))
dtw$year2<-right(dtw$year,2)
  

ggplot(dtw,aes(x=value.pdoeff,y=value.umudelta,label=year2,group=yf))+
  # geom_line(aes(x=value.pdoeff,y=value.umudelta,colour=yf))+
  # geom_point(aes(colour=yf,pch=yf))+
  geom_text(aes(colour=yf,size=1))+
  geom_hline(yintercept=c(1),colour="grey",lty=2)+
  geom_vline(xintercept=c(1),colour="grey",lty=2)+
  theme_acs()+
  facet_wrap(~variable,scales="free")+
  scale_colour_discrete(name="Decade")+
  ggtitle("Decadal Impacts of Climate")+
  ylab("Population Growth From PDO")+
  xlab("Pop Growth without PDO")

# 
# dt6<-melt(dtw,id.vars=c("year","variable","yf"))
# colnames(dt6)<-c("year","site","yf","type","value")
# ggplot(dt6,aes(x=yf,y=value,colour=type))+
#     stat_summary(fun.data=mean_cl_normal,position=position_dodge(0.95),geom="linerange")+ 
#     stat_summary(fun.y=mean,position=position_dodge(width=0.95),geom="point")+
#   geom_hline(yintercept=c(1),colour="grey",lty=2)+
#   theme_acs()+
#   facet_wrap(~site,scales="free")

#average out and look at two time periods in barplot doesn't help much

dt3$bin<-ifelse(dt3$year<1995,"1950-1994","2001-2015")
dt3b<-subset(dt3,type=="umudeltapdo")

ggplot(dt3b,aes(x=bin,y=value))+
  stat_summary(fun.data=mean_cl_normal,position=position_dodge(0.95),geom="linerange")+ 
  stat_summary(fun.y=mean,position=position_dodge(width=0.95),geom="point")+
  theme_acs()+
  facet_wrap(~variable,scales="free")+
  geom_hline(yintercept=1,colour="grey")+
  xlab("Time Period")+
  ylab("Realized Growth Rate")+
  ggtitle("Stocklet Specific Realized Growth Historically and Recently")
  

dev.off()

stat_sum_df <- function(fun, geom="crossbar", ...) {
  stat_summary(fun.data=fun, colour="red", geom=geom, width=0.2, ...)
}

stat_sum_single <- function(fun, geom="point", ...) {
  stat_summary(fun.y=fun, geom=geom, size = 1, ...)
}

ggplot(dt3b,aes(x=bin,y=value,group=variable))+
  stat_summary(fun.data=mean_cl_normal,position=position_dodge(0.95),geom="linerange")+ 
  stat_summary(fun.y=mean,position=position_dodge(width=0.95),geom="point")+
  stat_sum_single(mean, geom="line")+
  theme_acs()+
  facet_wrap(~variable,scales="free")+
  geom_hline(yintercept=1,colour="grey")+
  xlab("Time Period")+
  ylab("Realized Growth Rate")+
  ggtitle("Stocklet Specific Realized Growth Historically and Recently")


ggplot(dt3b,aes(x=bin,y=value,group=variable))+
  stat_summary(fun.data=mean_cl_normal,position=position_dodge(0.95),geom="linerange")+ 
  stat_summary(fun.y=mean,position=position_dodge(width=0.95),geom="point")+
  stat_sum_single(mean, geom="line")+
  theme_acs()+
  facet_wrap(~variable,scales="free")+
  geom_hline(yintercept=1,colour="grey")+
  xlab("Time Period")+
  ylab("Realized Growth Rate")+
  ggtitle("Stocklet Specific Realized Growth Historically and Recently")

###Stocklets interaction plot

ggplot(dt3b,aes(x=bin,y=value,group=variable,colour=variable,lty=variable))+
  #stat_summary(fun.data=mean_cl_normal,geom="linerange")+ 
  #stat_summary(fun.y=mean,geom="point")+
  stat_sum_single(mean, geom="line")+
  theme_acs()+
  # theme(legend.position="none")+
  #facet_wrap(~variable,scales="free")+
  geom_hline(yintercept=1,colour="grey")+
  xlab("Time Period")+
  ylab("Realized Growth Rate")



