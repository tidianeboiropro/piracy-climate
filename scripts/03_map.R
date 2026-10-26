# 03_map.R — Quick map of ASAM incidents and study zones
library(DBI)
library(duckdb)
library(ggplot2)

# Read-only connection, closed right after the query: avoids lock problems
con <- dbConnect(duckdb(), dbdir = "piracy.duckdb", read_only = TRUE)
pts <- dbGetQuery(con, "
  SELECT lon, lat, COALESCE(zone, 'Outside zones') AS zone
  FROM asam_zones
  WHERE date >= DATE '2000-01-01';
")
dbDisconnect(con, shutdown = TRUE)

# Study zone boxes, same bounds as in 02_diagnostic.R
boxes <- data.frame(
  zone = c("Aden_Somalia", "Guinea", "Malacca", "South_China_Sea"),
  xmin = c(40, -20, 95, 105), xmax = c(65, 15, 105, 125),
  ymin = c(-5, -10, -2, 0),   ymax = c(20, 10, 8, 25)
)

p <- ggplot() +
  borders("world", fill = "grey92", colour = "grey75") +
  geom_point(data = pts, aes(lon, lat, colour = zone), size = 0.4, alpha = 0.6) +
  geom_rect(data = boxes, aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
            fill = NA, colour = "black", linewidth = 0.4) +
  coord_quickmap(xlim = c(-30, 130), ylim = c(-15, 35)) +
  labs(title = "ASAM incidents since 2000 and study zones",
       caption = "Source: NGA ASAM (archive frozen July 2024)", colour = NULL) +
  theme_minimal()

ggsave("figures/map_raw.png", p, width = 12, height = 5, dpi = 150)