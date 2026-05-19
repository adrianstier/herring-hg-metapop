
library(ggplot2)
library(reshape2)
library(plyr)
library(maps)
library(mapproj)
library(ggmap)
library(sp)

setwd("~/Dropbox/Projects/In Progress/Pinniped_Herring_HG/Code")
source('theme_acs.R')
source('multiplot.R')

x=read.csv("HG_Spawn_Survey_1940_2013b.csv")
x<- x[c(1,3,13,14,15,16)]
x$SHI2<-log(x$SHI+1)
x$presabs <-ifelse(x$SHI>0,1,0)

##################################################################
############ time in rows, spawn index colums
##################################################################
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

dist_euc<-as.matrix(read.csv("h_dist_euc.csv")[,-1])
dist_euc<-dist_euc[-4,-4]

#estimate the null median nearest neighbor for all sites
null<-rep(NA,ncol(dist_euc))

#estimate the baseline if all neighbors present 
for(j in 1:ncol(dist_euc)){
	ms<-as.numeric(which(dist_euc[,j]>0))
	null[j]<-min(dist_euc[ms,j])
	
}


#calculate mean nearest neighbor distance through time
mnn<-rep(NA,nrow(Y))

for(i in 1:nrow(Y)){
	#subset out each year
	temp<-Y[i,]
	hp<-as.numeric(which(temp>0))
	dt<-dist_euc[hp,hp]

nnvec<-rep(NA,ncol(dt))
	
   for(k in 1:ncol(dt)){
	ms<-as.numeric(which(dt[,k]>0))
	nnvec[k]<-min(dt[ms,k])
}

mnn[i]<-median(nnvec)
	
}

sites<-melt(Y,na.rm=T)

df<-data.frame("year"=seq(1950,2013),
				"nearest_neighbor"=mnn,
				"sumspawn"=rowSums(Y,na.rm=T),
				"num_sites"=as.numeric(tapply(sites$value,list(sites$Var1),length))
				
				)

df2<-melt(df,id.vars=c("year"))

ggplot(df2,aes(x=year,y=value))+
	geom_line()+
	#geom_hline(yintercept=median(null),lty=2,colour="red")+
	facet_grid(variable~.,scales="free")+
	theme_acs()

ss<-subset(df2,variable=="sumspawn")

##draw
psite<-subset(x,presabs>0)
nyear<-seq(1950,2013)

find_hull <- function(df) df[chull(df$Longitude, df$Latitude),]
hulls <- ddply(psite,"year", find_hull)

xmin<-min(x$Longitude)
xmax<-max(x$Longitude)
ymin<-min(x$Latitude)
ymax<-max(x$Latitude)

al1 = get_map(location = c(-135,51.5,-131,55), zoom = 7, maptype = 'terrain')
al1MAP = ggmap(al1)

dispvec<-rep(NA,length(nyear))

for(i in 1:64){
	tempdat<-subset(psite,year==nyear[i])
	temphull<-ddply(tempdat,"year",find_hull)
  cent<-c(mean(tempdat$Longitude),mean(tempdat$Latitude))
	
  #median distance of each point to the centroid
	dispvec[i]<-median(spDistsN1(as.matrix(tempdat[,c(5,6)]),cent))
  #could also 
  
g1<-al1MAP+
	  #geom_point(data = tempdat, aes(x = Longitude, y = Latitude,size=SHI))+
	  geom_polygon(data=temphull,aes(x=Longitude,y=Latitude),alpha=0.2,fill="red")+
	  scale_size(range = c(4, 5))+
	  theme_acs()+
    theme(legend.position="none")
	
  
#   g1<-	ggplot(tempdat,aes(x=Longitude,y=Latitude))+
# 	geom_polygon(data=temphull,alpha=0.2,fill="blue")+
# 	xlim(xmin,xmax)+
# 	ylim(ymin,ymax)+
# 	theme_acs()

ggsum<-ggplot(ss,aes(x=year,y=value))+
    geom_line()+
    ylab("sum of spawn")+
    xlab("year")+
    theme_acs()+
    geom_vline(xintercept=nyear[i],colour="red")


	jpeg(filename = paste(nyear[i],"_dispersion.png"),width = 600, height = 300,)
	  
  multiplot(g1,ggsum,cols=2)
	  
dev.off()
	
}

df3<-data.frame(df,dispvec)
df4<-melt(df3,id.vars=c("year"))

ggplot(df4,aes(x=year,y=value))+
  geom_line()+
  #geom_hline(yintercept=median(null),lty=2,colour="red")+
  facet_grid(variable~.,scales="free")+
  theme_acs()


#look into estimating for each site a B0 and then estimating which sites are .25B0 present (i.e. acessible for fishing)


##################################################################
############
##################################################################



########################################################################
############ plot herrring catch time series by site 
########################################################################

setwd("~/Dropbox/Projects/In Progress/Pinniped_Herring_HG/Code")
c <- read.csv("herring_catch_local.csv")
yr_c<-unique(c$Year)
c$presabs <-ifelse(c$TotalCatch>0,1,0)
c<-subset(c,Section %in% c(1,2,3,5,6,11,12,21,22,23,24,25)) #remove sites that are offshore or don't have data for




tapply(x$SHI,list(x$section),mean)

df <- data.frame(x$section,x$section_name,x$Latitude,x$Longitude)
df2<-df[!duplicated(df), ]

rownames(Y)<-seq(1950,2013)
my<-melt(Y)




df3<-data.frame(df2[-4,],
           "ave_SHI"=tapply(my$value,list(my$Var2),mean,na.rm=T),
           "var_SHI"=tapply(my$value,list(my$Var2),var,na.rm=T),
           "sum_SHI"=tapply(my$value,list(my$Var2),sum,na.rm=T),
           "max_SHI"=tapply(my$value,list(my$Var2),max,na.rm=T)
)


al1 = get_map(location = c(-135,51.5,-131,55), zoom = 7, maptype = 'terrain')
al1MAP = ggmap(al1)

al2 = get_map(location = 'haida gwaii', zoom = 9, maptype = 'terrain')
al2MAP = ggmap(al2)

#average
al2MAP+
  geom_point(data = df3, aes(x = x.Longitude, y = x.Latitude,size=ave_SHI))+
  scale_size(range = c(4, 10))+
  geom_text(data = df3,aes(x = x.Longitude, y = x.Latitude,label=x.section_name),vjust=.1,hjust=-.1,size=5)
  
#max
al2MAP+
  geom_point(data = df3, aes(x = x.Longitude, y = x.Latitude,size=max_SHI))+
  scale_size(range = c(4, 10))+
  geom_text(data = df3,aes(x = x.Longitude, y = x.Latitude,label=x.section_name),vjust=.1,hjust=-.1,size=2)

#max
al2MAP+
  geom_point(data = df3, aes(x = x.Longitude, y = x.Latitude,size=var_SHI))+
  scale_size(range = c(4, 10))+
  geom_text(data = df3,aes(x = x.Longitude, y = x.Latitude,label=x.section_name),vjust=.1,hjust=-.1,size=2)











