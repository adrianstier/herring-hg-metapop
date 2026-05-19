# calculate nearest neighbor distances. Required input is a SpatialPoints object.

library(sp) # coordinates()
library(spdep) # knearneigh
library(gmt) #geodist, masked by bipartite because specieslevel uses geodist from package sna

#DAT = data
#COL = column name of suite of species to calculate NND (e.g. DATA$anemone)
#OBJ = object of species names

# was using DAT[,4:5] in split, worked, but is more generalizable with column names
nn.dist<-function(DAT, COL, OBJ){
	databyCOL<-split(DAT[,c("lat","lon")], COL)
	databyCOL<-databyCOL[OBJ]
	databyCOL<-sapply(databyCOL, unique, simplify=FALSE)
	for(i in 1:length(databyCOL)){
		coordinates(databyCOL[[i]])<-c("lon","lat")
		proj4string(databyCOL[[i]])<-CRS('+proj=lonlat')
	}
	nearestneighbors<-lapply(databyCOL, knearneigh, k=1, longlat=TRUE, RANN=FALSE)
	df.nn<-vector("list", length(nearestneighbors))
	names(df.nn)<-names(nearestneighbors)
	for(i in 1:length(nearestneighbors)){
		df.nn[[i]]<-data.frame(from=1: nearestneighbors[[i]]$np, fromX= nearestneighbors[[i]]$x[,1], fromY= nearestneighbors[[i]]$x[,2], to= nearestneighbors[[i]]$nn[,1], toX= nearestneighbors[[i]]$x[nearestneighbors[[i]]$nn[,1],1], toY= nearestneighbors[[i]]$x[nearestneighbors[[i]]$nn[,1],2])
	}
	df.nn<-lapply(df.nn, cbind, geodist="NA")
	max.nn<-vector("list", length(df.nn))
	names(max.nn)<-names(df.nn)
	for(i in 1:length(df.nn)){
		df.nn[[i]]$geodist<-gmt::geodist(Nfrom=df.nn[[i]]$fromY, Efrom=df.nn[[i]]$fromX, Nto=df.nn[[i]]$toY, Eto=df.nn[[i]]$toX, units="km")
		max.nn[[i]]<-max(df.nn[[i]]$geodist)
	}
	nn.distances<-list(df.nn, max.nn)
	return(nn.distances)
}

nn.fishes<-nn.dist(DAT=DATA.sdm, COL=DATA.sdm$fish, OBJ=fish)
nn.anemones<-nn.dist(DAT=DATA.sdm, COL=DATA$anemone, OBJ=anemones)
nn.max.fishes<-data.frame(species=names(nn.fishes[[2]]), max.nn=as.numeric(nn.fishes[[2]]))
nn.max.anemones<-data.frame(species=names(nn.anemones[[2]]), max.nn=as.numeric(nn.anemones[[2]]))
summary(nn.max.anemones)
summary(nn.max.fishes)
#save(nn.fishes, file="nn.fishes.RData")
#save(nn.anemones, file="nn.anemones.RData")
nn.dists.fish<-lapply(nn.fishes[[1]], "[", "geodist")
nn.dists.anem<-lapply(nn.anemones[[1]], "[", "geodist")

par(mar=c(5,7,3,1), mfcol=c(1,2))
boxplot(sapply(nn.dists.anem, "[[", 1), horizontal=TRUE, las=1, xlab="Nearest Neighbor Distances (km)", main="Anemones")
boxplot(sapply(nn.dists.fish, "[[", 1), horizontal=TRUE, las=1, xlab="Nearest Neighbor Distances (km)", main="Fish")

pdf(file="figure_nn_dist.pdf")
dev.off()

# Here's how to access the second greatest value nn distance:
temp<-as.list(sapply(nn.dists.anem, "[[", 1))
mean(sapply(temp, function(x) sort(x)[length(x)-2]))
median(sapply(temp, function(x) sort(x)[length(x)-2]))


#################### OLD ######################################
# original:
DATA.anem<-DATA
databyanemone<-split(DATA.anem[,4:5], DATA.anem$anemone)
databyanemone<-sapply(databyanemone, unique, simplify=FALSE)
for(i in 1:length(databyanemone)){
	coordinates(databyanemone[[i]])<-c("lon","lat")
	proj4string(databyanemone[[i]])<-CRS('+proj=lonlat')
}
# Therefore, databyanemone is a list of SpatialPoints objects.

# all at once
anemone.nn<-lapply(databyanemone, knearneigh, k=1, longlat=TRUE)

# load up those to and from points to dataframes
df.nn<-vector("list", length(anemone.nn))
names(df.nn)<-names(anemone.nn)
for(i in 1:length(anemone.nn)){
	df.nn[[i]]<-data.frame(from=1:anemone.nn[[i]]$np, fromX=anemone.nn[[i]]$x[,1], fromY=anemone.nn[[i]]$x[,2], to=anemone.nn[[i]]$nn[,1], toX=anemone.nn[[i]]$x[anemone.nn[[i]]$nn[,1],1], toY=anemone.nn[[i]]$x[anemone.nn[[i]]$nn[,1],2])
}

df.nn<-lapply(df.nn, cbind, geodist="NA")
max.nn<-vector("list", length(df.nn))
names(max.nn)<-names(df.nn)
for(i in 1:length(df.nn)){
	df.nn[[i]]$geodist<-geodist(Nfrom=df.nn[[i]]$fromY, Efrom=df.nn[[i]]$fromX, Nto=df.nn[[i]]$toY, Eto=df.nn[[i]]$toX, units="km")
	max.nn[[i]]<-max(df.nn[[i]]$geodist)
}

nn.dist<-list(df.nn, max.nn)

####
# FOR THE FISH:
####
DATA.fish<-DATA[DATA$fish %in% fish,]
DATA.fish$fish<-factor(DATA.fish$fish)
levels(DATA.fish$fish)
data.nn.fish<-split(DATA.fish[,c("lat","lon")], DATA.fish$fish)
data.nn.fish<-sapply(data.nn.fish, unique, simplify=FALSE)
for(i in 1:length(data.nn.fish)){
	coordinates(data.nn.fish[[i]])<-c("lon","lat")
	proj4string(data.nn.fish[[i]])<-CRS('+proj=lonlat')
}

#eliminate those with two few records; will cause problems otherwise
data.nn.fish[c(names(which(lapply(data.nn.fish, length)==1)))]<-NULL

# all at once
nn.fish<-lapply(data.nn.fish, knearneigh, k=1, longlat=TRUE)

# load up those to and from points to dataframes
nn.df<-vector("list", length(nn.fish))
names(nn.df)<-names(nn.fish)
for(i in 1:length(nn.fish)){
	nn.df[[i]]<-data.frame(from=1: nn.fish[[i]]$np, fromX= nn.fish[[i]]$x[,1], fromY= nn.fish[[i]]$x[,2], to= nn.fish[[i]]$nn[,1], toX= nn.fish[[i]]$x[nn.fish[[i]]$nn[,1],1], toY= nn.fish[[i]]$x[nn.fish[[i]]$nn[,1],2])
}

nn.df<-lapply(nn.df, cbind, geodist="NA")
max.nn<-vector("list", length(nn.df))
names(max.nn)<-names(nn.df)
for(i in 1:length(nn.df)){
	nn.df[[i]]$geodist<-geodist(Nfrom= nn.df[[i]]$fromY, Efrom= nn.df[[i]]$fromX, Nto= nn.df[[i]]$toY, Eto= nn.df[[i]]$toX, units="km")
	max.nn[[i]]<-max(nn.df[[i]]$geodist)
}

radius.fish<-list(nn.df, max.nn)
str(radius.fish)
nearest.neighbors.max.fish<-data.frame("max.nn"=as.numeric(max.nn), row.names=names(max.nn))
summary(nearest.neighbors.max.fish)
write.csv(nearest.neighbors.max.fish, file="nearest.neighbors.max.fish.csv")

#GRAVEYARD
# geodist(Nfrom=df$fromY, Efrom=df$fromX, Nto=df$toY, Eto=df$toX, units="km")
# single species example
nn.malu<-knearneigh(databyanemone$malu, k=1, longlat=TRUE)
#single species
df <- data.frame(from=1:nn.malu$np, fromX=nn.malu$x[,1], fromY=nn.malu$x[,2], to=nn.malu$nn[,1], toX=nn.malu$x[nn.malu$nn[,1],1], toY=nn.malu$x[nn.malu$nn[,1],2])