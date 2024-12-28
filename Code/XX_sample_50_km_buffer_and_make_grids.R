# script to randomly sample regions of the 50 km buffers


# packages
library(sf)
library(terra)
library(tidyverse)
# library(ggplot2)


# arguments for the script
taxa = "Aves" # taxa of interest (birds)
yr = 2010 # year of interest
grid_size = 5000 # unit: meters
gcs = 4326 # geographic coordinate system
pcs = 32633 # projected coordinate system (same as the one used for 50km buffers: XX_create geojson for 5 50km buffers for potential study sites.R)


# read in GBIF data
# only for one buffer for now
gbif_dat <- read_delim("Data/GBIF data for test cases/buffer_1_data/occurrence.txt")

# read in buffer geojson
buffer_spatial <- st_read("Data/GBIF data for test cases/buffer_1.geojson") %>% 
  st_transform(crs = pcs)

# make a grid of the buffer with the specified grid size
circ_grid <- buffer_spatial %>%
  st_make_grid(cellsize = grid_size, what = "polygons") %>% # Create a grid of the buffer
  st_sf() %>% # Convert to a spatial object
  st_filter(buffer_spatial, .predicate = st_within) # Filter the grid to only the cells within the buffer


# convert the GBIF data to a spatial object
gbif_dat_sf <- gbif_dat %>% 
  filter(class %in% taxa) %>% # subset to only the taxa of interest
  filter(year %in% yr) %>% # subset to only the year of interest
  st_as_sf(coords = c("decimalLongitude", "decimalLatitude"), crs = gcs) %>% # Convert to a spatial object
  st_transform(crs = pcs) %>% # Transform to the same coordinate system as the buffer
  st_filter(circ_grid, .predicate = st_within) %>% # Filter the data to only the points within the grid
  select(species, geometry) # Select only the species and geometry columns

# # plot the grid and GBIF data
# plot(st_geometry(buffer_spatial))
# plot(st_geometry(circ_grid), add = TRUE)
# plot(st_geometry(gbif_dat_sf), add = TRUE)


# create a raster of the grid
circ_vect <- vect(circ_grid) # convert to a SpatVector
r <- rast(ext(circ_vect), resolution = grid_size) # create an empty SpatRaster with the desired resolution
ras <- rasterize(circ_vect, r) # rasterize the grid
ras[!is.nan(values(ras))] <- 0 # set all cells to 0
# plot(ras)

# Create a raster of species counts
uni_spp <- unique(gbif_dat_sf$species) # get the unique species
ras.emp <- ras # empty raster to add the species rasters to
for(i in 1:length(uni_spp)){ # loop through each species
  rasx <- ras.emp # copy the empty raster
  sp <- uni_spp[i] # get the species
  
  sp_dat <- gbif_dat_sf %>% 
    filter(species %in% sp) %>% # subset to only the species of interest
    vect() # convert to a SpatVector
  
  e <- terra::extract(ras, sp_dat, cells = TRUE) %>% # extract the cells
    count(cell) # count the number of cells
  
  rasx[e$cell] <- 1 # detection = 1; nondetection = 0
  ras <- ras + rasx # add the species raster to the main raster
}
# plot(ras) # Check the raster

# Save the raster
writeRaster(ras, "Data/GBIF data for test cases/buffer_1_data/spp_count.tif", format = "geotiff")
