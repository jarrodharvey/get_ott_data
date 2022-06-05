rm(list=setdiff(ls(), c("rD", "remDr")))
cat("\014")

easypackages::packages("dplyr", "rotl", "DBI", "RSQLite", "pbapply", "stringr")

# Read the unique scientific names into memory
unique_scientific_names <- read.csv("/home/jarrod/R Scripts/merge_ncbi_and_col_datasets/species_table.csv") %>%
  .$scientific.name %>%
  unique(.)

# Connect to the db
ott_db <- dbConnect(RSQLite::SQLite(), "db/species_with_otts.sqlite")

# Read the already completed scientific names into memory
already_processed <- dbReadTable(ott_db, "ott_data") %>%
  .$search_string

# Create a list of scientific names to read based on what hasn't yet been done
still_to_process <- setdiff(str_to_lower(unique_scientific_names), str_to_lower(already_processed))

# Iterate through the remaining scientific names and write the OTT and the MATCHED names to the db
pblapply(still_to_process, function(scientific_name) {
  retrieved_data <- tnrs_match_names(scientific_name)
  if (is.na(retrieved_data$unique_name)) {
    print(paste(retrieved_data$search_string, "was not found!"))
  } else {
    print(paste(retrieved_data$unique_name, "added to database!"))
  }
  dbAppendTable(ott_db, "ott_data", retrieved_data)
})
