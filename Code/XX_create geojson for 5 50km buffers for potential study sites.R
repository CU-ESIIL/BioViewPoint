# R script to create geojson for 5 50km regions/buffers surrounding a lat/lng

# Load required libraries
library(sf)         # For working with geospatial data
library(dplyr)      # For data manipulation

# Define the points with latitude and longitude
points <- data.frame(
  id = 1:5,
  lat = c(27.664421, 26.067586, 40.011583, 39.120747, 42.412218),
  lon = c(-81.006829, -80.317387, -105.263905, -77.987449, -72.148415)
)

# Convert the points to an sf object
points_sf <- st_as_sf(points, coords = c("lon", "lat"), crs = 4326)

# Function to create a buffer of 50 km
create_buffer <- function(point_sf) {
  point_sf %>%
    st_transform(crs = 32633) %>%  # Transform to a projected coordinate system for accurate buffering
    st_buffer(dist = 50000) %>%     # Create a 50 km buffer (50,000 meters)
    st_transform(crs = 4326)        # Re-project back to lat/lon
}

# Apply the buffer function to each point
buffers <- lapply(1:nrow(points_sf), function(i) {
  buffer <- create_buffer(points_sf[i, ])
  buffer
})

# Write each buffer to a separate .geojson file
for (i in 1:length(buffers)) {
  filename <- paste0("Data/GBIF data for potential study sites/buffer_", i, ".geojson")
  st_write(buffers[[i]], filename, driver = "GeoJSON", delete_dsn = TRUE)
}

st_as_text(st_read("Data/GBIF data for test cases/buffer_1.geojson")$geometry)
st_as_text(st_read("Data/GBIF data for test cases/buffer_2.geojson")$geometry)
st_as_text(st_read("Data/GBIF data for test cases/buffer_3.geojson")$geometry)
st_as_text(st_read("Data/GBIF data for test cases/buffer_4.geojson")$geometry)
st_as_text(st_read("Data/GBIF data for test cases/buffer_5.geojson")$geometry)

