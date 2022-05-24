set_data_path = function(path = rappdirs::user_data_dir("gbif_niche")){
  if(!dir.exists(path)){
    okay = dir.create(path, recursive = TRUE)
  }
  return(path)
}

# maybe make zz doc

#' fetch occurrence data for given species from GBIF
#' 
#' @export
#' @param species character, latin name of species to fetch
#' @param cache logical, if true save results to cache
#' @return data frame in the form of a tibble
fetch_gbif = function(species = "Carcharodon carcharias", cache = TRUE){
  occurrence <- rgbif::occ_search(scientificName = species[1])$data
  if(cache == TRUE){
    occurrence = readr::write_csv(occurrence, 
                                  file.path(rappdirs::user_data_dir("gbif_niche"),
                                            paste0(species[1], ".csv.gz")))
  }
  return(occurrence)
}

#' function to read gbif with the option to fetch
#' 
#' reads file by species name, if file doesn't exist, first try to fetch it then save it to the cache
#' @export
#' @param species character, latin name of species
#' @param refresh logical, if true fetch fresh set of data
#' @return data frame in the form of a tibble
read_gbif = function(species = "Carcharodon carcharias", refresh = FALSE){
  filename = file.path(rappdirs::user_data_dir("gbif_niche"),
                       paste0(species[1], ".csv.gz"))
  if (!file.exists(filename) || refresh == TRUE) {
    x = fetch_gbif(species = species)
  }
  else{
    x = readr::read_csv(filename)
  }
  return(x)
}




 