library(ggplot2)
library(reshape2)

setwd("~/Dropbox/Projects/In Progress/Herring_Haida_Gwaii/Code")

#setwd("~/Desktop/Herring_Section")
source('multiplot.R')
source('theme_acs.R')

x=read.csv("ALLSPAWN.csv")
hg<-subset(x,SECTION %in% c(1,2,3,5,6,11,12,21,23,24,25))

tapply(hg$SECTCOEFF,list(hg$YEAR,hg$SECTION),mean)
