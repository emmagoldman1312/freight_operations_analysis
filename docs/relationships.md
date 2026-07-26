# Suggested Data Model

Synthetic dataset for a Freight Operations Control Tower project.

## Fact tables

- fact_shipments.csv: central table, one row per shipment.
- fact_route_legs.csv: one-to-many detail table from shipments to route legs.
- fact_events.csv: one-to-many milestone table from shipments to operational events.
- fact_incidents.csv: optional one-to-many incident table from shipments to incidents.
- fact_port_congestion.csv: monthly port indicators.
- fact_fuel_prices.csv: monthly fuel indicators.

## Dimensions

- dim_calendar.csv joins to fact_shipments by planned_pickup_datetime/date or actual_delivery_datetime/date.
- dim_projects.csv joins fact_shipments[project_id].
- dim_facilities.csv joins fact_shipments[origin_facility_id] and fact_shipments[destination_facility_id].
- dim_ports.csv joins fact_shipments[origin_port_id], fact_shipments[destination_port_id] and fact_port_congestion[port_id].
- dim_carriers.csv joins fact_shipments[carrier_id] and fact_route_legs[carrier_id].
- dim_vessels.csv joins fact_shipments[vessel_id] and fact_route_legs[vessel_id].
- dim_cargo_types.csv joins fact_shipments[cargo_type_id].

## QGIS

- Import qgis_nodes.csv as a point layer using longitude/latitude.
- Import qgis_route_legs_wkt.csv as a delimited text layer using wkt_linestring as WKT geometry.
- Use EPSG:4326 for both layers.

## Important note

This is synthetic data for learning and portfolio practice. Do not present it as
real company, customer, carrier or port performance data.
