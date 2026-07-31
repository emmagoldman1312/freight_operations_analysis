# ========================================================================================================
# ====================== FREIGHT OPERATIONS ANALYSIS: 02 DATA QUALITY ====================================
# ========================================================================================================

# Purpose:
# - Review the quality of the raw datasets.
# - Detect structural problems, missing values, invalid keys, and broken relationships.
# - Document relevant findings before cleaning or transforming the data.
#
# Important:
# - This script reads data/raw_data through 01_Import.R.
# - It does not modify or export any raw dataset.

library(tidyverse)
library(here)

source(here("R", "01_Import.R"))


# ========================================================================================================
# 1. DATASET INVENTORY AND IMPORT PROBLEMS
# ========================================================================================================


import_problem_summary <- map_dfr(
  names(datasets),
  function(table_name) {
    tibble(
      table = table_name,
      import_problems = nrow(problems(datasets[[table_name]]))
    )
  }
)

import_problem_summary


# ========================================================================================================
# 2. MISSING VALUES
# ========================================================================================================

# Display only columns containing at least one missing value.

missing_values_summary <- map_dfr(
  names(datasets),
  function(table_name) {
    data <- datasets[[table_name]]
    
    tibble(
      table = table_name,
      variable = names(data),
      missing_values = colSums(is.na(data))
    )
  }
) %>%
  filter(missing_values > 0)

print(missing_values_summary, n = Inf)


# ========================================================================================================
# 3. TEXT FORMATTING
# ========================================================================================================

# Check all character columns for empty strings and leading or trailing spaces.

text_format_issues <- map_dfr(
  names(datasets),
  function(table_name) {
    data <- datasets[[table_name]]
    character_columns <- names(data)[map_lgl(data, is.character)]
    
    map_dfr(
      character_columns,
      function(column_name) {
        values <- data[[column_name]]
        
        tibble(
          table = table_name,
          variable = column_name,
          empty_values = sum(!is.na(values) & str_trim(values) == ""),
          spacing_issues = sum(!is.na(values) & values != str_trim(values))
        )
      }
    )
  }
) %>%
  filter(empty_values > 0 | spacing_issues > 0)

text_format_issues


# ========================================================================================================
# 4. PRIMARY KEYS
# ========================================================================================================

# A valid primary key contains no missing values and one unique value per row.

check_primary_key <- function(data, key, table_name) {
  
  total_rows <- nrow(data)
  missing_keys <- sum(is.na(data[[key]]))
  unique_keys <- n_distinct(data[[key]], na.rm = TRUE)
  
  tibble(
    table = table_name,
    primary_key = key,
    total_rows = total_rows,
    unique_keys = unique_keys,
    missing_keys = missing_keys,
    duplicated_keys = total_rows - missing_keys - unique_keys,
    valid_primary_key = missing_keys == 0 & unique_keys == total_rows
  )
}


primary_key_spec <- c(
  dim_calendar = "date",
  dim_cargo_types = "cargo_type_id",
  dim_carriers = "carrier_id",
  dim_facilities = "facility_id",
  dim_ports = "port_id",
  dim_projects = "project_id",
  dim_vessels = "vessel_id",
  fact_events = "event_id",
  fact_fuel_prices = "fuel_month_id",
  fact_incidents = "incident_id",
  fact_port_congestion = "port_month_id",
  fact_route_legs = "leg_id",
  fact_shipments = "shipment_id"
)


primary_key_checks <- imap_dfr(
  primary_key_spec,
  function(key, table_name) {
    check_primary_key(
      datasets[[table_name]],
      key,
      table_name
    )
  }
)

primary_key_checks


# ========================================================================================================
# 5. BUSINESS KEYS
# ========================================================================================================

# These column combinations should be unique according to the expected table granularity.

business_key_checks <- tibble(
  table = c(
    "fact_route_legs",
    "fact_events",
    "fact_port_congestion",
    "fact_fuel_prices"
  ),
  business_key = c(
    "shipment_id + leg_sequence",
    "shipment_id + event_sequence",
    "port_id + month_start",
    "month_start"
  ),
  duplicated_combinations = c(
    nrow(
      datasets$fact_route_legs %>%
        count(shipment_id, leg_sequence) %>%
        filter(n > 1)
    ),
    nrow(
      datasets$fact_events %>%
        count(shipment_id, event_sequence) %>%
        filter(n > 1)
    ),
    nrow(
      datasets$fact_port_congestion %>%
        count(port_id, month_start) %>%
        filter(n > 1)
    ),
    nrow(
      datasets$fact_fuel_prices %>%
        count(month_start) %>%
        filter(n > 1)
    )
  )
)

business_key_checks


# ========================================================================================================
# 6. FOREIGN KEYS
# ========================================================================================================

# Missing values may be valid for optional relationships.
# Orphan values always indicate a broken relationship.

check_foreign_key <- function(
    child_data,
    child_key,
    parent_data,
    parent_key,
    relationship_name) {
  
  child_values <- child_data[[child_key]]
  parent_values <- parent_data[[parent_key]]
  
  orphan_values <- sum(
    !is.na(child_values) &
      !(child_values %in% parent_values)
  )
  
  tibble(
    relationship = relationship_name,
    child_rows = nrow(child_data),
    missing_values = sum(is.na(child_values)),
    orphan_values = orphan_values,
    valid_references = orphan_values == 0
  )
}


foreign_key_spec <- tribble(
  ~child_table,          ~child_key,                  ~parent_table,       ~parent_key,
  "fact_shipments",      "project_id",                "dim_projects",      "project_id",
  "fact_shipments",      "origin_facility_id",        "dim_facilities",    "facility_id",
  "fact_shipments",      "destination_facility_id",   "dim_facilities",    "facility_id",
  "fact_shipments",      "origin_port_id",            "dim_ports",         "port_id",
  "fact_shipments",      "destination_port_id",       "dim_ports",         "port_id",
  "fact_shipments",      "carrier_id",                "dim_carriers",      "carrier_id",
  "fact_shipments",      "vessel_id",                 "dim_vessels",       "vessel_id",
  "fact_shipments",      "cargo_type_id",             "dim_cargo_types",   "cargo_type_id",
  "fact_route_legs",     "shipment_id",               "fact_shipments",    "shipment_id",
  "fact_route_legs",     "carrier_id",                "dim_carriers",      "carrier_id",
  "fact_route_legs",     "vessel_id",                 "dim_vessels",       "vessel_id",
  "fact_events",         "shipment_id",               "fact_shipments",    "shipment_id",
  "fact_incidents",      "shipment_id",               "fact_shipments",    "shipment_id",
  "fact_port_congestion","port_id",                   "dim_ports",         "port_id",
  "dim_projects",        "destination_facility_id",   "dim_facilities",    "facility_id",
  "dim_facilities",      "default_port_id",           "dim_ports",         "port_id",
  "dim_vessels",         "operator_carrier_id",       "dim_carriers",      "carrier_id"
)


foreign_key_checks <- pmap_dfr(
  foreign_key_spec,
  function(child_table, child_key, parent_table, parent_key) {
    
    relationship_name <- paste0(
      child_table, ".", child_key,
      " -> ",
      parent_table, ".", parent_key
    )
    
    check_foreign_key(
      datasets[[child_table]],
      child_key,
      datasets[[parent_table]],
      parent_key,
      relationship_name
    )
  }
)

print(foreign_key_checks, n = Inf)


# ========================================================================================================
# 7. BINARY COLUMNS
# ========================================================================================================

# Check columns that should contain only "Y" and "N".

check_binary_column <- function(data, variable, table_name) {
  
  values <- data[[variable]]
  
  tibble(
    table = table_name,
    variable = variable,
    missing_values = sum(is.na(values)),
    invalid_values = sum(
      !is.na(values) &
        !(values %in% c("Y", "N"))
    )
  )
}


binary_column_spec <- tribble(
  ~table,                  ~variable,
  "fact_shipments",        "oversize_flag",
  "fact_shipments",        "heavy_lift_flag",
  "fact_shipments",        "hazardous_flag",
  "fact_shipments",        "temperature_controlled_flag",
  "fact_shipments",        "on_time_flag",
  "fact_shipments",        "damage_flag",
  "dim_calendar",          "is_weekend",
  "dim_calendar",          "is_holiday_sample",
  "dim_facilities",        "heavy_lift_yard",
  "dim_ports",             "heavy_lift_capable",
  "dim_cargo_types",       "hazardous_default",
  "fact_incidents",        "preventable_flag",
  "fact_port_congestion",  "strike_flag"
)


binary_value_checks <- pmap_dfr(
  binary_column_spec,
  function(table, variable) {
    check_binary_column(
      datasets[[table]],
      variable,
      table
    )
  }
)

binary_value_checks


# ========================================================================================================
# 8. EXPECTED MISSING VALUES BY TRANSPORT MODE
# ========================================================================================================

missing_by_primary_mode <- datasets$fact_shipments %>%
  group_by(primary_mode) %>%
  summarise(
    shipments = n(),
    missing_origin_port = sum(is.na(origin_port_id)),
    missing_destination_port = sum(is.na(destination_port_id)),
    missing_vessel = sum(is.na(vessel_id)),
    .groups = "drop"
  )

missing_by_primary_mode


# Add the shipment primary mode to each route leg in memory.

route_legs_with_primary_mode <- datasets$fact_route_legs %>%
  left_join(
    datasets$fact_shipments %>%
      select(shipment_id, primary_mode),
    by = "shipment_id"
  )


vessel_by_primary_and_leg_mode <- route_legs_with_primary_mode %>%
  group_by(primary_mode, mode) %>%
  summarise(
    route_legs = n(),
    missing_vessel = sum(is.na(vessel_id)),
    assigned_vessel = sum(!is.na(vessel_id)),
    .groups = "drop"
  )

vessel_by_primary_and_leg_mode


# ========================================================================================================
# 9. CALENDAR QUALITY
# ========================================================================================================

expected_calendar_dates <- seq(
  from = min(datasets$dim_calendar$date),
  to = max(datasets$dim_calendar$date),
  by = "day"
)


calendar_quality_check <- tibble(
  first_date = min(datasets$dim_calendar$date),
  last_date = max(datasets$dim_calendar$date),
  expected_dates = length(expected_calendar_dates),
  available_dates = n_distinct(datasets$dim_calendar$date),
  missing_dates_in_sequence = sum(
    !(expected_calendar_dates %in% datasets$dim_calendar$date)
  ),
  year_mismatches = sum(
    datasets$dim_calendar$year !=
      lubridate::year(datasets$dim_calendar$date)
  ),
  quarter_mismatches = sum(
    datasets$dim_calendar$quarter !=
      paste0("Q", lubridate::quarter(datasets$dim_calendar$date))
  ),
  month_mismatches = sum(
    datasets$dim_calendar$month !=
      lubridate::month(datasets$dim_calendar$date)
  ),
  month_name_mismatches = sum(
    datasets$dim_calendar$month_name !=
      month.abb[lubridate::month(datasets$dim_calendar$date)]
  ),
  year_month_mismatches = sum(
    datasets$dim_calendar$year_month !=
      format(datasets$dim_calendar$date, "%Y-%m")
  ),
  week_mismatches = sum(
    datasets$dim_calendar$week !=
      lubridate::isoweek(datasets$dim_calendar$date)
  ),
  weekday_mismatches = sum(
    datasets$dim_calendar$weekday !=
      lubridate::wday(
        datasets$dim_calendar$date,
        week_start = 1
      )
  ),
  weekend_flag_mismatches = sum(
    datasets$dim_calendar$is_weekend !=
      if_else(
        lubridate::wday(
          datasets$dim_calendar$date,
          week_start = 1
        ) >= 6,
        "Y",
        "N"
      )
  )
)

calendar_quality_check


# These dates are not errors.
# They show where the calendar year differs from the ISO week year.

calendar_iso_year_boundaries <- datasets$dim_calendar %>%
  mutate(
    iso_year = lubridate::isoyear(date)
  ) %>%
  filter(
    year != iso_year
  ) %>%
  select(
    date,
    weekday_name,
    year,
    iso_year,
    week
  )

calendar_iso_year_boundaries


# ========================================================================================================
# 10. SELECTED BUSINESS RULES
# ========================================================================================================

project_business_rules <- tibble(
  missing_project_dates = sum(
    is.na(datasets$dim_projects$start_date) |
      is.na(datasets$dim_projects$planned_finish_date)
  ),
  invalid_project_date_order = sum(
    !is.na(datasets$dim_projects$start_date) &
      !is.na(datasets$dim_projects$planned_finish_date) &
      datasets$dim_projects$planned_finish_date <
      datasets$dim_projects$start_date
  ),
  missing_on_time_targets = sum(
    is.na(datasets$dim_projects$target_on_time_pct)
  ),
  invalid_on_time_targets = sum(
    !is.na(datasets$dim_projects$target_on_time_pct) &
      (
        datasets$dim_projects$target_on_time_pct < 0 |
          datasets$dim_projects$target_on_time_pct > 100
      )
  ),
  invalid_priority_values = sum(
    !is.na(datasets$dim_projects$priority) &
      !(
        datasets$dim_projects$priority %in%
          c("Low", "Medium", "High", "Critical")
      )
  )
)

project_business_rules


facility_business_rules <- tibble(
  missing_coordinates = sum(
    is.na(datasets$dim_facilities$latitude) |
      is.na(datasets$dim_facilities$longitude)
  ),
  invalid_coordinate_range = sum(
    (
      !is.na(datasets$dim_facilities$latitude) &
        (
          datasets$dim_facilities$latitude < -90 |
            datasets$dim_facilities$latitude > 90
        )
    ) |
      (
        !is.na(datasets$dim_facilities$longitude) &
          (
            datasets$dim_facilities$longitude < -180 |
              datasets$dim_facilities$longitude > 180
          )
      )
  ),
  zero_coordinates = sum(
    datasets$dim_facilities$latitude == 0 &
      datasets$dim_facilities$longitude == 0
  ),
  missing_storage_capacity = sum(
    is.na(datasets$dim_facilities$storage_capacity_tons)
  ),
  invalid_storage_capacity = sum(
    !is.na(datasets$dim_facilities$storage_capacity_tons) &
      datasets$dim_facilities$storage_capacity_tons <= 0
  )
)

facility_business_rules


# ========================================================================================================
# 11. MAIN FINDINGS
# ========================================================================================================

data_quality_findings <- tibble(
  finding = c(
    "Road shipments without origin and destination ports",
    "Road shipments without vessel",
    "Intermodal shipments without vessel",
    "Intermodal Container Sea legs without vessel",
    "Calendar dates where calendar year differs from ISO year"
  ),
  affected_rows = c(
    sum(
      datasets$fact_shipments$primary_mode == "Road" &
        is.na(datasets$fact_shipments$origin_port_id) &
        is.na(datasets$fact_shipments$destination_port_id)
    ),
    sum(
      datasets$fact_shipments$primary_mode == "Road" &
        is.na(datasets$fact_shipments$vessel_id)
    ),
    sum(
      datasets$fact_shipments$primary_mode == "Intermodal" &
        is.na(datasets$fact_shipments$vessel_id)
    ),
    nrow(
      route_legs_with_primary_mode %>%
        filter(
          primary_mode == "Intermodal",
          mode == "Container Sea",
          is.na(vessel_id)
        )
    ),
    nrow(calendar_iso_year_boundaries)
  ),
  interpretation = c(
    "Expected structural missing values",
    "Expected structural missing values",
    "Potential dataset limitation requiring documentation",
    "Potential dataset limitation requiring documentation",
    "Not an error; use ISO year for weekly analysis"
  )
)

data_quality_findings