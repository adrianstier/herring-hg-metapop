# ============================================================================
# 07bk_doherty_hg_data_readiness.R
# Data-readiness audit for a Doherty-style Haida Gwaii herring/predator
# assessment analogue.
#
# This does not fit a new model. It checks which data streams are already
# present, which streams are only referenced by DFO manifests, and what must be
# requested before any catch-at-age / predator-removal branch is defensible.
# ============================================================================

library(tidyverse)
library(here)
library(knitr)
library(scales)

proj_dir <- here::here()
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
fig_dir <- file.path(proj_dir, "Output", "figures")
dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

predator_repo <- Sys.getenv(
  "PREDATOR_REPO_PATH",
  unset = file.path(dirname(proj_dir), "pacific-herring-predators")
)

rel_path <- function(path) {
  norm_path <- normalizePath(path, mustWork = FALSE)
  norm_proj <- normalizePath(proj_dir, mustWork = TRUE)
  norm_pred <- normalizePath(predator_repo, mustWork = FALSE)
  dplyr::case_when(
    startsWith(norm_path, norm_proj) ~ sub(paste0("^", norm_proj, "/?"), "", norm_path),
    startsWith(norm_path, norm_pred) ~ paste0(
      "../pacific-herring-predators/",
      sub(paste0("^", norm_pred, "/?"), "", norm_path)
    ),
    TRUE ~ path
  )
}

read_csv_safely <- function(path) {
  if (!file.exists(path) || file.info(path)$size == 0) {
    return(NULL)
  }
  tryCatch(
    readr::read_csv(path, show_col_types = FALSE, locale = readr::locale(encoding = "Latin1")),
    error = function(e) {
      tryCatch(
        readr::read_csv(path, show_col_types = FALSE),
        error = function(e2) NULL
      )
    }
  )
}

file_audit_one <- function(path) {
  exists <- file.exists(path)
  bytes <- if (exists) file.info(path)$size else NA_real_
  dat <- read_csv_safely(path)
  cols <- if (is.null(dat)) character() else names(dat)
  tibble(
    path = rel_path(path),
    exists = exists,
    bytes = bytes,
    n_rows = if (is.null(dat)) NA_integer_ else nrow(dat),
    n_cols = if (is.null(dat)) NA_integer_ else ncol(dat),
    column_names = paste(cols, collapse = " | "),
    has_age_col = any(str_detect(str_to_lower(cols), "(^|_|\\b)age($|_|\\b)|number-at-age|weight-at-age")),
    has_weight_col = any(str_detect(str_to_lower(cols), "weight|wt")),
    has_length_col = any(str_detect(str_to_lower(cols), "length")),
    has_catch_col = any(str_detect(str_to_lower(cols), "catch|prise")),
    has_spawn_col = any(str_detect(str_to_lower(cols), "spawn|shi")),
    has_predator_col = any(str_detect(str_to_lower(cols), "pred|consumption|pressure|exposure"))
  )
}

path_exists <- function(path) file.exists(path) && file.info(path)$size > 0

required_local_files <- c(
  file.path(proj_dir, "Data/raw/dfo-spawn/input-data.csv"),
  file.path(proj_dir, "Data/raw/dfo-catch/input-data.csv"),
  file.path(proj_dir, "Data/raw/HG_biological_samples.csv"),
  file.path(proj_dir, "Data/raw/HG_biological_samples_v2.csv"),
  file.path(proj_dir, "Data/raw/dfo-spawn/Pacific_herring_spawn_index_data_2025_EN.csv"),
  file.path(proj_dir, "Data/raw/dfo-spawn/HG_spawn_index_by_section_1951_2025.csv"),
  file.path(proj_dir, "Data/processed/HG_Spawn_Survey_1951_2025_all_sections.csv"),
  file.path(proj_dir, "Data/processed/herring_catch_local_1950_2024.csv"),
  file.path(proj_dir, "Data/processed/catch_matrix.csv"),
  file.path(proj_dir, "Data/processed/predators/hg_predation_pressure_covariates.csv"),
  file.path(proj_dir, "Data/processed/predators/hg_predator_consumption_by_group_year.csv"),
  file.path(proj_dir, "Data/processed/predators/hg_predator_consumption_by_species_recent.csv"),
  file.path(proj_dir, "Data/processed/predators/hg_spatial_predator_sites.csv"),
  file.path(predator_repo, "docs/data_catalog.csv"),
  file.path(predator_repo, "docs/data_catalog_HG_only.csv"),
  file.path(predator_repo, "docs/predator-coverage-matrix.csv")
)

local_file_audit <- map_dfr(required_local_files, file_audit_one)
write_csv(local_file_audit, file.path(diag_dir, "doherty_hg_local_file_audit.csv"))

input_manifest <- read_csv_safely(file.path(proj_dir, "Data/raw/dfo-spawn/input-data.csv"))
bio_manifest <- if (is.null(input_manifest)) {
  tibble()
} else {
  input_manifest %>%
    filter(Data == "Biological") %>%
    mutate(
      source_data_type = paste(Source, Gear, DataType, sep = " / "),
      source_data_type = str_replace_all(source_data_type, " /  / ", " / ")
    )
}

spawn_processed <- read_csv_safely(file.path(proj_dir, "Data/processed/HG_Spawn_Survey_1951_2025_all_sections.csv"))
catch_processed <- read_csv_safely(file.path(proj_dir, "Data/processed/herring_catch_local_1950_2024.csv"))
pred_covariates <- read_csv_safely(file.path(proj_dir, "Data/processed/predators/hg_predation_pressure_covariates.csv"))
pred_group <- read_csv_safely(file.path(proj_dir, "Data/processed/predators/hg_predator_consumption_by_group_year.csv"))
pred_species <- read_csv_safely(file.path(proj_dir, "Data/processed/predators/hg_predator_consumption_by_species_recent.csv"))
pred_spatial <- read_csv_safely(file.path(proj_dir, "Data/processed/predators/hg_spatial_predator_sites.csv"))
pred_catalog_hg <- read_csv_safely(file.path(predator_repo, "docs/data_catalog_HG_only.csv"))

spawn_summary <- if (is.null(spawn_processed)) {
  "No processed HG spawn table found."
} else {
  paste0(
    nrow(spawn_processed), " section-year rows, ",
    min(spawn_processed$year, na.rm = TRUE), "-",
    max(spawn_processed$year, na.rm = TRUE), ", ",
    n_distinct(spawn_processed$section_name), " sections."
  )
}

catch_summary <- if (is.null(catch_processed)) {
  "No processed HG catch table found."
} else {
  paste0(
    nrow(catch_processed), " section-year rows, ",
    min(catch_processed$Year, na.rm = TRUE), "-",
    max(catch_processed$Year, na.rm = TRUE), ", gear columns present: ",
    paste(intersect(c("Gillnet", "Seine", "Trawl", "SOK"), names(catch_processed)), collapse = ", "),
    "."
  )
}

bio_file_summary <- local_file_audit %>%
  filter(path %in% c("Data/raw/HG_biological_samples.csv", "Data/raw/HG_biological_samples_v2.csv")) %>%
  transmute(label = paste0(
    path, ": ",
    if_else(exists, paste0(coalesce(n_rows, 0L), " rows, ", coalesce(n_cols, 0L), " columns"), "missing"),
    if_else(has_age_col | has_weight_col | has_length_col, " with biological columns detected", " with no usable age/length/weight columns detected")
  )) %>%
  pull(label) %>%
  paste(collapse = "; ")

bio_manifest_summary <- if (nrow(bio_manifest) == 0) {
  "No DFO biological input manifest rows found."
} else {
  paste0(
    "DFO input manifest lists ", nrow(bio_manifest),
    " biological streams: ",
    paste(unique(bio_manifest$source_data_type), collapse = "; "),
    "."
  )
}

newer_extract_dir <- file.path(diag_dir, "dfo_newer_public_pdf_extract")
newer_status <- read_csv_safely(file.path(newer_extract_dir, "dfo_newer_public_pdf_status.csv"))
newer_table_1 <- read_csv_safely(file.path(newer_extract_dir, "dfo_sr_2025_005_table_1_input_data_windows.csv"))
newer_table_3 <- read_csv_safely(file.path(newer_extract_dir, "dfo_sr_2025_005_table_3_hg_spawn_2015_2024.csv"))
newer_table_15 <- read_csv_safely(file.path(newer_extract_dir, "dfo_sr_2025_005_table_15_hg_spawning_biomass_depletion_2015_2024.csv"))
newer_table_19 <- read_csv_safely(file.path(newer_extract_dir, "dfo_sr_2025_005_table_19_hg_reference_points.csv"))

newer_public_summary <- if (is.null(newer_status)) {
  "Newer public PDF extraction has not been run."
} else {
  paste0(
    "Code/02f extracted newer public PDF summaries: valid PDFs=",
    sum(newer_status$pdf_is_valid, na.rm = TRUE), "; DFO 2025/005 rows: input windows=",
    if_else(is.null(newer_table_1), 0L, nrow(newer_table_1)),
    ", HG spawn=",
    if_else(is.null(newer_table_3), 0L, nrow(newer_table_3)),
    ", HG biomass/depletion=",
    if_else(is.null(newer_table_15), 0L, nrow(newer_table_15)),
    ", HG reference points=",
    if_else(is.null(newer_table_19), 0L, nrow(newer_table_19)),
    "."
  )
}

predator_summary <- if (is.null(pred_covariates) || is.null(pred_group)) {
  "Predator demand covariates are missing."
} else {
  paste0(
    "Annual demand covariates ", min(pred_covariates$year, na.rm = TRUE),
    "-", max(pred_covariates$year, na.rm = TRUE), "; ",
    n_distinct(pred_group$group), " group streams; recent species table rows ",
    if_else(is.null(pred_species), 0L, nrow(pred_species)), "."
  )
}

predator_catalog_summary <- if (is.null(pred_catalog_hg)) {
  "Sibling predator repo HG data catalog not found."
} else {
  paste0(
    nrow(pred_catalog_hg), " HG-filtered predator/prey catalog rows in sibling repo across ",
    paste(sort(unique(pred_catalog_hg$functional_group)), collapse = ", "), "."
  )
}

status_levels <- c(
  "ready",
  "extracted_public_provisional",
  "published_extractable",
  "partial",
  "request_needed",
  "design_needed",
  "not_recommended"
)

readiness <- tribble(
  ~required_product, ~domain, ~grain, ~doherty_role, ~readiness, ~local_evidence, ~main_blocker, ~next_action,
  "herring_spawn_index", "herring", "year x section/SAR x survey method", "assessment abundance index", "ready",
  spawn_summary,
  "None for biomass-model analogue; method-scale caveats remain.",
  "Continue using current DFO spawn products; do not reinterpret missing/no-survey cells as absence.",
  "herring_fleet_catch", "herring", "year x section/SAR x fleet/gear", "catch removals by fishery", "partial",
  catch_summary,
  "Local table has catch by gear/section but is not a complete catch-at-age input bundle.",
  "Cross-check against DFO SCA/SISCAH input catch by source and SOK/open-pond categories.",
  "herring_age_composition", "herring", "year x SAR x fleet/source x age", "age-composition likelihood", "extracted_public_provisional",
  paste("Code/02e extracted Appendix B Table B.15 into provisional HG number-at-age CSVs.", newer_public_summary, bio_manifest_summary, bio_file_summary),
  "Public 1951-2017 number-at-age is extracted and DFO 2025/005 confirms age-composition input windows through 2024, but exact annual 2018-2024 number/proportion-at-age tables and effective sample-size metadata are not local.",
  "Spot-check extracted rows against the source PDFs, then request or locate exact machine-readable current SCA/SISCAH input files before modeling.",
  "herring_weight_at_age", "herring", "year x SAR x age", "spawning biomass and catch-at-age conversion", "extracted_public_provisional",
  paste("Code/02e extracted Appendix B Table B.22 into provisional HG weight-at-age CSVs.", newer_public_summary, bio_manifest_summary, bio_file_summary),
  "Public 1951-2017 weight-at-age is extracted and DFO 2025/005 confirms weight-at-age input windows through 2024, but exact annual 2018-2024 weight-at-age matrices and preprocessing metadata are not local.",
  "Spot-check extracted rows against the source PDFs, then request or locate exact machine-readable current SCA/SISCAH input files before modeling.",
  "herring_length_at_age", "herring", "year x SAR x age/source", "growth and predator-size vulnerability", "published_extractable",
  paste(newer_public_summary, bio_file_summary),
  "The HG rebuilding plan confirms length-at-age summaries and imputation rules in figures, but no usable machine-readable annual length-at-age table is present locally.",
  "Use figure captions as provenance only; request biological sample summaries tied to ageing records for any predator-size selectivity work.",
  "herring_maturity_at_age", "herring", "age", "mature biomass and spawning selectivity", "extracted_public_provisional",
  "Code/02e encoded the published fixed maturity schedule: age 2 about 25%, age 3 about 90%, age 4+ mature.",
  "Schedule is encoded from public text but still needs source-PDF spot check before model use.",
  "Retain as schema-ready provisional input; confirm against current DFO assessment inputs before modeling.",
  "test_fishery_biology", "herring", "year x SAR x test fishery x age/weight", "assessment age/weight sampling stream", "published_extractable",
  bio_manifest_summary,
  "Manifest references test-fishery number-at-age and weight-at-age starting 1975; public appendices summarize these streams, but exact model input files are absent.",
  "Extract public test-fishery age/weight tables first and preserve source/fleet labels; request model input files if public tables lack effective sample sizes.",
  "predator_consumption_total_group", "predator", "year x HG region x predator group/species", "external predator removals/demand", "ready",
  predator_summary,
  "Ready for biomass analogue, not sufficient for age-selective predation mortality.",
  "Keep using total/group demand for context and single-covariate screens; preserve uncertainty metadata.",
  "predator_class_mapping_doherty", "predator", "predator class x HG mapping", "translate Doherty predator classes to HG", "partial",
  predator_catalog_summary,
  "HG predator classes do not map one-to-one onto Doherty WCVI classes; fish/bird predators are broader in HG product.",
  "Maintain explicit class map: direct HG, BC-allocated, literature-scaled, or gap.",
  "predator_selectivity_age_class", "predator", "predator class x herring age/size", "age-specific predation mortality", "request_needed",
  "No maintained predator selectivity table exists in this repo.",
  "Diet/life-stage literature exists but is not encoded as model-ready selectivity.",
  "Extract Doherty selectivity assumptions and HG predator diet studies into a sourced selectivity table.",
  "predator_spatial_exposure_section_year", "predator", "year x section x predator class", "spatial predation exposure", "partial",
  paste0(
    if_else(is.null(pred_spatial), "No spatial predator site table found.", paste0(nrow(pred_spatial), " predator-site rows present.")),
    " Existing exposure prototype covers harbour seal and Steller sea lion, not all Doherty/HG predator classes."
  ),
  "Humpback/fish/bird section exposure remains incomplete; effort/fill flags need standardization.",
  "Refine harbour seal/SSL exposure; build or request HG humpback and fish/bird exposure products before section-level predator models.",
  "future_predator_scenarios", "predator/model", "scenario x year x predator class", "Doherty-style projections", "design_needed",
  "No future predator scenario table exists locally.",
  "Scenario design depends on a promoted/useful predator process and vetted predator abundance trajectories.",
  "Defer until a single predator process branch shows material calibration gain.",
  "catch_at_age_model_input_bundle", "model", "multi-table bundle", "true Doherty-style assessment", "design_needed",
  "Current model family is biomass-based and section-level; no HG catch-at-age input bundle exists.",
  "Age composition, weight-at-age, maturity, fleet catch, selectivity, and model design are not assembled.",
  "Build only after the herring biological request is fulfilled and the readiness report marks herring inputs usable."
) %>%
  mutate(
    readiness = factor(readiness, levels = status_levels),
    model_use_now = case_when(
      readiness == "ready" ~ "usable_now",
      readiness == "extracted_public_provisional" ~ "schema_audit_only",
      readiness == "published_extractable" ~ "extract_before_modeling",
      readiness == "partial" ~ "diagnostic_or_context_only",
      readiness == "request_needed" ~ "do_not_model_until_acquired",
      readiness == "design_needed" ~ "do_not_model_until_designed",
      TRUE ~ "do_not_use"
    ),
    priority = case_when(
      required_product %in% c("herring_age_composition", "herring_weight_at_age", "herring_fleet_catch") ~ "P1",
      required_product %in% c("predator_selectivity_age_class", "herring_maturity_at_age", "test_fishery_biology") ~ "P2",
      required_product %in% c("herring_length_at_age", "predator_class_mapping_doherty", "predator_spatial_exposure_section_year") ~ "P3",
      TRUE ~ "P4"
    )
  ) %>%
  arrange(factor(priority, levels = c("P1", "P2", "P3", "P4")), readiness, required_product)

write_csv(readiness, file.path(diag_dir, "doherty_hg_data_readiness.csv"))

source_registry <- tribble(
  ~dataset_id, ~required_product, ~source_type, ~current_local_path, ~primary_source, ~source_url, ~acquisition_method, ~owner_or_contact, ~status, ~notes,
  "dfo_herring_stock_assessment_landing", "herring_spawn_index;herring_age_composition;herring_weight_at_age;test_fishery_biology", "public_landing_page", NA_character_, "DFO Pacific herring stock assessments", "https://www.pac.dfo-mpo.gc.ca/science/species-especes/herring-hareng/stock-assessments-evaluations-stocks-eng.html", "download_public_open_data_and_assessment_appendices", "DFO Pacific herring stock assessment", "public_entry_point", "Public page confirms biological sampling, spawn surveys, model history, open spawn index data, and stock-assessment regions. Use as the starting point before any direct data request.",
  "dfo_hg_public_appendix_b_extract", "herring_fleet_catch;herring_spawn_index;herring_age_composition;herring_weight_at_age;herring_maturity_at_age", "provisional_public_extract", "Output/diagnostics/dfo_hg_public_extract/", "DFO CSAS Research Document 2018/028 Appendix B", "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/40944670.pdf", "already_extracted_public_provisional", "DFO CSAS / local extraction script", "extracted_public_provisional", "Generated by Code/02e_extract_dfo_hg_assessment_tables.R; use for schema audit and spot checks only, not direct model fitting.",
  "dfo_newer_public_pdf_extract", "herring_fleet_catch;herring_spawn_index;herring_age_composition;herring_weight_at_age;herring_length_at_age", "public_summary_extract", "Output/diagnostics/dfo_newer_public_pdf_extract/", "DFO CSAS Science Response 2025/005; 2024/2025 IFMP; HG rebuilding plan", "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41290963.pdf", "already_extracted_public_summary", "DFO CSAS / local extraction script", "extracted_public_summary", "Generated by Code/02f_extract_newer_dfo_public_pdfs.R; captures current public summaries through 2024 and biological figure/caption metadata, but not exact SCA/SISCAH input files.",
  "dfo_hg_spawn_index_2025", "herring_spawn_index", "raw_and_processed", "Data/raw/dfo-spawn/Pacific_herring_spawn_index_data_2025_EN.csv", "DFO Pacific herring spawn index open data", "https://open.canada.ca/data/en/dataset/d892511c-d851-4f85-a0ec-708bc05d2810", "already_local", "DFO Pacific herring stock assessment / Open Canada", "ready", "Maintained DFO tonnes-scale spawn index; keep q scale separate from Stier SHI. The DFO assessment landing page links this open data record.",
  "dfo_hg_local_catch_1950_2024", "herring_fleet_catch", "processed", "Data/processed/herring_catch_local_1950_2024.csv", "DFO local catch extracts in repo", "Data/raw/dfo-catch/README_catch_data.txt", "already_local_plus_crosscheck", "DFO / local archive", "partial", "Usable for biomass removals; not a full SCA catch-at-age input bundle.",
  "dfo_herring_input_manifest", "herring_age_composition;herring_weight_at_age;test_fishery_biology", "manifest_only", "Data/raw/dfo-spawn/input-data.csv", "DFO herring model input manifest", "Data/raw/dfo-spawn/input-data.csv", "public_appendix_then_request_raw_tables", "DFO Pacific Biological Station", "published_extractable", "Manifest names biological streams; public assessment appendices should be extracted first, then exact input files requested if needed.",
  "hg_biological_samples_local", "herring_age_composition;herring_weight_at_age;herring_length_at_age", "local_partial_or_misnamed", "Data/raw/HG_biological_samples.csv;Data/raw/HG_biological_samples_v2.csv", "Local biological-samples placeholder", "local", "audit_only", "local archive", "not_model_ready", "Current CSV is catch summary only; v2 is empty.",
  "dfo_csas_siscah_2023", "catch_at_age_model_input_bundle;herring_maturity_at_age", "method_reference", NA_character_, "DFO CSAS SAR 2023/040 and SISCAH research documentation", "https://www.dfo-mpo.gc.ca/csas-sccs/Publications/SAR-AS/2023/2023_040-eng.html", "reference_then_request_inputs", "DFO CSAS / PBS", "reference", "Documents required model ingredients and age-composition likelihood but not raw HG input tables.",
  "dfo_ifmp_2025_2026_summary", "catch_at_age_model_input_bundle", "method_reference", NA_character_, "Pacific Herring 2025-2026 IFMP summary", "https://www.pac.dfo-mpo.gc.ca/fm-gp/mplans/herring-hareng-ifmp-pgip-sm-eng.html", "reference", "DFO Pacific Region", "reference", "Confirms current model history and SISCAH implementation context.",
  "dfo_ifmp_2025_2026_full", "herring_age_composition;herring_weight_at_age;herring_fleet_catch", "method_reference", NA_character_, "Pacific Herring 2025-2026 full IFMP / Appendix 3 stock assessment results", "https://publications.gc.ca/site/eng/9.958396/publication.html", "reference_then_extract_inputs", "DFO Pacific Region", "reference", "Current full IFMP catalogue record; Appendix 3 states major-stock models use commercial catch, spawn survey, age composition, and weight-at-age. Direct PDF downloads may return an archived landing page, so use the catalogue page when needed.",
  "dfo_herring_assessment_appendix_2024_2025", "herring_age_composition;herring_weight_at_age;herring_fleet_catch", "method_reference", NA_character_, "Pacific Herring 2024-2025 IFMP Appendix 3 / stock assessment results", "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41274672.pdf", "reference_then_request_inputs", "DFO Pacific Region", "reference", "Prior full IFMP; useful for checking whether Appendix 3 wording/data windows changed.",
  "hg_predator_consumption_products", "predator_consumption_total_group", "processed", "Data/processed/predators/hg_predation_pressure_covariates.csv;Data/processed/predators/hg_predator_consumption_by_group_year.csv", "stier-lab/pacific-herring-predators", "../pacific-herring-predators/docs/data_catalog.csv", "already_local", "Stier lab predator repo", "ready_for_analogue", "Annual total/group/species demand; not age-selective predation.",
  "hg_predator_catalog", "predator_class_mapping_doherty;predator_spatial_exposure_section_year", "source_catalog", "../pacific-herring-predators/docs/data_catalog_HG_only.csv", "stier-lab/pacific-herring-predators HG catalog", "../pacific-herring-predators/docs/data_catalog_HG_only.csv", "already_local_plus_gap_fill", "Stier lab predator repo", "partial", "Class mapping and section exposure need explicit Doherty/HG crosswalk.",
  "doherty_2025_wcvi_predation", "predator_selectivity_age_class;future_predator_scenarios", "paper_reference", NA_character_, "Doherty et al. 2025 ICES JMS fsae183", "https://doi.org/10.1093/icesjms/fsae183", "extract_supplement_or_author_request", "paper authors / journal supplement", "request_needed", "Use for predator-removal model structure and selectivity assumptions; do not copy WCVI parameters blindly to HG.",
  "dfo_fish_ageing_lab", "herring_age_composition;herring_length_at_age;herring_weight_at_age", "data_owner_reference", NA_character_, "DFO Pacific Fish Ageing Lab", "https://www.pac.dfo-mpo.gc.ca/science/species-especes/agelab-scalimetrie/index-eng.html", "data_request", "DFO Pacific Biological Station / Fish Ageing Lab", "request_needed", "Likely custodian for ageing, size-at-age, and sample metadata."
)

write_csv(source_registry, file.path(diag_dir, "doherty_hg_source_registry.csv"))

schema_templates <- tribble(
  ~table_name, ~column_name, ~type, ~required, ~notes,
  "herring_fleet_catch_year_area_fleet", "year", "integer", TRUE, "Calendar year or assessment season year; define explicitly.",
  "herring_fleet_catch_year_area_fleet", "sar", "character", TRUE, "Stock Assessment Region; default Haida Gwaii.",
  "herring_fleet_catch_year_area_fleet", "section", "character", FALSE, "DFO section if available; leave NA for SAR-level records.",
  "herring_fleet_catch_year_area_fleet", "fleet", "character", TRUE, "Roe seine, roe gillnet, SOK/open pond, test fishery, other.",
  "herring_fleet_catch_year_area_fleet", "catch_tonnes", "double", TRUE, "Metric tonnes.",
  "herring_fleet_catch_year_area_fleet", "source_id", "character", TRUE, "Links to source registry.",
  "herring_age_composition_year_area_fleet", "year", "integer", TRUE, "Assessment/sample year.",
  "herring_age_composition_year_area_fleet", "sar", "character", TRUE, "Stock Assessment Region.",
  "herring_age_composition_year_area_fleet", "fleet_or_source", "character", TRUE, "Fishery/test/other sample source.",
  "herring_age_composition_year_area_fleet", "age", "integer", TRUE, "Herring age class.",
  "herring_age_composition_year_area_fleet", "n_at_age", "double", FALSE, "Raw aged count if available.",
  "herring_age_composition_year_area_fleet", "prop_at_age", "double", FALSE, "Proportion-at-age; must sum to 1 within sample group when complete.",
  "herring_age_composition_year_area_fleet", "sample_size", "double", FALSE, "Number aged or effective sample size.",
  "herring_weight_at_age_year_area", "year", "integer", TRUE, "Assessment/sample year.",
  "herring_weight_at_age_year_area", "sar", "character", TRUE, "Stock Assessment Region.",
  "herring_weight_at_age_year_area", "age", "integer", TRUE, "Herring age class.",
  "herring_weight_at_age_year_area", "mean_weight_g", "double", TRUE, "Mean individual weight in grams.",
  "herring_weight_at_age_year_area", "sample_size", "double", FALSE, "Number weighed.",
  "herring_length_at_age_year_area", "year", "integer", TRUE, "Assessment/sample year.",
  "herring_length_at_age_year_area", "sar", "character", TRUE, "Stock Assessment Region.",
  "herring_length_at_age_year_area", "age", "integer", TRUE, "Herring age class.",
  "herring_length_at_age_year_area", "mean_length_mm", "double", TRUE, "Mean length in millimetres.",
  "herring_maturity_at_age", "age", "integer", TRUE, "Herring age class.",
  "herring_maturity_at_age", "proportion_mature", "double", TRUE, "0-1 maturity proportion.",
  "predator_consumption_year_region_class", "year", "integer", TRUE, "Calendar year.",
  "predator_consumption_year_region_class", "region", "character", TRUE, "HG, BC, NEP, or other explicit spatial scope.",
  "predator_consumption_year_region_class", "predator_class", "character", TRUE, "Doherty-compatible or HG-specific predator class.",
  "predator_consumption_year_region_class", "consumption_tonnes", "double", TRUE, "Annual herring consumption.",
  "predator_consumption_year_region_class", "scope_flag", "character", TRUE, "direct_HG, BC_allocated_to_HG, literature_scaled, or gap.",
  "predator_selectivity_age_class", "predator_class", "character", TRUE, "Predator class.",
  "predator_selectivity_age_class", "age", "integer", TRUE, "Herring age class.",
  "predator_selectivity_age_class", "relative_selectivity", "double", TRUE, "Relative vulnerability by age.",
  "predator_exposure_section_year_class", "year", "integer", TRUE, "Calendar year.",
  "predator_exposure_section_year_class", "section_name", "character", TRUE, "Model section name.",
  "predator_exposure_section_year_class", "predator_class", "character", TRUE, "Predator class.",
  "predator_exposure_section_year_class", "exposure_index", "double", TRUE, "Kernel or allocation exposure index.",
  "predator_exposure_section_year_class", "data_fill_flag", "character", TRUE, "observed, interpolated, extrapolated, literature_scaled."
)

write_csv(schema_templates, file.path(diag_dir, "doherty_hg_schema_templates.csv"))

readiness_md <- readiness %>%
  mutate(readiness = as.character(readiness)) %>%
  select(
    required_product, domain, grain, doherty_role, readiness, model_use_now,
    priority, local_evidence, main_blocker, next_action
  )

registry_md <- source_registry %>%
  select(
    dataset_id, required_product, source_type, current_local_path, status,
    acquisition_method, owner_or_contact, primary_source, source_url, notes
  )

schema_md <- schema_templates %>%
  mutate(required = if_else(required, "yes", "no")) %>%
  select(table_name, column_name, type, required, notes)

lines <- c(
  "# Doherty-Style HG Data Readiness",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "This report checks whether the current Haida Gwaii workspace can support a Doherty-style herring/predator assessment analogue.",
  "",
  "## Bottom Line",
  "",
  "- The current repo has enough data for a biomass-model predator-demand analogue: spawn index, catch removals, and annual HG predator demand are present.",
  "- Public DFO Appendix B HG catch, spawn, number-at-age, weight-at-age, biosample, and maturity tables have now been extracted provisionally through 2017.",
  "- Newer public PDFs now add DFO 2025/005 current summary tables through 2024 for HG catch, spawn, SCA parameters, SCA model-output recruitment, biomass/depletion, reference points, and broad projected age proportions.",
  "- It does **not** yet have the herring biological inputs needed for a true catch-at-age model in final model-ready local form: exact annual 2018-2024 number/proportion-at-age, annual weight-at-age matrices, effective sample-size metadata, length-at-age tables, exact SCA/SISCAH input files, and predator age/size selectivity are still absent or unresolved.",
  "- A direct DFO request is still useful, but it should ask for machine-readable copies and metadata for the published assessment inputs rather than asking whether the inputs exist.",
  "- Source provenance is controlled by `docs/doherty-style-hg-source-provenance.md` and `Output/diagnostics/doherty_hg_source_registry.csv`; all extracted tables must retain source document/table/URL, extraction method, and extraction notes.",
  "",
  "## Source Provenance Control",
  "",
  "Tracked source map: `docs/doherty-style-hg-source-provenance.md`.",
  "",
  "Generated source controls:",
  "",
  "- `Output/diagnostics/doherty_hg_source_registry.csv`",
  "- `Output/diagnostics/dfo_assessment_public_source_registry.csv`",
  "- `Output/diagnostics/dfo_hg_public_extract/dfo_hg_public_extract_audit.csv`",
  "- `Output/diagnostics/dfo_newer_public_pdf_extract/dfo_newer_public_pdf_status.csv`",
  "",
  "Required source fields for clean extracted tables: `source_document`, `source_table`, `source_url`, `extraction_method`, and `extraction_notes`. Local/private sources must also record local path, upstream catalog, owner/custodian, and model-use status.",
  "",
  "## Readiness Matrix",
  "",
  knitr::kable(readiness_md, format = "pipe"),
  "",
  "## Source Registry",
  "",
  knitr::kable(registry_md, format = "pipe"),
  "",
  "## Schema Templates",
  "",
  knitr::kable(schema_md, format = "pipe"),
  "",
  "## Local File Audit",
  "",
  knitr::kable(
    local_file_audit %>%
      select(path, exists, bytes, n_rows, n_cols, has_age_col, has_weight_col, has_length_col, has_catch_col, has_spawn_col, has_predator_col),
    format = "pipe"
  ),
  "",
  "## Generated Files",
  "",
  "- `Output/diagnostics/doherty_hg_data_readiness.csv`",
  "- `Output/diagnostics/doherty_hg_source_registry.csv`",
  "- `Output/diagnostics/doherty_hg_schema_templates.csv`",
  "- `Output/diagnostics/doherty_hg_local_file_audit.csv`",
  "- `Output/diagnostics/doherty_hg_dfo_data_request_template.md`",
  "- `Output/figures/doherty_hg_data_readiness.pdf`",
  "- `Output/diagnostics/dfo_hg_public_extract/dfo_hg_public_extract_summary.md`",
  "- `Output/diagnostics/dfo_newer_public_pdf_extract/dfo_newer_public_pdf_extract_summary.md`",
  "- `Output/diagnostics/doherty_hg_replication_execution_status.md`"
)

writeLines(lines, file.path(diag_dir, "doherty_hg_data_readiness.md"))
writeLines(
  c(
    "# DFO Data Request Template: Haida Gwaii Pacific Herring Biological Inputs",
    "",
    "Subject: Request for Haida Gwaii Pacific Herring assessment biological input data",
    "",
    "Dear DFO Pacific herring assessment team,",
    "",
    "We are compiling a transparent Haida Gwaii Pacific Herring data bundle to evaluate a Doherty et al.-style predator-removal analogue alongside an existing section-level biomass model. The public DFO stock-assessment page, DFO CSAS Science Response 2025/005, and assessment appendices identify the needed spawn, catch, age-composition, and weight-at-age inputs, and the current local workspace contains spawn index, catch data, and public summary tables through 2024, but not the biological input tables in model-ready machine-readable form.",
    "",
    "Could you please share the Haida Gwaii assessment input data, or point us to the public repository / input archive, for the following streams in the form used by SCA/SISCAH?",
    "",
    "1. Annual number-at-age or proportion-at-age tables by sample source/fleet, including roe seine, roe gillnet, test fishery, and other fisheries where available.",
    "2. Annual weight-at-age matrices and sample sizes by stock assessment region and sample source where available.",
    "3. Length-at-age or biological sample summaries tied to the ageing records.",
    "4. Maturity-at-age schedule used in current SCA/SISCAH assessments, with source notes.",
    "5. Fleet/source-specific catch landings, including SOK/open-pond records, in the same form used by SCA/SISCAH.",
    "6. Metadata needed to interpret survey/fishery timing, ageing method, sample sizes, and any effective-sample-size adjustments.",
    "",
    "Preferred format: CSV, RDS, or the exact SCA/SISCAH input files used for recent Haida Gwaii assessments. If the current public assessment appendices are the authoritative source, we would appreciate guidance on table definitions and any effective-sample-size or preprocessing steps not recoverable from the PDFs. We will retain source metadata and cite DFO data provenance in all outputs.",
    "",
    "Thank you,",
    "",
    "[name]"
  ),
  file.path(diag_dir, "doherty_hg_dfo_data_request_template.md")
)

plot_tbl <- readiness %>%
  count(readiness, model_use_now, name = "n") %>%
  mutate(readiness = factor(as.character(readiness), levels = status_levels))

p <- ggplot(plot_tbl, aes(x = readiness, y = n, fill = model_use_now)) +
  geom_col(width = 0.72, colour = "grey25") +
  geom_text(aes(label = n), vjust = -0.35, size = 3.2) +
  scale_fill_brewer(palette = "Set2", name = "Model use now") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.12))) +
  labs(
    title = "Doherty-style HG data readiness",
    subtitle = "Biomass analogue inputs are present; published catch-at-age inputs still need extraction/machine-readable copies.",
    x = NULL,
    y = "Required data products"
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank(),
    legend.position = "bottom"
  )

ggsave(
  file.path(fig_dir, "doherty_hg_data_readiness.pdf"),
  p,
  width = 7,
  height = 4.5
)

cat("Saved Doherty-style HG data readiness outputs:\n")
cat("  Output/diagnostics/doherty_hg_data_readiness.md\n")
cat("  Output/diagnostics/doherty_hg_source_registry.csv\n")
cat("  Output/diagnostics/doherty_hg_schema_templates.csv\n")
cat("  Output/diagnostics/doherty_hg_dfo_data_request_template.md\n")
cat("  Output/figures/doherty_hg_data_readiness.pdf\n")
