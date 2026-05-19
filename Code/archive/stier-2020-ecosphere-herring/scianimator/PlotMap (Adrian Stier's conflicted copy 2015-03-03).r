rm(list=ls())
require(stats)
require(PBSmapping)
require(PBSmodelling)
require(animation)
require(plyr)
require(ggplot2)
require(reshape)
require(ade4)

vpa.rec<-read.table("VPARec.dat",header=T)

start.dir<-getwd()
isob <- c(100,200,300,400,500,1000);
icol <- rgb(0,0,seq(255,100,len=length(isob)),max=255);
data(nepacLLhigh)

##deprecated, plotting the bathymetry makes the map unintelligible
#bcbathy<-read.table("BathyData.dat",header=F,col.names=c("x","y","z"))
#bcbathy$x <- bcbathy$x - 360
#bcbathy$z <- -bcbathy$z
#alBathy <- makeTopography(bcbathy)
#alCL <- contourLines(alBathy,levels=isob)
#alCP <- convCP(alCL)
#alPoly <- alCP$PolySet
#attr(alPoly,"projection") <- "LL"

op<-par(no.readonly = TRUE)

area.names<-c("year","Area2","Area27","HG","PRD","CC","SOG","WCVI")
bat<-read.table("bat.dat",header=T,sep=",") #spawning biomass data
cat<-read.table("cat.dat",header=T,sep=",") #catch data (aggregated across all fleets)


n.colors<-5
label.location<-c(128,54.5)
years<-1951:2014
n.years<-length(years)
her.data<-read.table("ALLSPAWN.csv",header=T,sep=",")
her.data<-her.data[which(her.data$YEAR %in% years),]


hg.areas<-c(1,2)
prd.areas<-c(3, 4, 5)
cc.areas<-c(6, 7, 8, 9, 10)
sog.areas<-c(14, 15, 16, 17, 18, 19, 20, 28, 29)
wcvi.areas<-c(21, 23, 24, 25, 26)
max.obs<-max(her.data$SPAINDEX/1000)
max.spawn.areas<-length(unique(her.data$LOC_NAME))

her.data<-her.data[which(her.data$STATAREA %in% c(hg.areas,prd.areas)),]


map.html.data<-function(in.data,min.obs=0,max.obs=1050,x.range=c(-133.5,-128), y.range=c(51.5,54.5),addBathy=F,out.file.name="herring.html")
{  
  setwd("images")
  file.remove(dir())
  setwd(start.dir)
  oopt = ani.options(interval = 2, nmax = n.years,ani.width=850,ani.height=1100,loop=FALSE,htmlfile=out.file.name)
  
  surveyData<-in.data 
  surveyData<-surveyData[which(is.na(surveyData$loc_lat)==F),] 
  length.raw.data<-length(in.data[,1])
  length.sorted.data<-length(surveyData[,1])
  surveyData$EID<-1:length.sorted.data
  surveyData$Z <- surveyData$SPAINDEX/1000
  surveyData$X<-surveyData$loc_long
  surveyData$Y<-surveyData$loc_lat
  
  #local(envir=.PBSmapEnv,expr={
    oldpar = par(no.readonly=TRUE)
    data(nepacLLhigh,envir=.GlobalEnv) 
  
    saveHTML(
      
      for(i in years)
      {
        p.data<-surveyData[which(surveyData$YEAR==i),]  
        max.z<-max(p.data$Z)
        subset <- p.data[p.data$Z>0, ] 
            
        
        print(i)
        if(length(subset[,1])>=1)
        {  
          subset<-data.frame(EID=p.data$EID,X=p.data$X,Y=p.data$Y,Z=p.data$Z,loc=p.data$LOC_CODE)
          #t.dat<-aggregate(subset$Z, by=list(subset$X,subset$Y),FUN="sum")
        
          #names(t.dat)<-c("X","Y","Z")
          #t.dat$EID<-1:length(t.dat[,1])
          #subset<-t.dat
          #browser()
          plotMap(nepacLLhigh, xlim=x.range, ylim=y.range,
                col="gainsboro",plt=c(.08,.99,.08,.99))
          title(main=paste(i,"                         "),line=-4)
          #if(addBathy==T) addLines(alPoly,col=icol);
          ramp <- colorRamp(c("red", "white"))
          
          addBubbles(subset,type="surface",symbol.bg=rev(heat.colors(n.colors)),
                   legend.type="horiz",z.max=max.obs, legend.breaks=pretty(min.obs:max.obs, n=n.colors),
                   symbol.zero=FALSE, col="grey", min.size=0.1, max.size=0.4)  
        }
        ani.pause()
      },
      description="",
    )
    
    #ani.options(oopt)
    par(oldpar)
    gc()
  
}

spawn.freq<-aggregate(her.data$SPAINDEX>=1,list(her.data$YEAR,her.data$LOC_NAME),sum)
names(spawn.freq)<-c("year","loc","count")
spawn.counts<-table(spawn.freq$year,spawn.freq$loc)
sp.loc.counts<-colSums(t(spawn.counts))
sp.loc.counts<-data.frame(year=as.integer(names(sp.loc.counts)),counts=sp.loc.counts)
sp.loc.counts<-sp.loc.counts[sp.loc.counts$year>max.obs,] #trim off early years

d<-data.frame(bat$year,bat$Area2,bat$Area27,bat$HG,bat$CC,bat$PRD,bat$SOG,bat$WCVI)
c<-data.frame(cat$year,cat$Area2,cat$Area27,cat$HG,cat$CC,cat$PRD,cat$SOG,cat$WCVI)

names(c)<-area.names
names(d)<-area.names

mdata<-melt(d,id=c("year"))
mc.data<-melt(c,id=c("year"))
tot.bio<-bat$sum

plot(sp.loc.counts,type='b',pch=19,ylim=c(0,max(tot.bio)),bty="l",ylab="Occupied spawning localities/SBt")
lines(1951:2014,tot.bio)
#lines(vpa.rec$year,vpa.rec$locregb*5000,col=2)

#remove rows before 1951
sp.loc.counts<-sp.loc.counts[which(sp.loc.counts$year>1950),]
nareas<-sp.loc.counts$count


fit <- lm(nareas ~ tot.bio)
mod<-fit$model
#mod<-mod[order(mod[,2]),]

plot(tot.bio,nareas,pch=19,ylab="No. of areas occupied",xlab=expression(SB[t]))
lines(tot.bio,fit$fitted.values)
label<-paste("r=",round(summary(fit)$r.squared,3))
label=as.character(label,length=5)
rsq<-as.character(round(summary(fit)$r.squared,3))
label2<-bquote(bold(r^2==.(rsq)))

text(1.3*min(tot.bio),max(nareas),labels=label2)

#spawning biomass data
p<-ggplot(mdata, aes(x=year,y=value,group=variable,fill=variable)) 
p + geom_area(position="fill")+ylab("Proportion of SBt")

p<-ggplot(mdata, aes(x=year,y=value,group=variable,fill=variable)) 
p + geom_area(position="stack")+ylab(expression(SB[t]))
#catch data
p<-ggplot(mc.data, aes(x=year,y=value,group=variable,fill=variable)) 
p + geom_area(position="fill")+ ylab("Proportion of catch")

p<-ggplot(mc.data, aes(x=year,y=value,group=variable,fill=variable)) 
p + geom_area(position="stack")+ ylab("Catch (kt)")

on.exit(par(op))

