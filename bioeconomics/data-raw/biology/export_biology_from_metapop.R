# data-raw/biology/export_biology_from_metapop.R
#
# ONE-DIRECTIONAL FIREWALL: This script reads READ-ONLY from the sibling
# metapopulation repo and writes ONLY under herring-bioeconomics/data-raw/biology/.
# It must never create, modify, or git-add anything in stier-2027-herring-metapopulation.
#
# Source: m1_stier_11_total_biomass_by_year.csv  (promoted baseline model)
#         report_set == "all_11"  →  HG total across all 11 sections
# Output: data-raw/biology/m1_stier_11_biology_total_by_year.csv
#         data-raw/biology/PROVENANCE.yaml
#         data-raw/biology/MANIFEST.sha256
#
# Run from herring-bioeconomics project root:
#   Rscript --vanilla data-raw/biology/export_biology_from_metapop.R

library(here)
library(readr)
library(digest)

# ---------------------------------------------------------------------------
# 1.  Paths — READ-ONLY source, WRITE-ONLY destination
# ---------------------------------------------------------------------------
metapop_root <- path.expand("~/stier-2027-herring-metapopulation")
ledger_path  <- file.path(metapop_root, "Output", "diagnostics",
                          "model_decision_ledger.md")
source_path  <- file.path(metapop_root, "Output", "diagnostics",
                          "m1_stier_11_total_biomass_by_year.csv")
dest_dir     <- here::here("data-raw", "biology")
dest_csv     <- file.path(dest_dir, "m1_stier_11_biology_total_by_year.csv")
dest_prov    <- file.path(dest_dir, "PROVENANCE.yaml")
dest_manifest <- file.path(dest_dir, "MANIFEST.sha256")

# ---------------------------------------------------------------------------
# 2.  Assert ledger names m1_stier_11 as promoted_baseline
# ---------------------------------------------------------------------------
stopifnot(
  "model_decision_ledger.md not found in metapop repo" =
    file.exists(ledger_path)
)
ledger_text <- paste(readLines(ledger_path), collapse = "\n")
stopifnot(
  "m1_stier_11 not found as promoted_baseline in model_decision_ledger.md" =
    grepl("m1_stier_11.*promoted_baseline", ledger_text)
)
message("Ledger check PASSED: m1_stier_11 is promoted_baseline")

# ---------------------------------------------------------------------------
# 3.  Read source file (read-only), assert report_set == "all_11" exists
# ---------------------------------------------------------------------------
stopifnot(
  "source file not found in metapop repo" =
    file.exists(source_path)
)
src <- readr::read_csv(source_path, show_col_types = FALSE)
message(sprintf("Source rows: %d  cols: %s",
                nrow(src), paste(names(src), collapse = ", ")))

stopifnot(
  "report_set column not found in source file" =
    "report_set" %in% names(src),
  "report_set == 'all_11' rows not found in source file" =
    any(src$report_set == "all_11")
)
n_all11 <- sum(src$report_set == "all_11")
message(sprintf("  report_set='all_11' rows: %d  (year range: %d–%d)",
                n_all11,
                min(src$year[src$report_set == "all_11"]),
                max(src$year[src$report_set == "all_11"])))

# ---------------------------------------------------------------------------
# 4.  Compute sha256 of the source file (before any transformation)
# ---------------------------------------------------------------------------
sha256_hex <- digest::digest(file = source_path, algo = "sha256")
message(sprintf("sha256: %s", sha256_hex))

# ---------------------------------------------------------------------------
# 5.  Copy source CSV as-is to dest (frozen snapshot)
#     All column filtering (report_set == "all_11") is done at build_L1()
#     load time.  Copying verbatim preserves provenance integrity vs sha256.
# ---------------------------------------------------------------------------
if (!dir.exists(dest_dir)) dir.create(dest_dir, recursive = TRUE)
file.copy(source_path, dest_csv, overwrite = TRUE)
message(sprintf("Snapshot written to: %s", dest_csv))

# ---------------------------------------------------------------------------
# 6.  Write PROVENANCE.yaml
#     Format: key: value  (one key per line, no block scalars)
#     Keys must be compatible with the read_provenance() simple parser in
#     layer_L1_biology.R.
# ---------------------------------------------------------------------------
prov_lines <- c(
  sprintf("source_repo: %s", metapop_root),
  sprintf("model_branch: m1_stier_11 (promoted baseline)"),
  sprintf("source_file: Output/diagnostics/m1_stier_11_total_biomass_by_year.csv"),
  sprintf("sha256: %s", sha256_hex),
  sprintf("exported_utc: %s", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  paste0("biomass_note: posterior median of the HG total (all-11-section report set) ",
         "from the promoted m1_stier_11 baseline; faithful model import, not a section-sum")
)
writeLines(prov_lines, dest_prov)
message(sprintf("PROVENANCE.yaml written to: %s", dest_prov))

# ---------------------------------------------------------------------------
# 7.  (Re)generate MANIFEST.sha256 covering the snapshot CSV + PROVENANCE.yaml
#     This is done in R so re-export can never leave a stale manifest.
# ---------------------------------------------------------------------------
manifest_files <- c(dest_csv, dest_prov)
manifest_lines <- vapply(manifest_files, function(f) {
  paste(digest::digest(file = f, algo = "sha256"), basename(f))
}, character(1L))
writeLines(manifest_lines, dest_manifest)
message(sprintf("MANIFEST.sha256 written to: %s", dest_manifest))

message("Export complete.")
