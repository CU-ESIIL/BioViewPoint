###############################################################################
########                                                               ########
########             Examining which BBS regions of interest           ######## 
########                  intersect with wildfires                     ########
###############################################################################

# Author: Kimberly Thompson   

# This code uses data showing the perimeters of wildfires from 2000-2018 from
# the National Interagency Fire Center to check if any of the defined regions
# of interest (derived from the top and bottom 10% of land use change) occur
# in an area with a historical fire (if yes, then these will be filtered out 
# and replaced).



########## clean workspace and load required packages ####################

# clean workspace to improve efficiency: #
rm(list = ls() )
gc() #releases memory

library(tidyverse) # Data cleaning
library(sf)
library(terra)
library(ggplot2)


###############################################
###                                         ###
###             Data Loading                ###
###                                         ###
###############################################

# Set path to Bioviewpoint folder (where data resides)
path <- "~/Library/CloudStorage/GoogleDrive-mainelobster28@gmail.com/.shortcut-targets-by-id/1HhR4gs3fKXyAXBhQom6t69gAqR6SeKhx/BioViewPoint"
# path <- "~/share/groups/MAS/04_personal/Kim_T/BioViewPoint"
# path <- "I:/mas/04_personal/Kim_T/BioViewPoint"

# Define the coordinate system
albers = sp:: CRS("+init=epsg:5070")

# Load the square polygons (ROIs) with the column containing amount of change
bbs.roi <- st_read(paste(path, "/01_Analyses/BBS and LULC/BBS_Rtes_wLULC.shp", 
                         sep = ""))

bbs.roi <- sf :: st_transform(bbs.roi, albers)

# Load USA and Canada shapefile
usa.shape <- sf :: st_read(paste(path, "/00_Data/Raw/USACANAB.shp",
                                 sep = ""))

# Define coordintate system as albers:
usa.shape <- sf :: st_set_crs( usa.shape, albers )

# Remove Canada and Alaska
usa.shape <- usa.shape[usa.shape$STATE != "NWT" & usa.shape$STATE != "AK" &
                         usa.shape$STATE != "YT" & usa.shape$STATE != "BC" &
                         usa.shape$STATE != "QUE" & usa.shape$STATE != "LAB" &
                         usa.shape$STATE != "ALB" & usa.shape$STATE != "SAS" &
                         usa.shape$STATE != "xx" & usa.shape$STATE != "MAN" &
                         usa.shape$STATE != "NFD" & usa.shape$STATE != "ONT" &
                         usa.shape$STATE != "NS" & usa.shape$STATE != "NB" &
                         usa.shape$STATE != "PEI", ]

# Load the fire perimeter data
fire <- sf :: st_read(paste(path, 
                       "/00_Data/Raw/National Interagency Fire Center/US_HIST_FIRE_PERIMTRS_2000_2018_DD83.shp",
                       sep = ""))

# Transform to albers
fire <- sf :: st_transform(fire, albers)


###############################################
###                                         ###
###         Fire and ROI overlap            ###
###                                         ###
###############################################

# Check the validity of fire geometries
valid_fire <- st_is_valid(fire)

# Remove polygons with invalid geometries
invalid.fire <- which(valid_fire == FALSE)
fire <- fire[!(1:nrow(fire) %in% invalid.fire), ]

# Calculate the intersection
overlap <- sf :: st_intersection(bbs.roi, fire)

# Calculate the area of each overlap
overlap <- overlap %>%
  mutate(intersect_area = st_area(geometry))

length(unique(overlap$uniq_rt))
#705 routes


###############################################
###                                         ###
###         Filter the BBS routes           ###
###                                         ###
###############################################

# Make a vector of the routes to remove
routes.to.remove <- unique(overlap$uniq_rt)

# Remove from the BBS ROI
bbs.roi_revised <- bbs.roi[!(bbs.roi$uniq_rt %in% routes.to.remove), ]

# Write the revised sf object
st_write(bbs.roi_revised, 
         paste(path, "/01_Analyses/BBS and LULC/BBS_Rtes_wLULC_minusfire.shp",
               sep = ""))


###############################################
###                                         ###
###     Examine top and bottom 10% & 20%    ###
###                                         ###
###############################################

# top and bottom 10% of change
top <- bbs.roi_revised[ c(1:127) , ]
bottom <- bbs.roi_revised[ c(1153:1279), ]

ggplot() +
  geom_sf(data = usa.shape, fill = "lightgrey") +
  geom_sf(data = top, fill = "blue", color = "black") +
  geom_sf(data = bottom, fill = "red", color = "black")

# top and bottom 20% of change
top.20 <- bbs.roi_revised[ c(1:254), ]
bottom.20 <- bbs.roi_revised[ c(1026:1279), ]

ggplot() +
  geom_sf(data = usa.shape, fill = "lightgrey") +
  geom_sf(data = top.20, fill = "blue", color = "black") +
  geom_sf(data = bottom.20, fill = "red", color = "black")
