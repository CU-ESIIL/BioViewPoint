###############################################################################
########                                                               ########
########                  Final Cleaning of BBS Data                   ######## 
########                                                               ########
###############################################################################

# Author: Kimberly Thompson   

# This code harmonizes BBS data including stop-level breeding species counts,
# route data, weather data, and migrant data with the spatial data for the 
# routes, which has already undergone final cleaning to represent only 
# quality routes (adhering to quality and protocols) in the contiguous USA.


########## clean workspace and load required packages ####################

# clean workspace to improve efficiency: #
# rm(list = ls() )
# gc() #releases memory

library(tidyverse) # Data cleaning
library(sf)


###############################################
###                                         ###
###             Data Loading                ###
###                                         ###
###############################################

# Set path to Bioviewpoint folder (where data resides)
path <- "~/Library/CloudStorage/GoogleDrive-mainelobster28@gmail.com/.shortcut-targets-by-id/1HhR4gs3fKXyAXBhQom6t69gAqR6SeKhx/BioViewPoint"

# Load Stop level breeding data
bbs.data <- read.csv(paste(path, 
                           "/00_Data/Processed/BBS/1st Cleaning/BBS_StopLev_01_23__15plus.csv",
                           sep = ""),
                     header = TRUE)

# Load Migrant data
migrant.data <- read.csv(paste(path, 
                           "/00_Data/Processed/BBS/1st Cleaning/BBS_MigStop_01_23__15plus.csv",
                           sep = ""),
                     header = TRUE)

# Load route data
route.data <- read.csv(paste(path, 
                             "/00_Data/Processed/BBS/1st Cleaning/BBS_Routes.csv",
                             sep = ""),
                       header = TRUE)

# Load Weather data
weather.data <- read.csv(paste(path, 
                               "/00_Data/Processed/BBS/1st Cleaning/BBS_Weather_Quality.csv",
                               sep = ""),
                         header = TRUE)

# Load the spatial point file
spatial.data <- sf :: st_read(paste(path,
                                    "/00_Data/Processed/BBS/BBS_Rtes_Point.geojson",
                                    sep = ""))


###############################################
###                                         ###
###          Harmonize the Data             ###
###                                         ###
###############################################

# Dataframes need to match the routes present in the spatial data

# Make a list of routes to retain
routes.to.retain <- unique(spatial.data$unique_route)

# Filter each dataframe to be only these routes
bbs.data <- bbs.data %>%
  filter(unique_route %in% routes.to.retain)

migrant.data <- migrant.data %>%
  filter(unique_route %in% routes.to.retain)

route.data <- route.data %>%
  filter(unique_route %in% routes.to.retain)

weather.data <- weather.data %>%
  filter(unique_route %in% routes.to.retain)

# All dfs now have 1984 unique routes (with the exception of migrants where
# not all routes had migrants)

###############################################
###                                         ###
###        Write the resulting dfs          ###
###                                         ###
###############################################

write.csv(bbs.data, paste(path,
                        "/00_Data/Processed/BBS/Final_Cleaning/BBS_StopLev_01_23_15plus.csv", 
                        sep = ""), row.names = FALSE)

write.csv(migrant.data, paste(path,
                          "/00_Data/Processed/BBS/Final_Cleaning/BBS_MigStop_01_23_15plus.csv", 
                          sep = ""), row.names = FALSE)

write.csv(route.data, paste(path,
                        "/00_Data/Processed/BBS/Final_Cleaning/BBS_Routes.csv",
                        sep = ""), row.names = FALSE)

write.csv(weather.data, paste(path,
                         "/00_Data/Processed/BBS/Final_Cleaning/BBS_Weather_Quality.csv",
                         sep = ""), row.names = FALSE)






