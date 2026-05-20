#install.packages("devtools")
#devtools::install_github("twitter/BreakoutDetection")
library(BreakoutDetection)

setwd("~/Dropbox/Projects/NOAA Postdoc/Ocean Tipping Points/Research Activities/Case study - Haida Gwaii/Ecosystem Characterization/Analysis/MARSS 1st Pass")

#example from twitter guys
# data(Scribe)
# res = breakout(Scribe, min.size=24, method='multi', beta=.001, degree=1, plot=TRUE)
# res$plot



x=read.csv("all_dat.csv")

spawn <- x[-c(1:11,72:74),19]

plot(hgspawn,type="l")

res = breakout(spawn, min.size=5, method='multi', beta=.008, degree=1, plot=TRUE)
res$plot


#http://blog.ctrsu.org/?p=96
# stuff<-res$plot
# stuff+xlab("HerringSpawnBiomass")
# data$wkyr<-paste(data$Week, data$Year, sep=”-“)
# stuff+labs(y=”Percent of All Deaths Due to \nPneumonia and Influenza”,x=”Week-Year”)
# 
# 
# + scale_x_continuous(breaks=c(seq(from = 1, to = 261, by = 10)),
#                                                  labels = wkyr2) +
#   theme(axis.text.x = element_text(angle = 45, hjust = 1))