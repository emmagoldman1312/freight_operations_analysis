# Freight Operations Control Tower Dataset

This package contains a synthetic but coherent logistics dataset designed for a
creative dashboard project in Excel, Python/R, Power BI/Tableau and QGIS.

Scenario: industrial EPC cargo movements across Iberia, North Africa, Northern
Europe, the Mediterranean and the Arabian Gulf. The model includes project
shipments, route legs, ports, facilities, carriers, vessels, incidents, fuel
prices and port congestion.

## What you can analyze

- Executive logistics performance: shipments, tons, cost, delay, risk and CO2.
- Route profitability and cost per ton-km.
- On-time delivery by carrier, project, cargo family, lane and mode.
- Port congestion and its relationship with shipment delay.
- Heavy lift and oversize cargo planning complexity.
- Safety, claims and preventable incidents.
- QGIS route maps using point and WKT line layers.

## Recommended dashboard pages

1. Executive Overview
2. Network Map
3. Route and Mode Performance
4. Carrier Scorecard
5. Port Congestion and Delays
6. Heavy Lift / Oversize Cargo
7. Incidents, Claims and Risk
8. Sustainability and Fuel Exposure

## Files and row counts

- dim_calendar.csv: 731 rows
- dim_ports.csv: 18 rows
- dim_facilities.csv: 18 rows
- dim_projects.csv: 7 rows
- dim_carriers.csv: 12 rows
- dim_vessels.csv: 14 rows
- dim_cargo_types.csv: 10 rows
- fact_shipments.csv: 900 rows
- fact_route_legs.csv: 2436 rows
- fact_events.csv: 5772 rows
- fact_incidents.csv: 55 rows
- fact_port_congestion.csv: 432 rows
- fact_fuel_prices.csv: 24 rows
- qgis_nodes.csv: 36 rows
- qgis_route_legs_wkt.csv: 2436 rows
- data_dictionary.csv: 15 rows
- kpi_guide.csv: 10 rows
- dataset_quality_report.csv: 15 rows

## Suggested first workflow

1. Start in Excel or Power Query: inspect columns, missing values and types.
2. Use Python/R for validation, joins and exploratory charts.
3. Build the data model in Power BI or Tableau.
4. Add QGIS as a special map module using qgis_nodes.csv and qgis_route_legs_wkt.csv.

## Data status

The dataset is synthetic. Coordinates are approximate and only included to make
the scenario map-friendly. The data is designed to be realistic enough for
practice, not to represent actual operational performance.
