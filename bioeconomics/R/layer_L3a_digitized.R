# L3a — digitized value/price anchors.
# Provenance: see data-raw/digitized/SOURCES.md.
# Caveats: 1975 and 2015 SOK $/lb are nominal midpoints of Rebuilding-Plan
# real-2020$ bands ($16-31/lb 1970s; $11-14/lb recent). Other figures are
# source-stated or chart-read (IFMP Fig. 9, ±10%).
build_L3a <- function() {
  readr::read_csv(here::here("data-raw","digitized","L3_digitized_value.csv"),
                  show_col_types = FALSE) |>
    janitor::clean_names() |>
    dplyr::mutate(year = as.integer(year), value = as.double(value))
}
