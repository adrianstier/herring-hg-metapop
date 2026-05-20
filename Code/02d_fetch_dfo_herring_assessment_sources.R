# ============================================================================
# 02d_fetch_dfo_herring_assessment_sources.R
# Fetch public DFO Pacific Herring assessment source documents used by the
# Doherty-style Haida Gwaii data acquisition workflow.
#
# The default download directory is under Output/diagnostics so downloaded PDFs
# and text extracts stay out of git. Set DFO_PUBLIC_SOURCE_DIR to write them
# elsewhere.
# ============================================================================

library(tidyverse)
library(here)
library(knitr)

proj_dir <- here::here()
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
download_dir <- Sys.getenv(
  "DFO_PUBLIC_SOURCE_DIR",
  unset = file.path(diag_dir, "dfo_assessment_public_sources")
)

dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(download_dir, showWarnings = FALSE, recursive = TRUE)

source_registry <- tribble(
  ~source_id, ~source_type, ~title, ~url, ~local_file, ~role,
  "dfo_stock_assessment_landing", "webpage",
  "DFO Pacific herring stock assessments",
  "https://www.pac.dfo-mpo.gc.ca/science/species-especes/herring-hareng/stock-assessments-evaluations-stocks-eng.html",
  NA_character_,
  "Public entry point for assessment areas, biological sampling surveys, spawn surveys, model history, and open spawn-index links.",
  "dfo_ifmp_summary_2025_2026", "webpage",
  "Pacific herring 2025-2026 IFMP summary",
  "https://www.pac.dfo-mpo.gc.ca/fm-gp/mplans/herring-hareng-ifmp-pgip-sm-eng.html",
  NA_character_,
  "Current public management-plan summary and pointer to stock-assessment context.",
  "dfo_ifmp_catalog_2025_2026", "webpage",
  "Government of Canada Publications catalogue record for the 2025/2026 Pacific herring IFMP",
  "https://publications.gc.ca/site/eng/9.958396/publication.html",
  NA_character_,
  "Catalogue record for the current full IFMP; use this page if direct command-line PDF download returns an archived landing page.",
  "dfo_ifmp_full_2025_2026", "pdf",
  "Pacific Region Integrated Fisheries Management Plan, 2025/2026 Pacific herring",
  "https://publications.gc.ca/collections/collection_2026/mpo-dfo/Fs143-3-23-2600-eng.pdf",
  "dfo_ifmp_full_2025_2026.pdf",
  "Current full IFMP; Appendix 3 summarizes major-stock model inputs and HG forecast/status.",
  "dfo_science_response_2025_005", "pdf",
  "DFO CSAS Science Response 2025/005, Pacific herring status in 2024 and forecast for 2025",
  "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41290963.pdf",
  "dfo_science_response_2025_005.pdf",
  "Current public science response for HG, PRD, CC, and WCVI; includes SCA input data windows and HG stock-status summary tables through 2024.",
  "dfo_herring_scad_2018_028", "pdf",
  "DFO CSAS Research Document 2018/028, Pacific herring stock assessment data and model",
  "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/40944670.pdf",
  "dfo_herring_scad_2018_028.pdf",
  "Public assessment report with Appendix B input-data tables, including HG number-at-age and weight-at-age.",
  "dfo_herring_ifmp_2024_2025", "pdf",
  "Pacific Region Integrated Fisheries Management Plan, 2024/2025 Pacific herring",
  "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41274672.pdf",
  "dfo_herring_ifmp_2024_2025.pdf",
  "Prior full IFMP; useful comparison for Appendix 3 wording and data-window changes.",
  "dfo_hg_rebuilding_plan_2024", "pdf",
  "Haida Gwaii Pacific Herring Rebuilding Plan",
  "https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/41284161.pdf",
  "dfo_hg_rebuilding_plan_2024.pdf",
  "HG-specific rebuilding context, sub-stock structure, ecosystem attributes, and management objectives."
)

is_pdf_file <- function(path) {
  if (!file.exists(path) || file.info(path)$size == 0) {
    return(FALSE)
  }
  header <- readBin(path, what = "raw", n = 4)
  identical(rawToChar(header), "%PDF")
}

download_pdf <- function(url, dest) {
  if (is_pdf_file(dest)) {
    return("already_present")
  }

  had_non_pdf_dest <- file.exists(dest) && file.info(dest)$size > 0
  tmp_dest <- tempfile(fileext = ".pdf")

  tryCatch(
    {
      download.file(url, destfile = tmp_dest, mode = "wb", quiet = TRUE)
      if (!file.exists(tmp_dest) || file.info(tmp_dest)$size == 0) {
        return("download_empty")
      }
      if (!is_pdf_file(tmp_dest)) {
        if (had_non_pdf_dest) {
          return("existing_not_pdf_download_not_pdf_html_or_landing")
        }
        return("download_not_pdf_html_or_landing")
      }
      file.copy(tmp_dest, dest, overwrite = TRUE)
      if (had_non_pdf_dest) {
        "redownloaded_replaced_non_pdf"
      } else {
        "downloaded"
      }
    },
    error = function(e) paste0("download_failed: ", conditionMessage(e))
  )
}

extract_pdf_text <- function(pdf_path, text_path) {
  pdftotext <- Sys.which("pdftotext")
  if (!nzchar(pdftotext)) {
    return("pdftotext_not_found")
  }
  if (!file.exists(pdf_path) || file.info(pdf_path)$size == 0) {
    return("pdf_missing")
  }
  if (!is_pdf_file(pdf_path)) {
    return("pdf_path_not_pdf")
  }
  result <- system2(pdftotext, c(pdf_path, text_path), stdout = TRUE, stderr = TRUE)
  status <- attr(result, "status")
  if (!is.null(status) && status != 0) {
    return(paste0("extract_failed: ", paste(result, collapse = " ")))
  }
  if (!file.exists(text_path) || file.info(text_path)$size == 0) {
    return("extract_empty")
  }
  "text_extracted"
}

pdf_rows <- source_registry %>%
  filter(source_type == "pdf") %>%
  mutate(
    pdf_path = file.path(download_dir, local_file),
    text_file = str_replace(local_file, "\\.pdf$", ".txt"),
    text_path = file.path(download_dir, text_file)
  )

pdf_results <- pdf_rows %>%
  mutate(
    download_status = map2_chr(url, pdf_path, download_pdf),
    text_status = map2_chr(pdf_path, text_path, extract_pdf_text),
    pdf_bytes = if_else(file.exists(pdf_path), file.info(pdf_path)$size, NA_real_),
    text_bytes = if_else(file.exists(text_path), file.info(text_path)$size, NA_real_)
  )

keyword_hits <- pdf_results %>%
  mutate(
    text = map(text_path, ~ if (file.exists(.x)) readLines(.x, warn = FALSE) else character()),
    n_age_composition_hits = map_int(text, ~ sum(str_detect(str_to_lower(.x), "age composition|proportion-at-age|number-at-age"))),
    n_weight_at_age_hits = map_int(text, ~ sum(str_detect(str_to_lower(.x), "weight-at-age"))),
    n_haida_gwaii_hits = map_int(text, ~ sum(str_detect(str_to_lower(.x), "haida gwaii|\\bhg\\b"))),
    n_siscah_hits = map_int(text, ~ sum(str_detect(str_to_lower(.x), "siscah|statistical catch"))),
    n_appendix_b_hits = map_int(text, ~ sum(str_detect(str_to_lower(.x), "appendix b|table b\\.")))
  ) %>%
  select(
    source_id, download_status, text_status, pdf_bytes, text_bytes,
    n_age_composition_hits, n_weight_at_age_hits, n_haida_gwaii_hits,
    n_siscah_hits, n_appendix_b_hits, text_path
  )

registry_out <- source_registry %>%
  left_join(keyword_hits, by = "source_id")

write_csv(registry_out, file.path(diag_dir, "dfo_assessment_public_source_registry.csv"))

lines <- c(
  "# DFO Herring Public Assessment Sources",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  paste0("Download directory: `", download_dir, "`"),
  "",
  "This is the public-source acquisition layer for the Doherty-style HG data workflow. It fetches DFO public PDFs and extracts text so the next step can target Appendix/input tables instead of starting from scratch.",
  "",
  "Tracked source map: `docs/doherty-style-hg-source-provenance.md`. This generated registry records public source URLs, local downloaded filenames, source roles, and fetch/text-extraction status.",
  "",
  "## Source Registry",
  "",
  knitr::kable(
    registry_out %>%
      mutate(
        local_file = coalesce(local_file, ""),
        download_status = coalesce(download_status, ""),
        text_status = coalesce(text_status, ""),
        text_path = coalesce(text_path, "")
      ) %>%
      select(
        source_id, source_type, title, url, local_file, role,
        download_status, text_status, n_age_composition_hits,
        n_weight_at_age_hits, n_haida_gwaii_hits, n_appendix_b_hits
      ),
    format = "pipe"
  ),
  "",
  "## Next Extraction Targets",
  "",
  "- Use `dfo_herring_scad_2018_028.txt` to extract Appendix B HG number-at-age and weight-at-age tables as the first public test case.",
  "- Use `dfo_science_response_2025_005.txt` and `Code/02f_extract_newer_dfo_public_pdfs.R` for current public SCA summary tables through 2024.",
  "- Use the 2025/2026 IFMP summary/catalogue record to verify the current assessment data window and HG forecast/status context; if the direct PDF download returns an HTML landing page, save the PDF manually from the Government Publications page or request the alternate format.",
  "- Keep exact table extraction separate from model fitting; do not build an age-structured branch until extracted tables pass schema and provenance checks."
)

writeLines(lines, file.path(diag_dir, "dfo_assessment_public_source_inventory.md"))

cat("Saved DFO public source inventory:\n")
cat("  Output/diagnostics/dfo_assessment_public_source_registry.csv\n")
cat("  Output/diagnostics/dfo_assessment_public_source_inventory.md\n")
