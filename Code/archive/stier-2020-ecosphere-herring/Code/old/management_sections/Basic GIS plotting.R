### THIS IS A FILE TO LOAD AND PRIMITIVELY DISPLAY THE GIS SHAPEFILES

#### Learning how to use shapefiles in R

### Basic packages ###
 
library(sp)             # classes for spatial data
library(raster)         # grids, rasters
library(rasterVis)      # raster visualisation
library(maptools)
library(maps)
library(mapdata)
library(rgdal)
library(ggplot2)
library(gridExtra)
library(ggmap)

library(INLA)
library(lattice)
library(PBSmapping)
library(date)
library(ncdf)
library(fields)
library(mvtnorm)
library(splancs)


## READ IN THREE FILES- OBSERVATIONS (BLAKE DERIVED), SHORLELINE SEGMENTS (BLAKE DERIVED), REORDERED SHORLELINE  SEGMENTS (OLE DERIVED)
##########################################################################################
setwd("/Users/ole.shelton/GitHub/exxonValdez_nceas/GIS grid GOA/")
shp.poly		<-	readOGR(dsn=".",layer="two_km_gridcells_ak_albers")
shp.centroid	<-	readOGR(dsn=".","Two_km_gridcell_centroids_Final_Geo_WGS84")

dat.centroid		<- as(shp.centroid,"data.frame")
dat.centroid$SRTM_M <- as.numeric(as.integer(dat.centroid$SRTM_M))
#spplot(shp.centroid)


# > min(dat.centroid$LONGITUDE)
# [1] -172.7814
# > max(dat.centroid$LONGITUDE)
# [1] -130.6438
# > max(dat.centroid$LATITUDE)
# [1] 61.51267
# > min(dat.centroid$LATITUDE)
# [1] 51.69195

# commands for identifying bounding boxes
#bbox(shp.poly)
#bbox(shp.centroid)

### This doesn't work because the two are in different coordinate systems.... but this is the form for how you would overlay.
#over(shp.centroid,shp.poly)

summary(shp.poly)
summary(shp.centroid)
##########################################################################################
##########################################################################################
##########################################################################################
### THIS IS HOW TO MAKE SPATIAL PLOTS IN R using GGPLOT
##########################################################################################
##########################################################################################
##########################################################################################

# Some Arguments for making prettier plots
bGrid <-theme(panel.grid =element_blank())
bBack <-theme(panel.background =element_blank())
bAxis <-theme(axis.title.y =element_blank())
bTics <-theme(axis.text =element_blank(), axis.text.y =element_blank(), axis.ticks =element_blank())

###
setwd("/Users/ole.shelton/GitHub/exxonValdez_nceas/GIS grid GOA/census")
shp.states	<-	readOGR(dsn=".",layer="cb_2013_us_state_5m")
shp.alaska 		<- shp.states[shp.states$NAME=="Alaska",]

### MAKE AN Albers projection (good for east - west oriented areas like alaska)
## THIS IS THE SPOT WHERE YOU SHOULD CHANGE THE PROJECTION INFORMATION AND MAKE SURE THE TWO FILES ARE IN THE SAME UNITS.
aea.proj <- "+proj=aea +lat_1=51 +lat_2=62 +lon_0=-150 +x_0=0 +y_0=0 +datum=WGS84"

shp.alaska.3 	<- spTransform(shp.alaska, CRS(aea.proj))
dat.alaska.3 	<- fortify(shp.alaska.3,"data.frame")

# setwd("/Users/ole.shelton/GitHub/exxonValdez_nceas/GIS grid GOA/census")
# writeOGR(shp.alaska.3, ".", "Alaska-Albers", driver="ESRI Shapefile")

shp.centroid.2 <- spTransform(shp.centroid, CRS(aea.proj))
dat.centroid.2 <- as(shp.centroid.2,"data.frame")
colnames(dat.centroid.2)[match(c("coords.x1","coords.x2"),colnames(dat.centroid.2))] <- c("x","y")

# Make a second plot with the depth contours (this one is better)
dat.trim	<-	dat.centroid.2 [dat.centroid.2$NGDC24_M <= 0,] # get rid of the land.
dat.trim$NGDC24_M[dat.trim$NGDC24_M < -1000]	<-	-1000 # pretend everywhere > 1000m deep = 1000 m


### ADD ALASKA GIS LAYERS
p4	<-	ggplot() +
		scale_size(range = c(1,1))+
  		scale_colour_gradient(limits=c(-1001, 0),"Depth (m)",low="black",high="#98F5FF")+
    	geom_point(data=dat.trim,alpha=0.3,
    			mapping=aes(x,y,colour=NGDC24_M)) + 
		geom_polygon(data=dat.alaska.3, fill=grey(0.4),color=NA,aes(long,lat,group=group)) +
		labs(x = "Eastings",y="Northings",title="Depth (NGDC24_M)")+
  		coord_cartesian(xlim = c(min(dat.trim$x)*1.01,max(dat.trim$x)), ylim = c(min(dat.trim$y),6500000))+
 		bGrid  + bBack 
p4

setwd("/Users/ole.shelton/GitHub/exxonValdez_nceas/goaTrawl/")
dat.trawl<-read.csv("goa_500trawls_albers.csv")	
### ADD trawl locations
p5	<-	ggplot() +
		scale_size(range = c(1,1))+
  		scale_colour_gradient(limits=c(-1001, 0),"Depth (m)",low="black",high="#98F5FF")+
    	geom_point(data=dat.trim,alpha=0.3,
    			mapping=aes(x,y,colour=NGDC24_M)) + 
    	geom_point(data=dat.trawl,alpha=0.8,shape = "+",colour=grey(0.2),
    			mapping=aes(LonUTMAlbers,LatUTMAlbers)) + 
		geom_polygon(data=dat.alaska.3, fill=grey(0.4),color=NA,aes(long,lat,group=group)) +
		labs(x = "Eastings",y="Northings",title="Depth (NGDC24_M)")+
  		coord_cartesian(xlim = c(min(dat.trim$x)*1.01,max(dat.trim$x)), ylim = c(min(dat.trim$y),6500000))+
 		bGrid  + bBack 
p5



setwd("/Users/ole.shelton/GitHub/exxonValdez_nceas/GIS grid GOA")
# Write to File
pdf("Alaska Depth 2.pdf",onefile=TRUE,width=15,5)
		print(p4)
dev.off()

pdf("Alaska Depth 2 +trawl.pdf",onefile=TRUE,width=15,5)
		print(p5)
dev.off()














