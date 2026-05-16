# ============================================================================
# 07bm_doherty_public_extract_qc.R
# Source/provenance QC for public DFO extracts used in the Doherty-style HG
# replication workflow.
#
# This is not model fitting. It checks that extracted public tables have source
# fields, expected row counts/ranges, and the correct model-use status before
# they are used in talks or future data requests.
# ============================================================================

library(tidyverse)
library(here)
library(knitr)

proj_dir <- here::here()
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
extract_dir <- file.path(diag_dir, "dfo_hg_public_extract")
newer_extract_dir <- file.path(diag_dir, "dfo_newer_public_pdf_extract")

source_fields <- c(
  "source_document",
  "source_table",
  "source_url",
  "extraction_method",
  "extraction_notes"
)

read_csv_if_exists <- function(path) {
  if (!file.exists(path) || file.info(path)$size == 0) {
    return(tibble())
  }
  readr::read_csv(path, show_col_types = FALSE)
}

rel_path <- function(path) {
  sub(
    paste0("^", normalizePath(proj_dir, mustWork = TRUE), "/?"),
    "",
    normalizePath(path, mustWork = FALSE)
  )
}

field_status <- function(dat) {
  present <- intersect(source_fields, names(dat))
  missing <- setdiff(source_fields, names(dat))
  rows_complete <- if (length(missing) > 0 || nrow(dat) == 0) {
    FALSE
  } else {
    all(map_lgl(source_fields, ~ all(!is.na(dat[[.x]]) & dat[[.x]] != "")))
  }
  tibble(
    source_fields_present = paste(present, collapse = "; "),
    source_fields_missing = paste(missing, collapse = "; "),
    source_field_pass = length(missing) == 0,
    source_rows_complete = rows_complete
  )
}

year_min <- function(dat) if ("year" %in% names(dat) && nrow(dat) > 0) min(dat$year, na.rm = TRUE) else NA_real_
year_max <- function(dat) if ("year" %in% names(dat) && nrow(dat) > 0) max(dat$year, na.rm = TRUE) else NA_real_

table_specs <- tribble(
  ~product, ~path, ~expected_rows, ~expected_min_year, ~expected_max_year, ~model_use_status,
  "csas_2018_hg_catch_wide",
  file.path(extract_dir, "dfo_hg_appendix_b1_catch_wide.csv"),
  67L, 1951, 2017, "schema_audit_only",
  "csas_2018_hg_spawn",
  file.path(extract_dir, "dfo_hg_appendix_b8_spawn.csv"),
  67L, 1951, 2017, "schema_audit_only",
  "csas_2018_hg_number_at_age_long",
  file.path(extract_dir, "dfo_hg_appendix_b15_number_at_age_long.csv"),
  648L, 1951, 2017, "schema_audit_only",
  "csas_2018_hg_weight_at_age_long",
  file.path(extract_dir, "dfo_hg_appendix_b22_weight_at_age_long.csv"),
  603L, 1951, 2017, "schema_audit_only",
  "csas_2018_hg_biosamples",
  file.path(extract_dir, "dfo_hg_appendix_b29_biosamples_hg.csv"),
  63L, 1951, 2017, "schema_audit_only",
  "csas_2018_maturity_schedule",
  file.path(extract_dir, "dfo_hg_maturity_schedule.csv"),
  9L, NA, NA, "schema_audit_only",
  "dfo_2025_005_input_windows",
  file.path(newer_extract_dir, "dfo_sr_2025_005_table_1_input_data_windows.csv"),
  12L, NA, NA, "reporting_request_scoping_only",
  "dfo_2025_005_major_sar_catch",
  file.path(newer_extract_dir, "dfo_sr_2025_005_table_2_major_catch_2015_2024.csv"),
  10L, 2015, 2024, "reporting_request_scoping_only",
  "dfo_2025_005_hg_spawn",
  file.path(newer_extract_dir, "dfo_sr_2025_005_table_3_hg_spawn_2015_2024.csv"),
  10L, 2015, 2024, "reporting_request_scoping_only",
  "dfo_2025_005_hg_parameters",
  file.path(newer_extract_dir, "dfo_sr_2025_005_table_7_hg_key_parameters.csv"),
  11L, NA, NA, "reporting_request_scoping_only",
  "dfo_2025_005_hg_recruitment",
  file.path(newer_extract_dir, "dfo_sr_2025_005_table_11_hg_recruitment_2015_2024.csv"),
  10L, 2015, 2024, "reporting_request_scoping_only",
  "dfo_2025_005_hg_biomass_depletion",
  file.path(newer_extract_dir, "dfo_sr_2025_005_table_15_hg_spawning_biomass_depletion_2015_2024.csv"),
  10L, 2015, 2024, "external_comparison_only",
  "dfo_2025_005_hg_reference_points",
  file.path(newer_extract_dir, "dfo_sr_2025_005_table_19_hg_reference_points.csv"),
  13L, NA, NA, "external_comparison_only",
  "ifmp_2024_2025_projected_biomass_age_props",
  file.path(newer_extract_dir, "dfo_ifmp_2024_2025_table_3_1_projected_biomass_age_props.csv"),
  4L, NA, NA, "reporting_request_scoping_only",
  "hg_rebuilding_plan_biology_captions",
  file.path(newer_extract_dir, "dfo_hg_rebuilding_plan_biology_caption_catalog.csv"),
  92L, NA, NA, "caption_provenance_only"
)

qc <- table_specs %>%
  mutate(dat = map(path, read_csv_if_exists)) %>%
  mutate(
    exists = map_lgl(path, file.exists),
    rows = map_int(dat, nrow),
    cols = map_int(dat, ncol),
    min_year = map_dbl(dat, year_min),
    max_year = map_dbl(dat, year_max),
    row_count_pass = rows == expected_rows,
    year_range_pass = case_when(
      is.na(expected_min_year) & is.na(expected_max_year) ~ TRUE,
      TRUE ~ min_year == expected_min_year & max_year == expected_max_year
    ),
    field_info = map(dat, field_status)
  ) %>%
  unnest(field_info) %>%
  mutate(
    path = map_chr(path, rel_path),
    overall_pass = exists & row_count_pass & year_range_pass &
      source_field_pass & source_rows_complete,
    qc_status = case_when(
      overall_pass ~ "pass",
      !exists ~ "missing_file",
      !row_count_pass ~ "row_count_mismatch",
      !year_range_pass ~ "year_range_mismatch",
      !source_field_pass ~ "missing_source_fields",
      !source_rows_complete ~ "incomplete_source_fields",
      TRUE ~ "review"
    ),
    notes = case_when(
      model_use_status == "schema_audit_only" ~
        "Public extraction passes structural QC but remains provisional; use for schema/source spot checks, not model fitting.",
      model_use_status == "external_comparison_only" ~
        "Public DFO assessment output; use as external comparison, not as raw model input.",
      model_use_status == "caption_provenance_only" ~
        "Caption/catalog extract; records biological-data provenance but is not a numeric input table.",
      TRUE ~
        "Public summary extract; use for reporting and request scoping only."
    )
  ) %>%
  select(
    product, path, exists, rows, expected_rows, row_count_pass,
    min_year, max_year, expected_min_year, expected_max_year, year_range_pass,
    source_field_pass, source_rows_complete, qc_status, model_use_status,
    source_fields_present, source_fields_missing, notes
  )

write_csv(qc, file.path(diag_dir, "doherty_public_extract_qc.csv"))

status_counts <- qc %>%
  count(qc_status, model_use_status, name = "n") %>%
  arrange(qc_status, model_use_status)

lines <- c(
  "# Doherty-Style Public Extract QC",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "This diagnostic checks public DFO table extracts used by the Doherty-style HG workflow. It does not promote any extracted table to model input status.",
  "",
  "## QC Rule",
  "",
  "A table passes this structural QC only if it exists, has the expected row count, has the expected year range when applicable, and has complete source fields: `source_document`, `source_table`, `source_url`, `extraction_method`, and `extraction_notes`.",
  "",
  "## Status Counts",
  "",
  knitr::kable(status_counts, format = "pipe"),
  "",
  "## Table QC",
  "",
  knitr::kable(qc, format = "pipe"),
  "",
  "## Interpretation",
  "",
  "- The CSAS 2018/028 Appendix B extracts remain provisional public data products for schema and source-PDF spot checks.",
  "- The DFO 2025/005 and IFMP extracts are public summaries for reporting and DFO request scoping, not raw SCA/SISCAH input files.",
  "- Passing this QC means the extracted table is traceable and structurally consistent; it does not mean the table is ready for catch-at-age model fitting.",
  "",
  "## Outputs",
  "",
  "- `Output/diagnostics/doherty_public_extract_qc.csv`",
  "- `Output/diagnostics/doherty_public_extract_qc.md`"
)

writeLines(lines, file.path(diag_dir, "doherty_public_extract_qc.md"))

cat("Saved Doherty public extract QC:\n")
cat("  Output/diagnostics/doherty_public_extract_qc.md\n")
cat("  Output/diagnostics/doherty_public_extract_qc.csv\n")
