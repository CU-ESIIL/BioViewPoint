############################################################################################
########                                                                            ########
########              Determining spatial coordinates of BBS routes                 ######## 
########                                                                            ########
############################################################################################

# Author: Kimberly Thompson

# This code creates a simple features (package sf) dataframe of spatial points for each route
# in the North American Breeding Bird Survey Dataset (subsetted to SW as a pilot).
# The name of the route (as an identifier that can be matched with the biodiversity data)
# is also included.

# Important websites:
# Download shapefile of BBS routes from
# https://www.mbr-pwrc.usgs.gov/bbs/geographic_information/Instructions_trend_route.htm

# This shapefile of routes is from the 2004 release, the USGS no longer maintains
# data on the route paths so we have to work with what we have. 

########## clean workspace and load required packages ####################

# clean workspace to improve efficiency: #
rm(list = ls() )
gc() #releases memory

library(sp)
library(sf)
library(units)

library(ggplot2) # Plotting

library(tidyverse) # Data organization

# Set path to Bioviewpoint folder
path <- "I:/mas/04_personal/Kim_T/BioViewPoint"


###############################################
###                                         ###
###   Some Notes about Coordinate Systems   ###
###                                         ###
###############################################

# Deciding which projection to use
# https://gis.stackexchange.com/questions/104005/choosing-projected-coordinate-system-for-mapping-all-us-states
# Albers Equal Area Conic (Heinrich Albers, 1805): Like Lambert Conformal Conic, 
# this is a very popular map projection for the US, Canada and other continental/large countries
# with a primarily E-W extent. Used by the USGS for maps showing the conterminous United States
# (48 states) or large areas of the United States. Used for many thematic maps, especially
# choropleth and dot density maps.

# From searchable list of codes at http://www.spatialreference.org 
# Could not actually find the epsg code for this reference though
# EPSG code found at this site
#https://guides.library.duke.edu/r-geospatial/CRS
# epsg 5070: USA_Contiguous_Albers_Equal_Area_Conic


###############################################
###                                         ###
###        Load Shapefiles and CSVs         ###
###                                         ###
###############################################


# Define the coordinate system
albers = sp:: CRS("+init=epsg:5070")

# Load USA and Canada shapefile
usa.shape <- sf :: st_read(paste(path, "/00_Data/Raw/USACANAB.shp",
                                 sep = ""))

# Define coordintate system as albers:
usa.shape <- sf :: st_set_crs( usa.shape, albers )


# Load BBS routes shapefile
route.shapefile <- sf :: st_read(paste(path, 
                                       "/00_Data/Raw/BBS/GIS/nabbs02_mis_alb.shp",
                                       sep = ""))

# Define coordintate system as albers:
route.shapefile <- sf :: st_set_crs( route.shapefile, albers )


# Load the BBS route data
bbs_route.data <- read.csv(paste(path, "/00_Data/Processed/BBS/BBS_Routes.csv",
                                 sep = ""),
                           header = TRUE)



###############################################
###                                         ###
###    Convert bbs.routes into sf object    ###
###                                         ###
###                                         ###
###############################################

# Make bbs.route.data an sf object (lat, long in degrees)
bbs_route.data_sf <- sf :: st_as_sf(x = bbs_route.data,
                          coords = c("Longitude", "Latitude"),
                          crs = "+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0")

# Convert crs to albers:
bbs_route.data_sf <- sf :: st_transform( bbs_route.data_sf, albers )



###############################################
###                                         ###
###    Find which route shapes match the    ###
###           bbs observations              ###
###                                         ###
###############################################

# The spatial data provided in the BBS download gives the starting point of
# each route. We need to match the starting point to the vector of route 
# shapes.

# Find the route shape feature that is closest to the bbs observations (point)
closest.route <- st_nearest_feature(bbs_route.data_sf, route.shapefile) 

# Check that the order of the vector of indices for the closest linestring lines up
# with the corresponding point
plot(route.shapefile$geometry[closest.route[1]])
plot(bbs_route.data_sf$geometry[1], add = TRUE)


###############################################
###                                         ###
###    Calculate the distance btw the       ###
###  staring point and the closest route    ###
###                                         ###
###############################################

# Find the nearest points on the linestrings
nearest.points <- st_nearest_points(bbs_route.data_sf, 
                                    route.shapefile[closest.route, ],
                                    pairwise = TRUE)
# Calculate distances
distances <- st_length(nearest.points)

# Make dataframe from distances and convert to integer
df <- data.frame(distance = distances)
df$distance <- as.integer(df$distance)

# Examine frequencies of distances (in meters)
ggplot(df, aes(x = distance)) +
  geom_histogram(binwidth = 100, fill = "steelblue", color = "black") +
  scale_x_continuous(lim = c(0, 2500)) +
  scale_y_continuous(lim = c(0, 300)) +
  labs(title = "Histogram of Distances",
       x = "Distance",
       y = "Frequency") +
  theme_minimal()

# We need to set a threshold for the distance which we fine to be too far to 
# confidently say that the starting point of the route matches the linestring
# of the route
# 1 km (1000 meters) seems appropriate

# Add the distances to bbs_route.data_sf 
bbs_route.data_sf$dist_to_route <- distances


###############################################
###                                         ###
###       Merging point geometry and        ###
###         linestring geometry             ###
###                                         ###
###############################################

# Reduce the Route shapefile based on the vector of indices - this already has
# it in the right order
updated.route.shapefile <- route.shapefile[closest.route, ]

# Create a dataframe with all the information in both the bbs routes df and the
# updated.route df but with the point geometry only
bbs_route.data_sf.point <- cbind(bbs_route.data_sf, updated.route.shapefile) 
bbs_route.data_sf.point$geometry.1 <- NULL

# Create a dataframe with all the information in both the bbs routes df and the
# updated.route df but with the route shape (linestring) geometry only
bbs_route.data_sf.line <- cbind(bbs_route.data_sf, updated.route.shapefile) 
bbs_route.data_sf.line$geometry <- NULL
names(bbs_route.data_sf.line)[21] <- "geometry"


###############################################
###                                         ###
###     Verifying the merge by comparing    ###
###        route names and examining        ###
###             distances                   ###
###############################################

# Make a sepearate dataframe (to aid in visual inspection) with the route
# names

name.comparison <- data.frame(Point.Name = bbs_route.data_sf.point$RouteName,
                              Line.Name = bbs_route.data_sf.point$SRTENAME,
                              Logical = bbs_route.data_sf.point$RouteName == 
                                bbs_route.data_sf.point$SRTENAME,
                              Distance = 
                                as.integer(bbs_route.data_sf.point$dist_to_route))

# Examine the frequency of true/falses
name.comparison %>%
  count(Logical) %>%
  mutate(Prop = prop.table(n))

# 152 falses, 2 NAs

# Visual inspection of these instances to see if it is really a mismatch or
# simply a slight different in how the names were recorded.
# It seems like the distance is a better way to determine the routes to retain
# than matching the names because for some routes it seems the naming convention
# changed either slightly or to a total renaming.

# check if after removing the high distances does this reduce the number of 
# falses
name.comparison_reduced <- name.comparison %>%
  filter(Distance <= 1000)

# Examine the frequency of true/falses
name.comparison_reduced %>%
  count(Logical) %>%
  mutate(Prop = prop.table(n))

###############################################
###                                         ###
###     Pare dataframes to observations     ###
###        that fit distance criteria       ###
###                                         ###
###############################################

# Distance threshold: 1 km

bbs_route.data_sf.line <- bbs_route.data_sf.line %>%
  filter(dist_to_route <= set_units(1000, "m"))

bbs_route.data_sf.point <- bbs_route.data_sf.point %>%
  filter(dist_to_route <= set_units(1000, "m")) 


###############################################
###                                         ###
###     Final Cleaning: Exclude Canada      ###
###               and Alaska                ###
###                                         ###
###############################################

# 840 is the country number of the US
# 3 is the state number of Alaska

bbs_route.data_sf.line <- bbs_route.data_sf.line %>%
  filter(bbs_route.data_sf.line$CountryNum == 840 &
           bbs_route.data_sf.line$StateNum != 3)

bbs_route.data_sf.point <- bbs_route.data_sf.point %>%
  filter(bbs_route.data_sf.point$CountryNum == 840 &
           bbs_route.data_sf.point$StateNum != 3)


# examine results
plot(bbs_route.data_sf.line$geometry,
     col = "black")
plot(usa.shape$geometry, add = TRUE)
plot(bbs_route.data_sf.point$geometry, 
     col = "red", add = TRUE)


###############################################
###                                         ###
###            Write sf objects             ###
###                                         ###
###                                         ###
###############################################

# Write each sf dataframe as a geo json file

st_write(bbs_route.data_sf.point, 
         paste(path, "/00_Data/Processed/BBS_Rtes_Point.geojson",
                                        sep = ""))
st_write(bbs_route.data_sf.line, 
         paste(path, "/00_Data/Processed/BBS_Rtes_Linestring.geojson",
                                       sep = ""))


