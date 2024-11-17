###############################################################################
########                                                               ########
########             Developing 40x40km Regions of Interest            ######## 
########                     Around Each BBS Route                     ########
###############################################################################

# Author: Kimberly Thompson   

# This code generates square polygons around each BBS route, using the midpoint
# of each linestring, such that the midpoint is 20 km from each side of the 
# square.


########## clean workspace and load required packages ####################

# clean workspace to improve efficiency: #
rm(list = ls() )
gc() #releases memory

library(tidyverse) # Data cleaning
library(sf)


###############################################
###                                         ###
###             Data Loading                ###
###                                         ###
###############################################

# Set path to Bioviewpoint folder (where data resides)
# path <- "~/Library/CloudStorage/GoogleDrive-mainelobster28@gmail.com/.shortcut-targets-by-id/1HhR4gs3fKXyAXBhQom6t69gAqR6SeKhx/BioViewPoint"
# path <- "~/share/groups/MAS/04_personal/Kim_T/BioViewPoint"
path <- "I:/mas/04_personal/Kim_T/BioViewPoint"


# Load the spatial linestring file
spatial.data <- sf :: st_read(paste(path,
                                    "/00_Data/Processed/BBS/BBS_Rtes_Linestring.shp",
                                    sep = ""))

# Load USA and Canada shapefile
usa.shape <- sf :: st_read(paste(path, "/00_Data/Raw/USACANAB.shp",
                                 sep = ""))

# Define the coordinate system
albers = sp:: CRS("+init=epsg:5070")

# Define coordintate system as albers:
usa.shape <- sf :: st_set_crs( usa.shape, albers )


###############################################
###                                         ###
###           Calculating Midpoints         ###
###                                         ###
###############################################

# Use st_length to get the total length of each linestring
# each is approximately 40km but will vary
# Use st_line_interpolate with half the length of each line 
# to find the midpoint

# Calculate midpoints
midpoints <- spatial.data %>%
  # Calculate length of each linestring
  mutate(length = st_length(geometry),
         # Find midpoint
         midpoint = st_line_interpolate(geometry, length / 2)) %>%  
  select(midpoint)

###############################################
###                                         ###
###           Generating Squares            ###
###                                         ###
###############################################

# Define the side length of the square (40km)
side_length <- 40000 # in meters

# Define function to create a square polygon around each point
create_square <- function(point, side_length) {
  
  half_side <- side_length / 2
  
  # Create a matrix of corner points for the square
  coords <- matrix(c(
    st_coordinates(point)[1] - half_side, st_coordinates(point)[2] - half_side,
    st_coordinates(point)[1] + half_side, st_coordinates(point)[2] - half_side,
    st_coordinates(point)[1] + half_side, st_coordinates(point)[2] + half_side,
    st_coordinates(point)[1] - half_side, st_coordinates(point)[2] + half_side,
    # Closing the square
    st_coordinates(point)[1] - half_side, st_coordinates(point)[2] - half_side), 
    ncol = 2, byrow = TRUE)
  
  # Create a polygon from the coordinates
  polygon <- st_polygon(list(coords))
  
  return(st_sfc(polygon, crs = st_crs(spatial.data)))
  
}

# Apply the function to create squares for each point
squares <- midpoints %>%
  rowwise() %>%
  mutate(square = list(create_square(midpoint, side_length))) %>%
  unnest(square) %>%
  select(square)

# Convert squares to sf object
squares_sf <- st_sf(squares)


###############################################
###                                         ###
###             Housekeeping                ###
###                                         ###
###############################################


# Create an ID column for both dataframes
squares_sf <- squares_sf %>%
  mutate(id = row_number())  # Create an ID for squares_sf

spatial.data <- spatial.data %>%
  mutate(id = row_number()) %>%  # Create an ID for spatial.data
  select(1:20, id)  # Select only the first 20 columns and the ID

# Combine the dataframes by binding columns
combined_data <- bind_cols(squares_sf, spatial.data)

# Set squares as the active geometry
st_geometry(combined_data) <- combined_data$square

# Remove unwanted columns (e.g., LINESTRING and geometry.1)
combined_data <- combined_data %>%
  select(-c(2, 3, 24, 25))  


# Write the new sf object
st_write(combined_data, 
         paste(path, "/00_Data/Processed/BBS/40km ROIs.shp",
               sep = ""))






