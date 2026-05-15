# ============================================================================
# 07bl_doherty_replication_execution_status.R
# Summarize how far the repository can go toward a Doherty-style Haida Gwaii
# predator-removal replication using public/local data only.
# ============================================================================

library(tidyverse)
library(here)
library(knitr)

proj_dir <- here::here()
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
extract_dir <- file.path(diag_dir, "dfo_hg_public_extract")
dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)

read_csv_if_exists <- function(path) {
  if (!file.exists(path) || file.info(path)$size == 0) {
    return(tibble())
  }
  readr::read_csv(path, show_col_types = FALSE)
}

count_rows <- function(path) {
  dat <- read_csv_if_exists(path)
  if (nrow(dat) == 0 && !file.exists(path)) {
    return(NA_integer_)
  }
  nrow(dat)
}

extract_audit <- read_csv_if_exists(file.path(extract_dir, "dfo_hg_public_extract_audit.csv"))
gap_ledger <- read_csv_if_exists(file.path(extract_dir, "doherty_hg_schema_gap_ledger.csv"))

pred_species <- read_csv_if_exists(
  file.path(proj_dir, "Data", "processed", "predators", "hg_predator_consumption_by_species_recent.csv")
)
pred_group <- read_csv_if_exists(
  file.path(proj_dir, "Data", "processed", "predators", "hg_predator_consumption_by_group_year.csv")
)
pred_spatial <- read_csv_if_exists(
  file.path(proj_dir, "Data", "processed", "predators", "hg_spatial_predator_sites.csv")
)

rows <- list(
  catch = count_rows(file.path(extract_dir, "dfo_hg_appendix_b1_catch_wide.csv")),
  spawn = count_rows(file.path(extract_dir, "dfo_hg_appendix_b8_spawn.csv")),
  number_at_age = count_rows(file.path(extract_dir, "dfo_hg_appendix_b15_number_at_age_long.csv")),
  weight_at_age = count_rows(file.path(extract_dir, "dfo_hg_appendix_b22_weight_at_age_long.csv")),
  biosamples = count_rows(file.path(extract_dir, "dfo_hg_appendix_b29_biosamples_hg.csv")),
  maturity = count_rows(file.path(extract_dir, "dfo_hg_maturity_schedule.csv"))
)

execution_status <- tribble(
  ~step, ~doherty_component, ~status, ~evidence, ~remaining_gap, ~model_decision,
  1L, "Public DFO source acquisition", "completed_public_sources",
  "DFO CSAS 2018/028, 2024/2025 IFMP, and HG rebuilding-plan PDFs were fetched and text-extracted; 2025/2026 full IFMP direct download returns an archived landing page, with catalogue page recorded.",
  "Need manual/current full IFMP PDF or exact SCA/SISCAH input files for 2018-2024 update.",
  "No model change.",
  2L, "HG catch/spawn/age/weight table extraction", "completed_public_provisional",
  paste0(
    "Extracted Appendix B HG catch wide rows=", rows$catch,
    ", spawn rows=", rows$spawn,
    ", number-at-age long rows=", rows$number_at_age,
    ", weight-at-age long rows=", rows$weight_at_age,
    ", biosample rows=", rows$biosamples,
    ", maturity rows=", rows$maturity, "."
  ),
  "Tables need source-PDF spot checks and current-year extension before any age-structured fit.",
  "Available for schema audit only, not for fitting.",
  3L, "Catch-at-age input bundle", "partial_public_1951_2017",
  "Public HG catch, spawn, number-at-age, weight-at-age, biosamples, and maturity are now in provisional CSV form.",
  "Exact SCA/SISCAH input files, effective sample sizes, preprocessing rules, selectivity assumptions, and 2018-2024 biology are not local.",
  "Do not fit a catch-at-age model yet.",
  4L, "Predator annual demand/removals", "completed_context",
  paste0(
    "HG predator consumption exists by group/year rows=", nrow(pred_group),
    " and recent species rows=", nrow(pred_species), "."
  ),
  "Annual demand is available, but Doherty-style age-specific removals require predator age/size selectivity.",
  "Use as descriptive/removal-rate context; held Stan demand branch remains context.",
  5L, "Predator class crosswalk", "partial",
  "HG predator data products cover mammals, fish, salmon, and birds; Steller sea lion/harbour seal spatial sites exist.",
  "Doherty WCVI marine-mammal classes do not map one-to-one to HG fish/bird/salmon predator products; humpback section exposure and all age selectivities are missing.",
  "No richer predator Stan branch.",
  6L, "Doherty-style predation mortality model", "blocked",
  "Current repository can compute biomass-scale removal analogues but lacks age-selective predation mortality inputs.",
  "Need predator selectivity-at-age, exact herring catch-at-age inputs, and a deliberate regional model design.",
  "Blocked for fitting.",
  7L, "Future predator/herring projections", "blocked",
  "No vetted future predator scenario table is present in the herring repo.",
  "Need future predator abundance scenarios and a promoted/useful predation mortality model first.",
  "Do not launch projections."
)

predator_crosswalk <- tribble(
  ~hg_predator_class, ~doherty_analogue, ~local_data_status, ~consumption_status, ~spatial_exposure_status, ~age_selectivity_status, ~use_now,
  "Humpback whale", "Primary recovered cetacean predator in Doherty-style marine-mammal mortality",
  "HG photo-ID/derived consumption available; current demand product includes humpback.",
  "available_recent_and_historical_derived", "section_exposure_missing", "missing",
  "Descriptive annual demand only; do not use as section-level effect.",
  "Steller sea lion", "Pinniped predator class",
  "HG breeding/non-breeding count products and spatial sites available.",
  "available", "partial_hg_sites_available", "missing",
  "Candidate future exposure class after raw/fill flags and selectivity are resolved.",
  "Harbour seal", "Pinniped predator class",
  "HG haul-out counts and spatial sites available; recent consumption contribution is small in current HG product.",
  "available", "partial_hg_sites_available", "missing",
  "Candidate future exposure class after complex-year collapsing and selectivity are resolved.",
  "California sea lion", "Pinniped predator class",
  "Northern BC broad-superset count product; not a clean HG-only series.",
  "available_broad_allocated", "missing_hg_specific", "missing",
  "Context only until HG allocation is defensible.",
  "Fish predators combined", "Not central to Doherty marine-mammal paper, but important HG predator-demand layer",
  "HG/Hecate/West Coast HG trawl-derived predator biomass product and consumption estimates available.",
  "available", "coarse_regional_not_section", "missing",
  "Descriptive demand and future candidate regional covariate, not age-selective removals yet.",
  "Salmon predators", "Juvenile/life-stage predation context",
  "HG/BC salmon consumption product available in sibling predator repo.",
  "available", "coarse_regional_not_section", "missing",
  "Context only; not adult SSB predation mortality.",
  "Bird egg predators", "Egg predation / spawn-stage pressure, not Doherty adult natural mortality",
  "HG seabird colony and combined bird egg-predator consumption products available.",
  "available_descriptive", "coarse_or_location_specific", "not_applicable_to_adult_age_selectivity",
  "Use in timing/substrate/spawn-location interpretation, not adult catch-at-age removals."
)

model_gate <- gap_ledger %>%
  select(required_product, status, model_gate, next_action, notes) %>%
  bind_rows(
    tibble(
      required_product = c(
        "predator_class_crosswalk",
        "future_predator_scenarios",
        "regional_hg_catch_at_age_model_design"
      ),
      status = c("partial", "not_found", "not_started"),
      model_gate = c(
        "available_for_context_not_model_fit",
        "blocks_doherty_style_projection",
        "blocks_doherty_style_model_fit"
      ),
      next_action = c(
        "Review predator crosswalk and extract selectivity assumptions before any model branch.",
        "Build scenarios only after predation mortality model is useful.",
        "Design regional HG age-structured model separately from the 11-section Stier biomass model."
      ),
      notes = c(
        "Crosswalk created from current HG predator products.",
        "No future predator abundance scenario table in herring repo.",
        "The promoted baseline remains section-level biomass, not catch-at-age."
      )
    )
  )

write_csv(execution_status, file.path(diag_dir, "doherty_hg_replication_execution_status.csv"))
write_csv(predator_crosswalk, file.path(diag_dir, "doherty_hg_predator_class_crosswalk.csv"))
write_csv(model_gate, file.path(diag_dir, "doherty_hg_model_gate_ledger.csv"))

lines <- c(
  "# Doherty-Style HG Replication Execution Status",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "This report records what has now been executed with public/local data and what remains blocked for a true Doherty-style catch-at-age predator-removal model.",
  "",
  "## Execution Status",
  "",
  knitr::kable(execution_status, format = "pipe"),
  "",
  "## Predator Class Crosswalk",
  "",
  knitr::kable(predator_crosswalk, format = "pipe"),
  "",
  "## Model Gate Ledger",
  "",
  knitr::kable(model_gate, format = "pipe"),
  "",
  "## Bottom Line",
  "",
  "- Public DFO HG catch, spawn, number-at-age, weight-at-age, biosample count, and maturity schedule tables are now extracted provisionally through 2017.",
  "- Current 2018-2024 machine-readable biological inputs, effective sample size/preprocessing metadata, length-at-age tables, and predator age selectivity are still not found locally.",
  "- The current defensible output is a data bundle and gap ledger. It is still too early to fit a Doherty-style predator-removal catch-at-age model."
)

writeLines(lines, file.path(diag_dir, "doherty_hg_replication_execution_status.md"))

cat("Saved Doherty-style HG replication execution status:\n")
cat("  Output/diagnostics/doherty_hg_replication_execution_status.md\n")
cat("  Output/diagnostics/doherty_hg_predator_class_crosswalk.csv\n")
cat("  Output/diagnostics/doherty_hg_model_gate_ledger.csv\n")
