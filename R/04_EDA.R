# ========================================================================================================
# ================= FREIGHT OPERATIONS ANALYSIS: 04 EXPLORATORY DATA ANALYSIS ============================
# ========================================================================================================

library(tidyverse)
library(here)
library(skimr)


# ========================================================================================================
# 1. IMPORT PROCESSED DATA
# ========================================================================================================

# Define the folder containing the cleaned datasets.

processed_data_path <- here(
  "data",
  "processed_data"
)

# Find all CSV files inside the processed data folder.

processed_csv_paths <- list.files(
  path = processed_data_path,
  pattern = "\\.csv$",
  full.names = TRUE
)

# Stop the script if no processed CSV files are found.

if (length(processed_csv_paths) == 0) {
  stop(
    "No processed CSV files were found in data/processed_data."
  )
}

# Read all processed CSV files and store them in a named list.

eda_datasets <- map(
  processed_csv_paths,
  ~ read_csv(
    .x,
    show_col_types = FALSE
  )
)

names(eda_datasets) <- tools::file_path_sans_ext(
  basename(processed_csv_paths)
)

# Display the imported table names.

names(eda_datasets)

# ========================================================================================================
# 2. SUMMARIZE THE SIZE OF EACH IMPORTED DATASET
# ========================================================================================================

eda_data_inventory <- tibble(
  dataset = names(eda_datasets),
  rows = map_int(
    eda_datasets,
    nrow
  ),
  columns = map_int(
    eda_datasets,
    ncol
  )
) %>%
  arrange(dataset)

eda_data_inventory



# ========================================================================================================
# 3. CREATE THE MAIN SHIPMENT ANALYSIS TABLE
# ========================================================================================================

# Start from fact_shipments, where each row represents one shipment.

shipments_eda <- eda_datasets$fact_shipments %>%
  
  # Add project information.
  
  left_join(
    eda_datasets$dim_projects %>%
      select(
        project_id,
        project_name,
        sector,
        customer_segment,
        project_priority = priority,
        contract_model,
        target_on_time_pct
      ),
    by = "project_id"
  ) %>%
  
  # Add carrier information.
  
  left_join(
    eda_datasets$dim_carriers %>%
      select(
        carrier_id,
        carrier_name,
        carrier_mode = mode,
        carrier_specialization = specialization,
        carrier_country = country_base,
        carrier_contract_type = contract_type,
        carrier_reliability_score = reliability_score,
        carrier_cost_tier = cost_tier,
        carrier_co2_rating = co2_rating
      ),
    by = "carrier_id"
  ) %>%
  
  # Add cargo type information.
  
  left_join(
    eda_datasets$dim_cargo_types %>%
      select(
        cargo_type_id,
        cargo_type,
        cargo_family,
        cargo_base_weight_tons = base_weight_tons,
        cargo_base_volume_cbm = base_volume_cbm,
        cargo_hazardous_default = hazardous_default,
        cargo_oversize_probability = oversize_probability,
        cargo_value_density_eur_per_ton = value_density_eur_per_ton
      ),
    by = "cargo_type_id"
  )


# Check whether every shipment found its corresponding dimension record.

shipment_dimension_matches <- shipments_eda %>%
  summarise(
    shipments = n(),
    missing_project_match = sum(
      is.na(project_name)
    ),
    missing_carrier_match = sum(
      is.na(carrier_name)
    ),
    missing_cargo_type_match = sum(
      is.na(cargo_type)
    )
  )

shipment_dimension_matches


# ========================================================================================================
# 4. GENERAL OPERATIONS OVERVIEW
# ========================================================================================================

# Create a general summary of shipment volume and operational performance.

operations_overview <- shipments_eda %>%
  summarise(
    total_shipments = n(),
    
    total_projects = n_distinct(
      project_id
    ),
    total_carriers = n_distinct(
      carrier_id
    ),
    total_cargo_types = n_distinct(
      cargo_type_id
    ),
    total_weight_tons = round(
      sum(
        weight_tons,
        na.rm = TRUE
      ),
      2
    ),
    cumulative_distance_km = round(
      sum(
        actual_distance_km,
        na.rm = TRUE
      ),
      2
    ),
    total_cost_eur = round(
      sum(
        total_logistics_cost_eur,
        na.rm = TRUE
      ),
      2
    ),
    average_cost_per_shipment_eur = round(
      mean(
        total_logistics_cost_eur,
        na.rm = TRUE
      ),
      2
    ),
    on_time_shipments = sum(
      on_time_flag,
      na.rm = TRUE
    ),
    on_time_rate_pct = round(
      mean(
        on_time_flag,
        na.rm = TRUE
      ) * 100,
      2
    ),
    damaged_shipments = sum(
      damage_flag,
      na.rm = TRUE
    ),
    damage_rate_pct = round(
      mean(
        damage_flag,
        na.rm = TRUE
      ) * 100,
      2
    )
  )
print(
  operations_overview,
  width = Inf
)



# ========================================================================================================
# 5. NUMERIC VARIABLE SUMMARY
# ========================================================================================================

# Review the distribution and descriptive statistics of the main numeric variables.

shipment_numeric_summary <- shipments_eda %>%
  select(
    weight_tons,
    volume_cbm,
    actual_distance_km,
    delay_hours,
    total_logistics_cost_eur,
    cargo_value_eur,
    co2e_kg,
    risk_score
  ) %>%
  skim()

shipment_numeric_summary



# ========================================================================================================
# 6. CATEGORICAL VARIABLE SUMMARY
# ========================================================================================================

# Review the structure and diversity of the main categorical variables.

shipment_categorical_summary <- shipments_eda %>%
  select(
    project_name,
    sector,
    customer_segment,
    project_priority,
    contract_model,
    carrier_name,
    carrier_mode,
    carrier_specialization,
    carrier_country,
    carrier_contract_type,
    carrier_cost_tier,
    carrier_co2_rating,
    cargo_type,
    cargo_family,
    primary_mode,
    status,
    service_level,
    incoterm,
    late_bucket,
    main_delay_reason,
    risk_level,
    oversize_flag,
    heavy_lift_flag,
    hazardous_flag,
    temperature_controlled_flag,
    on_time_flag,
    damage_flag
  ) %>%
  skim()

shipment_categorical_summary


# ========================================================================================================
# 7. NUMERIC VARIABLE DISTRIBUTIONS
# ========================================================================================================

# Convert the main numeric variables to long format for visualization.

shipment_numeric_long <- shipments_eda %>%
  select(
    shipment_id,
    weight_tons,
    volume_cbm,
    actual_distance_km,
    delay_hours,
    total_logistics_cost_eur,
    cargo_value_eur,
    co2e_kg,
    risk_score
  ) %>%
  pivot_longer(
    cols = -shipment_id,
    names_to = "variable",
    values_to = "value"
  )


# Display the distribution of each numeric variable.

numeric_distribution_plot <- shipment_numeric_long %>%
  ggplot(
    aes(
      x = value
    ),
  ) +
  geom_histogram(
    bins = 30,
    boundary = 0,
    fill="turquoise4",
    col="white"
  ) +
  facet_wrap(
    vars(variable),
    scales = "free",
    ncol = 2
  ) +
  labs(
    title = "DISTRIBUTION OF NUMERIC VARIABLES - SHIPMENTS HISTOGRAMS",
    x = NULL,
    y = "y = number of shipments"
  ) +
  theme_minimal()

numeric_distribution_plot

# Display the spread and potential outliers of each numeric variable.

numeric_boxplot <- shipment_numeric_long %>%
  ggplot(
    aes(
      x = variable,
      y = value,
      fill = variable,
    )
  ) +
  geom_boxplot(
    outlier.alpha = 0.5
  ) +
  facet_wrap(
    vars(variable),
    scales = "free",
    ncol = 4
  ) +
  labs(
    title = "DISTRIBUTION OF NUMERIC VARIABLES - SHIPMENTS BOXPLOTS ANALYSIS",
    x = NULL,
    y = NULL
  ) +
  theme(
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank()
  )

numeric_boxplot



# ========================================================================================================
# 8. POTENTIAL OUTLIER IDENTIFICATION
# ========================================================================================================

# Identify potential outliers using the interquartile range criterion.

numeric_outlier_summary <- shipment_numeric_long %>%
  group_by(variable) %>%
  summarise(
    lower_limit = quantile(value, 0.25) - 1.5 * IQR(value),
    upper_limit = quantile(value, 0.75) + 1.5 * IQR(value),
    total_outliers = sum(
      value < lower_limit | value > upper_limit
    ),
    outlier_rate_pct = round(
      total_outliers / n() * 100,
      2
    ),
    .groups = "drop"
  )

numeric_outlier_summary

# ========================================================================================================
# 9. IDENTIFY FIRST 10 SHIPMENTS IN DESCENDENT ORDER WITH HIGHEST TOTAL LOGISTICS COSTS AND WEIGHT TONS
# ========================================================================================================

highest_cost_shipments <- shipments_eda %>%
  arrange(
    desc(total_logistics_cost_eur)
  ) %>%
  select(
    shipment_id,
    project_name,
    carrier_name,
    primary_mode,
    cargo_type,
    weight_tons,
    volume_cbm,
    actual_distance_km,
    total_logistics_cost_eur,
    cargo_value_eur,
    co2e_kg,
    risk_level
  ) %>%
  slice_head(
    n = 10
  )

highest_cost_shipments


highest_weight_shipments <- shipments_eda %>%
  arrange(
    desc(weight_tons)
  ) %>%
  select(
    shipment_id,
    project_name,
    primary_mode,
    cargo_type,
    cargo_family,
    weight_tons,
    volume_cbm,
    total_logistics_cost_eur,
    heavy_lift_flag,
    oversize_flag
  ) %>%
  slice_head(
    n = 10
  )

highest_weight_shipments




# ========================================================================================================
# 10. STUDY OPERATIONAL RELATIONSHIPS - SPEARMAN CORRELATION MATRIX
# ========================================================================================================

# Select the numeric variables used to study operational relationships.

numeric_relationship_variables <- shipments_eda %>%
  select(
    total_logistics_cost_eur,
    weight_tons,
    volume_cbm,
    actual_distance_km,
    cargo_value_eur,
    co2e_kg,
    delay_hours,
    risk_score
  )


# Calculate the Spearman correlation matrix.

spearman_correlation_matrix <- cor(numeric_relationship_variables,method = "spearman")
round(spearman_correlation_matrix,2)


# Extract and rank correlations with logistics cost.

cost_correlations <- tibble(
  variable = rownames(
    spearman_correlation_matrix
  ),
  spearman_correlation =
    spearman_correlation_matrix[
      ,
      "total_logistics_cost_eur"
    ]
) %>%
  filter(
    variable != "total_logistics_cost_eur"
  ) %>%
  arrange(
    desc(
      abs(spearman_correlation)
    )
  ) %>%
  mutate(
    spearman_correlation = round(
      spearman_correlation,
      3
    )
  )

cost_correlations


# ========================================================================================================
# 11. VISUALIZE MAIN RELATIONSHIPS WITH LOGISTICS COST
# ========================================================================================================

# Convert the main cost-related variables to long format.

cost_relationships_long <- shipments_eda %>%
  select(
    total_logistics_cost_eur,
    co2e_kg,
    weight_tons,
    volume_cbm,
    actual_distance_km,
    risk_score
  ) %>%
  pivot_longer(
    cols = -total_logistics_cost_eur,
    names_to = "variable",
    values_to = "value"
  )


# Visualize the relationship between each variable and logistics cost.

cost_relationships_plot <- ggplot(
  cost_relationships_long,
  aes(
    x = value,
    y = total_logistics_cost_eur
  )
) +
  geom_point(
    color = "#01B7CD",
    alpha = 0.45,
    size = 1.8
  ) +
  geom_smooth(
    color = "#003566",
    linewidth = 1.1,
    se = FALSE
  ) +
  facet_wrap(
    vars(variable),
    scales = "free_x",
    ncol = 2
  ) +
  labs(
    title = "Main Relationships with Logistics Cost",
    x = NULL,
    y = "Total logistics cost (EUR)"
  ) +
  theme_minimal()

cost_relationships_plot


# ========================================================================================================
# 12. OPERATIONAL PERFORMANCE BY PRIMARY TRANSPORT MODE
# ========================================================================================================

# Compare cost, delay, punctuality, damage and emissions by transport mode.

mode_performance <- shipments_eda %>%
  group_by(primary_mode) %>%
  summarise(
    shipments = n(),
    median_cost_eur = round(
      median(total_logistics_cost_eur),
      2
    ),
    median_delay_hours = round(
      median(delay_hours),
      2
    ),
    on_time_rate_pct = round(
      mean(on_time_flag) * 100,
      2
    ),
    damage_rate_pct = round(
      mean(damage_flag) * 100,
      2
    ),
    median_co2e_kg = round(
      median(co2e_kg),
      2
    ),
    .groups = "drop"
  ) %>%
  arrange(
    desc(shipments)
  )

mode_performance



# ========================================================================================================
# 13. PROJECT PERFORMANCE AGAINST ON-TIME TARGET
# ========================================================================================================

# Compare actual project performance with the defined on-time target.

project_performance <- shipments_eda %>%
  group_by(project_name) %>%
  summarise(
    shipments = n(),
    target_on_time_pct = first(
      target_on_time_pct
    ),
    on_time_rate_pct = round(
      mean(on_time_flag) * 100,
      2
    ),
    median_delay_hours = round(
      median(delay_hours),
      2
    ),
    median_cost_eur = round(
      median(total_logistics_cost_eur),
      2
    ),
    damage_rate_pct = round(
      mean(damage_flag) * 100,
      2
    ),
    .groups = "drop"
  ) %>%
  mutate(
    on_time_gap_pp = round(
      on_time_rate_pct - target_on_time_pct,
      2
    )
  ) %>%
  arrange(on_time_gap_pp)

project_performance



# ========================================================================================================
# 14. VISUALIZE PROJECT ON-TIME PERFORMANCE
# ========================================================================================================

# Compare actual on-time performance with each project target.

project_performance_plot <- project_performance %>%
  ggplot(
    aes(
      x = reorder(project_name, on_time_gap_pp),
      y = on_time_rate_pct
    )
  ) +
  geom_col(
    fill = "#00A6C8",
    width = 0.55
  ) +
  geom_point(
    aes(
      y = target_on_time_pct
    ),
    color = "#AE2012",
    size = 5
  ) +
  coord_flip() +
  scale_y_continuous(
    limits = c(0, 100),
    breaks = seq(0, 100, 10)
  ) +
  labs(
    title = "ACTUAL ON TIME PERFORMANCE VS PROJECT TARGET",
    subtitle = "Bars: actual | Points: target",
    x = NULL,
    y = "On-time shipments (%)"
  ) +
  theme_minimal()

project_performance_plot


# ========================================================================================================
# 15. OPERATIONAL PERFORMANCE BY CARRIER
# ========================================================================================================

# Compare shipment volume and operational performance by carrier.

carrier_performance <- shipments_eda %>%
  group_by(
    carrier_name,
    carrier_mode
  ) %>%
  summarise(
    shipments = n(),
    on_time_rate_pct = round(
      mean(on_time_flag) * 100,
      2
    ),
    median_delay_hours = round(
      median(delay_hours),
      2
    ),
    median_cost_eur = round(
      median(total_logistics_cost_eur),
      2
    ),
    damage_rate_pct = round(
      mean(damage_flag) * 100,
      2
    ),
    .groups = "drop"
  ) %>%
  arrange(
    on_time_rate_pct
  )

carrier_performance


# ========================================================================================================
# 16. MONTHLY OPERATIONAL PERFORMANCE
# ========================================================================================================

# Analyze operational results by actual delivery month.

monthly_performance <- shipments_eda %>%
  mutate(
    delivery_month = as.Date(
      lubridate::floor_date(
        actual_delivery_datetime,
        unit = "month"
      )
    )
  ) %>%
  group_by(delivery_month) %>%
  summarise(
    shipments = n(),
    
    on_time_rate_pct = round(
      mean(on_time_flag) * 100,
      2
    ),
    median_delay_hours = round(
      median(delay_hours),
      2
    ),
    total_cost_eur = round(
      sum(total_logistics_cost_eur),
      2
    ),
    .groups = "drop"
  )

monthly_performance


# ========================================================================================================
# 17. VISUALIZE MONTHLY OPERATIONAL TRENDS
# ========================================================================================================

monthly_performance_long <- monthly_performance %>%
  pivot_longer(
    cols = -delivery_month,
    names_to = "metric",
    values_to = "value"
  )
monthly_performance_plot <- ggplot(
  monthly_performance_long,
  aes(
    x = delivery_month,
    y = value
  )
) +
  geom_line(
    color = "#004C6D",
    linewidth = 1
  ) +
  geom_point(
    color = "#E56B6F",
    size = 2
  ) +
  facet_wrap(
    vars(metric),
    scales = "free_y",
    ncol = 2
  ) +
  labs(
    title = "MONTHLY FREIGHT OPERATIONS PERFORMANCE",
    x = NULL,
    y = NULL
  ) +
  theme_minimal()
monthly_performance_plot



# ========================================================================================================
# 18. OPERATIONAL PROFILE BY CARGO FAMILY
# ========================================================================================================

# Compare shipment characteristics and performance by cargo family.

cargo_family_performance <- shipments_eda %>%
  group_by(cargo_family) %>%
  summarise(
    shipments = n(),
    median_weight_tons = round(
      median(weight_tons),
      2
    ),
    median_cost_eur = round(
      median(total_logistics_cost_eur),
      2
    ),
    on_time_rate_pct = round(
      mean(on_time_flag) * 100,
      2
    ),
    damage_rate_pct = round(
      mean(damage_flag) * 100,
      2
    ),
    heavy_lift_rate_pct = round(
      mean(heavy_lift_flag) * 100,
      2
    ),
    .groups = "drop"
  ) %>%
  arrange(
    desc(median_cost_eur)
  )

cargo_family_performance


# ========================================================================================================
# 19. PERFORMANCE BY SPECIAL CARGO CHARACTERISTICS
# ========================================================================================================

# Compare operational performance according to special cargo characteristics.

special_cargo_performance <- shipments_eda %>%
  select(
    total_logistics_cost_eur,
    delay_hours,
    on_time_flag,
    damage_flag,
    oversize_flag,
    heavy_lift_flag,
    hazardous_flag,
    temperature_controlled_flag
  ) %>%
  pivot_longer(
    cols = c(
      oversize_flag,
      heavy_lift_flag,
      hazardous_flag,
      temperature_controlled_flag
    ),
    names_to = "cargo_characteristic",
    values_to = "characteristic_present"
  ) %>%
  group_by(
    cargo_characteristic,
    characteristic_present
  ) %>%
  summarise(
    shipments = n(),
    
    median_cost_eur = round(
      median(total_logistics_cost_eur),
      2
    ),
    median_delay_hours = round(
      median(delay_hours),
      2
    ),
    on_time_rate_pct = round(
      mean(on_time_flag) * 100,
      2
    ),
    damage_rate_pct = round(
      mean(damage_flag) * 100,
      2
    ),
    .groups = "drop"
  )

special_cargo_performance


# ========================================================================================================
# 20. OPERATIONAL PERFORMANCE BY RISK LEVEL
# ========================================================================================================

# Compare operational performance across shipment risk levels.

risk_level_performance <- shipments_eda %>%
  mutate(
    risk_level = factor(
      risk_level,
      levels = c(
        "Low",
        "Medium",
        "High"
      )
    )
  ) %>%
  group_by(risk_level) %>%
  summarise(
    shipments = n(),
    median_cost_eur = round(
      median(total_logistics_cost_eur),
      2
    ),
    median_delay_hours = round(
      median(delay_hours),
      2
    ),
    on_time_rate_pct = round(
      mean(on_time_flag) * 100,
      2
    ),
    damage_rate_pct = round(
      mean(damage_flag) * 100,
      2
    ),
    .groups = "drop"
  )

risk_level_performance


# ========================================================================================================
# 21. CREATE THE INCIDENT ANALYSIS TABLE
# ========================================================================================================

# Add shipment information to each incident.

incidents_eda <- eda_datasets$fact_incidents %>%
  left_join(
    shipments_eda %>%
      select(
        shipment_id,
        project_name,
        primary_mode,
        carrier_name,
        cargo_family,
        risk_level
      ),
    by = "shipment_id"
  )


# Incident overview

incident_overview <- incidents_eda %>%
  summarise(
    total_incidents = n(),
    affected_shipments = n_distinct(
      shipment_id
    ),
    affected_shipment_rate_pct = round(
      affected_shipments /
        nrow(shipments_eda) * 100,
      2
    ),
    preventable_incidents = sum(
      preventable_flag,
      na.rm = TRUE
    ),
    preventable_rate_pct = round(
      mean(
        preventable_flag,
        na.rm = TRUE
      ) * 100,
      2
    ),
    total_delay_hours_impact = round(
      sum(
        delay_hours_impact,
        na.rm = TRUE
      ),
      2
    ),
    total_direct_cost_eur = round(
      sum(
        direct_cost_eur,
        na.rm = TRUE
      ),
      2
    ),
    
    total_claim_amount_eur = round(
      sum(
        claim_amount_eur,
        na.rm = TRUE
      ),
      2
    )
  )

print(
  incident_overview,
  width = Inf
)


# Compare frequency, prevent-ability and operational impact by incident type.

incident_type_impact <- incidents_eda %>%
  group_by(incident_type) %>%
  summarise(
    incidents = n(),
    preventable_rate_pct = round(
      mean(preventable_flag, na.rm = TRUE) * 100,
      2
    ),
    total_delay_hours = round(
      sum(delay_hours_impact, na.rm = TRUE),
      2
    ),
    median_delay_hours = round(
      median(delay_hours_impact, na.rm = TRUE),
      2
    ),
    total_direct_cost_eur = round(
      sum(direct_cost_eur, na.rm = TRUE),
      2
    ),
    total_claim_amount_eur = round(
      sum(claim_amount_eur, na.rm = TRUE),
      2
    ),
    .groups = "drop"
  ) %>%
  arrange(
    desc(total_direct_cost_eur)
  )

incident_type_impact


# Compare incident frequency and impact by root cause.

root_cause_impact <- incidents_eda %>%
  mutate(
    root_cause = if_else(
      root_cause == "None",
      "Not identified",
      root_cause
    )
  ) %>%
  group_by(root_cause) %>%
  summarise(
    incidents = n(),
    
    preventable_rate_pct = round(
      mean(preventable_flag, na.rm = TRUE) * 100,
      2
    ),
    total_delay_hours = round(
      sum(delay_hours_impact, na.rm = TRUE),
      2
    ),
    total_direct_cost_eur = round(
      sum(direct_cost_eur, na.rm = TRUE),
      2
    ),
    total_claim_amount_eur = round(
      sum(claim_amount_eur, na.rm = TRUE),
      2
    ),
    
    .groups = "drop"
  ) %>%
  mutate(
    average_direct_cost_eur = round(
      total_direct_cost_eur / incidents,
      2
    )
  ) %>%
  arrange(
    desc(total_direct_cost_eur)
  )

root_cause_impact


# Compare incident frequency and impact by severity level.

incident_severity_impact <- incidents_eda %>%
  mutate(
    severity = factor(
      severity,
      levels = c(
        "Low",
        "Medium",
        "High",
        "Critical"
      )
    )
  ) %>%
  group_by(severity) %>%
  summarise(
    incidents = n(),
    preventable_rate_pct = round(
      mean(preventable_flag) * 100,
      2
    ),
    median_delay_hours = round(
      median(delay_hours_impact),
      2
    ),
    total_direct_cost_eur = round(
      sum(direct_cost_eur),
      2
    ),
    total_claim_amount_eur = round(
      sum(claim_amount_eur),
      2
    ),
    .groups = "drop"
  )

incident_severity_impact


# Compare incident frequency and impact by location type.

incident_location_impact <- incidents_eda %>%
  group_by(location_type) %>%
  summarise(
    incidents = n(),
    preventable_rate_pct = round(
      mean(preventable_flag) * 100,
      2
    ),
    median_delay_hours = round(
      median(delay_hours_impact),
      2
    ),
    total_direct_cost_eur = round(
      sum(direct_cost_eur),
      2
    ),
    average_direct_cost_eur = round(
      mean(direct_cost_eur),
      2
    ),
    
    total_claim_amount_eur = round(
      sum(claim_amount_eur),
      2
    ),
    .groups = "drop"
  ) %>%
  arrange(
    desc(total_direct_cost_eur)
  )

incident_location_impact


# ========================================================================================================
# 22. CREATE THE ROUTE LEG ANALYSIS TABLE
# ========================================================================================================

# Add shipment and carrier information to each route leg.

route_legs_eda <- eda_datasets$fact_route_legs %>%
  left_join(
    shipments_eda %>%
      select(
        shipment_id,
        project_name,
        shipment_primary_mode = primary_mode,
        cargo_family,
        weight_tons
      ),
    by = "shipment_id"
  ) %>%
  left_join(
    eda_datasets$dim_carriers %>%
      select(
        carrier_id,
        leg_carrier_name = carrier_name
      ),
    by = "carrier_id"
  )


# Count the number of route legs contained in each shipment.

route_legs_per_shipment <- route_legs_eda %>%
  count(
    shipment_id,
    name = "route_legs"
  )

# Summarize the route structure.

route_structure_overview <- route_legs_per_shipment %>%
  summarise(
    shipments_with_route_legs = n(),
    shipments_without_route_legs =
      nrow(shipments_eda) - n(),
    total_route_legs = sum(
      route_legs
    ),
    average_legs_per_shipment = round(
      mean(route_legs),
      2
    ),
    median_legs_per_shipment = median(
      route_legs
    ),
    minimum_legs = min(
      route_legs
    ),
    maximum_legs = max(
      route_legs
    )
  )

route_structure_overview


# Compare route leg volume and operational performance by transport mode.

route_leg_mode_performance <- route_legs_eda %>%
  group_by(mode) %>%
  summarise(
    route_legs = n(),
    shipments = n_distinct(shipment_id),
    median_distance_km = round(
      median(actual_distance_km),
      2
    ),
    median_transit_hours = round(
      median(actual_transit_hours),
      2
    ),
    median_delay_hours = round(
      median(delay_hours),
      2
    ),
    median_leg_cost_eur = round(
      median(leg_cost_eur),
      2
    ),
    median_co2e_kg = round(
      median(co2e_kg),
      2
    ),
    .groups = "drop"
  ) %>%
  arrange(
    desc(route_legs)
  )

route_leg_mode_performance


# Check how many delayed route legs have a specific recorded cause.

delay_reason_documentation <- route_legs_eda %>%
  summarise(
    delayed_legs = sum(
      delay_hours > 0
    ),
    delayed_legs_with_reason = sum(
      delay_hours > 0 &
        delay_reason != "None"
    ),
    delayed_legs_without_reason = sum(
      delay_hours > 0 &
        delay_reason == "None"
    ),
    reason_documentation_rate_pct = round(
      delayed_legs_with_reason /
        delayed_legs * 100,
      2
    )
  )

delay_reason_documentation


# Compare the frequency and delay impact of specifically recorded causes.

route_leg_delay_impact <- route_legs_eda %>%
  filter(
    delay_reason != "None"
  ) %>%
  group_by(delay_reason) %>%
  summarise(
    route_legs = n(),
    total_delay_hours = round(
      sum(delay_hours),
      2
    ),
    median_delay_hours = round(
      median(delay_hours),
      2
    ),
    
    maximum_delay_hours = round(
      max(delay_hours),
      2
    ),
    .groups = "drop"
  ) %>%
  arrange(
    desc(total_delay_hours)
  )

route_leg_delay_impact


# ========================================================================================================
# 23. CREATE THE EVENT ANALYSIS TABLE
# ========================================================================================================

# Add basic shipment information to each operational event.

events_eda <- eda_datasets$fact_events %>%
  left_join(
    shipments_eda %>%
      select(
        shipment_id,
        project_name,
        primary_mode,
        cargo_family
      ),
    by = "shipment_id"
  )


# Count the number of operational events recorded for each shipment.

events_per_shipment <- events_eda %>%
  count(
    shipment_id,
    name = "events"
  )


# Summarize the number of events contained in each shipment.

event_structure_overview <- events_per_shipment %>%
  summarise(
    shipments = n(),
    total_events = sum(
      events
    ),
    average_events_per_shipment = round(
      mean(events),
      2
    ),
    median_events_per_shipment = median(
      events
    ),
    minimum_events = min(
      events
    ),
    maximum_events = max(
      events
    )
  )

event_structure_overview


# Check how frequently each event type appears across shipments.

event_type_coverage <- events_eda %>%
  group_by(event_type) %>%
  summarise(
    events = n(),
    shipments = n_distinct(
      shipment_id
    ),
    shipment_coverage_pct = round(
      shipments / nrow(shipments_eda) * 100,
      2
    ),
    .groups = "drop"
  ) %>%
  arrange(
    desc(shipments)
  )

event_type_coverage


# Summarize the status of all operational events.

event_status_overview <- events_eda %>%
  count(
    event_status,
    name = "events"
  ) %>%
  mutate(
    event_share_pct = round(
      events / sum(events) * 100,
      2
    )
  ) %>%
  arrange(
    desc(events)
  )

event_status_overview


# Compare delayed event frequency across operational milestones.

event_delay_by_type <- events_eda %>%
  group_by(event_type) %>%
  summarise(
    events = n(),
    delayed_events = sum(
      event_status == "Delayed"
    ),
    delayed_event_rate_pct = round(
      mean(event_status == "Delayed") * 100,
      2
    ),
    .groups = "drop"
  ) %>%
  arrange(
    desc(delayed_event_rate_pct)
  )

event_delay_by_type

# Summarize the responsible party recorded for delayed deliveries.

delayed_event_responsibility <- events_eda %>%
  filter(
    event_status == "Delayed"
  ) %>%
  count(
    responsible_party,
    name = "delayed_events",
    sort = TRUE
  ) %>%
  mutate(
    delayed_event_share_pct = round(
      delayed_events / sum(delayed_events) * 100,
      2
    )
  )

delayed_event_responsibility

# All delayed events correspond to "Delivery completed and are assigned to the carrier.


# ========================================================================================================
# 24. CREATE THE PORT CONGESTION ANALYSIS TABLE
# ========================================================================================================

# Add descriptive port information to each monthly congestion record.

port_congestion_eda <- eda_datasets$fact_port_congestion %>%
  left_join(
    eda_datasets$dim_ports %>%
      select(
        port_id,
        port_name,
        country,
        region,
        port_cluster,
        specialization,
        heavy_lift_capable,
        avg_berth_productivity_tph,
        customs_risk_level
      ),
    by = "port_id"
  )

port_congestion_eda %>%
  slice_head(
    n = 10
  )

# Summarize the overall port congestion conditions.

port_congestion_overview <- port_congestion_eda %>%
  summarise(
    records = n(),
    ports = n_distinct(
      port_id
    ),
    months = n_distinct(
      month_start
    ),
    first_month = min(
      month_start
    ),
    last_month = max(
      month_start
    ),
    median_congestion_index = round(
      median(congestion_index),
      2
    ),
    median_vessel_wait_hours = round(
      median(avg_vessel_wait_hours),
      2
    ),
    
    median_berth_utilization_pct = round(
      median(berth_utilization_pct),
      2
    ),
    median_customs_clearance_days = round(
      median(customs_clearance_avg_days),
      2
    ),
    strike_months = sum(
      strike_flag
    ),
    strike_month_rate_pct = round(
      mean(strike_flag) * 100,
      2
    )
  )

port_congestion_overview


# Compare congestion and operational conditions across ports.

port_congestion_by_port <- port_congestion_eda %>%
  group_by(
    port_id,
    port_name,
    country,
    region
  ) %>%
  summarise(
    months = n(),
    median_congestion_index = round(
      median(congestion_index),
      2
    ),
    median_vessel_wait_hours = round(
      median(avg_vessel_wait_hours),
      2
    ),
    median_berth_utilization_pct = round(
      median(berth_utilization_pct),
      2
    ),
    median_customs_clearance_days = round(
      median(customs_clearance_avg_days),
      2
    ),
    strike_months = sum(
      strike_flag
    ),
    .groups = "drop"
  ) %>%
  arrange(
    desc(median_congestion_index)
  )

port_congestion_by_port


# Study the relationships between the main port congestion indicators.

port_congestion_correlations <- port_congestion_eda %>%
  select(
    congestion_index,
    avg_vessel_wait_hours,
    berth_utilization_pct,
    customs_clearance_avg_days
  ) %>%
  cor(
    method = "spearman"
  )

round(
  port_congestion_correlations,
  2
)


# Compare port conditions between port-months with and without strikes.

port_strike_comparison <- port_congestion_eda %>%
  mutate(
    strike_status = if_else(
      strike_flag,
      "Strike",
      "No strike"
    )
  ) %>%
  group_by(strike_status) %>%
  summarise(
    port_months = n(),
    ports = n_distinct(
      port_id
    ),
    
    median_congestion_index = round(
      median(congestion_index),
      2
    ),
    median_vessel_wait_hours = round(
      median(avg_vessel_wait_hours),
      2
    ),
    median_berth_utilization_pct = round(
      median(berth_utilization_pct),
      2
    ),
    median_customs_clearance_days = round(
      median(customs_clearance_avg_days),
      2
    ),
    .groups = "drop"
  )

port_strike_comparison


# Summarize port congestion conditions by month.

monthly_port_congestion <- port_congestion_eda %>%
  group_by(month_start) %>%
  summarise(
    ports = n_distinct(
      port_id
    ),
    median_congestion_index = round(
      median(congestion_index),
      2
    ),
    median_vessel_wait_hours = round(
      median(avg_vessel_wait_hours),
      2
    ),
    median_berth_utilization_pct = round(
      median(berth_utilization_pct),
      2
    ),
    median_customs_clearance_days = round(
      median(customs_clearance_avg_days),
      2
    ),
    strike_port_months = sum(
      strike_flag
    ),
    .groups = "drop"
  )

monthly_port_congestion



# Visualize the monthly median congestion index across all ports.

monthly_port_congestion_plot <- monthly_port_congestion %>%
  ggplot(
    aes(
      x = month_start,
      y = median_congestion_index
    )
  ) +
  geom_line(
    color = "#004C6D",
    linewidth = 1
  ) +
  geom_point(
    color = "#E56B6F",
    size = 2
  ) +
  scale_x_date(
    date_breaks = "3 months",
    date_labels = "%b\n%Y"
  ) +
  labs(
    title = "MONTHLY PORT CONGESTION",
    subtitle = "Median congestion index across 18 ports",
    x = NULL,
    y = "Median congestion index"
  ) +
  theme_minimal()

monthly_port_congestion_plot



# ========================================================================================================
# 25. FUEL PRICE ANALYSIS
# ========================================================================================================

# Create the monthly fuel price analysis table.

fuel_prices_eda <- eda_datasets$fact_fuel_prices


# Summarize the period and central fuel prices.

fuel_price_overview <- fuel_prices_eda %>%
  summarise(
    records = n(),
    months = n_distinct(
      month_start
    ),
    first_month = min(
      month_start
    ),
    last_month = max(
      month_start
    ),
    median_diesel_eur_per_liter = round(
      median(diesel_eur_per_liter),
      2
    ),
    
    median_mgo_eur_per_ton = round(
      median(mgo_eur_per_ton),
      2
    ),
    median_vlsfo_eur_per_ton = round(
      median(vlsfo_eur_per_ton),
      2
    )
  )

fuel_price_overview


# Convert fuel prices to long format for visualization.

fuel_prices_long <- fuel_prices_eda %>%
  select(
    month_start,
    diesel_eur_per_liter,
    mgo_eur_per_ton,
    vlsfo_eur_per_ton
  ) %>%
  pivot_longer(
    cols = -month_start,
    names_to = "fuel_type",
    values_to = "price"
  )


# Visualize the monthly evolution of each fuel price.

fuel_price_trend_plot <- fuel_prices_long %>%
  ggplot(
    aes(
      x = month_start,
      y = price
    )
  ) +
  geom_line(
    color = "#004C6D",
    linewidth = 1
  ) +
  geom_point(
    color = "#E56B6F",
    size = 2
  ) +
  facet_wrap(
    vars(fuel_type),
    scales = "free_y",
    ncol = 1
  ) +
  scale_x_date(
    date_breaks = "3 months",
    date_labels = "%b\n%Y"
  ) +
  labs(
    title = "MONTHLY FUEL PRICE TRENDS",
    x = NULL,
    y = NULL
  ) +
  theme_minimal()

fuel_price_trend_plot


# Summarize shipment fuel surcharges by actual pickup month.

monthly_fuel_surcharge <- shipments_eda %>%
  mutate(
    month_start = as.Date(
      lubridate::floor_date(
        actual_pickup_datetime,
        unit = "month"
      )
    ),
    
    fuel_surcharge_rate_pct = round(
      fuel_surcharge_eur /
        freight_cost_eur * 100,
      2
    )
  ) %>%
  group_by(month_start) %>%
  summarise(
    shipments = n(),
    
    median_fuel_surcharge_eur = round(
      median(fuel_surcharge_eur),
      2
    ),
    
    median_fuel_surcharge_rate_pct = round(
      median(fuel_surcharge_rate_pct),
      2
    ),
    .groups = "drop"
  )


# Add the corresponding monthly fuel prices.

fuel_surcharge_and_prices <- monthly_fuel_surcharge %>%
  left_join(
    fuel_prices_eda,
    by = "month_start"
  )

fuel_surcharge_and_prices


# Summarize the fuel surcharge rate by month and primary transport mode.

monthly_fuel_surcharge_by_mode <- shipments_eda %>%
  mutate(
    month_start = as.Date(
      lubridate::floor_date(
        actual_pickup_datetime,
        unit = "month"
      )
    ),
    
    fuel_surcharge_rate_pct =
      fuel_surcharge_eur /
      freight_cost_eur * 100
  ) %>%
  group_by(
    month_start,
    primary_mode
  ) %>%
  summarise(
    shipments = n(),
    
    median_fuel_surcharge_rate_pct = round(
      median(
        fuel_surcharge_rate_pct,
        na.rm = TRUE
      ),
      2
    ),
    
    .groups = "drop"
  ) %>%
  left_join(
    fuel_prices_eda %>%
      select(
        month_start,
        diesel_eur_per_liter,
        mgo_eur_per_ton,
        vlsfo_eur_per_ton
      ),
    by = "month_start"
  ) %>%
  arrange(
    primary_mode,
    month_start
  )

monthly_fuel_surcharge_by_mode


# Review whether monthly mode groups contain enough shipments for a meaningful comparison with fuel prices.

fuel_surcharge_mode_sample_size <- monthly_fuel_surcharge_by_mode %>%
  group_by(primary_mode) %>%
  summarise(
    months_available = n(),
    total_shipments = sum(
      shipments
    ),
    minimum_shipments_per_month = min(
      shipments
    ),
    median_shipments_per_month = median(
      shipments
    ),
    maximum_shipments_per_month = max(
      shipments
    ),
    
    months_with_fewer_than_5_shipments = sum(
      shipments < 5
    ),
    
    .groups = "drop"
  ) %>%
  arrange(
    desc(total_shipments)
  )

fuel_surcharge_mode_sample_size


# Group transport modes according to their main fuel exposure.

fuel_surcharge_by_transport_group <- shipments_eda %>%
  mutate(
    month_start = as.Date(
      lubridate::floor_date(
        actual_pickup_datetime,
        unit = "month"
      )
    ),
    transport_group = case_when(
      primary_mode == "Road" ~ "Road",
      
      primary_mode %in% c(
        "Sea Breakbulk",
        "Container Sea",
        "RoRo"
      ) ~ "Maritime",
      TRUE ~ NA_character_
    ),
    fuel_surcharge_rate_pct =
      fuel_surcharge_eur /
      freight_cost_eur * 100
  ) %>%
  filter(
    !is.na(transport_group)
  ) %>%
  group_by(
    month_start,
    transport_group
  ) %>%
  summarise(
    shipments = n(),
    
    median_fuel_surcharge_rate_pct = round(
      median(
        fuel_surcharge_rate_pct,
        na.rm = TRUE
      ),
      2
    ),
    .groups = "drop"
  ) %>%
  left_join(
    fuel_prices_eda %>%
      select(
        month_start,
        diesel_eur_per_liter,
        mgo_eur_per_ton,
        vlsfo_eur_per_ton
      ),
    by = "month_start"
  ) %>%
  arrange(
    transport_group,
    month_start
  )

fuel_surcharge_by_transport_group


# Separate road and maritime monthly observations.

road_fuel_data <- fuel_surcharge_by_transport_group %>%
  filter(
    transport_group == "Road"
  )

maritime_fuel_data <- fuel_surcharge_by_transport_group %>%
  filter(
    transport_group == "Maritime"
  )


# Calculate Spearman correlations between fuel prices and the median fuel surcharge rate.

fuel_price_correlations <- tibble(
  relationship = c(
    "Road surcharge vs diesel price",
    "Maritime surcharge vs MGO price",
    "Maritime surcharge vs VLSFO price"
  ),
  spearman_correlation = round(
    c(
      cor(
        road_fuel_data$median_fuel_surcharge_rate_pct,
        road_fuel_data$diesel_eur_per_liter,
        method = "spearman"
      ),
      cor(
        maritime_fuel_data$median_fuel_surcharge_rate_pct,
        maritime_fuel_data$mgo_eur_per_ton,
        method = "spearman"
      ),
      
      cor(
        maritime_fuel_data$median_fuel_surcharge_rate_pct,
        maritime_fuel_data$vlsfo_eur_per_ton,
        method = "spearman"
      )
    ),
    3
  )
)

fuel_price_correlations



# ========================================================================================================
# 26. LOGISTICS COST COMPOSITION
# ========================================================================================================

# Summarize the contribution of each cost component
# to the total logistics expenditure.

cost_composition <- shipments_eda %>%
  summarise(
    Freight = sum(
      freight_cost_eur
    ),
    `Fuel surcharge` = sum(
      fuel_surcharge_eur
    ),
    `Port costs` = sum(
      port_cost_eur
    ),
    `Customs costs` = sum(
      customs_cost_eur
    )
  ) %>%
  pivot_longer(
    cols = everything(),
    names_to = "cost_component",
    values_to = "total_cost_eur"
  ) %>%
  mutate(
    cost_share_pct = round(
      total_cost_eur /
        sum(total_cost_eur) * 100,
      2
    ),
    total_cost_eur = round(
      total_cost_eur,
      2
    )
  ) %>%
  arrange(
    desc(total_cost_eur)
  )

cost_composition



# ========================================================================================================
# 27. EMISSIONS INTENSITY BY PRIMARY TRANSPORT MODE
# ========================================================================================================

# Compare normalized emissions across primary transport modes.

emissions_intensity_by_mode <- shipments_eda %>%
  group_by(primary_mode) %>%
  summarise(
    shipments = n(),
    median_co2e_kg_per_ton_km = round(
      median(
        co2e_kg_per_ton_km,
        na.rm = TRUE
      ),
      4
    ),
    .groups = "drop"
  ) %>%
  arrange(
    desc(median_co2e_kg_per_ton_km)
  )

emissions_intensity_by_mode


# ========================================================================================================
# 28. OPERATIONAL PERFORMANCE BY SERVICE LEVEL
# ========================================================================================================

# Compare cost and delivery performance across service levels.

service_level_performance <- shipments_eda %>%
  group_by(service_level) %>%
  summarise(
    shipments = n(),
    median_cost_eur = round(
      median(total_logistics_cost_eur),
      2
    ),
    median_delay_hours = round(
      median(delay_hours),
      2
    ),
    on_time_rate_pct = round(
      mean(on_time_flag) * 100,
      2
    ),
    damage_rate_pct = round(
      mean(damage_flag) * 100,
      2
    ),
    .groups = "drop"
  ) %>%
  arrange(
    desc(on_time_rate_pct)
  )

service_level_performance



# ========================================================================================================
# 29. SHIPMENT MAIN DELAY REASON ANALYSIS
# ========================================================================================================

# Check how the main delay reason is recorded for on-time and late shipments.

shipment_delay_reason_check <- shipments_eda %>%
  summarise(
    late_shipments = sum(
      !on_time_flag
    ),
    late_shipments_with_reason = sum(
      !on_time_flag &
        main_delay_reason != "None"
    ),
    late_shipments_without_reason = sum(
      !on_time_flag &
        main_delay_reason == "None"
    ),
    on_time_shipments_with_reason = sum(
      on_time_flag &
        main_delay_reason != "None"
    )
  )

shipment_delay_reason_check


# Compare shipment frequency and delivery performance according to the main recorded delay reason.

shipment_delay_reason_performance <- shipments_eda %>%
  mutate(
    main_delay_reason = if_else(
      main_delay_reason == "None",
      "Not recorded",
      main_delay_reason
    )
  ) %>%
  group_by(main_delay_reason) %>%
  summarise(
    shipments = n(),
    late_shipments = sum(
      !on_time_flag
    ),
    late_shipment_rate_pct = round(
      mean(!on_time_flag) * 100,
      2
    ),
    median_delay_hours = round(
      median(delay_hours),
      2
    ),
    total_delay_hours = round(
      sum(delay_hours),
      2
    ),
    .groups = "drop"
  ) %>%
  arrange(
    desc(total_delay_hours)
  )

shipment_delay_reason_performance