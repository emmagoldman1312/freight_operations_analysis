# ========================================================================================================
# ===================== FREIGHT OPERATIONS ANALYSIS: 03 DATA CLEANING ====================================
# ========================================================================================================

library(tidyverse)
library(here)


# ========================================================================================================
# 1. IMPORT DATA AND CREATE A WORKING COPY
# ========================================================================================================

# Run the import script.

source(here("R", "01_Import.R"))


# Create a separate copy for cleaning and transformation.

clean_datasets <- datasets

# Check that the working copy contains the same tables as the raw data object.

cleaning_setup_check <- tibble(
  raw_tables = length(datasets),
  clean_tables = length(clean_datasets),
  same_table_names = identical(
    names(datasets),
    names(clean_datasets)
  ),
  same_initial_content = identical(
    datasets,
    clean_datasets
  )
)

cleaning_setup_check


# ========================================================================================================
# 2. ADD ISO YEAR TO THE CALENDAR AND CREATE AN ISO WEEK IDENTIFIER
# ========================================================================================================

# ISO weeks can belong to a different year than the calendar year. Add the ISO year to support correct weekly analysis.

clean_datasets$dim_calendar <- clean_datasets$dim_calendar %>%
  mutate(
    iso_year = lubridate::isoyear(date)
  ) %>%
  relocate(
    iso_year,
    .after = year
  )


# Check that the new variable was calculated correctly.

calendar_cleaning_check <- clean_datasets$dim_calendar %>%
  summarise(
    total_dates = n(),
    missing_iso_year = sum(is.na(iso_year)),
    incorrect_iso_year = sum(
      iso_year != lubridate::isoyear(date),
      na.rm = TRUE
    )
  )

calendar_cleaning_check

# Combine the ISO year and ISO week number into a unique weekly identifier. Week numbers are padded with a leading zero to preserve chronological order.

clean_datasets$dim_calendar <- clean_datasets$dim_calendar %>%
  mutate(
    iso_year_week = paste0(
      iso_year,
      "-W",
      str_pad(
        week,
        width = 2,
        side = "left",
        pad = "0"
      )
    )
  ) %>%
  relocate(
    iso_year_week,
    .after = week
  )

# ========================================================================================================
# 3. CONVERT SHIPMENT FLAGS TO LOGICAL VALUES
# ========================================================================================================

# Define the binary columns contained in the main shipments table.

shipment_flag_columns <- c(
  "oversize_flag",
  "heavy_lift_flag",
  "hazardous_flag",
  "temperature_controlled_flag",
  "on_time_flag",
  "damage_flag"
)


# Convert "Y" and "N" values to TRUE and FALSE. Missing values remain as NA.

clean_datasets$fact_shipments <- clean_datasets$fact_shipments %>%
  mutate(
    across(
      all_of(shipment_flag_columns),
      ~ .x == "Y"
    )
  )


# ========================================================================================================
# 4. CONVERT OTHER BINARY COLUMNS TO LOGICAL VALUES
# ========================================================================================================

# Define the remaining binary columns by dataset.

other_binary_columns <- list(
  dim_calendar = c(
    "is_weekend",
    "is_holiday_sample"
  ),
  dim_facilities = "heavy_lift_yard",
  dim_ports = "heavy_lift_capable",
  dim_cargo_types = "hazardous_default",
  fact_incidents = "preventable_flag",
  fact_port_congestion = "strike_flag"
)


# Convert "Y" and "N" values to TRUE and FALSE in each dataset.

clean_datasets[names(other_binary_columns)] <- imap(
  other_binary_columns,
  function(columns, table_name) {
    
    clean_datasets[[table_name]] %>%
      mutate(
        across(
          all_of(columns),
          ~ {
            if (is.logical(.x)) {
              .x
            } else {
              .x == "Y"
            }
          }
        )
      )
  }
)

# ========================================================================================================
# 5. VALIDATE CLEANED DATASETS
# ========================================================================================================

cleaning_validation <- tibble(
  table = names(datasets),
  
  raw_rows = map_int(
    datasets,
    nrow
  ),
  
  clean_rows = map_int(
    clean_datasets,
    nrow
  ),
  
  raw_columns = map_int(
    datasets,
    ncol
  ),
  
  clean_columns = map_int(
    clean_datasets,
    ncol
  )
) %>%
  mutate(
    rows_preserved = raw_rows == clean_rows,
    
    added_columns = clean_columns - raw_columns,
    
    expected_added_columns = if_else(
      table == "dim_calendar",
      2L,
      0L
    ),
    
    valid_column_change =
      added_columns == expected_added_columns
  )

cleaning_validation



# Summarize the final structural validation.

cleaning_validation_summary <- cleaning_validation %>%
  summarise(
    tables_checked = n(),
    
    tables_with_row_changes = sum(
      !rows_preserved
    ),
    
    tables_with_unexpected_column_changes = sum(
      !valid_column_change
    ),
    
    valid_structure = all(
      rows_preserved &
        valid_column_change
    )
  )

cleaning_validation_summary


# ========================================================================================================
# 6. EXPORT CLEANED DATASETS
# ========================================================================================================

# Define the folder where cleaned datasets will be stored.

processed_data_path <- here(
  "data",
  "processed_data"
)


# Export each cleaned dataset as a separate CSV file.

iwalk(
  clean_datasets,
  function(data, table_name) {
    
    write_csv(
      data,
      file = file.path(
        processed_data_path,
        paste0(table_name, ".csv")
      ),
      na = ""
    )
  }
)