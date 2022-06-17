#' Rename one or more fields (columns) in a GBIF tibble
#'
#' @export
#' @param x tibble of data
#' @param fields named character vector with oldname = newname
#' @return renamed tibble
rename_gbif <- function(x, 
                        fields = c("name" = "scientificName",
                                   "longitude" = "decimalLongitude",
                                   "latitude" = "decimalLatitude")){
  #xnames <- colnames(x)
  
  #for (nm in names(fields)){
  #  if(nm %in% xnames) x <- dplyr::rename(x, fields[[nm]] = nm)
  #}
  x <- dplyr::rename(x, !!!fields)
  x
}

#' Plot the locations of a GBIF dataset
#' 
#' @export
#' @param x tibble of GBIF data
#' @param what character, one of 'base', 'ggplot', 'leaflet', 'gist'
#' @param ... other arguments for mapr package map_* functions
plot_gbif <- function(x, what = c('base', 'ggplot', 'leaflet', 'gist')[1], ...){
  
  x <- rename_gbif(x)
  switch(tolower(what[1]),
         "base" = mapr::map_plot(x, ...),
         "ggplot" = mapr::map_ggplot(x, ...),
         "leaflet" = mapr::map_leaflet(x, ...),
         "ggplot" = mapr::map_gist(x, ...))
  
}