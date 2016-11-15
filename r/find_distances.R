library(geosphere)

#define centroid function
getCentroid <- function(row){
  coords = matrix(ncol=2, nrow=0)
  n = 0
  t = 0
  if (startsWith(row[2], "redir")){
    row = locations[which(locations$LocCode == as.numeric(substr(row[2], 7, 99))),]
  }
  for (i in names(row)){
    if (i != "LocCode"){
      if (!is.na(row[[i]])){
        if (n == 0){
          t = as.numeric(row[[i]])
          n = 1
        } else {
          coords = rbind(coords, c(as.numeric(row[[i]]), t))
          n = 0
        }
      }
    }
  }
  if (nrow(coords) == 1){
    return (coords)
  } else if (nrow(coords) == 2){
    return (colMeans(coords))
  } else {
    return (centroid(coords))
  }
}

getDistance <- function(row){
  return (distHaversine(c(row[["orig_lon"]], row[["orig_lat"]]), c(row[["dest_lon"]], row[["dest_lat"]])))
  
}

#read locations
maxcols <- max(count.fields("domestic_region_locations.csv", sep=","))
locations <- read.csv("domestic_region_locations.csv", header=FALSE, fill=TRUE, col.names=c("LocCode", c(paste0("Col", seq_len(maxcols - 1)))), stringsAsFactors = FALSE)

#read master data table
if (file.exists("FAF42_data.rds")){
  #Faster to read RDS file than CSV file
  data <- readRDS('FAF42_data.rds')
} else {
  data <- read.csv("FAF42_data.csv")
  saveRDS(data, 'FAF42_data.rds')
}


#add centroids to locations
locationsWithCentroids <- as.data.frame(cbind(t(apply(locations, 1, getCentroid)), locations$LocCode))
names(locationsWithCentroids) <- c("lon", "lat", "LocCode")

#add origin lat/lon to data and rename columns
data <- merge(data, locationsWithCentroids, by.x = 'dms_orig', by.y = 'LocCode')
names(data)[names(data) == 'lon'] <- 'orig_lon'
names(data)[names(data) == 'lat'] <- 'orig_lat'

#add destination lat/lon to data and rename columns
data <- merge(data, locationsWithCentroids, by.x = 'dms_dest', by.y = 'LocCode')
names(data)[names(data) == 'lon'] <- 'dest_lon'
names(data)[names(data) == 'lat'] <- 'dest_lat'

distances <- apply(data, 1, getDistance)
