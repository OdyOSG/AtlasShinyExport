
# function to read in app data from saved json files extracted from Atlas/WebAPI
# `path` argument should point to the folder where the json files are stored

path = "data"
read_data <- function(path) {
  require(dplyr)
  
  # get the list of unique data source keys
  data_sources <- list.files(path, pattern = ".json$") %>% 
    stringr::str_remove("_by_(person|event).json$") %>% 
    stringr::str_unique()
  
  # construct a single app_data list
  app_data <- list()
  
  for (d in data_sources) {
    for (e in c("event", "person")) {
      
      file_path <- file.path(path, glue::glue("{d}_by_{e}.json"))
      
      if (!file.exists(file_path)) stop(paste(file_path, "cannot be found!"))
      
      x <- jsonlite::read_json(file_path, simplifyVector = FALSE)
      
      app_data[[d]][[e]][["summary_table"]] <- dplyr::tibble(
        initial_index_events = x$summary$baseCount,
        final_index_events = x$summary$finalCount,
        percent_included = x$summary$percentMatched)
      
      app_data[[d]][[e]][["inclusion_table"]] <- dplyr::tibble(value = x$inclusionRuleStats) %>% 
        tidyr::unnest_wider(col = value) %>% 
        mutate(id = id + 1) %>% # start ids at 1 instead of 0
        select(ID = id, `Inclusion Rule` = name, Count = countSatisfying, Percent = percentSatisfying)
      
      app_data[[d]][[e]][["treemap_table"]] <- x$treemapData %>% 
        jsonlite::fromJSON(simplifyVector = FALSE) %>% 
        tidy_treemap_data()
    }
  }
  return(app_data)
}


# Helper function to convert the nested list with treemap data into a dataframe
tidy_treemap_data <- function(treemap_data) {
  
  # initialize vectors to hold output
  name <- character()
  size <- numeric()
  
  # define recursive function that extracts values
  recurse <- function(lst) {
    for (item in lst) {
      if (is.list(item) && "size" %in% names(item)) {
        # the elements we want to extract have names "name" and "size"
        stopifnot("name" %in% names(item)) 
        name <<- c(name, item$name)
        size <<- c(size, item$size)
      } else if (is.list(item)) {
        recurse(item)
      } else {
        next
      }
    }
  }
  
  # call the recursive function to populate the vectors
  recurse(treemap_data)
  
  # convert name encoding into a comma separted list of inclusion rule IDs
  name2 <- purrr::map_chr(name, function(encoded_name) {
    stringr::str_split_1(encoded_name, "") %>% 
      as.numeric() %>% 
      {.*seq_along(.)} %>% 
      as.character() %>% 
      stringr::str_subset("0", negate = T) %>% 
      stringr::str_c(collapse = ",") %>% 
      {ifelse(. == "", "None", .)}
  })
  
  # return a dataframe with the counts of each partition
  return(dplyr::tibble(name = name2, value = size))
}