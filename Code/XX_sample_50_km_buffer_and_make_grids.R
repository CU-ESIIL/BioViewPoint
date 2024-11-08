# script to randomly sample regions of the 50 km buffers


# packages
library(sf)
library(tidyverse)
library(ggplot2)


# read in GBIF data
# only for one buffer for now
gbif_dat <- read_delim("Data/GBIF data for test cases/buffer_1_data/occurrence.txt")

# read in buffer geojson
buffer_spatial <- st_read("Data/GBIF data for test cases/buffer_1.geojson")

plot(buffer_spatial)
