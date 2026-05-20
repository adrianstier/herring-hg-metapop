#plot general HG map
library(PBSmapping)
library(ggplot2)

#load the data
data(nepacLLhigh)

xlim=c(-134.5,-130)
ylim=c(51.5,54.5)

#using the PBS package
plotMap(nepacLLhigh, xlim=xlim, ylim=ylim,
        col="gainsboro",plt=c(.08,.99,.08,.99))

#using ggplot

ggplot() +
  coord_map(xlim=xlim,ylim=ylim) +
  geom_polygon(data=nepacLLhigh,aes(X,Y,group=PID),
               fill = "darkseagreen",color="grey50") +
  labs(y="",x="") 