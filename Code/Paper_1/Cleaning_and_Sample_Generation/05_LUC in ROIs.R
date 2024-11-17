###############################################################################
########                                                               ########
########             Calculating Amount of Land-use Change             ######## 
########        Around Each BBS Route's 40km Region of Interest        ########
###############################################################################

# Author: Kimberly Thompson   

# This code uses a the presence/absence of land-use change from 2001-2021 
# (reclassified from NLCD) to sum the cells with change for each 
# Breeding Bird survey Region of Interest (ROI).



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
# path <- "~/Library/CloudStorage/GoogleDrive-mainelobster28@gmail.com/.shortcut-targets-by-id/1HhR4gs3fKXyAXBhQom6t69gAqR6SeKhx/BioViewPoint"
path <- "~/share/groups/MAS/04_personal/Kim_T/BioViewPoint"
# path <- "I:/mas/04_personal/Kim_T/BioViewPoint"

# Load the square polygons (ROIs)
bbs.roi <- sf :: st_read(paste(path,
                                    "/00_Data/Processed/BBS/40km ROIs.shp",
                                    sep = ""))

# Load the National Land Cover Database Change
nlcd <- terra :: rast(paste(path,
                               "/00_Data/Processed/National Land Cover Database/NLCD_PresAb.tiff",
                               sep = ""))

# Define the coordinate system
albers = sp:: CRS("+init=epsg:5070")

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


###############################################
###                                         ###
###         Extract Raster Values           ###
###                                         ###
###############################################

# Move ID column (uniq_rt) for bbs.roi to 1st column
# This will be returned in the extraction
bbs.roi <- bbs.roi[ , c(10, 1:9, 11:21)]

# check and align CRS
if (st_crs(bbs.roi) != crs(nlcd)) {
  bbs.roi <- st_transform(bbs.roi, crs(nlcd))
}


### Testing with just 1 polygon to confirm sum is correct
single_polygon <- bbs.roi[1, ]
plot(nlcd)
plot(st_geometry(single_polygon), add = TRUE, border = 'red')

test.ext <- terra :: extract(nlcd, vect(single_polygon), 
                             touches = TRUE,
                             na.rm = TRUE)

sum(test.ext$Class_Names, na.rm = TRUE)
#267,764 - correct



# Extract the values from the raster to each polygon
start.time <- Sys.time()
extracted_values <- terra :: extract(nlcd, vect(bbs.roi), fun = sum, 
                                     touches = TRUE, bind = TRUE,
                                     na.rm = TRUE)
end.time <- Sys.time()
paste("Extraction finished in ", end.time - start.time, sep = "")

# Convert spatvector to sf object
extracted_sf <- sf :: st_as_sf(extracted_values)

# Rename 'Class_Names' (output of extraction)
names(extracted_sf)[21] <- "change.amt"

# Sort by amount of change
extracted_sf <- arrange(extracted_sf, desc(change.amt))

# Write the shapefile with change
st_write(extracted_sf, 
         paste(path, "/01_Analyses/BBS and LULC/BBS_Rtes_wLULC.shp",
               sep = ""))


###############################################
###                                         ###
###        Examine top and bottom 10%       ###
###                                         ###
###############################################

# top and bottom 10% of change
top <- extracted_sf[ c(1:198) , ]
bottom <- extracted_sf[ c(1787:1984), ]

ggplot() +
  geom_sf(data = usa.shape, fill = "lightgrey") +
  geom_sf(data = top, fill = "blue", color = "black") +
  geom_sf(data = bottom, fill = "red", color = "black")

# top and bottom 20% of change
top.20 <- extracted_sf[ c(1:396), ]
bottom.20 <- extracted_sf[ c(1589:1984), ]

ggplot() +
  geom_sf(data = usa.shape, fill = "lightgrey") +
  geom_sf(data = top.20, fill = "blue", color = "black") +
  geom_sf(data = bottom.20, fill = "red", color = "black")

  
ggplot(extracted_sf, aes(x = change.amt)) +
  geom_histogram(binwidth = 1000, fill = "blue", color = "black")







