# L2 harvest. AUTHORITATIVE SOURCES (read-only snapshots from the metapopulation repo):
#  - catch_total_t, catch_sok_t  <- herring_catch_local_1950_2024.csv
#       catch_sok_t is the `sok` column = SOK PRODUCT tonnes (scale ~100-360 t,
#       consistent with Powell 2012's documented SOK product series 111-256 t).
#  - catch_roe_t                 <- Haida_Gwaii_roe_catch.csv (latin1, bilingual headers)
#
# NOT USED in backbone v1 (copied as a candidate only):
#  - harvest-sok-hg.csv `Harvest` (~85,214 t at 1989) is IMPOUNDED ponding herring
#    BIOMASS, a different quantity from SOK product. The schema has no impound-biomass
#    column; a dedicated series is deferred to a future schema revision. catch_sok_t
#    must NOT be sourced from this file. (Flag for Task 11 QA / DATA_DICTIONARY.)
#
# DATA CAVEATS (surface in the Task 11 QA report / DATA_DICTIONARY):
#  - 1956 HG total: DFO section database sums to ~83,653 t; Hourston (1980) reports
#    77,500 t for the QCI/HG stock (~8% gap, statistical-area/tally-methodology).
#    DFO data is authoritative; Hourston is a historical cross-reference.
#  - Roe file WP cells: some roe rows hold the string "WP" (work-in-progress /
#    withheld) — coerced to NA and excluded from sums. The source's own comment
#    column documents a WP sum ~430.38 t for the 1972-1978 seasons; 1985-1993 WP
#    rows are unquantified -> a known minor under-count of catch_roe_t.
build_L2 <- function() {
  if (!exists("REGIONS")) stop("REGIONS not found - source R/schema.R before calling build_L2()")

  local_catch <- readr::read_csv(
    here::here("data-raw","harvest","herring_catch_local_1950_2024.csv"),
    show_col_types = FALSE) |>
    janitor::clean_names() |>
    dplyr::group_by(year) |>
    dplyr::summarise(catch_total_t = sum(total_catch, na.rm = TRUE),
                     catch_sok_t = sum(sok, na.rm = TRUE), .groups = "drop") |>
    dplyr::mutate(region = factor("HG", levels = REGIONS))

  roe <- readr::read_csv(
    here::here("data-raw","harvest","Haida_Gwaii_roe_catch.csv"),
    show_col_types = FALSE, locale = readr::locale(encoding = "latin1"),
    name_repair = "minimal") |>
    janitor::clean_names()
  qty_col <- names(roe)[grepl("catch.*metric|metric.*tonnes|prises", names(roe))][1]
  yr_col  <- names(roe)[grepl("^(year|ann)", names(roe))][1]

  if (is.na(qty_col) || is.na(yr_col)) {
    stop(paste0(
      "NEEDS_CONTEXT: roe CSV column detection failed.\n",
      "qty_col=", qty_col, "  yr_col=", yr_col, "\n",
      "Available column names: ", paste(names(roe), collapse = ", ")
    ))
  }

  # Non-numeric roe cells (e.g. "WP") -> NA via as.double, then excluded by na.rm; see header WP caveat.
  roe_y <- roe |>
    dplyr::transmute(year = suppressWarnings(as.integer(.data[[yr_col]])),
                     v = suppressWarnings(as.double(.data[[qty_col]]))) |>
    dplyr::filter(!is.na(year)) |>
    dplyr::group_by(year) |>
    dplyr::summarise(catch_roe_t = sum(v, na.rm = TRUE), .groups = "drop") |>
    dplyr::mutate(region = factor("HG", levels = REGIONS))

  dplyr::full_join(local_catch, roe_y, by = c("region","year")) |>
    dplyr::mutate(year = as.integer(year),
                  dplyr::across(c(catch_total_t, catch_roe_t, catch_sok_t),
                                \(x) tidyr::replace_na(x, 0)))
}
