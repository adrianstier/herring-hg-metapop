# ============================================================================
# 02f_extract_newer_dfo_public_pdfs.R
# Extract newer public DFO Pacific Herring PDF content relevant to the
# Doherty-style Haida Gwaii data workflow.
#
# This script mines post-2018 public PDFs for machine-readable tables, captions,
# and keyword windows. Outputs are provenance/audit products only; they are not
# final SCA/SISCAH input files.
# ============================================================================

library(tidyverse)
library(here)
library(knitr)

proj_dir <- here::here()
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
source_dir <- file.path(diag_dir, "dfo_assessment_public_sources")
extract_dir <- file.path(diag_dir, "dfo_newer_public_pdf_extract")
dir.create(extract_dir, showWarnings = FALSE, recursive = TRUE)

pdftotext <- Sys.which("pdftotext")
if (!nzchar(pdftotext)) {
  stop("pdftotext is required for newer public PDF extraction.")
}

newer_sources <- tribble(
  ~source_id, ~title, ~source_url, ~local_file, ~role,
  "dfo_science_response_2025_005",
  "DFO CSAS Science Response 2025/005, Pacific herring status in 2024 and forecast for 2025",
  "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41290963.pdf",
  "dfo_science_response_2025_005.pdf",
  "Current public SCA summaries for HG, PRD, CC, and WCVI through 2024.",
  "dfo_ifmp_full_2025_2026",
  "Pacific Region Integrated Fisheries Management Plan, 2025/2026 Pacific herring",
  "https://publications.gc.ca/collections/collection_2026/mpo-dfo/Fs143-3-23-2600-eng.pdf",
  "dfo_ifmp_full_2025_2026.pdf",
  "Current full IFMP; command-line access currently returns an archive HTML page, so record the block.",
  "dfo_herring_ifmp_2024_2025",
  "Pacific Region Integrated Fisheries Management Plan, 2024/2025 Pacific herring",
  "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41274672.pdf",
  "dfo_herring_ifmp_2024_2025.pdf",
  "Prior full IFMP with Appendix 3 stock-assessment results.",
  "dfo_hg_rebuilding_plan_2024",
  "Haida Gwaii Pacific Herring Rebuilding Plan",
  "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41284161.pdf",
  "dfo_hg_rebuilding_plan_2024.pdf",
  "HG-specific rebuilding context, biological figure captions, and model-structure descriptions."
)

is_pdf_file <- function(path) {
  if (!file.exists(path) || file.info(path)$size == 0) {
    return(FALSE)
  }
  header <- readBin(path, what = "raw", n = 4)
  identical(rawToChar(header), "%PDF")
}

run_pdftotext <- function(pdf_path, text_path, layout = FALSE) {
  if (!is_pdf_file(pdf_path)) {
    return("pdf_missing_or_not_pdf")
  }
  args <- if (layout) {
    c("-layout", pdf_path, text_path)
  } else {
    c(pdf_path, text_path)
  }
  result <- system2(pdftotext, args, stdout = TRUE, stderr = TRUE)
  status <- attr(result, "status")
  if (!is.null(status) && status != 0) {
    return(paste0("extract_failed: ", paste(result, collapse = " ")))
  }
  if (!file.exists(text_path) || file.info(text_path)$size == 0) {
    return("extract_empty")
  }
  "text_extracted"
}

read_text <- function(path) {
  if (!file.exists(path)) {
    return(character())
  }
  readLines(path, warn = FALSE) %>%
    iconv(from = "", to = "UTF-8", sub = "")
}

clean_line <- function(x) {
  x %>%
    str_replace_all("\f", " ") %>%
    str_squish()
}

parse_num <- function(x) {
  suppressWarnings(readr::parse_number(str_replace_all(x, ",", "")))
}

split_fields <- function(x) {
  str_split(str_trim(x), "\\s{2,}", simplify = FALSE)[[1]]
}

context_at <- function(lines, i, n = 4) {
  if (length(lines) == 0 || is.na(i)) {
    return(NA_character_)
  }
  lo <- max(1, i - n)
  hi <- min(length(lines), i + n)
  paste(lines[lo:hi] %>% clean_line(), collapse = "\n")
}

extract_block <- function(lines, start_pattern, end_pattern) {
  start <- str_which(lines, start_pattern)[1]
  ends <- str_which(lines, end_pattern)
  end <- ends[ends > start][1]
  if (is.na(start) || is.na(end) || end <= start) {
    return(character())
  }
  lines[start:(end - 1)]
}

source_status <- newer_sources %>%
  mutate(
    pdf_path = file.path(source_dir, local_file),
    pdf_is_valid = map_lgl(pdf_path, is_pdf_file),
    plain_text_path = file.path(source_dir, str_replace(local_file, "\\.pdf$", ".txt")),
    layout_text_path = file.path(source_dir, str_replace(local_file, "\\.pdf$", "_layout.txt")),
    plain_text_status = map2_chr(pdf_path, plain_text_path, ~ run_pdftotext(.x, .y, layout = FALSE)),
    layout_text_status = map2_chr(pdf_path, layout_text_path, ~ run_pdftotext(.x, .y, layout = TRUE)),
    pdf_bytes = if_else(file.exists(pdf_path), file.info(pdf_path)$size, NA_real_),
    plain_text_lines = map_int(plain_text_path, ~ length(read_text(.x))),
    layout_text_lines = map_int(layout_text_path, ~ length(read_text(.x)))
  )

line_index <- source_status %>%
  mutate(lines = map(plain_text_path, read_text)) %>%
  select(source_id, title, source_url, lines) %>%
  unnest_longer(lines, values_to = "line_text", indices_to = "line_number", keep_empty = TRUE) %>%
  filter(!is.na(line_text)) %>%
  mutate(clean_text = clean_line(line_text))

keyword_patterns <- tribble(
  ~keyword_family, ~pattern,
  "haida_gwaii", regex("Haida Gwaii|\\bHG\\b", ignore_case = TRUE),
  "catch_age_model", regex("statistical catch-age|SCA|SISCAH", ignore_case = TRUE),
  "age_composition", regex("age composition|proportion-at-age|number-at-age|number aged", ignore_case = TRUE),
  "weight_length_age", regex("weight-at-age|length-at-age|size-at-age", ignore_case = TRUE),
  "biological_samples", regex("biological samples|biological data|test fishery", ignore_case = TRUE),
  "spawn_index", regex("spawn survey|spawn index|spawning biomass", ignore_case = TRUE),
  "missing_imputed", regex("missing|imputed|withheld|privacy", ignore_case = TRUE),
  "predation_environment", regex("predation|predator|natural mortality|environmental drivers", ignore_case = TRUE)
)

keyword_windows <- pmap_dfr(
  list(keyword_patterns$keyword_family, keyword_patterns$pattern),
  function(keyword_family, pattern) {
    line_index %>%
      filter(str_detect(clean_text, pattern)) %>%
      group_by(source_id) %>%
      mutate(
        context = map2_chr(
          line_number,
          source_id,
          ~ context_at(
            line_index$line_text[line_index$source_id == .y],
            .x,
            n = 4
          )
        )
      ) %>%
      ungroup() %>%
      transmute(source_id, title, source_url, keyword_family, line_number, clean_text, context)
  }
)

caption_catalog <- line_index %>%
  filter(str_detect(clean_text, "^(Table|Figure)\\s+[0-9]+\\.")) %>%
  mutate(
    item_type = str_match(clean_text, "^(Table|Figure)")[, 2],
    item_number = parse_num(str_match(clean_text, "^(?:Table|Figure)\\s+([0-9]+)")[, 2]),
    context = map2_chr(
      line_number,
      source_id,
      ~ context_at(line_index$line_text[line_index$source_id == .y], .x, n = 5)
    )
  ) %>%
  select(source_id, title, source_url, item_type, item_number, line_number, clean_text, context)

read_layout <- function(local_file) {
  read_text(file.path(source_dir, str_replace(local_file, "\\.pdf$", "_layout.txt")))
}

parse_table_row_numbers <- function(block, pattern, columns) {
  matches <- str_match(block, pattern)
  keep <- !is.na(matches[, 1])
  if (!any(keep)) {
    return(tibble())
  }
  as_tibble(matches[keep, -1, drop = FALSE], .name_repair = ~ columns)
}

ifmp_2024_lines <- read_layout("dfo_herring_ifmp_2024_2025.pdf")
ifmp_2024_table_3_1 <- parse_table_row_numbers(
  extract_block(ifmp_2024_lines, "^Table 3\\.1\\.", "^Table 3\\.2"),
  "^\\s*(HG|PRD|CC|WCVI)\\s+([0-9.]+)\\s+([0-9.]+)\\s+([0-9.]+)\\s+([0-9.]+)\\s+([0-9.]+)\\s+([0-9.]+)\\s+([0-9.]+)\\s+([0-9.]+)\\s+([0-9.]+)\\s*$",
  c(
    "sar", "sb2025_kt_p05", "sb2025_kt_median", "sb2025_kt_p95",
    "age3_prop_p05", "age3_prop_median", "age3_prop_p95",
    "age4_10_prop_p05", "age4_10_prop_median", "age4_10_prop_p95"
  )
) %>%
  mutate(
    across(-sar, parse_num),
    source_document = "DFO Pacific herring IFMP 2024/2025",
    source_table = "Appendix 3 Table 3.1",
    source_url = "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41274672.pdf",
    extraction_method = "pdftotext -layout row-regex extraction",
    extraction_notes = "Projected 2025 spawning biomass and broad age-class proportions; public summary, not raw SCA input."
  )

sr_2025_lines <- read_layout("dfo_science_response_2025_005.pdf")

sr_table_1 <- extract_block(sr_2025_lines, "^Table 1\\.", "^Table 2\\.") %>%
  keep(~ str_detect(.x, "\\b(1951|1972|1975|1988) to (1987|20[0-9]{2})\\b")) %>%
  map_dfr(function(x) {
    parts <- split_fields(x)
    if (length(parts) < 3) {
      return(tibble())
    }
    tibble(
      source = parts[1],
      data_stream = parts[2],
      years = parts[3]
    )
  }) %>%
  mutate(
    source = str_replace_all(source, c("fshery" = "fishery", "fsheries" = "fisheries")),
    source_document = "DFO CSAS Science Response 2025/005",
    source_table = "Table 1",
    source_url = "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41290963.pdf",
    extraction_method = "pdftotext -layout split on repeated whitespace",
    extraction_notes = "Input data windows for 2024 SCA major-stock models; describes coverage, not raw input values."
  )

sr_table_2 <- parse_table_row_numbers(
  extract_block(sr_2025_lines, "^Table 2\\.", "^Table 3\\."),
  "^\\s*(201[5-9]|202[0-4])\\s+([0-9,]+|WP)\\s+([0-9,]+|WP)\\s+([0-9,]+|WP)\\s+([0-9,]+|WP)\\s+([0-9,]+|WP)\\s*$",
  c("year", "HG_tonnes", "PRD_tonnes", "CC_tonnes", "SoG_tonnes", "WCVI_tonnes")
) %>%
  mutate(
    year = as.integer(year),
    across(ends_with("_tonnes"), ~ parse_num(.x)),
    source_document = "DFO CSAS Science Response 2025/005",
    source_table = "Table 2",
    source_url = "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41290963.pdf",
    extraction_method = "pdftotext -layout row-regex extraction",
    extraction_notes = "Total landed catch by major SAR, 2015-2024; WP/privacy cells become NA if present."
  )

sr_table_3 <- parse_table_row_numbers(
  extract_block(sr_2025_lines, "^Table 3\\.", "^Table 4\\."),
  "^\\s*(201[5-9]|202[0-4])\\s+([0-9,]+)\\s+([0-9.]+|NA)\\s+([0-9.]+|NA)\\s+([0-9.]+|NA)\\s*$",
  c("year", "spawn_index_tonnes", "cumshewa_selwyn_prop", "juan_perez_skincuttle_prop", "louscoone_prop")
) %>%
  mutate(
    year = as.integer(year),
    across(-year, parse_num),
    source_document = "DFO CSAS Science Response 2025/005",
    source_table = "Table 3",
    source_url = "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41290963.pdf",
    extraction_method = "pdftotext -layout row-regex extraction",
    extraction_notes = "HG aggregate spawn index and major sub-stock proportions, 2015-2024; not scaled by q."
  )

sr_table_7_raw <- parse_table_row_numbers(
  extract_block(sr_2025_lines, "^Table 7\\.", "^Table 8\\."),
  "^\\s*(\\S+)\\s+([0-9,\\.]+)\\s+([0-9,\\.]+)\\s+([0-9,\\.]+)\\s+([0-9,\\.]+)\\s*$",
  c("parameter_raw", "p05", "median", "p95", "mpd")
)

sr_table_7 <- sr_table_7_raw %>%
  mutate(
    parameter = case_when(
      row_number() == 6 ~ "rho_observation_error_fraction",
      row_number() == 7 ~ "tau_total_error_precision",
      row_number() == 10 ~ "sigma_process_recruitment",
      row_number() == 11 ~ "sigma_observation_survey_index",
      TRUE ~ parameter_raw
    ),
    across(c(p05, median, p95, mpd), parse_num),
    source_document = "DFO CSAS Science Response 2025/005",
    source_table = "Table 7",
    source_url = "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41290963.pdf",
    extraction_method = "pdftotext -layout row-regex extraction",
    extraction_notes = "HG SCA key parameter public summary; Greek symbols are normalized by row order where extraction mangles glyphs."
  ) %>%
  select(parameter, parameter_raw, p05, median, p95, mpd, everything())

sr_table_11 <- parse_table_row_numbers(
  extract_block(sr_2025_lines, "^Table 11\\.", "^Table 12\\."),
  "^\\s*(201[5-9]|202[0-4])\\s+([0-9,\\.]+)\\s+([0-9,\\.]+)\\s+([0-9,\\.]+)\\s+([0-9,\\.]+)\\s*$",
  c("year", "recruitment_millions_p05", "recruitment_millions_median", "recruitment_millions_p95", "recruitment_millions_mpd")
) %>%
  mutate(
    year = as.integer(year),
    across(-year, parse_num),
    source_document = "DFO CSAS Science Response 2025/005",
    source_table = "Table 11",
    source_url = "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41290963.pdf",
    extraction_method = "pdftotext -layout row-regex extraction",
    extraction_notes = "HG age-2 recruitment public SCA summary, 2015-2024."
  )

sr_table_15 <- parse_table_row_numbers(
  extract_block(sr_2025_lines, "^Table 15\\.", "^Table 16\\."),
  "^\\s*(201[5-9]|202[0-4])\\s+([0-9.]+)\\s+([0-9.]+)\\s+([0-9.]+)\\s+([0-9.]+)\\s+([0-9.]+)\\s+([0-9.]+)\\s+([0-9.]+)\\s+([0-9.]+)\\s*$",
  c(
    "year",
    "spawning_biomass_kt_p05", "spawning_biomass_kt_median", "spawning_biomass_kt_p95", "spawning_biomass_kt_mpd",
    "depletion_p05", "depletion_median", "depletion_p95", "depletion_mpd"
  )
) %>%
  mutate(
    year = as.integer(year),
    across(-year, parse_num),
    source_document = "DFO CSAS Science Response 2025/005",
    source_table = "Table 15",
    source_url = "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41290963.pdf",
    extraction_method = "pdftotext -layout row-regex extraction",
    extraction_notes = "HG spawning biomass and depletion public SCA summary, 2015-2024."
  )

sr_table_19 <- extract_block(sr_2025_lines, "^Table 19\\.", "^Table 20\\.") %>%
  keep(~ length(split_fields(.x)) >= 4) %>%
  map_dfr(function(x) {
    parts <- split_fields(x)
    tibble(
      reference_point = parts[1],
      p05 = parse_num(parts[2]),
      median = parse_num(parts[3]),
      p95 = parse_num(parts[4])
    )
  }) %>%
  filter(!str_detect(reference_point, "^Reference point$")) %>%
  mutate(
    source_document = "DFO CSAS Science Response 2025/005",
    source_table = "Table 19",
    source_url = "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41290963.pdf",
    extraction_method = "pdftotext -layout split on repeated whitespace",
    extraction_notes = "HG reference points and 2025 projection public SCA summary; probability rows have only median probabilities in the PDF table."
  )

rebuilding_biology_caption_catalog <- caption_catalog %>%
  filter(
    source_id == "dfo_hg_rebuilding_plan_2024",
    str_detect(
      context,
      regex("proportion-at-age|number aged|weight-at-age|length-at-age|biological|spawn index|catch|model", ignore_case = TRUE)
    )
  ) %>%
  mutate(
    source_document = title,
    source_table = paste(item_type, item_number),
    extraction_method = "pdftotext caption catalog filtered by biological keywords",
    extraction_notes = "Caption/provenance audit for HG rebuilding-plan biological figures/tables; not a numeric input table."
  )

source_status <- source_status %>%
  mutate(
    keyword_windows = map_int(source_id, ~ sum(keyword_windows$source_id == .x)),
    table_figure_captions = map_int(source_id, ~ sum(caption_catalog$source_id == .x))
  )

write_csv(source_status, file.path(extract_dir, "dfo_newer_public_pdf_status.csv"))
write_csv(keyword_windows, file.path(extract_dir, "dfo_newer_public_pdf_keyword_windows.csv"))
write_csv(caption_catalog, file.path(extract_dir, "dfo_newer_public_pdf_table_figure_caption_catalog.csv"))
write_csv(ifmp_2024_table_3_1, file.path(extract_dir, "dfo_ifmp_2024_2025_table_3_1_projected_biomass_age_props.csv"))
write_csv(sr_table_1, file.path(extract_dir, "dfo_sr_2025_005_table_1_input_data_windows.csv"))
write_csv(sr_table_2, file.path(extract_dir, "dfo_sr_2025_005_table_2_major_catch_2015_2024.csv"))
write_csv(sr_table_3, file.path(extract_dir, "dfo_sr_2025_005_table_3_hg_spawn_2015_2024.csv"))
write_csv(sr_table_7, file.path(extract_dir, "dfo_sr_2025_005_table_7_hg_key_parameters.csv"))
write_csv(sr_table_11, file.path(extract_dir, "dfo_sr_2025_005_table_11_hg_recruitment_2015_2024.csv"))
write_csv(sr_table_15, file.path(extract_dir, "dfo_sr_2025_005_table_15_hg_spawning_biomass_depletion_2015_2024.csv"))
write_csv(sr_table_19, file.path(extract_dir, "dfo_sr_2025_005_table_19_hg_reference_points.csv"))
write_csv(rebuilding_biology_caption_catalog, file.path(extract_dir, "dfo_hg_rebuilding_plan_biology_caption_catalog.csv"))

summary_lines <- c(
  "# Newer DFO Public PDF Extraction",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "This report records post-2018 public DFO PDF extraction relevant to a Doherty-style HG data workflow. The outputs are public-summary and audit products; exact SCA/SISCAH input files and effective-sample-size metadata are still not present.",
  "",
  "## Source Fields",
  "",
  "Clean table extracts retain `source_document`, `source_table`, `source_url`, `extraction_method`, and `extraction_notes`. Source status and keyword/caption audits retain `source_id`, `title`, and `source_url`. The tracked source map is `docs/doherty-style-hg-source-provenance.md`.",
  "",
  "## Source Status",
  "",
  knitr::kable(
    source_status %>%
      select(source_id, title, pdf_is_valid, plain_text_status, layout_text_status, pdf_bytes, plain_text_lines, layout_text_lines, keyword_windows, table_figure_captions),
    format = "pipe"
  ),
  "",
  "## Clean Table Extracts",
  "",
  paste0("- DFO 2025/005 Table 1 input data windows rows: `", nrow(sr_table_1), "`."),
  paste0("- DFO 2025/005 Table 2 major catch rows: `", nrow(sr_table_2), "`."),
  paste0("- DFO 2025/005 Table 3 HG spawn/proportion rows: `", nrow(sr_table_3), "`."),
  paste0("- DFO 2025/005 Table 7 HG key-parameter rows: `", nrow(sr_table_7), "`."),
  paste0("- DFO 2025/005 Table 11 HG recruitment rows: `", nrow(sr_table_11), "`."),
  paste0("- DFO 2025/005 Table 15 HG biomass/depletion rows: `", nrow(sr_table_15), "`."),
  paste0("- DFO 2025/005 Table 19 HG reference-point rows: `", nrow(sr_table_19), "`."),
  paste0("- 2024/2025 IFMP Appendix 3 Table 3.1 projected biomass/age rows: `", nrow(ifmp_2024_table_3_1), "`."),
  "",
  "## Interpretation",
  "",
  "- DFO 2025/005 confirms that the 2024 major-stock SCA input windows run through 2024 for catch, spawn index, age composition, and weight-at-age.",
  "- The Science Response provides useful public summaries for HG recent catch, spawn, SCA parameters, recruitment, biomass/depletion, reference points, and projected broad age composition.",
  "- The HG rebuilding plan provides figure captions confirming major and sub-stock age/length/weight summaries and the imputation rule for missing weight/length-at-age values, but it does not provide machine-readable fish-level or annual age-length tables.",
  "- The 2025/2026 IFMP catalogue page confirms a public PDF, but command-line requests to the direct PDF currently return an HTML archive page. Treat it as a public-source access block, not a biological-data absence.",
  "",
  "## Files",
  "",
  "- `Output/diagnostics/dfo_newer_public_pdf_extract/dfo_newer_public_pdf_status.csv`",
  "- `Output/diagnostics/dfo_newer_public_pdf_extract/dfo_newer_public_pdf_keyword_windows.csv`",
  "- `Output/diagnostics/dfo_newer_public_pdf_extract/dfo_newer_public_pdf_table_figure_caption_catalog.csv`",
  "- `Output/diagnostics/dfo_newer_public_pdf_extract/dfo_sr_2025_005_table_1_input_data_windows.csv`",
  "- `Output/diagnostics/dfo_newer_public_pdf_extract/dfo_sr_2025_005_table_2_major_catch_2015_2024.csv`",
  "- `Output/diagnostics/dfo_newer_public_pdf_extract/dfo_sr_2025_005_table_3_hg_spawn_2015_2024.csv`",
  "- `Output/diagnostics/dfo_newer_public_pdf_extract/dfo_sr_2025_005_table_7_hg_key_parameters.csv`",
  "- `Output/diagnostics/dfo_newer_public_pdf_extract/dfo_sr_2025_005_table_11_hg_recruitment_2015_2024.csv`",
  "- `Output/diagnostics/dfo_newer_public_pdf_extract/dfo_sr_2025_005_table_15_hg_spawning_biomass_depletion_2015_2024.csv`",
  "- `Output/diagnostics/dfo_newer_public_pdf_extract/dfo_sr_2025_005_table_19_hg_reference_points.csv`",
  "- `Output/diagnostics/dfo_newer_public_pdf_extract/dfo_ifmp_2024_2025_table_3_1_projected_biomass_age_props.csv`",
  "- `Output/diagnostics/dfo_newer_public_pdf_extract/dfo_hg_rebuilding_plan_biology_caption_catalog.csv`"
)

writeLines(summary_lines, file.path(extract_dir, "dfo_newer_public_pdf_extract_summary.md"))

cat("Saved newer DFO public PDF extraction outputs:\n")
cat("  Output/diagnostics/dfo_newer_public_pdf_extract/dfo_newer_public_pdf_extract_summary.md\n")
cat("  Output/diagnostics/dfo_newer_public_pdf_extract/dfo_sr_2025_005_table_3_hg_spawn_2015_2024.csv\n")
