# Making a map of Alaska for herring data

library(maps)

########################################################
#
# This is sample code for creating a map of a region
# and displaying a small inset map for orientation
#
# Eli Gurarie
# edited by Ian Taylor538855414

#
########################################################

# basic mapmaking functions
library(maps)

# more high-resolution world data (you might not need but what the heck)
library(mapdata)

# extra stuff like gridlines, etc.
library(mapproj)

# make basic map
map("worldHires",
    ylim=c(51,55),xlim=c(-150,-125.5),
    col="black",fill=T)