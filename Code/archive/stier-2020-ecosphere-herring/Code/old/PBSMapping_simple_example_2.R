#plot general HG map
library(PBSmapping)
library(ggplot2)


###############
#Haida Gwaii
###############

#load the data
data(nepacLLhigh)

xlim=c(-134.5,-130)
ylim=c(51.5,54.5)

#using the PBS package (basically base R)

plotMap(nepacLLhigh, xlim=xlim, ylim=ylim,
        col="gainsboro",plt=c(.08,.99,.08,.99))


#using ggplot

ggplot() +
  coord_map(xlim=xlim,ylim=ylim) +
  geom_polygon(data=nepacLLhigh,aes(X,Y,group=PID),
               fill = "darkseagreen",color="grey50") +
  labs(y="",x="") 
  
 
###############
#Puget Sound
###############
xlim=c(-124.0,-122)
ylim=c(47,49)

#using the PBS package (basically base R)

plotMap(nepacLLhigh, xlim=xlim, ylim=ylim,
        col="gainsboro",plt=c(.08,.99,.08,.99))

#make example vector
evec<-rpois(10,10)
elong<-rnorm(10,-123,.5)
elat<-rnorm(10,48,.5)

edf<-data.frame("longitude"=elong,"latitude"=elat,"value"=evec)

#using ggplot
ggplot() +
  coord_map(xlim=xlim,ylim=ylim) +
  geom_polygon(data=nepacLLhigh,aes(X,Y,group=PID),
               fill = "lightgrey",color="grey50") +
  geom_point(data=edf,aes(x= longitude,y= latitude,size=value,colour=value))+
  scale_colour_gradient(low="red",high="dodgerblue")+
  scale_size(range = c(4, 10),name="Value")+
  labs(y="",x="")+
  theme_bw()
  
  
  
  
