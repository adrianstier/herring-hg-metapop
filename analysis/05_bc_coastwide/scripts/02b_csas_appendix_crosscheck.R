# ============================================================================
# 02b_csas_appendix_crosscheck.R — Cross-check Open Data catch against CSAS
# analysis/05_bc_coastwide
#
# Input:  Data/raw/dfo-catch/csas-appendix-pdfs/  (downloaded via Code/02d)
# Output: Data/processed/bc_catch_csas_appendix.csv
#         Output/diagnostics/bc_catch_csas_concordance.md
#
# CSAS Stock Assessment Reports publish year × stock-area × gear × tonnes
# in Appendix tables. This script OCR-extracts those appendices via the
# existing pipeline at Code/02f_extract_newer_dfo_public_pdfs.R, then
# compares against the Open Data catch panel.
#
# Pass criterion: 95% of joint stock-area-year rows within 2% relative
# difference, max relative difference 10%.
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(here)
})

source(here::here("R", "00_setup.R"))
source(here::here("Code", "02f_extract_newer_dfo_public_pdfs.R"))
# ^ supplies extract_catch_table_from_pdf(); reuse the existing parser

csas_dir <- here::here("Data", "raw", "dfo-catch", "csas-appendix-pdfs")
dir.create(csas_dir, showWarnings = FALSE, recursive = TRUE)

# CSAS SAR PDFs for the most recent 5 years per stock area. URLs are recorded
# in Code/02d_fetch_dfo_herring_assessment_sources.R. The first run downloads
# any missing PDFs; subsequent runs use the cache.
pdf_manifest <- tibble::tribble(
  ~stock_area, ~report_year, ~url,
  "HG",  2025L, "https://waves-vagues.dfo-mpo.gc.ca/Library/41139013.pdf",
  "PRD", 2024L, "https://waves-vagues.dfo-mpo.gc.ca/Library/41099012.pdf",
  "CC",  2024L, "https://waves-vagues.dfo-mpo.gc.ca/Library/41099013.pdf",
  "SoG", 2024L, "https://waves-vagues.dfo-mpo.gc.ca/Library/41099014.pdf",
  "WCVI",2024L, "https://waves-vagues.dfo-mpo.gc.ca/Library/41099015.pdf"
)
# NOTE: URLs above are placeholders representing the typical DFO library
# pattern. On first run, browse https://waves-vagues.dfo-mpo.gc.ca/ for the
# current SAR PDFs per stock area and update this manifest.

all_csas <- list()
for (i in seq_len(nrow(pdf_manifest))) {
  row <- pdf_manifest[i, ]
  local_pdf <- file.path(csas_dir,
                         sprintf("csas_%s_%d.pdf", row$stock_area, row$report_year))
  if (!file.exists(local_pdf)) {
    cat("Downloading", row$url, "...\n")
    download.file(row$url, local_pdf, mode = "wb", quiet = TRUE)
  }
  cat("Parsing", local_pdf, "...\n")
  extracted <- tryCatch(
    extract_catch_table_from_pdf(local_pdf, stock_area = row$stock_area),
    error = function(e) {
      warning("Parse failed for ", local_pdf, ": ", conditionMessage(e))
      NULL
    }
  )
  if (!is.null(extracted)) all_csas[[i]] <- extracted
}

csas <- bind_rows(all_csas)
stopifnot(nrow(csas) > 0)

out_path <- here::here("Data", "processed", "bc_catch_csas_appendix.csv")
write_csv(csas, out_path)
cat("Wrote", nrow(csas), "rows to", out_path, "\n")

# Build concordance report
od <- read_csv(here::here("Data", "processed", "bc_catch_by_section_year_gear.csv"),
               show_col_types = FALSE)
od_sum <- od |> group_by(year, stock_area) |>
  summarise(od_t = sum(catch_tonnes, na.rm = TRUE), .groups = "drop")
csas_sum <- csas |> group_by(year, stock_area) |>
  summarise(csas_t = sum(catch_tonnes, na.rm = TRUE), .groups = "drop")
comp <- inner_join(od_sum, csas_sum, by = c("year", "stock_area")) |>
  mutate(diff_t = od_t - csas_t,
         rel_diff = if_else(csas_t > 0, abs(diff_t) / csas_t, NA_real_))

diag_path <- here::here("Output", "diagnostics", "bc_catch_csas_concordance.md")
dir.create(dirname(diag_path), showWarnings = FALSE, recursive = TRUE)
sink(diag_path)
cat("# BC Catch Concordance: Open Data vs CSAS Appendices\n\n")
cat("Generated:", format(Sys.time()), "\n\n")
cat("## Summary\n\n")
cat("- Joint rows:", nrow(comp), "\n")
cat("- Within 2%:", sum(comp$rel_diff <= 0.02, na.rm = TRUE),
    sprintf("(%.1f%%)\n", 100 * mean(comp$rel_diff <= 0.02, na.rm = TRUE)))
cat("- Max relative diff:", sprintf("%.2f%%\n", 100 * max(comp$rel_diff, na.rm = TRUE)))
cat("\n## Detail\n\n")
print(knitr::kable(comp))
sink()
cat("Wrote concordance report to", diag_path, "\n")
