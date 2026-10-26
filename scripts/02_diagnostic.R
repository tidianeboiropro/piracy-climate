# 02_diagnostic.R — Feasibility diagnostic on ASAM
library(DBI)
library(duckdb)

con <- dbConnect(duckdb(), dbdir = "piracy.duckdb")
dbExecute(con, "LOAD spatial;")

# Clean table: keep useful columns, readable names, explicit lat/lon
dbExecute(con, "
  CREATE OR REPLACE TABLE asam AS
  SELECT
    reference,
    dateofocc   AS date,
    entrydate   AS entry_date,
    subreg,
    hostility_  AS hostility,
    victim_d    AS victim,
    descriptio  AS description,
    ST_Y(geom)  AS lat,
    ST_X(geom)  AS lon
  FROM asam_raw;
")

# 1. Time coverage: the decisive question tonight
dbGetQuery(con, "
  SELECT MIN(date) AS first_incident, MAX(date) AS last_incident,
         MAX(entry_date) AS last_entry
  FROM asam;
")

# 2. Sanity check on coordinates
dbGetQuery(con, "
  SELECT MIN(lat), MAX(lat), MIN(lon), MAX(lon),
         SUM(CASE WHEN lat IS NULL OR (lat = 0 AND lon = 0) THEN 1 ELSE 0 END) AS no_coords
  FROM asam;
")

# 3. Incidents per year
dbGetQuery(con, "
  SELECT year(date) AS year, COUNT(*) AS n
  FROM asam
  GROUP BY year(date)
  ORDER BY year;
")

# 4. Assign incidents to study zones (half-open bounds avoid double counting at 105°E)
dbExecute(con, "
  CREATE OR REPLACE TABLE asam_zones AS
  SELECT *,
    CASE
      WHEN lat >= -5  AND lat < 20 AND lon >= 40  AND lon < 65  THEN 'Aden_Somalia'
      WHEN lat >= -10 AND lat < 10 AND lon >= -20 AND lon < 15  THEN 'Guinea'
      WHEN lat >= -2  AND lat < 8  AND lon >= 95  AND lon < 105 THEN 'Malacca'
      WHEN lat >= 0   AND lat < 25 AND lon >= 105 AND lon < 125 THEN 'South_China_Sea'
    END AS zone
  FROM asam;
")

# 5. Incidents per zone since 2000 (criterion: >= 300 in total)
dbGetQuery(con, "
  SELECT zone, COUNT(*) AS n
  FROM asam_zones
  WHERE date >= DATE '2000-01-01' AND zone IS NOT NULL
  GROUP BY ROLLUP(zone)
  ORDER BY n DESC;
")

# 6. Hostility types in the Aden zone since 2022 (Houthi contamination check)
dbGetQuery(con, "
  SELECT year(date) AS year, hostility, COUNT(*) AS n
  FROM asam_zones
  WHERE zone = 'Aden_Somalia' AND date >= DATE '2022-01-01'
  GROUP BY ALL
  ORDER BY year, n DESC;
")

dbDisconnect(con, shutdown = TRUE)
