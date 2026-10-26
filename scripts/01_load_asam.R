# 01_load_asam.R — Load NGA ASAM shapefile into DuckDB
library(DBI)
library(duckdb)

# Open (or create) the database file at the project root
con <- dbConnect(duckdb(), dbdir = "piracy.duckdb")

# Spatial extension: lets DuckDB read shapefiles directly
dbExecute(con, "INSTALL spatial;")
dbExecute(con, "LOAD spatial;")

# Load the raw shapefile as a table
dbExecute(con, "
  CREATE OR REPLACE TABLE asam_raw AS
  SELECT * FROM ST_Read('data/raw/asam/Asam_data_download/All ASAM Events.shp');
")

# First checks
dbGetQuery(con, "DESCRIBE asam_raw;")
dbGetQuery(con, "SELECT COUNT(*) AS n FROM asam_raw;")

dbDisconnect(con, shutdown = TRUE)
