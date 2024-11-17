###############################################################################
########                                                               ########
########               Downloading and Cleaning BBS Data               ######## 
########                                                               ########
###############################################################################

# Author: Kimberly Thompson

# This code does initial 
# cleaning and preprocessing of the North American Breeding Bird 
# Survey Dataset including: stop level data, migrants (stop-level format),
# routes, and weather.

# Main preprocessing step is to add a unique route ID to each dataset, which 
# simply combines the state ID with the route ID, so that each dataset can
# talk to one another

# Website for data download
# https://www.sciencebase.gov/catalog/item/5ea04e9a82cefae35a129d65

# state level: 1966-2023, 50 stops along each route aggregated into 10-stop
#              bins
# stop level: 1997-2023, data for each of 50 stops recorded


# Download includes:
# States - 62 individual files, 1 for each state and province - 1966-2023
# Stop_Data - 10 files, with 5-9 states represented in each file, data for
#             all 50 stops for each route, officially 1997-2023 but some other
#             older years sneak in 
# Migrants - counts of non-breeding birds, stop data format, data for
#             all 50 stops for each route, officially 1997-2023 but some other
#             older years sneak in 
# Migrant Summary - counts for non-breeding birds, state data format,
#                   1966-2023
# Routes - Route information plus the lat long coordinate of the route's
#          starting point
# Species List - Links AOU (4-digit species ID code) with order, family, genus
#                and species
# Vehicle Data - vehicle counts and excessive noise ??? no info in metadata
# Weather - route quality information and weather conditions - more info in 
#           metadata

# Why do we focus only on stop level data here?
# Because we will match with MODIS data from 2001-2023; therefore the stop level
# data fits our timeline AND in case we decide to incorporate some method for
# detection probability, the stop level data provides the best option for that.


# Produces datasets:





########## clean workspace and load required packages ####################

# clean workspace to improve efficiency: #
# rm(list = ls() )
# gc() #releases memory

library(tidyverse) # Data cleaning


###############################################
###                                         ###
###          Stop-Level Data                ###
###             Processing                  ###
###############################################

# Combine data into 1 CSV file, add a unique identifier for each route

# File path - set to Bioviewpoint folder
path <- "I:/mas/04_personal/Kim_T/BioViewPoint"
stop.list <- list.files(paste(path, "/00_Data/Raw/BBS/Stop_Data",
                              sep = ""))


# Create blank dataframe
master <- data.frame()

for (i in 1:length(stop.list)) {
  
  setwd(path)
  
  tmp.file <- read.csv(stop.list[i], header = TRUE)
  
  master <- rbind(master, tmp.file)
  
  print(i)
  
  }

# Column RPID represents 3-digit run protocol ID
# 101: Standard BBS Protocol: 3-minute counts, 1 observer, single run per year
# 102: Standard BBS Protocol, Replicate 1: 3-minute counts, 1 observer 
#      (same or different person), second run in year
# 103: Standard BBS Protocol, Replicate 1: 3-minute counts, 1 observer 
#      (same or different person), second run in year
# 104: Standard BBS Protocol, Replicate 3: 3-minute counts, 1 observer 
#      (same or different person), fourth run in year.
# 203: Experimental Protocol: Double-Observer Independent: 3-minute counts, 
#      2 observer method, single run per year, Secondary Observer
# 501: Experimental Protocol: Distance and time-of-detection methods: Three 
#      1-minute sample periods; two distance bands (0-50 m, >50-400m)
# 502: Experimental Protocol: Distance and time-of-detection methods, Rep1: 
#      Three 1-minute sample periods; two distance bands (0-50 m, >50-400m),
#      second run in year.

# Frequency of each protocol type
master %>%
  count(RPID) %>%
  mutate(prop = prop.table(n))

# We will keep only protocol 101 which represents 99.4% of the data
master <- master %>%
  filter(RPID == 101)

# Define both statenum and Route as character columns so that trailing zeros
# are retained
master$StateNum <- as.character(master$StateNum)
master$Route <- as.character(master$Route)

# Create a unique route identifier
master$unique_route <- paste(master$StateNum, master$Route, sep = "_")

# Filter data to be only for 2001 - 2023
master <- master %>%
  filter(Year >= 2001)

# How many routes do we have given these initial filters?
length(unique(master$unique_route))
# 4944


###############################################
###                                         ###
###          Stop-Level Data                ###
###       Processing Time Series            ###
###############################################

# To ensure the time series analysis can proceed, we need to see which routes
# do not have sufficient observations within the 2001-2023 period

# Make a vector of unique route numbers
route.num <- unique(master$unique_route)

# Create a data frame in which to store results
total.years <- data.frame(Route = character(), Total = integer())

# Loop to calculate the number of years for the routes
for (i in 1:length(route.num)) {
  
  # find the unique years for each unique route
  years <- length(unique(master$Year[master$unique_route == route.num[i]]))
  
  # Create a dataframe for consecutive years
  tmp.df <- data.frame(Route = route.num[i], Total = years)
  
  # Rbind to the total.years dataframe
  total.years <- rbind(total.years, tmp.df)
  
  print(i)
  
}

# Frequency of total years surveyed between 2001-2023
total.years %>%
  count(Total) %>%
  mutate(prop = prop.table(n))

# Retain routes that have been surveyed at least 15 years out of the 22 possible
# *** This threshold could be adjusted later depending on the causal methodology
#     we use

# Create a vector of routes to retain
routes_to_retain <- total.years$Route[total.years$Total >= 15]

# Filter the master df according to routes to retain
master <- master %>%
  filter(unique_route %in% routes_to_retain)

# Create a column for the total abundance (summed across each stop)
master$Total.Abund <- rowSums(master[, grep("^Stop", names(master))],
                              na.rm = TRUE)

# Reorder columns
master <- master[ , c(1:4, 58, 5:57, 59)]

# clean up workspace
rm(tmp.df, tmp.file, total.years, i, path, route.num, stop.list,
   years)


###############################################
###                                         ###
###                 Migrants                ###
###                Processing               ###
###############################################

# RPID, unique_route, year range, routes-to-retain, Total abundance

migrants <- read.csv(paste(path, "/00_Data/Raw/BBS/Migrants.csv",
                           sep = ""),
                           header = TRUE)

# keep only protocol 101
migrants <- migrants %>%
  filter(RPID == 101)

# Define both statenum and Route as character columns so that trailing zeros
# are retained
migrants$StateNum <- as.character(migrants$StateNum)
migrants$Route <- as.character(migrants$Route)

# Create a unique route identifier
migrants$unique_route <- paste(migrants$StateNum, migrants$Route, sep = "_")

# Filter data to be only for 2001 - 2023
migrants <- migrants %>%
  filter(Year >= 2001)

# Filter the migrants df according to routes to retain
migrants <- migrants %>%
  filter(unique_route %in% routes_to_retain)

length(unique(migrants$unique_route))
# 1418 routes of the 2605 in the master data have info on migrants

# Create a column for the total abundance (summed across each stop)
migrants$Total.Abund <- rowSums(migrants[, grep("^Stop", names(migrants))],
                              na.rm = TRUE)


###############################################
###                                         ###
###                 Routes                  ###
###               Processing                ###
###############################################

routes <- read.csv(paste(path, "/00_Data/Raw/BBS/Routes.csv",
                         sep = ""),
                   header = TRUE)

# Active: active (1) or discontinued (0)

# RouteTypeID: indicates if a route was established along a roadside or 
# on a body of water (1 = Roadside, 2 = water)

# RouteTypeDetailID: Indicates route length and selection criteria
# 1: Location of route randomly established, 50 point counts
# 2: Location of route non-randomly established, 50 point counts
# 3: Location of route non-randomly established, < 50 point counts

# Frequency of DetailID types
routes %>%
  count(RouteTypeDetailID) %>%
  mutate(prop = prop.table(n))

# Remove type 3 which accounts for 0.003% of routes
routes <- routes %>%
  filter(RouteTypeDetailID != 3)

# Define both statenum and Route as character columns so that trailing zeros
# are retained
routes$StateNum <- as.character(routes$StateNum)
routes$Route <- as.character(routes$Route)

# Create a unique route identifier
routes$unique_route <- paste(routes$StateNum, routes$Route, sep = "_")



###############################################
###                                         ###
###            Weather/Quality              ###
###               Processing                ###
###############################################

# RPID, unique_route, year range, routes-to-retain, Total abundance

weather <- read.csv(paste(path, "/00_Data/Raw/BBS/Weather.csv",
                          sep = ""),
                    header = TRUE)

# keep only protocol 101
weather <- weather %>%
  filter(RPID == 101)

# Define both statenum and Route as character columns so that trailing zeros
# are retained
weather$StateNum <- as.character(weather$StateNum)
weather$Route <- as.character(weather$Route)

# Create a unique route identifier
weather$unique_route <- paste(weather$StateNum, weather$Route, sep = "_")

# Filter data to be only for 2001 - 2023
weather <- weather %>%
  filter(Year >= 2001)

# Filter the weather df according to routes to retain
weather <- weather %>%
  filter(unique_route %in% routes_to_retain)

length(unique(weather$unique_route))
# 2605 

# Month: Month surveyed; values range from April - July. We may want to filter 
# this further depending on what we acquire for MODIS, or just include this 
# in the analysis

# Day: Day surveyed; same as above

# Quality Current ID: indicates if the sampling took place under suitable 
# weather conditions and met suitable time, data, and route completion criteria
# 1 - Data meet quality control criteria
# 0 - Data do not meet one or more quality control criteria

# Remove samplings with a 0 for quality control
weather <- weather %>%
  filter(QualityCurrentID == 1)

# Runtype: identifies which data were collected consistent with all standard
# BBS criteria
# 1: consistent
# 0: not consistent

# Remove samplings with a 0 for RunType
weather <- weather %>%
  filter(RunType == 1)



###############################################
###                                         ###
###      Last step in Initial Cleaning      ###
###                                         ###
###############################################


# Each dataset has been pared to retain only routes with high quality and 
# adherence to protocols

length(unique(master$unique_route))
# 2605

length(unique(routes$unique_route))
# 5805

length(unique(weather$unique_route))
# 2455

# The routes in weather should be used to further pare the master and routes 
# dataframes, as well as the migrant dataframe.

final.routes <- unique(weather$unique_route)

# Filter the master df according to final.routes
master <- master %>%
  filter(unique_route %in% final.routes)

# Filter the routes df according to final.routes
routes <- routes %>%
  filter(unique_route %in% final.routes)

migrants <- migrants %>%
  filter(unique_route %in% final.routes)



# Write the resulting files
write.csv(master, paste(path,
                        "/00_Data/Processed/BBS/1st Cleaning/BBS_StopLev_01_23_15plus.csv", 
                        sep = ""), row.names = FALSE)

write.csv(migrants, paste(path,
                          "/00_Data/Processed/BBS/1st Cleaning/BBS_MigStop_01_23_15plus.csv", 
                          sep = ""), row.names = FALSE)

write.csv(routes, paste(path,
                        "/00_Data/Processed/BBS/1st Cleaning/BBS_Routes.csv",
                        sep = ""), row.names = FALSE)

write.csv(weather, paste(path,
                         "/00_Data/Processed/BBS/1st Cleaning/BBS_Weather_Quality.csv",
                         sep = ""), row.names = FALSE)