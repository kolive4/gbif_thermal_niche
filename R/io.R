#' Retrieve a data path
#' 
#' @export
#' @param ... charcater, one or more file path segments to be post-pended to \code{root}
#' @param root character, the root data directory path
#' @return charcater path specification
get_path <- function(..., root = rappdirs::user_data_dir("gbif_niche")){
  file.path(root, ...)
}

# # fetch occurrence data for given species from GBIF
# # 
# # @export
# # @param species character, latin name of species to fetch
# # @param cache logical, if true save results to cache
# # @return data frame in the form of a tibble (or an error object if issues arise)
# fetch_gbif = function(species = "Carcharodon carcharias", cache = TRUE){
#   occurrence <- try(rgbif::occ_search(scientificName = species[1]))
#   if (!inherits(occurrence, "try-error")){
#     occurrence <- occurrence$data
#     if(cache == TRUE){
#       path <- get_path(paste0(species, ".csv.gz"))
#       occurrence <- readr::write_csv(occurrence, path)
#     }
#   }
#   return(occurrence)
# }

#' Fetch occurrence data for given species from GBIF
#' 
#' @export
#' @param species character, latin name of species to fetch
#' @param cache logical, if true save results to cache
#' @param verbose logical, if true prints counter of progress
#' @param progress logical, if true print progress bar and ignore verbose
#' @return data frame in the form of a tibble
fetch_gbif = function(species = "Carcharodon carcharias", 
                      cache = TRUE, 
                      verbose = FALSE, 
                      progress = !verbose){
  
  if(progress == TRUE){
    verbose = FALSE
  }
  
  DONE = FALSE
  LIMIT = 500
  CUR = 0
  FROM = "gbif"
  
  x <- spocc::occ(query = species[1], limit = LIMIT, from = FROM, 
                  start = CUR, throw_warnings = FALSE)
  COUNT = x[[FROM]]$meta$found
  NCHUNKS = ceiling(COUNT / LIMIT)
  ICHUNK = 1
  
  xx = vector(mode = "list", length = NCHUNKS)
  xx[[ICHUNK]] <- x[[FROM]]
  ICHUNK = ICHUNK + 1
  CUR = CUR + LIMIT
  
  if(progress) pb = txtProgressBar(min = 0, max = NCHUNKS, initial = ICHUNK, style = 3) 
  
  while(ICHUNK <= NCHUNKS){
    if(verbose){
      cat(sprintf("%i:%i", ICHUNK, CUR))
    }
    if(progress) setTxtProgressBar(pb, ICHUNK)
    x <- spocc::occ(query = species[1], limit = LIMIT, 
                    from = FROM, start = CUR, 
                    throw_warnings = FALSE)
    xx[[ICHUNK]] <- x[[FROM]]
    ICHUNK = ICHUNK + 1
    CUR = CUR + LIMIT
  }
  
  if(progress) close(pb)
  
  occurrence = lapply(xx, 
    function(y){
     return(y$data[[1]] |> 
              dplyr::as_tibble() |> 
              dplyr::select(-dplyr::any_of("networkKeys")))
    }) |>
    dplyr::bind_rows()
  
  
  if(cache == TRUE){
    path <- get_path(paste0(species[1], ".csv.gz"))
    occurrence <- readr::write_csv(occurrence, path)
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
  filename = get_path(paste0(species[1], ".csv.gz"))
  if (!file.exists(filename) || refresh == TRUE) {
    x = fetch_gbif(species = species)
  }
  else{
    x = readr::read_csv(filename)
  }
  return(x)
}




 