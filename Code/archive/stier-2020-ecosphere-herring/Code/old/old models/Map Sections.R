#https://github.com/hadley/ggplot2/wiki/plotting-polygon-shapefiles

require("rgdal") # requires sp, will use proj.4 if installed
require("maptools")
require("ggplot2")
require("plyr")
library(PBSmapping)

gpclibPermit()

setwd("~/Desktop/management_sections")

shp.poly <- readOGR(dsn=".", layer="management_sections_bc_dig_watershed_polys_tmer")

shp.poly@data$id = rownames(shp.poly@data)

# shp.poly@data$id = shp.poly@data$SECTION_NO
f.shp.poly <-fortify(shp.poly,region="id")

ggplot(f.shp.poly) + 
  aes(long,lat,group=group,fill=id) + 
  geom_polygon() +
  # geom_path(color="white") +
  coord_equal()


