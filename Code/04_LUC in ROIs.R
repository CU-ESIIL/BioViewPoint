###############################################################################
########                                                               ########
########             Calculating Amount of Land-use Change             ######## 
########        Around Each BBS Route's 40km Region of Interest        ########
###############################################################################

# Author: Kimberly Thompson   

# This code reclassfies land-use change from type of change (e.g., habitat
# type 1 to habitat type 2) to a presence/absences of change and then 
# the sum of presences from 2001 to 2021 to identify regions of interest
# with the highest and loweest change.


########## clean workspace and load required packages ####################

# clean workspace to improve efficiency: #
rm(list = ls() )
gc() #releases memory

library(tidyverse) # Data cleaning
library(sf)
library(terra)

###############################################
###                                         ###
###             Data Loading                ###
###                                         ###
###############################################

# Set path to Bioviewpoint folder (where data resides)
path <- "~/Library/CloudStorage/GoogleDrive-mainelobster28@gmail.com/.shortcut-targets-by-id/1HhR4gs3fKXyAXBhQom6t69gAqR6SeKhx/BioViewPoint"
# path <- "~/share/groups/MAS/04_personal/Kim_T/BioViewPoint"
# path <- "I:/mas/04_personal/Kim_T/BioViewPoint"

# Load the square polygons (ROIs)
bbs.roi <- sf :: st_read(paste(path,
                                    "/00_Data/Processed/BBS/40km ROIs.shp",
                                    sep = ""))

# Load the National Land Cover Database Change
nlcd <- terra :: rast(paste(path,
                               "/00_Data/Raw/National Land Cover Database/nlcd_2001_2021_land_cover_change_index_l48_20230630.img",
                               sep = ""))


###############################################
###                                         ###
###   Reclassify Land Use Change Raster     ###
###                                         ###
###############################################

# We want to know primarily, which areas have experienced the most (and least)
# change, as opposed to knowing the specific types of change.
# Because the goal is to filter the BBS routes based on amounts of change.

# Display categories
levels(nlcd)

#       value                           Class_Names
# 1       0                                      
# 2       1                             no change
# 3       2                          water change
# 4       3                          urban change
# 5       4           wetland within class change
# 6       5             herbaceous wetland change
# 7       6       agriculture within class change
# 8       7                cultivated crop change
# 9       8                    hay/pasture change
# 10      9 rangeland herbaceous and shrub change
# 11     10                         barren change
# 12     11                         forest change
# 13     12                  woody wetland change
# 14     13                           snow change
# And numbers above with no cat name

# Create a reclassification matrix
# This matrix tells R to:
#         Reclassify value 1 to 0
#         Reclassify values 2 through 13 to 1
#         Reclassify values 14 and above to 0
rcl <- matrix(c(1, 1, 0,
                2, 13, 1,
                14, Inf, 0), 
              ncol=3, byrow=TRUE)

# Apply the reclassification
nlcd_reclass <- classify(nlcd, rcl)

# Define the levels of the reclassification
levels(nlcd_reclass) <- data.frame(id=c(0,1), class=c("None", "Target"))





# Define the coordinate system
albers = sp:: CRS("+init=epsg:5070")

crs(nlcd) == crs(bbs.roi)


