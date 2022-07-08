gbif and xyzt
================

### Load up the tools

``` r
suppressPackageStartupMessages({
  library(dplyr)
  library(gbifniche)
  library(xyzt)
  library(ghrsst)
  library(ncdf4)
})
```

### Gather the observation data

``` r
(spp <- list_gbif())
```

    ## [1] "Carcharodon carcharias"                           
    ## [2] "Prionace glauca"                                  
    ## [3] "Squalus acanthias subsp. acanthias Linnaeus, 1758"

``` r
x <- read_gbif(spp[1]) |>
  dplyr::filter(dplyr::between(eventDate, 
                               as.Date("2002-06-01"), 
                               as.Date("2002-12-31"))) |>
  dplyr::group_by(eventDate) |>
  dplyr::rename(lat = "decimalLatitude",
                lon = "decimalLongitude") |>
  dplyr::filter(!is.na(lat) & !is.na(lon))
glimpse(x)
```

    ## Rows: 7
    ## Columns: 13
    ## Groups: eventDate [7]
    ## $ occurrenceID         <chr> "P1388", NA, NA, "https://observation.org/observa…
    ## $ basisOfRecord        <chr> "HUMAN_OBSERVATION", "HUMAN_OBSERVATION", "HUMAN_…
    ## $ scientificName       <chr> "Carcharodon carcharias (Linnaeus, 1758)", "Carch…
    ## $ eventDate            <date> 2002-06-16, 2002-07-19, 2002-07-25, 2002-08-25, …
    ## $ taxonRank            <chr> "SPECIES", "SPECIES", "SPECIES", "SPECIES", "SPEC…
    ## $ kingdom              <chr> "Animalia", "Animalia", "Animalia", "Animalia", "…
    ## $ lat                  <dbl> 6.365359, -2.000000, -3.000000, -34.569115, 37.61…
    ## $ lon                  <dbl> 2.418329, 53.000000, 59.500000, 19.328499, -123.0…
    ## $ geodeticDatum        <chr> "WGS84", "WGS84", "WGS84", "WGS84", "WGS84", "WGS…
    ## $ countryCode          <chr> "BJ", "SC", NA, "ZA", "US", "SC", "SC"
    ## $ individualCount      <int> NA, NA, NA, 4, NA, NA, NA
    ## $ organismQuantity     <int> NA, NA, NA, NA, NA, NA, NA
    ## $ organismQuantityType <chr> NA, NA, NA, NA, NA, NA, NA

### Go collect GHRSST data

``` r
mur <- xyzt::as_POINT(x) |>
  dplyr:::group_map(
    function(subx, key){                                  # an anonymous function
      on.exit(ncdf4::nc_close(X))                         # last thing is clean up
      url <- ghrsst::mur_url(key$eventDate)               # get a URL for this date
      X <- ncdf4::nc_open(url)                            # open the resource
      ghrsst::extract(subx, X, varname = c("analysed_sst", "mask")) # get and return the goods
    },
    .keep = TRUE) |>
  dplyr::bind_rows()
glimpse(mur)
```

    ## Rows: 7
    ## Columns: 2
    ## $ analysed_sst <dbl> NA, 299.043, 299.831, 288.986, 287.920, 302.015, 301.451
    ## $ mask         <int> 2, 1, 1, 1, 1, 1, 1

### Join with original data

``` r
(x <- dplyr::bind_cols(x, mur))
```

    ## # A tibble: 7 × 15
    ## # Groups:   eventDate [7]
    ##   occurrenceID  basisOfRecord scientificName eventDate  taxonRank kingdom    lat
    ##   <chr>         <chr>         <chr>          <date>     <chr>     <chr>    <dbl>
    ## 1 P1388         HUMAN_OBSERV… Carcharodon c… 2002-06-16 SPECIES   Animal…   6.37
    ## 2 <NA>          HUMAN_OBSERV… Carcharodon c… 2002-07-19 SPECIES   Animal…  -2   
    ## 3 <NA>          HUMAN_OBSERV… Carcharodon c… 2002-07-25 SPECIES   Animal…  -3   
    ## 4 https://obse… HUMAN_OBSERV… Carcharodon c… 2002-08-25 SPECIES   Animal… -34.6 
    ## 5 https://www.… HUMAN_OBSERV… Carcharodon c… 2002-10-10 SPECIES   Animal…  37.6 
    ## 6 <NA>          HUMAN_OBSERV… Carcharodon c… 2002-12-14 SPECIES   Animal…  -5.46
    ## 7 <NA>          HUMAN_OBSERV… Carcharodon c… 2002-12-17 SPECIES   Animal…  -4.19
    ## # … with 8 more variables: lon <dbl>, geodeticDatum <chr>, countryCode <chr>,
    ## #   individualCount <int>, organismQuantity <int>, organismQuantityType <chr>,
    ## #   analysed_sst <dbl>, mask <int>
