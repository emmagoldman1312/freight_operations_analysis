# ========================================================================================================
# =========================== FREIGHT OPERATIONS ANALYSIS: 01 IMPORT DATA ================================
# ========================================================================================================

library(tidyverse)
library(here)

# Find all CSV files inside the data/raw_data folder.

csv_paths <- list.files(
  path       = here("data", "raw_data"), # path: folder where R will search for files.
  pattern    = "\\.csv$", # pattern: keeps only files ending in .csv.
  full.names = TRUE) # full.names = TRUE: returns the full file path, not only the file name.

csv_paths
basename(csv_paths) # Display only the file names, without the folder path.

# Read all CSV files and store them in a list.Each element of the list will be a separate dataframe/tibble.

datasets <- lapply(csv_paths, read_csv)
names(datasets) <- tools::file_path_sans_ext(basename(csv_paths)) # Assign names to each table inside the datasets list.


# Detect any import problems in each file and display the column names of each dataset.

map(datasets, problems)
map(datasets, names)


# View dimension tables.

datasets$dim_projects
datasets$dim_ports
datasets$dim_carriers
datasets$dim_facilities
datasets$dim_cargo_types
datasets$dim_vessels


# Count the total number of rows in the main shipments table and how many unique shipment_id values to verify if it is really a unique identifier.
nrow(datasets$fact_shipments)
n_distinct(datasets$fact_shipments$shipment_id)


