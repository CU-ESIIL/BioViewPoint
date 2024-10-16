###############################################################################
########                                                               ########
########             Reclassifying NLCD Change Map                     ######## 
########            into Presence/Absence of change                    ########
###############################################################################

# Author: Kimberly Thompson   

# This code reclassfies land-use change from 2001 to 2021 from type of change (e.g., habitat
# type 1 to habitat type 2) to a presence/absences of change.

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
# path <- "~/Library/CloudStorage/GoogleDrive-mainelobster28@gmail.com/.shortcut-targets-by-id/1HhR4gs3fKXyAXBhQom6t69gAqR6SeKhx/BioViewPoint"
# path <- "~/share/groups/MAS/04_personal/Kim_T/BioViewPoint"
path <- "I:/mas/04_personal/Kim_T/BioViewPoint"

# Load the square polygons (ROIs)
bbs.roi <- sf :: st_read(paste(path,
                                    "/00_Data/Processed/BBS/40km ROIs.shp",
                                    sep = ""))

# Load the National Land Cover Database Change
nlcd <- terra :: rast(paste(path,
                               "/00_Data/Raw/National Land Cover Database/nlcd_2001_2021_land_cover_change_index_l48_20230630.img",
                               sep = ""))


###############################################
###        *** ONLY DONE oNCE ***           ###
###   Reclassify Land Use Change Raster     ###
###                                         ###
###############################################

# *** if already done skip to line 

# We want to know primarily, which areas have experienced the most (and least)
# change, as opposed to knowing the specific types of change.
# Because the goal is to filter the BBS routes based on amounts of change.

# Display categories
levels(nlcd)[[1]]

levels_nlcd <- levels(nlcd)[[1]]

levels_df <- data.frame(
  Value = seq_along(levels_nlcd),  # Integer values from 1 to number of levels
  Level = levels_nlcd
)


# value                           Class_Names
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
#         Reclassify value 1 to NA
#         Reclassify value 2 to 0
#         Reclassify values 3 through 14 to 1
#         Reclassify values 15 and above to 0
rcl <- matrix(c(1, 1, NA,
                2, 2, 0,
                3, 14, 1,
                15, Inf, 0), 
              ncol=3, byrow=TRUE)

# Apply the reclassification
nlcd_reclass <- terra :: classify(nlcd, rcl, include.lowest = TRUE, right = NA,
                                  othersNA = TRUE)

nlcd_reclass
plot(nlcd_reclass)


# Write the reclasified raster 
writeRaster(nlcd_reclass, paste(path, "/00_Data/Processed/National Land Cover Database/NLCD_PresAb.tiff",
                                sep = ""),
                                overwrite = TRUE)



