# ============================================================================
# 02e_extract_dfo_hg_assessment_tables.R
# Extract public Haida Gwaii herring assessment input tables from DFO CSAS
# Research Document 2018/028 Appendix B.
#
# This creates provisional public-extracted tables for the Doherty-style HG
# replication workflow. These are not final SCA/SISCAH input files; they need
# provenance review before model fitting.
# ============================================================================

library(tidyverse)
library(here)
library(knitr)

proj_dir <- here::here()
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
source_dir <- file.path(diag_dir, "dfo_assessment_public_sources")
extract_dir <- file.path(diag_dir, "dfo_hg_public_extract")
dir.create(extract_dir, showWarnings = FALSE, recursive = TRUE)

source_pdf <- file.path(source_dir, "dfo_herring_scad_2018_028.pdf")
layout_txt <- file.path(source_dir, "dfo_herring_scad_2018_028_layout.txt")

if (!file.exists(source_pdf)) {
  stop(
    "Missing DFO CSAS source PDF. Run Code/02d_fetch_dfo_herring_assessment_sources.R first."
  )
}

pdftotext <- Sys.which("pdftotext")
if (!nzchar(pdftotext)) {
  stop("pdftotext is required for layout-preserving extraction.")
}

invisible(system2(pdftotext, c("-layout", source_pdf, layout_txt), stdout = TRUE, stderr = TRUE))
layout_lines <- readLines(layout_txt, warn = FALSE)

source_url <- "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/40944670.pdf"

extract_block <- function(lines, start_pattern, end_pattern) {
  start <- str_which(lines, start_pattern)[1]
  end <- str_which(lines, end_pattern)
  end <- end[end > start][1]
  if (is.na(start) || is.na(end) || end <= start) {
    stop("Could not locate table block: ", start_pattern, " to ", end_pattern)
  }
  lines[start:(end - 1)]
}

parse_rows <- function(block, pattern, columns) {
  matches <- stringr::str_match(block, pattern)
  keep <- !is.na(matches[, 1])
  if (!any(keep)) {
    return(tibble())
  }
  as_tibble(matches[keep, -1, drop = FALSE], .name_repair = ~ columns)
}

num <- function(x) {
  readr::parse_number(if_else(x == "NA", NA_character_, x))
}

add_source <- function(dat, source_table, notes) {
  dat %>%
    mutate(
      source_document = "DFO CSAS Research Document 2018/028",
      source_table = source_table,
      source_url = source_url,
      extraction_method = "pdftotext -layout row-regex extraction",
      extraction_notes = notes
    )
}

float <- "(NA|[0-9]+(?:\\.[0-9]+)?)"
integer <- "([0-9]+)"

# Table B.1: HG catch by gear, in kt.
catch_block <- extract_block(layout_lines, "Table B\\.1\\.", "Table B\\.2\\.")
catch_wide <- parse_rows(
  catch_block,
  paste0("^\\s*(\\d{4})\\s+", float, "\\s+", float, "\\s+", float, "\\s*$"),
  c("year", "gear1_kt", "gear2_kt", "gear3_kt")
) %>%
  mutate(
    year = as.integer(year),
    across(ends_with("_kt"), num),
    total_catch_kt = gear1_kt + gear2_kt + gear3_kt,
    total_catch_tonnes = total_catch_kt * 1000
  ) %>%
  add_source(
    "Appendix B Table B.1",
    "HG catch in thousands of metric tonnes by period/gear; Gear1 reduction/food-bait/special-use, Gear2 roe seine, Gear3 roe gillnet."
  )

catch_long <- catch_wide %>%
  select(year, gear1_kt, gear2_kt, gear3_kt, source_document:extraction_notes) %>%
  pivot_longer(
    cols = starts_with("gear"),
    names_to = "fleet",
    values_to = "catch_kt"
  ) %>%
  mutate(
    fleet = recode(
      fleet,
      gear1_kt = "Gear1_reduction_food_bait_special_use",
      gear2_kt = "Gear2_roe_seine",
      gear3_kt = "Gear3_roe_gillnet"
    ),
    catch_tonnes = catch_kt * 1000,
    sar = "HG"
  ) %>%
  select(year, sar, fleet, catch_kt, catch_tonnes, everything())

# Table B.8: HG spawn index, in kt.
spawn_block <- extract_block(layout_lines, "Table B\\.8\\.", "Table B\\.9\\.")
spawn <- parse_rows(
  spawn_block,
  paste0("^\\s*(\\d{4})\\s+", float, "\\s+(Surface|Dive)\\s*$"),
  c("year", "spawn_index_kt", "survey_method")
) %>%
  mutate(
    year = as.integer(year),
    spawn_index_kt = num(spawn_index_kt),
    spawn_index_tonnes = spawn_index_kt * 1000,
    sar = "HG"
  ) %>%
  add_source(
    "Appendix B Table B.8",
    "HG raw spawn index in thousands of metric tonnes; not scaled by q."
  ) %>%
  select(year, sar, survey_method, spawn_index_kt, spawn_index_tonnes, everything())

# Table B.15: HG number-at-age by gear/source.
age_capture_groups <- paste(rep(integer, 9), collapse = "\\s+")
naa_block <- extract_block(layout_lines, "Table B\\.15\\.", "Table B\\.16\\.")
naa_wide <- parse_rows(
  naa_block,
  paste0("^\\s*(\\d{4})\\s+(\\d+)\\s+", age_capture_groups, "\\s*$"),
  c("year", "gear", paste0("age_", 2:10))
) %>%
  mutate(
    year = as.integer(year),
    gear = as.integer(gear),
    across(starts_with("age_"), as.integer),
    total_n_at_age = rowSums(across(starts_with("age_")), na.rm = TRUE),
    sar = "HG",
    fleet = recode(
      as.character(gear),
      `1` = "Gear1_reduction_food_bait_special_use",
      `2` = "Gear2_roe_seine",
      `3` = "Gear3_roe_gillnet"
    )
  ) %>%
  add_source(
    "Appendix B Table B.15",
    "HG number-at-age; age 10 is a plus group."
  ) %>%
  select(year, sar, gear, fleet, starts_with("age_"), total_n_at_age, everything())

naa_long <- naa_wide %>%
  select(year, sar, gear, fleet, starts_with("age_"), total_n_at_age, source_document:extraction_notes) %>%
  pivot_longer(
    cols = starts_with("age_"),
    names_to = "age",
    values_to = "n_at_age"
  ) %>%
  mutate(
    age = as.integer(str_remove(age, "^age_")),
    prop_at_age_within_row = if_else(total_n_at_age > 0, n_at_age / total_n_at_age, NA_real_)
  ) %>%
  select(year, sar, gear, fleet, age, n_at_age, prop_at_age_within_row, total_n_at_age, everything())

# Table B.22: HG weight-at-age by year, in kg.
weight_capture_groups <- paste(rep(float, 9), collapse = "\\s+")
waa_block <- extract_block(layout_lines, "Table B\\.22\\.", "Table B\\.23\\.")
waa_wide <- parse_rows(
  waa_block,
  paste0("^\\s*(\\d{4})\\s+", weight_capture_groups, "\\s*$"),
  c("year", paste0("age_", 2:10, "_kg"))
) %>%
  mutate(
    year = as.integer(year),
    across(ends_with("_kg"), num),
    sar = "HG"
  ) %>%
  add_source(
    "Appendix B Table B.22",
    "HG mean weight-at-age in kilograms; seine samples only; age 10 is a plus group."
  ) %>%
  select(year, sar, starts_with("age_"), everything())

waa_long <- waa_wide %>%
  select(year, sar, starts_with("age_"), source_document:extraction_notes) %>%
  pivot_longer(
    cols = starts_with("age_"),
    names_to = "age",
    values_to = "mean_weight_kg"
  ) %>%
  mutate(
    age = as.integer(str_match(age, "^age_([0-9]+)_kg$")[, 2]),
    mean_weight_g = mean_weight_kg * 1000
  ) %>%
  select(year, sar, age, mean_weight_kg, mean_weight_g, everything())

# Table B.29: biosamples by SAR; retain all SAR columns plus HG.
biosamples_block <- extract_block(layout_lines, "Table B\\.29\\.", "APPENDIX C\\.")
biosamples <- parse_rows(
  biosamples_block,
  paste0("^\\s*(\\d{4})\\s+", paste(rep(integer, 7), collapse = "\\s+"), "\\s*$"),
  c("year", "A27", "A2W", "CC", "HG", "PRD", "SoG", "WCVI")
) %>%
  mutate(
    year = as.integer(year),
    across(A27:WCVI, as.integer)
  ) %>%
  add_source(
    "Appendix B Table B.29",
    "Number of biological samples by SAR; each sample is approximately 100 fish."
  )

biosamples_hg <- biosamples %>%
  transmute(
    year,
    sar = "HG",
    n_biosamples = HG,
    approx_fish_sampled = HG * 100,
    source_document,
    source_table,
    source_url,
    extraction_method,
    extraction_notes
  )

# Section 2.1.4 fixed maturity schedule, encoded for ages in Appendix B.
maturity <- tibble(age = 2:10) %>%
  mutate(
    proportion_mature = case_when(
      age == 2 ~ 0.25,
      age == 3 ~ 0.90,
      age >= 4 ~ 1.00,
      TRUE ~ NA_real_
    ),
    sar = "all_major_stocks",
    source_document = "DFO CSAS Research Document 2018/028",
    source_table = "Section 2.1.4 Assumed biological parameters",
    source_url = source_url,
    extraction_method = "manual encoding from published text",
    extraction_notes = "Fixed maturity schedule used for all herring stocks: 25% age 2, 90% age 3, 100% ages 4+."
  ) %>%
  select(age, sar, proportion_mature, everything())

write_csv(catch_wide, file.path(extract_dir, "dfo_hg_appendix_b1_catch_wide.csv"))
write_csv(catch_long, file.path(extract_dir, "dfo_hg_appendix_b1_catch_long.csv"))
write_csv(spawn, file.path(extract_dir, "dfo_hg_appendix_b8_spawn.csv"))
write_csv(naa_wide, file.path(extract_dir, "dfo_hg_appendix_b15_number_at_age_wide.csv"))
write_csv(naa_long, file.path(extract_dir, "dfo_hg_appendix_b15_number_at_age_long.csv"))
write_csv(waa_wide, file.path(extract_dir, "dfo_hg_appendix_b22_weight_at_age_wide.csv"))
write_csv(waa_long, file.path(extract_dir, "dfo_hg_appendix_b22_weight_at_age_long.csv"))
write_csv(biosamples, file.path(extract_dir, "dfo_hg_appendix_b29_biosamples_all_sar.csv"))
write_csv(biosamples_hg, file.path(extract_dir, "dfo_hg_appendix_b29_biosamples_hg.csv"))
write_csv(maturity, file.path(extract_dir, "dfo_hg_maturity_schedule.csv"))

audit <- tribble(
  ~product, ~source_table, ~expected_rows, ~extracted_rows, ~status, ~notes,
  "herring_fleet_catch", "Appendix B Table B.1", 67L, nrow(catch_wide), "extracted_public_provisional",
  "HG catch by Gear1/Gear2/Gear3, 1951-2017, kt and tonnes.",
  "herring_spawn_index", "Appendix B Table B.8", 67L, nrow(spawn), "extracted_public_provisional",
  "HG aggregate spawn index, 1951-2017, surface/dive method retained.",
  "herring_age_composition", "Appendix B Table B.15", 72L, nrow(naa_wide), "extracted_public_provisional",
  "Number-at-age rows by gear/source; age 10 is plus group. Long table has one row per age.",
  "herring_weight_at_age", "Appendix B Table B.22", 67L, nrow(waa_wide), "extracted_public_provisional",
  "Mean weight-at-age from seine biological samples, 1951-2017, kg and grams.",
  "herring_biosample_counts", "Appendix B Table B.29", 63L, nrow(biosamples_hg), "extracted_public_provisional",
  "HG biosample counts by year; each sample approximately 100 fish.",
  "herring_maturity_at_age", "Section 2.1.4", 9L, nrow(maturity), "encoded_public_provisional",
  "Fixed maturity schedule for ages 2-10.",
  "herring_length_at_age", "Rebuilding plan figures / assessment text", NA_integer_, 0L, "not_found_as_table",
  "Length-at-age is discussed and plotted in public documents, but no machine-readable public Appendix table was found in this extraction pass.",
  "current_2018_2024_biology", "Current full IFMP / SCA-SISCAH input files", NA_integer_, 0L, "not_found_machine_readable",
  "Current IFMP confirms age/weight inputs, but direct command-line PDF download returns a landing page and exact 2018-2024 input tables are not local.",
  "effective_sample_sizes", "SCA/SISCAH model input metadata", NA_integer_, 0L, "not_found_machine_readable",
  "Number of biosamples is public; effective sample size/preprocessing metadata for age-composition likelihood are not present locally.",
  "predator_age_selectivity", "Doherty supplement / diet literature", NA_integer_, 0L, "not_found_machine_readable",
  "No HG predator age/size selectivity table found locally."
) %>%
  mutate(
    pass = case_when(
      is.na(expected_rows) ~ NA,
      expected_rows == extracted_rows ~ TRUE,
      TRUE ~ FALSE
    )
  )

write_csv(audit, file.path(extract_dir, "dfo_hg_public_extract_audit.csv"))

schema_gap_ledger <- audit %>%
  transmute(
    required_product = product,
    source_table,
    status,
    extracted_rows,
    model_gate = case_when(
      status %in% c("extracted_public_provisional", "encoded_public_provisional") ~
        "available_for_schema_audit_not_model_fit",
      TRUE ~ "blocks_doherty_style_model_fit"
    ),
    next_action = case_when(
      product == "herring_length_at_age" ~
        "Search public rebuilding-plan appendices/tables; otherwise keep as request item.",
      product == "current_2018_2024_biology" ~
        "Use Government Publications catalogue or manual download path; request exact SCA/SISCAH input files if public PDF tables are insufficient.",
      product == "effective_sample_sizes" ~
        "Request model input metadata or infer only after validating published age rows against assessment figures.",
      product == "predator_age_selectivity" ~
        "Extract Doherty predator selectivity assumptions and HG diet/life-stage studies into a sourced table.",
      TRUE ~
        "Review extracted table against source PDF and retain provenance before any modeling use."
    ),
    notes
  )

write_csv(schema_gap_ledger, file.path(extract_dir, "doherty_hg_schema_gap_ledger.csv"))

summary_lines <- c(
  "# DFO HG Public Assessment Table Extraction",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "This report records the public DFO Appendix B tables extracted for a Doherty-style Haida Gwaii herring/predator replication. These tables are provisional: they are good enough for schema and provenance review, not yet for a new catch-at-age model fit.",
  "",
  "## Extracted Products",
  "",
  knitr::kable(audit, format = "pipe"),
  "",
  "## Key Tables",
  "",
  paste0("- HG catch rows: `", nrow(catch_wide), "` wide rows, `", nrow(catch_long), "` long gear rows."),
  paste0("- HG spawn rows: `", nrow(spawn), "`."),
  paste0("- HG number-at-age rows: `", nrow(naa_wide), "` source-year rows, `", nrow(naa_long), "` long age rows."),
  paste0("- HG weight-at-age rows: `", nrow(waa_wide), "` year rows, `", nrow(waa_long), "` long age rows."),
  paste0("- HG biosample rows: `", nrow(biosamples_hg), "`."),
  paste0("- Maturity rows: `", nrow(maturity), "`."),
  "",
  "## Files",
  "",
  "- `Output/diagnostics/dfo_hg_public_extract/dfo_hg_appendix_b1_catch_wide.csv`",
  "- `Output/diagnostics/dfo_hg_public_extract/dfo_hg_appendix_b1_catch_long.csv`",
  "- `Output/diagnostics/dfo_hg_public_extract/dfo_hg_appendix_b8_spawn.csv`",
  "- `Output/diagnostics/dfo_hg_public_extract/dfo_hg_appendix_b15_number_at_age_wide.csv`",
  "- `Output/diagnostics/dfo_hg_public_extract/dfo_hg_appendix_b15_number_at_age_long.csv`",
  "- `Output/diagnostics/dfo_hg_public_extract/dfo_hg_appendix_b22_weight_at_age_wide.csv`",
  "- `Output/diagnostics/dfo_hg_public_extract/dfo_hg_appendix_b22_weight_at_age_long.csv`",
  "- `Output/diagnostics/dfo_hg_public_extract/dfo_hg_appendix_b29_biosamples_all_sar.csv`",
  "- `Output/diagnostics/dfo_hg_public_extract/dfo_hg_appendix_b29_biosamples_hg.csv`",
  "- `Output/diagnostics/dfo_hg_public_extract/dfo_hg_maturity_schedule.csv`",
  "- `Output/diagnostics/dfo_hg_public_extract/dfo_hg_public_extract_audit.csv`",
  "- `Output/diagnostics/dfo_hg_public_extract/doherty_hg_schema_gap_ledger.csv`"
)

writeLines(summary_lines, file.path(extract_dir, "dfo_hg_public_extract_summary.md"))

cat("Saved DFO HG public assessment table extraction outputs:\n")
cat("  Output/diagnostics/dfo_hg_public_extract/dfo_hg_public_extract_summary.md\n")
cat("  Output/diagnostics/dfo_hg_public_extract/doherty_hg_schema_gap_ledger.csv\n")
