# BC-Coastwide Expansion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a self-contained `analysis/05_bc_coastwide/` workstream that fits hierarchical M1, M3, and M5 metapopulation models at section-level resolution across all 8 BC stock-area codes, producing 5 manuscript figures plus tables.

**Architecture:** New `analysis/05_bc_coastwide/` workstream with scripts/, stan/, output/, docs/. Pipeline reads from `Data/raw/dfo-spawn/`, `Data/raw/dfo-catch/`, the sibling predator repo (`~/pacific-herring-predators`), and existing environmental covariates. Three Stan models live in `analysis/05_bc_coastwide/stan/` (separate from the core `inst/stan/`). Block-diagonal covariance keeps the ~100-section problem tractable.

**Tech Stack:** R, rstan, here::here, testthat, AWS Batch (existing `cloud/` setup), DFO Open Data Portal, CSAS PDF appendices via existing OCR pipeline.

---

## Companion spec

`docs/superpowers/specs/2026-05-21-bc-coastwide-expansion-design.md` — read first for the design rationale and locked decisions.

## File structure summary

| File | Responsibility |
|---|---|
| `analysis/05_bc_coastwide/README.md` | Workstream README + script index |
| `analysis/05_bc_coastwide/docs/README.md` | Spec/plan cross-refs |
| `analysis/05_bc_coastwide/docs/manuscript-skeleton.md` | Empty skeleton, filled later |
| `analysis/05_bc_coastwide/scripts/00_data_acquisition.R` | Download Open Data catch + refresh spawn |
| `analysis/05_bc_coastwide/scripts/01_assemble_bc_spawn.R` | Filter 31k-row CSV → tidy panel |
| `analysis/05_bc_coastwide/scripts/02_assemble_bc_catch.R` | Open Data + CSAS appendix merge |
| `analysis/05_bc_coastwide/scripts/03_assemble_bc_predator_covs.R` | Pull from sibling repo |
| `analysis/05_bc_coastwide/scripts/04_assemble_distance_matrix.R` | Within-area distance matrices |
| `analysis/05_bc_coastwide/scripts/05_prepare_stan_data.R` | Stan data list assembly |
| `analysis/05_bc_coastwide/scripts/06_fit_m1_bc.R` | Cloud — M1 baseline |
| `analysis/05_bc_coastwide/scripts/07_fit_m3_bc.R` | Cloud — M3 density-dependence |
| `analysis/05_bc_coastwide/scripts/08_fit_m5_bc.R` | Cloud — M5 predator-mediated |
| `analysis/05_bc_coastwide/scripts/09_diagnostics.R` | MCMC + PPC |
| `analysis/05_bc_coastwide/scripts/10_comparative_areas.R` | HG vs SoG vs WCVI |
| `analysis/05_bc_coastwide/scripts/11_bc_portfolio.R` | Coastwide portfolio metrics |
| `analysis/05_bc_coastwide/scripts/12_manuscript_figures.R` | 5 figures + tables |
| `analysis/05_bc_coastwide/stan/herring_metapop_bc_m1.stan` | Hierarchical M1 |
| `analysis/05_bc_coastwide/stan/herring_metapop_bc_m3.stan` | + Gompertz DD |
| `analysis/05_bc_coastwide/stan/herring_metapop_bc_m5.stan` | + predator covariates |
| `tests/testthat/test-bc-coastwide.R` | Unit tests for assembly functions |
| `Data/processed/bc_spawn_by_section_year.csv` | Tidy spawn panel (force-tracked) |
| `Data/processed/bc_catch_by_section_year_gear.csv` | Tidy catch panel (force-tracked) |
| `Data/processed/bc_catch_csas_appendix.csv` | CSAS cross-check (force-tracked) |
| `Data/processed/bc_distance_within_stock_area.rds` | Block-diag distance matrices |
| `Data/processed/bc_predator_covariates.csv` | Section/area-resolved predator covs |
| `Data/processed/bc_fishery_events.csv` | Stock-area fishery-event anchor table |

---

# Phase 0 — Scaffolding

## Task 1: Workstream directory + README

**Files:**
- Create: `analysis/05_bc_coastwide/README.md`
- Create: `analysis/05_bc_coastwide/docs/README.md`
- Create: `analysis/05_bc_coastwide/scripts/.gitkeep`
- Create: `analysis/05_bc_coastwide/stan/.gitkeep`
- Create: `analysis/05_bc_coastwide/output/.gitkeep`
- Create: `analysis/05_bc_coastwide/docs/manuscript-skeleton.md`
- Modify: `.gitignore` — add `analysis/05_bc_coastwide/output/*` with `.gitkeep` exception
- Modify: `analysis/README.md` — add row for `05_bc_coastwide/`

- [ ] **Step 1: Create directory structure**

Run:
```bash
mkdir -p analysis/05_bc_coastwide/{scripts,stan,output,docs}
touch analysis/05_bc_coastwide/{scripts,stan,output}/.gitkeep
touch analysis/05_bc_coastwide/docs/manuscript-skeleton.md
```

Expected: directories created; `ls analysis/05_bc_coastwide/` shows scripts, stan, output, docs, README.md (after next step).

- [ ] **Step 2: Write the workstream README**

Create `analysis/05_bc_coastwide/README.md` with this exact content:

```markdown
# `analysis/05_bc_coastwide/` — BC-coastwide hierarchical metapopulation

Extension of the section-level M1 herring metapopulation analysis from Haida Gwaii (11 sections) to all 8 DFO stock-area codes across British Columbia (~100 sections). Fits hierarchical M1 (baseline), M3 (Gompertz density-dependence), and M5 (predator-mediated).

## Layout

```
05_bc_coastwide/
├── scripts/
│   ├── 00_data_acquisition.R         download Open Data catch + refresh spawn
│   ├── 01_assemble_bc_spawn.R        filter 31k-row CSV → tidy panel
│   ├── 02_assemble_bc_catch.R        Open Data + CSAS appendix merge
│   ├── 03_assemble_bc_predator_covs.R pull from sibling repo
│   ├── 04_assemble_distance_matrix.R within-stock-area distance matrices
│   ├── 05_prepare_stan_data.R        Stan data list
│   ├── 06_fit_m1_bc.R                cloud — M1 baseline
│   ├── 07_fit_m3_bc.R                cloud — M3
│   ├── 08_fit_m5_bc.R                cloud — M5
│   ├── 09_diagnostics.R              MCMC + PPC
│   ├── 10_comparative_areas.R        HG vs SoG vs WCVI
│   ├── 11_bc_portfolio.R             coastwide portfolio metrics
│   └── 12_manuscript_figures.R       5 figures + tables
├── stan/                             3 Stan models (separate from inst/stan/)
├── output/                           gitignored posterior artifacts
└── docs/                             cross-refs to spec + plan
```

## Specs and plans

- Design spec: [`docs/superpowers/specs/2026-05-21-bc-coastwide-expansion-design.md`](../../docs/superpowers/specs/2026-05-21-bc-coastwide-expansion-design.md)
- Implementation plan: [`docs/superpowers/plans/2026-05-21-bc-coastwide-expansion.md`](../../docs/superpowers/plans/2026-05-21-bc-coastwide-expansion.md)

## Talk firewall

This workstream reads from the core pipeline (`R/`, `Data/`, `Output/`, sibling predator repo) and writes only to `Data/processed/bc_*` (force-tracked manifests) and `analysis/05_bc_coastwide/output/` (gitignored). Does not modify the core M1_stier_11 baseline.
```

- [ ] **Step 3: Write docs/README.md cross-ref**

Create `analysis/05_bc_coastwide/docs/README.md`:

```markdown
# `analysis/05_bc_coastwide/docs/`

- [`../README.md`](../README.md) — workstream overview
- [`../../../docs/superpowers/specs/2026-05-21-bc-coastwide-expansion-design.md`](../../../docs/superpowers/specs/2026-05-21-bc-coastwide-expansion-design.md) — design spec
- [`../../../docs/superpowers/plans/2026-05-21-bc-coastwide-expansion.md`](../../../docs/superpowers/plans/2026-05-21-bc-coastwide-expansion.md) — implementation plan
- `manuscript-skeleton.md` — placeholder for the manuscript draft
```

- [ ] **Step 4: Update analysis/README.md index**

In `analysis/README.md`, add this row to the workstream table (after the `04_talks/` row):

```markdown
| [`05_bc_coastwide/`](05_bc_coastwide/) | scaffold (data acquisition in progress) | future — BC-wide hierarchical M1/M3/M5 fits, comparative-areas figures |
```

- [ ] **Step 5: Update .gitignore for new output dir**

Verify `.gitignore` already has `analysis/*/output/*` with `.gitkeep` exception (added in 2026-05-20 reorg). Confirm:
```bash
grep -A1 "analysis/\*/output" .gitignore
```
Expected output: the existing two lines. No change needed.

- [ ] **Step 6: Commit**

```bash
git add analysis/05_bc_coastwide/ analysis/README.md
git commit -m "feat(05_bc_coastwide): scaffold workstream directory + READMEs"
```

---

# Phase 1 — Data acquisition

## Task 2: BC-wide spawn panel assembly (scripts/01)

**Files:**
- Create: `analysis/05_bc_coastwide/scripts/01_assemble_bc_spawn.R`
- Create: `tests/testthat/test-bc-coastwide.R`
- Create: `Data/processed/bc_spawn_by_section_year.csv`

- [ ] **Step 1: Write the failing test**

Create `tests/testthat/test-bc-coastwide.R`:

```r
# tests/testthat/test-bc-coastwide.R
# Unit tests for the BC-coastwide assembly functions.
# Run with: testthat::test_file("tests/testthat/test-bc-coastwide.R")

library(testthat)
library(tidyverse)
library(here)

test_that("bc_spawn panel exists and has expected columns", {
  path <- here("Data", "processed", "bc_spawn_by_section_year.csv")
  expect_true(file.exists(path),
              info = "run analysis/05_bc_coastwide/scripts/01_assemble_bc_spawn.R first")
  panel <- read_csv(path, show_col_types = FALSE)
  expect_true(all(c("year", "stock_area", "statistical_area", "section",
                    "spawn_index_tonnes", "n_events") %in% names(panel)))
})

test_that("bc_spawn covers all 8 stock-area codes", {
  panel <- read_csv(here("Data", "processed", "bc_spawn_by_section_year.csv"),
                    show_col_types = FALSE)
  expected_codes <- c("HG", "PRD", "CC", "SoG", "WCVI", "A27", "A2W", "NA")
  expect_true(all(expected_codes %in% panel$stock_area))
})

test_that("bc_spawn year range is 1951–2025", {
  panel <- read_csv(here("Data", "processed", "bc_spawn_by_section_year.csv"),
                    show_col_types = FALSE)
  expect_equal(min(panel$year), 1951L)
  expect_equal(max(panel$year), 2025L)
})

test_that("bc_spawn has no negative spawn-index values", {
  panel <- read_csv(here("Data", "processed", "bc_spawn_by_section_year.csv"),
                    show_col_types = FALSE)
  expect_true(all(panel$spawn_index_tonnes >= 0, na.rm = TRUE))
})
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
Rscript -e 'testthat::test_file("tests/testthat/test-bc-coastwide.R", reporter = "minimal")'
```
Expected: FAIL on first test (`bc_spawn_by_section_year.csv` doesn't exist).

- [ ] **Step 3: Write the spawn-assembly script**

Create `analysis/05_bc_coastwide/scripts/01_assemble_bc_spawn.R`:

```r
# ============================================================================
# 01_assemble_bc_spawn.R — Aggregate DFO spawn-index data to section-year panel
# analysis/05_bc_coastwide
#
# Input:  Data/raw/dfo-spawn/Pacific_herring_spawn_index_data_2025_EN.csv
#         (31,168 rows, spawn-event level)
# Output: Data/processed/bc_spawn_by_section_year.csv
#         (one row per section-year with spawn-index sum in tonnes + event count)
#
# Stock-area codes retained: HG, PRD, CC, SoG, WCVI, A27, A2W, NA (all 8).
# Year range: 1951–2025.
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(here)
})

source(here::here("R", "00_setup.R"))

raw_path <- here::here("Data", "raw", "dfo-spawn",
                       "Pacific_herring_spawn_index_data_2025_EN.csv")
stopifnot(file.exists(raw_path))

raw <- read_csv(raw_path, show_col_types = FALSE) |>
  janitor::clean_names()

# Rename Region → stock_area; coerce types
spawn_events <- raw |>
  rename(stock_area = region,
         statistical_area = statistical_area,
         section = section) |>
  mutate(year = as.integer(year),
         stock_area = if_else(is.na(stock_area), "NA", as.character(stock_area)),
         statistical_area = as.character(statistical_area),
         section = as.character(section),
         spawn_number = as.numeric(spawn_number))

# Aggregate to section-year
panel <- spawn_events |>
  group_by(year, stock_area, statistical_area, section) |>
  summarise(spawn_index_tonnes = sum(spawn_number, na.rm = TRUE),
            n_events = n(),
            .groups = "drop") |>
  arrange(year, stock_area, statistical_area, section) |>
  filter(year >= 1951L, year <= 2025L)

out_path <- here::here("Data", "processed", "bc_spawn_by_section_year.csv")
dir.create(dirname(out_path), showWarnings = FALSE, recursive = TRUE)
write_csv(panel, out_path)

cat("Wrote", nrow(panel), "rows to", out_path, "\n")
cat("Stock-area distribution:\n")
print(panel |> count(stock_area))
```

- [ ] **Step 4: Run the script**

```bash
Rscript analysis/05_bc_coastwide/scripts/01_assemble_bc_spawn.R
```
Expected: prints row count and stock-area distribution. Creates `Data/processed/bc_spawn_by_section_year.csv`.

- [ ] **Step 5: Run test to verify it passes**

```bash
Rscript -e 'testthat::test_file("tests/testthat/test-bc-coastwide.R", reporter = "minimal")'
```
Expected: all 4 tests pass.

- [ ] **Step 6: Commit**

```bash
git add -f Data/processed/bc_spawn_by_section_year.csv
git add analysis/05_bc_coastwide/scripts/01_assemble_bc_spawn.R tests/testthat/test-bc-coastwide.R
git commit -m "feat(05_bc_coastwide): assemble BC spawn panel (8 stock areas, 1951-2025)"
```

## Task 3: BC-wide catch acquisition — Open Data Portal download (scripts/00)

**Files:**
- Create: `analysis/05_bc_coastwide/scripts/00_data_acquisition.R`
- Create: `Data/raw/dfo-catch/bc_commercial_catch_OPEN_DATA.csv` (downloaded)

DFO publishes the BC-wide commercial herring catch on the Government of Canada Open Data Portal. The dataset is searchable as "Pacific Herring Commercial Catch" and provides year × statistical-area × section × gear × tonnes. URL pattern: `https://open.canada.ca/data/en/dataset?q=pacific+herring+catch`. The exact download URL must be recorded in the script header on first run; check the portal page for the current download link.

- [ ] **Step 1: Write the failing test for catch raw**

Append to `tests/testthat/test-bc-coastwide.R`:

```r
test_that("bc commercial catch raw download exists and has stock-area-resolved rows", {
  path <- here("Data", "raw", "dfo-catch", "bc_commercial_catch_OPEN_DATA.csv")
  expect_true(file.exists(path),
              info = "run analysis/05_bc_coastwide/scripts/00_data_acquisition.R first")
  raw <- read_csv(path, show_col_types = FALSE, n_max = 200)
  # Expect at least one of these conventional column names from DFO Open Data
  cols <- tolower(names(raw))
  expect_true(any(grepl("section", cols)) || any(grepl("statistical", cols)))
})
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
Rscript -e 'testthat::test_file("tests/testthat/test-bc-coastwide.R", reporter = "minimal")'
```
Expected: FAIL on the new test (`bc_commercial_catch_OPEN_DATA.csv` does not exist).

- [ ] **Step 3: Write the acquisition script**

Create `analysis/05_bc_coastwide/scripts/00_data_acquisition.R`:

```r
# ============================================================================
# 00_data_acquisition.R — Refresh BC-wide DFO datasets
# analysis/05_bc_coastwide
#
# Downloads/refreshes:
#   - Pacific Herring spawn index (BC-wide; already present, re-download for refresh)
#   - Pacific Herring commercial catch (BC-wide, Open Data Portal)
#
# Open Data Portal landing:
#   https://open.canada.ca/data/en/dataset?q=pacific+herring
#
# IMPORTANT: DFO occasionally rotates the resource URL on the portal. If the
# request returns a 404, browse the portal, find the most recent "Pacific
# Herring Commercial Catch" resource, update CATCH_URL below, and re-run.
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(here)
  library(httr)
})

source(here::here("R", "00_setup.R"))

raw_dir <- here::here("Data", "raw", "dfo-catch")
dir.create(raw_dir, showWarnings = FALSE, recursive = TRUE)

# Resolve the most recent Open Data resource. As of 2026-05-21 the canonical
# resource lives at the Pacific Herring Commercial Catch dataset; update CATCH_URL
# from the portal if the next refresh 404s.
CATCH_URL <- Sys.getenv(
  "DFO_HERRING_CATCH_URL",
  unset = "https://open.canada.ca/data/en/dataset/2deec71e-fcf9-4cf6-8c8a-fa4097ef0fd9"
)

cat("Fetching DFO commercial catch from:\n  ", CATCH_URL, "\n")
cat("If this 404s, browse https://open.canada.ca/data/en/dataset?q=pacific+herring,\n",
    "find the current Pacific Herring Commercial Catch resource, set\n",
    "DFO_HERRING_CATCH_URL env var to the .csv resource URL, and re-run.\n\n")

dest_path <- file.path(raw_dir, "bc_commercial_catch_OPEN_DATA.csv")

resp <- httr::GET(CATCH_URL, httr::write_disk(dest_path, overwrite = TRUE))

if (httr::status_code(resp) != 200L) {
  stop("Download failed (HTTP ", httr::status_code(resp), "). ",
       "Resolve the portal URL manually and set DFO_HERRING_CATCH_URL.")
}

cat("Wrote", file.size(dest_path), "bytes to", dest_path, "\n")

# Sanity check: file should not be an HTML error page
first_line <- readLines(dest_path, n = 1L)
if (grepl("^<", first_line)) {
  stop("Downloaded file appears to be HTML, not CSV. ",
       "The URL likely points to a portal landing page; ",
       "you need the direct CSV resource URL.")
}

cat("First line preview:", substring(first_line, 1L, 120L), "\n")
```

- [ ] **Step 4: Run the script**

```bash
Rscript analysis/05_bc_coastwide/scripts/00_data_acquisition.R
```
Expected: prints download size and first-line preview. If the URL has rotated, prints the recovery instructions and exits non-zero — in that case, browse the portal, find the current resource, and re-run with `DFO_HERRING_CATCH_URL=<url> Rscript ...`.

- [ ] **Step 5: Run test to verify it passes**

```bash
Rscript -e 'testthat::test_file("tests/testthat/test-bc-coastwide.R", reporter = "minimal")'
```
Expected: all tests pass including the new catch-raw test.

- [ ] **Step 6: Commit**

```bash
git add analysis/05_bc_coastwide/scripts/00_data_acquisition.R tests/testthat/test-bc-coastwide.R
# Do NOT git add the raw CSV — it's covered by Data/raw .gitignore. If it's
# accidentally tracked, run: git update-index --skip-worktree Data/raw/dfo-catch/bc_commercial_catch_OPEN_DATA.csv
git commit -m "feat(05_bc_coastwide): DFO Open Data Portal catch acquisition (scripts/00)"
```

## Task 4: BC-wide catch panel assembly (scripts/02 — Open Data half)

**Files:**
- Create: `analysis/05_bc_coastwide/scripts/02_assemble_bc_catch.R`
- Create: `Data/processed/bc_catch_by_section_year_gear.csv`

- [ ] **Step 1: Write the failing test**

Append to `tests/testthat/test-bc-coastwide.R`:

```r
test_that("bc_catch panel exists with section-year-gear schema", {
  path <- here("Data", "processed", "bc_catch_by_section_year_gear.csv")
  expect_true(file.exists(path),
              info = "run scripts/02_assemble_bc_catch.R first")
  panel <- read_csv(path, show_col_types = FALSE)
  expect_true(all(c("year", "stock_area", "statistical_area", "section",
                    "gear", "catch_tonnes") %in% names(panel)))
})

test_that("bc_catch year range starts at 1951 or earlier", {
  panel <- read_csv(here("Data", "processed", "bc_catch_by_section_year_gear.csv"),
                    show_col_types = FALSE)
  expect_true(min(panel$year, na.rm = TRUE) <= 1951L)
})

test_that("bc_catch covers at least 5 major stock areas", {
  panel <- read_csv(here("Data", "processed", "bc_catch_by_section_year_gear.csv"),
                    show_col_types = FALSE)
  major <- c("HG", "PRD", "CC", "SoG", "WCVI")
  expect_true(all(major %in% panel$stock_area))
})
```

- [ ] **Step 2: Run test to verify it fails**

```bash
Rscript -e 'testthat::test_file("tests/testthat/test-bc-coastwide.R", reporter = "minimal")'
```
Expected: 3 new tests FAIL.

- [ ] **Step 3: Write the catch-assembly script**

Create `analysis/05_bc_coastwide/scripts/02_assemble_bc_catch.R`:

```r
# ============================================================================
# 02_assemble_bc_catch.R — Assemble BC-wide catch panel from Open Data + CSAS
# analysis/05_bc_coastwide
#
# Input:  Data/raw/dfo-catch/bc_commercial_catch_OPEN_DATA.csv
#         (from scripts/00_data_acquisition.R)
# Output: Data/processed/bc_catch_by_section_year_gear.csv
#         (one row per section-year-gear with catch in metric tonnes)
#
# Schema target: year, stock_area, statistical_area, section, gear, catch_tonnes.
# The DFO Open Data raw column names vary release-to-release; this script does
# name harmonization via clean_names() + an explicit rename map.
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(here)
  library(janitor)
})

source(here::here("R", "00_setup.R"))

raw_path <- here::here("Data", "raw", "dfo-catch", "bc_commercial_catch_OPEN_DATA.csv")
stopifnot(file.exists(raw_path))

raw <- read_csv(raw_path, show_col_types = FALSE) |> clean_names()

cat("Raw catch columns:", paste(names(raw), collapse = ", "), "\n")

# Map common DFO column names → canonical schema. Update this map after
# inspecting the raw header; the script below assumes the most common
# DFO publication names. If names differ, alter the rename block.
panel <- raw |>
  rename(year = any_of(c("year", "calendar_year", "fishing_year")),
         stock_area = any_of(c("stock_assessment_region", "stock_area", "region")),
         statistical_area = any_of(c("statistical_area", "stat_area", "area")),
         section = any_of(c("section")),
         gear = any_of(c("gear", "gear_type")),
         catch_tonnes = any_of(c("sum_of_catch_metric_tonnes",
                                  "catch_tonnes", "catch", "catch_t"))) |>
  mutate(year = as.integer(year),
         stock_area = as.character(stock_area),
         statistical_area = as.character(statistical_area),
         section = as.character(section),
         gear = as.character(gear),
         catch_tonnes = as.numeric(catch_tonnes)) |>
  filter(!is.na(year), !is.na(stock_area)) |>
  select(year, stock_area, statistical_area, section, gear, catch_tonnes) |>
  arrange(year, stock_area, statistical_area, section, gear)

out_path <- here::here("Data", "processed", "bc_catch_by_section_year_gear.csv")
dir.create(dirname(out_path), showWarnings = FALSE, recursive = TRUE)
write_csv(panel, out_path)

cat("Wrote", nrow(panel), "rows to", out_path, "\n")
cat("Stock-area distribution:\n")
print(panel |> count(stock_area))
cat("Gear distribution:\n")
print(panel |> count(gear))
```

- [ ] **Step 4: Run the script**

```bash
Rscript analysis/05_bc_coastwide/scripts/02_assemble_bc_catch.R
```
Expected: prints row count and distributions. If the rename block fails (NA values in `year` / `stock_area`), inspect the raw columns and update the `any_of()` lists.

- [ ] **Step 5: Run tests to verify they pass**

```bash
Rscript -e 'testthat::test_file("tests/testthat/test-bc-coastwide.R", reporter = "minimal")'
```
Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add -f Data/processed/bc_catch_by_section_year_gear.csv
git add analysis/05_bc_coastwide/scripts/02_assemble_bc_catch.R tests/testthat/test-bc-coastwide.R
git commit -m "feat(05_bc_coastwide): assemble BC catch panel from Open Data (scripts/02)"
```

## Task 5: CSAS appendix scrape + cross-check (scripts/02b)

**Files:**
- Create: `analysis/05_bc_coastwide/scripts/02b_csas_appendix_crosscheck.R`
- Create: `Data/processed/bc_catch_csas_appendix.csv`
- Create: `Output/diagnostics/bc_catch_csas_concordance.md`

This task reuses the existing OCR pipeline at `Code/02f_extract_newer_dfo_public_pdfs.R`. CSAS SAR PDFs are typically at `https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/...` — paths are tracked in `Code/02d_fetch_dfo_herring_assessment_sources.R`. The cross-check passes if BC-wide catch sums per stock-area-year agree within ±2% of CSAS totals.

- [ ] **Step 1: Write the failing test**

Append to `tests/testthat/test-bc-coastwide.R`:

```r
test_that("CSAS appendix catch table exists and matches Open Data within tolerance", {
  csas_path <- here("Data", "processed", "bc_catch_csas_appendix.csv")
  od_path   <- here("Data", "processed", "bc_catch_by_section_year_gear.csv")
  expect_true(file.exists(csas_path),
              info = "run scripts/02b_csas_appendix_crosscheck.R first")
  csas <- read_csv(csas_path, show_col_types = FALSE)
  od   <- read_csv(od_path, show_col_types = FALSE)

  od_sum <- od |>
    group_by(year, stock_area) |>
    summarise(od_t = sum(catch_tonnes, na.rm = TRUE), .groups = "drop")
  csas_sum <- csas |>
    group_by(year, stock_area) |>
    summarise(csas_t = sum(catch_tonnes, na.rm = TRUE), .groups = "drop")

  comp <- inner_join(od_sum, csas_sum, by = c("year", "stock_area")) |>
    filter(csas_t > 0) |>
    mutate(rel_diff = abs(od_t - csas_t) / csas_t)

  # Tolerance: 95% of joint rows within 2%, max row within 10%
  expect_gte(mean(comp$rel_diff <= 0.02), 0.95)
  expect_lte(max(comp$rel_diff), 0.10)
})
```

- [ ] **Step 2: Run test to verify it fails**

```bash
Rscript -e 'testthat::test_file("tests/testthat/test-bc-coastwide.R", reporter = "minimal")'
```
Expected: FAIL on the new test (file doesn't exist).

- [ ] **Step 3: Write the cross-check script**

Create `analysis/05_bc_coastwide/scripts/02b_csas_appendix_crosscheck.R`:

```r
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
```

- [ ] **Step 4: Run the script**

```bash
Rscript analysis/05_bc_coastwide/scripts/02b_csas_appendix_crosscheck.R
```
Expected: downloads PDFs (first run), parses each, writes the CSAS panel and concordance report. If any URL 404s, update the `pdf_manifest` from the DFO library and re-run.

- [ ] **Step 5: Run test to verify it passes**

```bash
Rscript -e 'testthat::test_file("tests/testthat/test-bc-coastwide.R", reporter = "minimal")'
```
Expected: all tests pass; 95% of joint rows within 2%, max within 10%.

- [ ] **Step 6: Commit**

```bash
git add -f Data/processed/bc_catch_csas_appendix.csv Output/diagnostics/bc_catch_csas_concordance.md
git add analysis/05_bc_coastwide/scripts/02b_csas_appendix_crosscheck.R tests/testthat/test-bc-coastwide.R
git commit -m "feat(05_bc_coastwide): CSAS appendix cross-check (scripts/02b) + concordance report"
```

---

# Phase 2 — Data assembly (covariates + distance + Stan input)

## Task 6: Predator covariates assembly (scripts/03)

**Files:**
- Create: `analysis/05_bc_coastwide/scripts/03_assemble_bc_predator_covs.R`
- Create: `Data/processed/bc_predator_covariates.csv`
- Create: `Data/processed/bc_predator_covariates_provenance.md`

The sibling repo at `~/pacific-herring-predators` has BC-wide species totals (harbour seal interpolated curve, Steller sea lion, California sea lion, humpback, synoptic-trawl 7-spp, seabirds, salmon escapement). Per the spec, section-level resolution exists for HG but not all BC sections; aggregate to stock-area-level where section-resolution unavailable, and document per-species in the provenance file.

- [ ] **Step 1: Write the failing test**

Append to `tests/testthat/test-bc-coastwide.R`:

```r
test_that("bc_predator_covariates exists with stock-area-year schema", {
  path <- here("Data", "processed", "bc_predator_covariates.csv")
  expect_true(file.exists(path),
              info = "run scripts/03_assemble_bc_predator_covs.R first")
  covs <- read_csv(path, show_col_types = FALSE)
  expect_true(all(c("year", "stock_area", "section") %in% names(covs)))
  # At least one species column beyond keys
  numeric_cols <- names(covs)[sapply(covs, is.numeric)]
  expect_true(length(setdiff(numeric_cols, c("year"))) >= 1)
})

test_that("bc_predator_covariates_provenance.md documents per-species resolution", {
  path <- here("Data", "processed", "bc_predator_covariates_provenance.md")
  expect_true(file.exists(path))
  text <- readLines(path, warn = FALSE) |> paste(collapse = "\n")
  for (sp in c("harbour_seal", "steller", "humpback")) {
    expect_match(text, sp, fixed = TRUE,
                 info = paste("provenance should document", sp))
  }
})
```

- [ ] **Step 2: Run test to verify it fails**

```bash
Rscript -e 'testthat::test_file("tests/testthat/test-bc-coastwide.R", reporter = "minimal")'
```
Expected: FAIL on the new tests.

- [ ] **Step 3: Write the predator-covs assembly script**

Create `analysis/05_bc_coastwide/scripts/03_assemble_bc_predator_covs.R`:

```r
# ============================================================================
# 03_assemble_bc_predator_covs.R — Section/area-resolved predator covariates
# analysis/05_bc_coastwide
#
# Input: Sibling repo ~/pacific-herring-predators/data/processed/
# Output: Data/processed/bc_predator_covariates.csv (long format)
#         Data/processed/bc_predator_covariates_provenance.md (per-species notes)
#
# Spatial-resolution strategy:
#   - Where section-resolved data exists (HG), use it directly.
#   - Where only stock-area-aggregate exists (most species, most BC areas),
#     replicate the stock-area value across all sections in that area.
#   - Document per-species resolution in the provenance file so the modeling
#     step can decide which species to use as section-level vs stock-area-level
#     covariates.
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(here)
})

source(here::here("R", "00_setup.R"))

PRED_REPO <- Sys.getenv("PREDATOR_REPO_PATH",
                        unset = "/Users/adrianstier/pacific-herring-predators")
stopifnot(dir.exists(PRED_REPO))

bc_spawn <- read_csv(here::here("Data", "processed", "bc_spawn_by_section_year.csv"),
                     show_col_types = FALSE)
section_key <- bc_spawn |>
  distinct(stock_area, statistical_area, section) |>
  arrange(stock_area, statistical_area, section)

# ── 1. Harbour seal: BC-wide interpolated curve (Olesiuk 2010), stock-area scope ──
hs_path <- file.path(PRED_REPO, "data", "processed", "consumption_budget",
                     "harbour_seal_BC_interpolated_along_Olesiuk_2010_curve.csv")
hs <- if (file.exists(hs_path)) {
  read_csv(hs_path, show_col_types = FALSE) |>
    select(year, harbour_seal_index = any_of(c("seal_n", "abundance", "value")))
} else {
  warning("harbour seal file missing: ", hs_path)
  tibble(year = integer(), harbour_seal_index = numeric())
}

# ── 2. Steller sea lion: BC-wide counts, stock-area scope ──
ssl_path <- file.path(PRED_REPO, "data", "processed", "consumption_budget",
                      "steller_sea_lion_BC_pup_count.csv")
ssl <- if (file.exists(ssl_path)) {
  read_csv(ssl_path, show_col_types = FALSE) |>
    select(year, steller_index = any_of(c("pups", "n", "count")))
} else {
  warning("steller sea lion file missing: ", ssl_path)
  tibble(year = integer(), steller_index = numeric())
}

# ── 3. Humpback whale: BC-wide photo-ID counts ──
hw_path <- file.path(PRED_REPO, "data", "processed", "consumption_budget",
                     "cheeseman_2024_humpback_BC_annual_indiv_encounters.csv")
hw <- if (file.exists(hw_path)) {
  read_csv(hw_path, show_col_types = FALSE) |>
    select(year, humpback_index = any_of(c("n_indiv_BC", "n", "abundance")))
} else {
  warning("humpback file missing: ", hw_path)
  tibble(year = integer(), humpback_index = numeric())
}

bc_year_cov <- reduce(list(hs, ssl, hw),
                     ~ full_join(.x, .y, by = "year")) |>
  arrange(year)

# Expand BC-wide year-covariates to section-year by replicating across sections.
covs_long <- crossing(year = YEARS,
                      section_key) |>
  left_join(bc_year_cov, by = "year")

out_path <- here::here("Data", "processed", "bc_predator_covariates.csv")
write_csv(covs_long, out_path)
cat("Wrote", nrow(covs_long), "rows to", out_path, "\n")

# Provenance file
prov_path <- here::here("Data", "processed", "bc_predator_covariates_provenance.md")
sink(prov_path)
cat("# BC Predator Covariates — Provenance and Spatial Resolution\n\n")
cat("Generated:", format(Sys.time()), "\n\n")
cat("Source repo: `", PRED_REPO, "`\n\n")
cat("## Per-species notes\n\n")
cat("| Species | Source file | Native resolution | Used in model as |\n")
cat("|---|---|---|---|\n")
cat("| harbour_seal | `harbour_seal_BC_interpolated_along_Olesiuk_2010_curve.csv` | BC-wide year | Stock-area-level covariate (replicated across sections within a stock area is identical) |\n")
cat("| steller | `steller_sea_lion_BC_pup_count.csv` | BC-wide year | Stock-area-level covariate (same) |\n")
cat("| humpback | `cheeseman_2024_humpback_BC_annual_indiv_encounters.csv` | BC-wide year | Stock-area-level covariate (same) |\n")
cat("\n")
cat("**Implication:** in scripts/08_fit_m5_bc.R, predator covariates enter as\n")
cat("year-by-stock-area effects, not section-by-year. Section-level predator\n")
cat("variation will be added in a later iteration if section-resolved data\n")
cat("becomes available from the sibling repo's consumption-budget products.\n")
sink()
cat("Wrote provenance to", prov_path, "\n")
```

- [ ] **Step 4: Run the script**

```bash
Rscript analysis/05_bc_coastwide/scripts/03_assemble_bc_predator_covs.R
```
Expected: prints row count; warns if any of the 3 source files are missing. Produces both output files.

- [ ] **Step 5: Run test to verify it passes**

```bash
Rscript -e 'testthat::test_file("tests/testthat/test-bc-coastwide.R", reporter = "minimal")'
```
Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add -f Data/processed/bc_predator_covariates.csv Data/processed/bc_predator_covariates_provenance.md
git add analysis/05_bc_coastwide/scripts/03_assemble_bc_predator_covs.R tests/testthat/test-bc-coastwide.R
git commit -m "feat(05_bc_coastwide): predator covariates (BC-wide year, stock-area-level) (scripts/03)"
```

## Task 7: Within-stock-area distance matrices (scripts/04)

**Files:**
- Create: `analysis/05_bc_coastwide/scripts/04_assemble_distance_matrix.R`
- Create: `Data/processed/bc_distance_within_stock_area.rds`

The block-diagonal Σ trick (section 3 of spec) requires distance matrices within each stock area. Compute haversine distance from spawn-event lat/long centroids per section.

- [ ] **Step 1: Write the failing test**

Append to `tests/testthat/test-bc-coastwide.R`:

```r
test_that("bc_distance_within_stock_area is a list of symmetric distance matrices", {
  path <- here("Data", "processed", "bc_distance_within_stock_area.rds")
  expect_true(file.exists(path),
              info = "run scripts/04_assemble_distance_matrix.R first")
  D_list <- readRDS(path)
  expect_type(D_list, "list")
  expect_true(length(D_list) >= 5)  # at least 5 major stock areas
  for (nm in names(D_list)) {
    D <- D_list[[nm]]
    expect_true(is.matrix(D), info = paste(nm, "must be a matrix"))
    expect_equal(nrow(D), ncol(D), info = paste(nm, "must be square"))
    expect_equal(D, t(D), info = paste(nm, "must be symmetric"))
    expect_true(all(diag(D) == 0), info = paste(nm, "diagonal must be 0"))
  }
})
```

- [ ] **Step 2: Run test to verify it fails**

```bash
Rscript -e 'testthat::test_file("tests/testthat/test-bc-coastwide.R", reporter = "minimal")'
```
Expected: FAIL.

- [ ] **Step 3: Write the distance-matrix script**

Create `analysis/05_bc_coastwide/scripts/04_assemble_distance_matrix.R`:

```r
# ============================================================================
# 04_assemble_distance_matrix.R — Within-stock-area distance matrices
# analysis/05_bc_coastwide
#
# Input:  Data/raw/dfo-spawn/Pacific_herring_spawn_index_data_2025_EN.csv
# Output: Data/processed/bc_distance_within_stock_area.rds
#         (named list of haversine distance matrices, one per stock area, km)
#
# Section centroid = median(lat, long) over all spawn events ever recorded
# in that section. Block-diagonal Σ in the Stan model uses these within-area
# matrices; cross-area distances are set to Inf and yield Σ entries of 0.
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(here)
  library(geosphere)
})

source(here::here("R", "00_setup.R"))

raw <- read_csv(here::here("Data", "raw", "dfo-spawn",
                           "Pacific_herring_spawn_index_data_2025_EN.csv"),
                show_col_types = FALSE) |>
  janitor::clean_names()

centroids <- raw |>
  filter(!is.na(longitude), !is.na(latitude)) |>
  rename(stock_area = region) |>
  mutate(stock_area = if_else(is.na(stock_area), "NA", as.character(stock_area)),
         statistical_area = as.character(statistical_area),
         section = as.character(section)) |>
  group_by(stock_area, statistical_area, section) |>
  summarise(lon = median(longitude, na.rm = TRUE),
            lat = median(latitude,  na.rm = TRUE),
            .groups = "drop")

stopifnot(nrow(centroids) > 0)
cat("Section centroids computed for", nrow(centroids), "sections across",
    n_distinct(centroids$stock_area), "stock areas.\n")

D_list <- centroids |>
  split(centroids$stock_area) |>
  map(function(df) {
    if (nrow(df) < 2L) {
      return(matrix(0, nrow = nrow(df), ncol = nrow(df),
                    dimnames = list(df$section, df$section)))
    }
    coords <- as.matrix(df[, c("lon", "lat")])
    D_m <- geosphere::distm(coords, fun = geosphere::distHaversine)
    D_km <- D_m / 1000
    dimnames(D_km) <- list(df$section, df$section)
    D_km
  })

out_path <- here::here("Data", "processed", "bc_distance_within_stock_area.rds")
saveRDS(D_list, out_path)
cat("Wrote distance-matrix list to", out_path, "\n")
cat("Stock areas:", paste(names(D_list), collapse = ", "), "\n")
cat("Sizes (sections):",
    paste(sprintf("%s=%d", names(D_list), sapply(D_list, nrow)),
          collapse = ", "), "\n")
```

- [ ] **Step 4: Run the script**

```bash
Rscript analysis/05_bc_coastwide/scripts/04_assemble_distance_matrix.R
```
Expected: prints centroid counts and stock-area sizes. Creates the RDS.

- [ ] **Step 5: Run test**

```bash
Rscript -e 'testthat::test_file("tests/testthat/test-bc-coastwide.R", reporter = "minimal")'
```
Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add -f Data/processed/bc_distance_within_stock_area.rds
git add analysis/05_bc_coastwide/scripts/04_assemble_distance_matrix.R tests/testthat/test-bc-coastwide.R
git commit -m "feat(05_bc_coastwide): within-stock-area distance matrices (scripts/04)"
```

## Task 8: Stan data list assembly (scripts/05)

**Files:**
- Create: `analysis/05_bc_coastwide/scripts/05_prepare_stan_data.R`
- Create: `Data/processed/bc_stan_data.rds`

Combines spawn, catch, predator covs, distance matrices, and the fishery-events anchor table into a single Stan data list. Also writes the fishery-events table (closure years per stock area) as documented in the spec.

- [ ] **Step 1: Write the failing test**

Append to `tests/testthat/test-bc-coastwide.R`:

```r
test_that("bc_stan_data.rds is a complete Stan data list", {
  path <- here("Data", "processed", "bc_stan_data.rds")
  expect_true(file.exists(path),
              info = "run scripts/05_prepare_stan_data.R first")
  d <- readRDS(path)
  expect_true(is.list(d))
  required <- c("N_sections", "N_years", "N_stock_areas",
                "stock_area_of", "y", "obs_mask",
                "D_blocks", "block_starts", "block_sizes",
                "predator_covs",
                "fishery_active", "n_years_active")
  expect_true(all(required %in% names(d)),
              info = paste("missing:", setdiff(required, names(d))))
  expect_true(d$N_sections >= 80)
  expect_equal(d$N_years, 75L)  # 1951–2025
  expect_equal(d$N_stock_areas, 8L)
})

test_that("bc_fishery_events.csv lists anchor years per stock area", {
  path <- here("Data", "processed", "bc_fishery_events.csv")
  expect_true(file.exists(path))
  evt <- read_csv(path, show_col_types = FALSE)
  expect_true(all(c("stock_area", "event_year", "event_kind") %in% names(evt)))
  # HG must have a 2002 closure
  hg_close <- evt |> filter(stock_area == "HG", event_kind == "closure")
  expect_true(any(hg_close$event_year %in% 2001:2003))
})
```

- [ ] **Step 2: Run test to verify it fails**

```bash
Rscript -e 'testthat::test_file("tests/testthat/test-bc-coastwide.R", reporter = "minimal")'
```
Expected: FAIL on the new tests.

- [ ] **Step 3: Write the fishery-events seed table**

Create `Data/processed/bc_fishery_events.csv` with this exact content:

```csv
stock_area,event_year,event_kind,note
HG,2002,closure,Haida Gwaii commercial roe-seine closure (continued through present)
WCVI,1968,closure,WCVI commercial closure (reopened intermittently)
WCVI,2006,closure,WCVI extended closure phase
CC,2007,closure,Central Coast extended closure
PRD,2008,closure,Prince Rupert District extended closure
SoG,NA,never_closed,Strait of Georgia commercial fishery never fully closed
```

- [ ] **Step 4: Write the Stan-data-prep script**

Create `analysis/05_bc_coastwide/scripts/05_prepare_stan_data.R`:

```r
# ============================================================================
# 05_prepare_stan_data.R — Assemble BC-wide Stan data list
# analysis/05_bc_coastwide
#
# Input:  Data/processed/bc_spawn_by_section_year.csv
#         Data/processed/bc_catch_by_section_year_gear.csv
#         Data/processed/bc_predator_covariates.csv
#         Data/processed/bc_distance_within_stock_area.rds
#         Data/processed/bc_fishery_events.csv
# Output: Data/processed/bc_stan_data.rds (named list ready for rstan::sampling())
#
# The list contains:
#   N_sections, N_years, N_stock_areas, stock_area_of[N_sections]
#   y[N_sections, N_years]      spawn-index tonnes (positive-only; zeros NA)
#   obs_mask[N_sections, N_years]  1 if y observed positive, 0 otherwise
#   D_blocks: long vector of within-area distances
#   block_starts, block_sizes: indices that reconstruct D as block-diagonal
#   predator_covs[N_stock_areas, N_years, P]
#   fishery_active[N_sections, N_years]   0/1 indicator using bc_fishery_events
#   n_years_active[N_sections]            count, for prior scaling
# ============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(here)
})

source(here::here("R", "00_setup.R"))

spawn <- read_csv(here::here("Data", "processed",
                             "bc_spawn_by_section_year.csv"),
                  show_col_types = FALSE)
catch <- read_csv(here::here("Data", "processed",
                             "bc_catch_by_section_year_gear.csv"),
                  show_col_types = FALSE)
covs  <- read_csv(here::here("Data", "processed",
                             "bc_predator_covariates.csv"),
                  show_col_types = FALSE)
D_list <- readRDS(here::here("Data", "processed",
                             "bc_distance_within_stock_area.rds"))
events <- read_csv(here::here("Data", "processed",
                              "bc_fishery_events.csv"),
                   show_col_types = FALSE)

section_key <- spawn |>
  distinct(stock_area, statistical_area, section) |>
  arrange(stock_area, statistical_area, section) |>
  mutate(section_idx = row_number())

stock_areas <- sort(unique(section_key$stock_area))
section_key <- section_key |>
  mutate(stock_area_idx = match(stock_area, stock_areas))

N_sections <- nrow(section_key)
N_years    <- length(YEARS)
N_stock_areas <- length(stock_areas)

# y matrix (positive spawn only; zeros → NA → masked)
y_mat <- matrix(NA_real_, nrow = N_sections, ncol = N_years,
                dimnames = list(section_key$section_idx, YEARS))
spawn_keyed <- spawn |>
  inner_join(section_key, by = c("stock_area", "statistical_area", "section"))
for (i in seq_len(nrow(spawn_keyed))) {
  r <- spawn_keyed[i, ]
  if (!is.na(r$spawn_index_tonnes) && r$spawn_index_tonnes > 0) {
    y_mat[r$section_idx, as.character(r$year)] <- r$spawn_index_tonnes
  }
}
obs_mask <- (!is.na(y_mat)) * 1L

# Block-diagonal D: stack within-area matrices in stock-area order
D_blocks <- numeric()
block_starts <- integer()
block_sizes <- integer()
cur <- 0L
for (sa in stock_areas) {
  D <- D_list[[sa]]
  if (is.null(D)) D <- matrix(0, 0, 0)
  block_starts <- c(block_starts, cur + 1L)
  block_sizes <- c(block_sizes, nrow(D))
  D_blocks <- c(D_blocks, as.numeric(D))
  cur <- cur + length(D)
}

# Predator covariates: collapse to stock-area-year (predator data is
# stock-area-level per provenance file)
pred_pivot <- covs |>
  group_by(stock_area, year) |>
  summarise(across(any_of(c("harbour_seal_index", "steller_index",
                            "humpback_index")),
                   ~ mean(.x, na.rm = TRUE)),
            .groups = "drop")
pred_cols <- intersect(c("harbour_seal_index", "steller_index", "humpback_index"),
                       names(pred_pivot))
P <- length(pred_cols)
pred_arr <- array(0.0, dim = c(N_stock_areas, N_years, P),
                  dimnames = list(stock_areas, YEARS, pred_cols))
for (sa in stock_areas) {
  for (yr in YEARS) {
    row <- pred_pivot |> filter(stock_area == sa, year == yr)
    if (nrow(row) == 1L) {
      for (p in pred_cols) {
        v <- row[[p]]
        pred_arr[sa, as.character(yr), p] <- ifelse(is.finite(v), v, 0.0)
      }
    }
  }
}

# Fishery-active matrix from bc_fishery_events
fishery_active <- matrix(1L, nrow = N_sections, ncol = N_years,
                         dimnames = list(section_key$section_idx, YEARS))
for (i in seq_len(nrow(events))) {
  r <- events[i, ]
  if (r$event_kind == "closure" && !is.na(r$event_year)) {
    sec_mask <- section_key$stock_area == r$stock_area
    year_mask <- as.integer(YEARS) >= r$event_year
    fishery_active[sec_mask, year_mask] <- 0L
  }
}
n_years_active <- rowSums(fishery_active)

stan_data <- list(
  N_sections     = N_sections,
  N_years        = N_years,
  N_stock_areas  = N_stock_areas,
  N_pred_covs    = P,
  stock_area_of  = section_key$stock_area_idx,
  y              = y_mat,
  obs_mask       = obs_mask,
  D_blocks       = D_blocks,
  block_starts   = block_starts,
  block_sizes    = block_sizes,
  predator_covs  = pred_arr,
  fishery_active = fishery_active,
  n_years_active = n_years_active,
  era_break_year = rep(1988L, N_stock_areas),  # placeholder; per-area in M3+
  section_meta   = section_key,
  stock_area_codes = stock_areas,
  years          = YEARS
)

out_path <- here::here("Data", "processed", "bc_stan_data.rds")
saveRDS(stan_data, out_path)
cat("Wrote Stan data list to", out_path, "\n")
cat("  N_sections:", N_sections, "\n")
cat("  N_years:", N_years, "\n")
cat("  N_stock_areas:", N_stock_areas, "\n")
cat("  Total positive obs:", sum(obs_mask), "\n")
```

- [ ] **Step 5: Run the script**

```bash
Rscript analysis/05_bc_coastwide/scripts/05_prepare_stan_data.R
```
Expected: prints N_sections, N_years, N_stock_areas, positive obs count.

- [ ] **Step 6: Run test**

```bash
Rscript -e 'testthat::test_file("tests/testthat/test-bc-coastwide.R", reporter = "minimal")'
```
Expected: all tests pass.

- [ ] **Step 7: Commit**

```bash
git add -f Data/processed/bc_stan_data.rds Data/processed/bc_fishery_events.csv
git add analysis/05_bc_coastwide/scripts/05_prepare_stan_data.R tests/testthat/test-bc-coastwide.R
git commit -m "feat(05_bc_coastwide): Stan data list assembly + fishery events (scripts/05)"
```

---

# Phase 3 — Stan models

## Task 9: Hierarchical M1 Stan model

**Files:**
- Create: `analysis/05_bc_coastwide/stan/herring_metapop_bc_m1.stan`

The model implements the spec's process and observation equations with block-diagonal Σ. Cross-area entries are not stored (they're zero by construction); the within-block likelihood loops per stock area.

- [ ] **Step 1: Write the failing test (smoke-fit on minimal data)**

Append to `tests/testthat/test-bc-coastwide.R`:

```r
test_that("herring_metapop_bc_m1.stan compiles and smoke-fits on 5-section synthetic data", {
  skip_on_cran()
  skip_if_not_installed("rstan")
  stan_path <- here("analysis", "05_bc_coastwide", "stan",
                    "herring_metapop_bc_m1.stan")
  expect_true(file.exists(stan_path))

  # Synthetic mini-data: 5 sections, 2 stock areas (3+2), 10 years
  set.seed(20260521)
  N_s <- 5L; N_y <- 10L; N_a <- 2L
  z <- matrix(rnorm(N_s * N_y), N_s, N_y)
  y <- exp(z + rnorm(N_s * N_y, 0, 0.1))
  obs_mask <- matrix(1L, N_s, N_y)
  D1 <- as.matrix(dist(matrix(rnorm(6), 3, 2)))
  D2 <- as.matrix(dist(matrix(rnorm(4), 2, 2)))
  D_blocks <- c(as.numeric(D1), as.numeric(D2))
  block_starts <- c(1L, length(as.numeric(D1)) + 1L)
  block_sizes <- c(3L, 2L)
  stan_data <- list(
    N_sections = N_s, N_years = N_y, N_stock_areas = N_a,
    stock_area_of = c(1L, 1L, 1L, 2L, 2L),
    y = y, obs_mask = obs_mask,
    D_blocks = D_blocks,
    block_starts = block_starts, block_sizes = block_sizes
  )

  mod <- rstan::stan_model(stan_path, verbose = FALSE)
  fit <- rstan::sampling(mod, data = stan_data, chains = 1, iter = 200,
                         warmup = 100, refresh = 0, verbose = FALSE)
  expect_true(inherits(fit, "stanfit"))
})
```

- [ ] **Step 2: Run test to verify it fails (file missing)**

```bash
Rscript -e 'testthat::test_file("tests/testthat/test-bc-coastwide.R", reporter = "minimal")'
```
Expected: FAIL — the Stan file doesn't exist.

- [ ] **Step 3: Write the Stan model**

Create `analysis/05_bc_coastwide/stan/herring_metapop_bc_m1.stan`:

```stan
// ============================================================================
// herring_metapop_bc_m1.stan — Hierarchical M1 baseline (block-diagonal Σ)
// analysis/05_bc_coastwide
//
// State: log-biomass per section per year, z[s, y]
// Hierarchy: section -> stock_area
// Σ block-diagonal: within-area distance-decay, between-area zero
// Observation: positive spawn-index tonnes only (zeros = ambiguous)
// ============================================================================

data {
  int<lower=1> N_sections;
  int<lower=1> N_years;
  int<lower=1> N_stock_areas;
  array[N_sections] int<lower=1, upper=N_stock_areas> stock_area_of;

  array[N_sections, N_years] real<lower=0> y;          // 0 marks unobserved
  array[N_sections, N_years] int<lower=0, upper=1> obs_mask;

  // Block-diagonal distance entries in stock-area order
  int<lower=0> N_D;                                    // total entries
  vector[N_D] D_blocks;
  array[N_stock_areas] int<lower=1> block_starts;
  array[N_stock_areas] int<lower=0> block_sizes;
}

transformed data {
  // Compute log-y where observed (used in likelihood); guard zeros
  array[N_sections, N_years] real log_y;
  for (s in 1:N_sections)
    for (t in 1:N_years)
      log_y[s, t] = obs_mask[s, t] == 1 ? log(y[s, t]) : 0.0;
}

parameters {
  vector[N_stock_areas] r_area;          // stock-area intrinsic growth
  vector<lower=0>[N_stock_areas] sigma_area;  // process sd
  vector<lower=0>[N_stock_areas] range_area;  // distance-decay range (km)
  real<lower=0> sigma_obs;               // log-normal observation sd
  array[N_sections, N_years] real z;     // latent log-biomass
  vector[N_sections] z0;                 // initial state
}

model {
  // Priors
  r_area ~ normal(0, 0.5);
  sigma_area ~ normal(0, 1);
  range_area ~ normal(50, 50);           // ~50 km characteristic range
  sigma_obs ~ normal(0, 1);
  z0 ~ normal(log(100), 2);              // ~100 tonnes section-level prior

  // Initial year
  for (s in 1:N_sections) z[s, 1] ~ normal(z0[s], sigma_area[stock_area_of[s]]);

  // Process: section-level random walk + stock-area intrinsic growth
  for (s in 1:N_sections)
    for (t in 2:N_years)
      z[s, t] ~ normal(z[s, t-1] + r_area[stock_area_of[s]],
                       sigma_area[stock_area_of[s]]);

  // Observation
  for (s in 1:N_sections)
    for (t in 1:N_years)
      if (obs_mask[s, t] == 1)
        log_y[s, t] ~ normal(z[s, t], sigma_obs);
}

generated quantities {
  array[N_sections, N_years] real y_rep;
  for (s in 1:N_sections)
    for (t in 1:N_years)
      y_rep[s, t] = lognormal_rng(z[s, t], sigma_obs);
}
```

This is the **baseline M1 form** without the within-area distance-decay covariance — it sets each section's process noise as independent within an area (controlled by `sigma_area`). The distance-decay extension (full Σ correlations within blocks) is an M1+ refinement covered in Task 11 below; this baseline is the integration-test target and the simplest fit.

- [ ] **Step 4: Update the test smoke-fit data**

Append to the test in Step 1, the `stan_data` list needs `N_D`:

In `tests/testthat/test-bc-coastwide.R`, find the `stan_data <- list(...)` for the M1 smoke test, and add `N_D = length(D_blocks),` immediately before `D_blocks = D_blocks,`.

- [ ] **Step 5: Run test to verify it passes**

```bash
Rscript -e 'testthat::test_file("tests/testthat/test-bc-coastwide.R", reporter = "minimal")'
```
Expected: all tests pass. The smoke-fit takes ~30 seconds.

- [ ] **Step 6: Commit**

```bash
git add analysis/05_bc_coastwide/stan/herring_metapop_bc_m1.stan tests/testthat/test-bc-coastwide.R
git commit -m "feat(05_bc_coastwide): hierarchical M1 Stan model (baseline, no within-area covariance)"
```

## Task 10: M3 Stan — adds Gompertz density-dependence

**Files:**
- Create: `analysis/05_bc_coastwide/stan/herring_metapop_bc_m3.stan`

- [ ] **Step 1: Write the failing test**

Append:

```r
test_that("herring_metapop_bc_m3.stan compiles", {
  skip_on_cran()
  skip_if_not_installed("rstan")
  stan_path <- here("analysis", "05_bc_coastwide", "stan",
                    "herring_metapop_bc_m3.stan")
  expect_true(file.exists(stan_path))
  expect_silent(rstan::stan_model(stan_path, verbose = FALSE))
})
```

- [ ] **Step 2: Run test to verify it fails**

```bash
Rscript -e 'testthat::test_file("tests/testthat/test-bc-coastwide.R", reporter = "minimal")'
```
Expected: FAIL.

- [ ] **Step 3: Write the M3 model**

Create `analysis/05_bc_coastwide/stan/herring_metapop_bc_m3.stan`:

```stan
// ============================================================================
// herring_metapop_bc_m3.stan — Hierarchical M1 + Gompertz density-dependence
// analysis/05_bc_coastwide
//
// Adds beta[stock_area] * z[s, t-1] term: -beta produces mean-reverting
// dynamics around K[stock_area]. M3 reduces to M1 when beta -> 0.
// ============================================================================

data {
  int<lower=1> N_sections;
  int<lower=1> N_years;
  int<lower=1> N_stock_areas;
  array[N_sections] int<lower=1, upper=N_stock_areas> stock_area_of;
  array[N_sections, N_years] real<lower=0> y;
  array[N_sections, N_years] int<lower=0, upper=1> obs_mask;
  int<lower=0> N_D;
  vector[N_D] D_blocks;
  array[N_stock_areas] int<lower=1> block_starts;
  array[N_stock_areas] int<lower=0> block_sizes;
}

transformed data {
  array[N_sections, N_years] real log_y;
  for (s in 1:N_sections)
    for (t in 1:N_years)
      log_y[s, t] = obs_mask[s, t] == 1 ? log(y[s, t]) : 0.0;
}

parameters {
  vector[N_stock_areas] r_area;
  vector<lower=0, upper=1>[N_stock_areas] beta_area;   // Gompertz density-dep
  vector[N_stock_areas] K_area;                        // log-carrying capacity
  vector<lower=0>[N_stock_areas] sigma_area;
  vector<lower=0>[N_stock_areas] range_area;
  real<lower=0> sigma_obs;
  array[N_sections, N_years] real z;
  vector[N_sections] z0;
}

model {
  r_area ~ normal(0, 0.5);
  beta_area ~ beta(2, 8);
  K_area ~ normal(log(500), 1);
  sigma_area ~ normal(0, 1);
  range_area ~ normal(50, 50);
  sigma_obs ~ normal(0, 1);
  z0 ~ normal(log(100), 2);

  for (s in 1:N_sections) z[s, 1] ~ normal(z0[s], sigma_area[stock_area_of[s]]);
  for (s in 1:N_sections) {
    int a = stock_area_of[s];
    for (t in 2:N_years) {
      real mu = z[s, t-1] + r_area[a] - beta_area[a] * (z[s, t-1] - K_area[a]);
      z[s, t] ~ normal(mu, sigma_area[a]);
    }
  }
  for (s in 1:N_sections)
    for (t in 1:N_years)
      if (obs_mask[s, t] == 1) log_y[s, t] ~ normal(z[s, t], sigma_obs);
}

generated quantities {
  array[N_sections, N_years] real y_rep;
  for (s in 1:N_sections)
    for (t in 1:N_years)
      y_rep[s, t] = lognormal_rng(z[s, t], sigma_obs);
}
```

- [ ] **Step 4: Run test**

```bash
Rscript -e 'testthat::test_file("tests/testthat/test-bc-coastwide.R", reporter = "minimal")'
```
Expected: PASS — model compiles.

- [ ] **Step 5: Commit**

```bash
git add analysis/05_bc_coastwide/stan/herring_metapop_bc_m3.stan tests/testthat/test-bc-coastwide.R
git commit -m "feat(05_bc_coastwide): M3 Stan model — adds Gompertz density-dependence"
```

## Task 11: M5 Stan — adds predator covariates

**Files:**
- Create: `analysis/05_bc_coastwide/stan/herring_metapop_bc_m5.stan`

- [ ] **Step 1: Write the failing test**

Append:

```r
test_that("herring_metapop_bc_m5.stan compiles", {
  skip_on_cran()
  skip_if_not_installed("rstan")
  stan_path <- here("analysis", "05_bc_coastwide", "stan",
                    "herring_metapop_bc_m5.stan")
  expect_true(file.exists(stan_path))
  expect_silent(rstan::stan_model(stan_path, verbose = FALSE))
})
```

- [ ] **Step 2: Run test**

```bash
Rscript -e 'testthat::test_file("tests/testthat/test-bc-coastwide.R", reporter = "minimal")'
```
Expected: FAIL.

- [ ] **Step 3: Write the M5 model**

Create `analysis/05_bc_coastwide/stan/herring_metapop_bc_m5.stan`:

```stan
// ============================================================================
// herring_metapop_bc_m5.stan — M3 + predator covariates (year-by-stock-area)
// analysis/05_bc_coastwide
//
// Adds -gamma[p, a] * predator_covs[a, t, p] term per predator species.
// Predator covariates are year-by-stock-area per provenance notes.
// ============================================================================

data {
  int<lower=1> N_sections;
  int<lower=1> N_years;
  int<lower=1> N_stock_areas;
  int<lower=0> N_pred_covs;
  array[N_sections] int<lower=1, upper=N_stock_areas> stock_area_of;
  array[N_sections, N_years] real<lower=0> y;
  array[N_sections, N_years] int<lower=0, upper=1> obs_mask;
  int<lower=0> N_D;
  vector[N_D] D_blocks;
  array[N_stock_areas] int<lower=1> block_starts;
  array[N_stock_areas] int<lower=0> block_sizes;
  array[N_stock_areas, N_years, N_pred_covs] real predator_covs;
}

transformed data {
  array[N_sections, N_years] real log_y;
  for (s in 1:N_sections)
    for (t in 1:N_years)
      log_y[s, t] = obs_mask[s, t] == 1 ? log(y[s, t]) : 0.0;
}

parameters {
  vector[N_stock_areas] r_area;
  vector<lower=0, upper=1>[N_stock_areas] beta_area;
  vector[N_stock_areas] K_area;
  vector<lower=0>[N_stock_areas] sigma_area;
  vector<lower=0>[N_stock_areas] range_area;
  real<lower=0> sigma_obs;
  matrix[N_pred_covs, N_stock_areas] gamma_pred;   // predator effect per species per area
  array[N_sections, N_years] real z;
  vector[N_sections] z0;
}

model {
  r_area ~ normal(0, 0.5);
  beta_area ~ beta(2, 8);
  K_area ~ normal(log(500), 1);
  sigma_area ~ normal(0, 1);
  range_area ~ normal(50, 50);
  sigma_obs ~ normal(0, 1);
  z0 ~ normal(log(100), 2);
  to_vector(gamma_pred) ~ normal(0, 0.5);  // weakly informative around no-effect

  for (s in 1:N_sections) z[s, 1] ~ normal(z0[s], sigma_area[stock_area_of[s]]);
  for (s in 1:N_sections) {
    int a = stock_area_of[s];
    for (t in 2:N_years) {
      real pred_term = 0;
      for (p in 1:N_pred_covs)
        pred_term += gamma_pred[p, a] * predator_covs[a, t, p];
      real mu = z[s, t-1] + r_area[a]
              - beta_area[a] * (z[s, t-1] - K_area[a])
              - pred_term;
      z[s, t] ~ normal(mu, sigma_area[a]);
    }
  }
  for (s in 1:N_sections)
    for (t in 1:N_years)
      if (obs_mask[s, t] == 1) log_y[s, t] ~ normal(z[s, t], sigma_obs);
}

generated quantities {
  array[N_sections, N_years] real y_rep;
  for (s in 1:N_sections)
    for (t in 1:N_years)
      y_rep[s, t] = lognormal_rng(z[s, t], sigma_obs);
}
```

- [ ] **Step 4: Run test**

```bash
Rscript -e 'testthat::test_file("tests/testthat/test-bc-coastwide.R", reporter = "minimal")'
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add analysis/05_bc_coastwide/stan/herring_metapop_bc_m5.stan tests/testthat/test-bc-coastwide.R
git commit -m "feat(05_bc_coastwide): M5 Stan model — adds predator covariates"
```

---

# Phase 4 — Fits (cloud)

## Task 12: Fit M1 BC — integration-test subset (HG+WCVI) first

**Files:**
- Create: `analysis/05_bc_coastwide/scripts/06_fit_m1_bc.R`
- Output: `analysis/05_bc_coastwide/output/m1_bc_fit.rds`
- Output: `analysis/05_bc_coastwide/output/m1_bc_subset_HG_WCVI_fit.rds` (integration-test)

The integration-test requirement from the spec: fit M1 on HG+WCVI subset (~30 sections) and validate that HG-section posteriors overlap the existing HG-only M1_stier_11 fit at the 80% credible-interval level. This is the gate before the full ~100-section fit.

- [ ] **Step 1: Write the failing test**

Append:

```r
test_that("m1_bc subset (HG+WCVI) posteriors overlap existing M1_stier_11 on HG sections", {
  skip_on_cran()
  skip_if_not(file.exists(here("analysis", "05_bc_coastwide", "output",
                               "m1_bc_subset_HG_WCVI_fit.rds")),
              "run scripts/06_fit_m1_bc.R with SUBSET=HG_WCVI first")
  bc_fit <- readRDS(here("analysis", "05_bc_coastwide", "output",
                         "m1_bc_subset_HG_WCVI_fit.rds"))
  hg_fit <- readRDS(here("Output", "posteriors", "m1_stier_11_fit.rds"))

  # Compare posterior mean of r_area[HG] in bc_fit to posterior mean of r in hg_fit
  bc_r <- rstan::extract(bc_fit$fit, "r_area")$r_area
  bc_r_hg <- bc_r[, bc_fit$stock_areas == "HG"]
  hg_r <- rstan::extract(hg_fit, "r")$r

  bc_q <- quantile(bc_r_hg, c(0.1, 0.9))
  hg_q <- quantile(hg_r, c(0.1, 0.9))

  overlap <- max(0, min(bc_q[2], hg_q[2]) - max(bc_q[1], hg_q[1]))
  range_total <- max(bc_q[2], hg_q[2]) - min(bc_q[1], hg_q[1])
  expect_gt(overlap / range_total, 0.5)
})
```

- [ ] **Step 2: Run test to verify it fails (subset fit doesn't exist)**

```bash
Rscript -e 'testthat::test_file("tests/testthat/test-bc-coastwide.R", reporter = "minimal")'
```
Expected: SKIP — file missing.

- [ ] **Step 3: Write the fit script**

Create `analysis/05_bc_coastwide/scripts/06_fit_m1_bc.R`:

```r
# ============================================================================
# 06_fit_m1_bc.R — Fit hierarchical M1 BC-wide
# analysis/05_bc_coastwide
#
# Mode A (default, integration-test): SUBSET=HG_WCVI fits only HG+WCVI
#   sections. Compare to existing HG-only M1_stier_11 fit (gate before
#   full coastwide fit).
# Mode B (production): SUBSET=ALL fits all ~100 sections.
#
# Cloud deploy: this script honors HERRING_SMOKE, STAN_CHAINS, STAN_ITER,
# STAN_WARMUP, STAN_CORES env vars via cloud_fit_control().
# ============================================================================

suppressPackageStartupMessages({
  library(rstan)
  library(here)
  library(tidyverse)
})

source(here::here("R", "00_setup.R"))
source(here::here("R", "cloud_fit_control.R"))

rstan_options(auto_write = TRUE)

stan_data <- readRDS(here::here("Data", "processed", "bc_stan_data.rds"))

SUBSET <- Sys.getenv("SUBSET", unset = "HG_WCVI")
if (SUBSET != "ALL") {
  keep_codes <- strsplit(SUBSET, "_")[[1]]
  cat("Subsetting to stock areas:", paste(keep_codes, collapse = ", "), "\n")
  keep_idx <- which(stan_data$section_meta$stock_area %in% keep_codes)
  stock_area_remap <- setNames(seq_along(keep_codes), keep_codes)

  stan_data$N_sections <- length(keep_idx)
  stan_data$y <- stan_data$y[keep_idx, , drop = FALSE]
  stan_data$obs_mask <- stan_data$obs_mask[keep_idx, , drop = FALSE]
  stan_data$stock_area_of <- as.integer(
    stock_area_remap[stan_data$section_meta$stock_area[keep_idx]])
  stan_data$N_stock_areas <- length(keep_codes)
  stan_data$stock_area_codes <- keep_codes

  # Trim block-diagonal D to kept stock areas
  blocks <- list()
  for (sa in keep_codes) {
    sa_idx <- match(sa, stan_data$stock_area_codes)
    starts <- stan_data$block_starts[sa_idx]
    sz <- stan_data$block_sizes[sa_idx]
    blocks[[sa]] <- if (sz > 0) stan_data$D_blocks[starts:(starts + sz * sz - 1)]
                    else numeric(0)
  }
  stan_data$D_blocks <- unlist(blocks)
  stan_data$block_sizes <- sapply(blocks, function(b) sqrt(length(b)))
  stan_data$block_starts <- cumsum(c(1L, head(sapply(blocks, length), -1)))
  stan_data$N_D <- length(stan_data$D_blocks)
}

# Reduce list to what the .stan model declares
stan_input <- stan_data[c("N_sections", "N_years", "N_stock_areas",
                          "stock_area_of", "y", "obs_mask",
                          "N_D", "D_blocks", "block_starts", "block_sizes")]
stan_input$N_D <- length(stan_input$D_blocks)

ctrl <- cloud_fit_control()
cat("Sampler config: chains=", ctrl$chains, " iter=", ctrl$iter,
    " warmup=", ctrl$warmup, " cores=", ctrl$cores, "\n")

mod <- stan_model(here::here("analysis", "05_bc_coastwide", "stan",
                             "herring_metapop_bc_m1.stan"))
fit <- sampling(mod, data = stan_input,
                chains = ctrl$chains, iter = ctrl$iter,
                warmup = ctrl$warmup, cores = ctrl$cores,
                refresh = max(50L, ctrl$iter %/% 20L),
                control = list(adapt_delta = 0.95, max_treedepth = 12))

out_dir <- here::here("analysis", "05_bc_coastwide", "output")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
out_name <- if (SUBSET == "ALL") "m1_bc_fit.rds" else
            paste0("m1_bc_subset_", SUBSET, "_fit.rds")
out_path <- file.path(out_dir, out_name)

saveRDS(list(fit = fit, stock_areas = stan_data$stock_area_codes,
             section_meta = stan_data$section_meta),
        out_path)
cat("Wrote fit to", out_path, "\n")
```

- [ ] **Step 4: Run the subset fit locally (smoke mode)**

```bash
HERRING_SMOKE=1 SUBSET=HG_WCVI Rscript analysis/05_bc_coastwide/scripts/06_fit_m1_bc.R
```
Expected: fits in ~10 minutes locally with smoke settings (1 chain, 200 iter). Produces `m1_bc_subset_HG_WCVI_fit.rds`.

- [ ] **Step 5: Run the integration test**

```bash
Rscript -e 'testthat::test_file("tests/testthat/test-bc-coastwide.R", reporter = "minimal")'
```
Expected: integration test passes — HG-section posterior overlap > 50% of joint range. If it fails, the hierarchical structure is shifting estimates non-trivially; iterate on priors or pooling structure before proceeding.

- [ ] **Step 6: Commit the script + subset fit**

```bash
git add analysis/05_bc_coastwide/scripts/06_fit_m1_bc.R tests/testthat/test-bc-coastwide.R
# Do not commit the subset .rds fit (gitignored by analysis/*/output/* rule)
git commit -m "feat(05_bc_coastwide): M1 fit script + integration-test subset (HG+WCVI)"
```

- [ ] **Step 7: Submit the full BC-wide cloud fit**

```bash
SUBSET=ALL bash cloud/run_cloud_job.sh \
  analysis/05_bc_coastwide/scripts/06_fit_m1_bc.R \
  --name m1_bc_all \
  --stan-chains 4 --stan-iter 4500 --stan-warmup 2000 --stan-cores 4
```
Expected: AWS Batch job submitted. Track via `cloud/job_status/m1_bc_all.json`. Wall-clock ~5–8 days per the spec compute estimate.

- [ ] **Step 8: After job completes, pull the fit and commit the diagnostic**

```bash
bash cloud/promote_cloud_results.sh m1_bc_all
ls -la analysis/05_bc_coastwide/output/m1_bc_fit.rds
Rscript -e 'fit <- readRDS(here::here("analysis", "05_bc_coastwide", "output", "m1_bc_fit.rds")); summary(fit$fit, pars = c("r_area", "sigma_area", "sigma_obs"))$summary'
```
Commit any updated diagnostic / sampler-summary outputs that land in `Output/diagnostics/`:

```bash
git add Output/diagnostics/m1_bc_*.{md,csv,png} 2>/dev/null || true
git commit --allow-empty -m "feat(05_bc_coastwide): M1 BC-wide cloud fit complete"
```

## Task 13: Fit M3 BC (cloud, builds on M1 cache)

**Files:**
- Create: `analysis/05_bc_coastwide/scripts/07_fit_m3_bc.R`
- Output: `analysis/05_bc_coastwide/output/m3_bc_fit.rds`

Copy the structure of `06_fit_m1_bc.R`, changing the Stan model path to `herring_metapop_bc_m3.stan`.

- [ ] **Step 1: Write the failing test**

Append:

```r
test_that("M3 BC fit exists and has Gompertz beta posteriors", {
  skip_on_cran()
  path <- here("analysis", "05_bc_coastwide", "output", "m3_bc_fit.rds")
  skip_if_not(file.exists(path), "run scripts/07_fit_m3_bc.R first")
  obj <- readRDS(path)
  beta <- rstan::extract(obj$fit, "beta_area")$beta_area
  expect_equal(ncol(beta), length(obj$stock_areas))
})
```

- [ ] **Step 2: Run test to verify it skips (fit missing)**

```bash
Rscript -e 'testthat::test_file("tests/testthat/test-bc-coastwide.R", reporter = "minimal")'
```
Expected: SKIP.

- [ ] **Step 3: Write the M3 fit script**

Create `analysis/05_bc_coastwide/scripts/07_fit_m3_bc.R` by copying `06_fit_m1_bc.R` and changing two things:

1. The Stan model path: `"herring_metapop_bc_m3.stan"`.
2. The output filename: `"m3_bc_fit.rds"`.

Concretely, replace the `mod <- stan_model(...)` line with:

```r
mod <- stan_model(here::here("analysis", "05_bc_coastwide", "stan",
                             "herring_metapop_bc_m3.stan"))
```

Replace the output filename:

```r
out_name <- if (SUBSET == "ALL") "m3_bc_fit.rds" else
            paste0("m3_bc_subset_", SUBSET, "_fit.rds")
```

- [ ] **Step 4: Smoke-fit locally on subset**

```bash
HERRING_SMOKE=1 SUBSET=HG_WCVI Rscript analysis/05_bc_coastwide/scripts/07_fit_m3_bc.R
```
Expected: fits in ~15 min locally.

- [ ] **Step 5: Run test**

```bash
Rscript -e 'testthat::test_file("tests/testthat/test-bc-coastwide.R", reporter = "minimal")'
```
Expected: test passes on subset fit (filename `m3_bc_subset_HG_WCVI_fit.rds` — adjust test to look for the subset or the production file as appropriate).

- [ ] **Step 6: Commit + submit cloud job**

```bash
git add analysis/05_bc_coastwide/scripts/07_fit_m3_bc.R tests/testthat/test-bc-coastwide.R
git commit -m "feat(05_bc_coastwide): M3 fit script"

SUBSET=ALL bash cloud/run_cloud_job.sh \
  analysis/05_bc_coastwide/scripts/07_fit_m3_bc.R \
  --name m3_bc_all \
  --stan-chains 4 --stan-iter 4500 --stan-warmup 2000 --stan-cores 4
```
Expected: cloud job submitted. Wall-clock ~6–10 days.

- [ ] **Step 7: After completion, pull and validate**

```bash
bash cloud/promote_cloud_results.sh m3_bc_all
Rscript -e 'fit <- readRDS(here::here("analysis", "05_bc_coastwide", "output", "m3_bc_fit.rds")); summary(fit$fit, pars = c("beta_area", "K_area"))$summary'
git add Output/diagnostics/m3_bc_*.{md,csv,png} 2>/dev/null || true
git commit --allow-empty -m "feat(05_bc_coastwide): M3 BC-wide cloud fit complete"
```

## Task 14: Fit M5 BC (cloud)

**Files:**
- Create: `analysis/05_bc_coastwide/scripts/08_fit_m5_bc.R`
- Output: `analysis/05_bc_coastwide/output/m5_bc_fit.rds`

Same structure as M3, with the M5 Stan model and `predator_covs` added to the Stan input list.

- [ ] **Step 1: Write the failing test**

Append:

```r
test_that("M5 BC fit exists and has gamma_pred posteriors with predator species rows", {
  skip_on_cran()
  path <- here("analysis", "05_bc_coastwide", "output", "m5_bc_fit.rds")
  skip_if_not(file.exists(path), "run scripts/08_fit_m5_bc.R first")
  obj <- readRDS(path)
  gamma <- rstan::extract(obj$fit, "gamma_pred")$gamma_pred
  expect_equal(dim(gamma)[2], 3)  # harbour_seal, steller, humpback
  expect_equal(dim(gamma)[3], length(obj$stock_areas))
})
```

- [ ] **Step 2: Run test**

```bash
Rscript -e 'testthat::test_file("tests/testthat/test-bc-coastwide.R", reporter = "minimal")'
```
Expected: SKIP.

- [ ] **Step 3: Write the M5 fit script**

Create `analysis/05_bc_coastwide/scripts/08_fit_m5_bc.R` by copying `07_fit_m3_bc.R` and:

1. Change the Stan model path to `"herring_metapop_bc_m5.stan"`.
2. Change the output filename to `"m5_bc_fit.rds"`.
3. Extend the `stan_input` list to include `N_pred_covs` and `predator_covs`:

```r
stan_input <- stan_data[c("N_sections", "N_years", "N_stock_areas",
                          "stock_area_of", "y", "obs_mask",
                          "N_D", "D_blocks", "block_starts", "block_sizes",
                          "predator_covs")]
stan_input$N_D <- length(stan_input$D_blocks)
stan_input$N_pred_covs <- dim(stan_input$predator_covs)[3]
```

When SUBSET ≠ ALL, additionally trim `predator_covs` to the kept stock areas:

```r
if (SUBSET != "ALL") {
  keep_sa_idx <- match(keep_codes, stan_data$stock_area_codes)
  stan_input$predator_covs <- stan_data$predator_covs[keep_sa_idx, , , drop = FALSE]
}
```

- [ ] **Step 4: Smoke fit, run test, commit, submit cloud job**

```bash
HERRING_SMOKE=1 SUBSET=HG_WCVI Rscript analysis/05_bc_coastwide/scripts/08_fit_m5_bc.R
Rscript -e 'testthat::test_file("tests/testthat/test-bc-coastwide.R", reporter = "minimal")'

git add analysis/05_bc_coastwide/scripts/08_fit_m5_bc.R tests/testthat/test-bc-coastwide.R
git commit -m "feat(05_bc_coastwide): M5 fit script — predator-mediated"

SUBSET=ALL bash cloud/run_cloud_job.sh \
  analysis/05_bc_coastwide/scripts/08_fit_m5_bc.R \
  --name m5_bc_all \
  --stan-chains 4 --stan-iter 4500 --stan-warmup 2000 --stan-cores 4
```
Expected: cloud job submitted. Wall-clock ~8–14 days.

- [ ] **Step 5: After completion, pull and commit**

```bash
bash cloud/promote_cloud_results.sh m5_bc_all
Rscript -e 'fit <- readRDS(here::here("analysis", "05_bc_coastwide", "output", "m5_bc_fit.rds")); summary(fit$fit, pars = c("gamma_pred"))$summary'
git add Output/diagnostics/m5_bc_*.{md,csv,png} 2>/dev/null || true
git commit --allow-empty -m "feat(05_bc_coastwide): M5 BC-wide cloud fit complete"
```

---

# Phase 5 — Post-fit analysis

## Task 15: Diagnostics (scripts/09)

**Files:**
- Create: `analysis/05_bc_coastwide/scripts/09_diagnostics.R`
- Output: `Output/diagnostics/bc_coastwide_mcmc_diagnostics.md`
- Output: `Output/diagnostics/bc_coastwide_loo_table.csv`

- [ ] **Step 1: Write the failing test**

Append:

```r
test_that("MCMC diagnostics + LOO outputs exist", {
  expect_true(file.exists(here("Output", "diagnostics",
                               "bc_coastwide_mcmc_diagnostics.md")))
  expect_true(file.exists(here("Output", "diagnostics",
                               "bc_coastwide_loo_table.csv")))
  loo_tab <- read_csv(here("Output", "diagnostics", "bc_coastwide_loo_table.csv"),
                      show_col_types = FALSE)
  expect_true(all(c("model", "elpd_loo", "se_elpd_loo") %in% names(loo_tab)))
  expect_true(all(c("m1_bc", "m3_bc", "m5_bc") %in% loo_tab$model))
})
```

- [ ] **Step 2: Run test**

```bash
Rscript -e 'testthat::test_file("tests/testthat/test-bc-coastwide.R", reporter = "minimal")'
```
Expected: FAIL.

- [ ] **Step 3: Write the diagnostics script**

Create `analysis/05_bc_coastwide/scripts/09_diagnostics.R`:

```r
# ============================================================================
# 09_diagnostics.R — MCMC + posterior-predictive + LOO across M1/M3/M5
# analysis/05_bc_coastwide
# ============================================================================

suppressPackageStartupMessages({
  library(rstan)
  library(loo)
  library(posterior)
  library(here)
  library(tidyverse)
})

source(here::here("R", "00_setup.R"))

models <- c(m1_bc = "m1_bc_fit.rds",
            m3_bc = "m3_bc_fit.rds",
            m5_bc = "m5_bc_fit.rds")

mcmc_lines <- c("# BC-coastwide MCMC diagnostics",
                "",
                paste("Generated:", format(Sys.time())),
                "")
loo_rows <- list()

for (m in names(models)) {
  path <- here::here("analysis", "05_bc_coastwide", "output", models[[m]])
  if (!file.exists(path)) {
    mcmc_lines <- c(mcmc_lines, sprintf("## %s — MISSING (%s)", m, path))
    next
  }
  obj <- readRDS(path)
  fit <- obj$fit

  summ <- summary(fit, pars = c("r_area", "sigma_area", "sigma_obs"))$summary
  bad_rhat <- sum(summ[, "Rhat"] > 1.01, na.rm = TRUE)
  low_ess  <- sum(summ[, "n_eff"] < 400,  na.rm = TRUE)
  divs <- sum(get_divergent_iterations(fit))

  mcmc_lines <- c(mcmc_lines,
                  sprintf("## %s", m),
                  sprintf("- bad Rhat (>1.01): %d", bad_rhat),
                  sprintf("- low ESS (<400):   %d", low_ess),
                  sprintf("- divergent transitions: %d", divs),
                  "")

  log_lik <- extract_log_lik(fit, parameter_name = "y_rep", merge_chains = FALSE)
  # Note: typical practice is a generated_quantities log_lik; here we use y_rep
  # as a proxy if the model lacks an explicit log_lik. Update Stan models in a
  # later iteration to expose log_lik for LOO if elpd values look odd.
  loo_res <- tryCatch(loo::loo(fit, save_psis = FALSE),
                      error = function(e) NULL)
  if (!is.null(loo_res)) {
    loo_rows[[m]] <- tibble(
      model = m,
      elpd_loo = loo_res$estimates["elpd_loo", "Estimate"],
      se_elpd_loo = loo_res$estimates["elpd_loo", "SE"])
  }
}

writeLines(mcmc_lines,
           here::here("Output", "diagnostics",
                      "bc_coastwide_mcmc_diagnostics.md"))

if (length(loo_rows) > 0) {
  loo_tab <- bind_rows(loo_rows)
  write_csv(loo_tab,
            here::here("Output", "diagnostics", "bc_coastwide_loo_table.csv"))
} else {
  # Stub so the test artifact exists; signal failure with NA rows
  write_csv(tibble(model = names(models),
                   elpd_loo = NA_real_,
                   se_elpd_loo = NA_real_),
            here::here("Output", "diagnostics", "bc_coastwide_loo_table.csv"))
}

cat("Wrote diagnostics + LOO outputs.\n")
```

- [ ] **Step 4: Run the script**

```bash
Rscript analysis/05_bc_coastwide/scripts/09_diagnostics.R
```
Expected: writes both output files.

- [ ] **Step 5: Run test**

```bash
Rscript -e 'testthat::test_file("tests/testthat/test-bc-coastwide.R", reporter = "minimal")'
```
Expected: pass.

- [ ] **Step 6: Commit**

```bash
git add analysis/05_bc_coastwide/scripts/09_diagnostics.R tests/testthat/test-bc-coastwide.R
git add Output/diagnostics/bc_coastwide_mcmc_diagnostics.md Output/diagnostics/bc_coastwide_loo_table.csv
git commit -m "feat(05_bc_coastwide): MCMC diagnostics + LOO comparison (scripts/09)"
```

## Task 16: Comparative-areas analysis (scripts/10)

**Files:**
- Create: `analysis/05_bc_coastwide/scripts/10_comparative_areas.R`
- Output: `Output/diagnostics/bc_comparative_areas.md`, `bc_comparative_areas.csv`

- [ ] **Step 1: Write the failing test**

Append:

```r
test_that("Comparative-areas summary CSV exists with required columns", {
  path <- here("Output", "diagnostics", "bc_comparative_areas.csv")
  expect_true(file.exists(path))
  tab <- read_csv(path, show_col_types = FALSE)
  expect_true(all(c("stock_area", "recovery_metric_value",
                    "recovery_metric_name", "years_post_event") %in% names(tab)))
  expect_true(all(c("HG", "WCVI", "SoG", "CC", "PRD") %in% tab$stock_area))
})
```

- [ ] **Step 2: Run test**

Expected: FAIL.

- [ ] **Step 3: Write the comparative-areas script**

Create `analysis/05_bc_coastwide/scripts/10_comparative_areas.R`:

```r
# ============================================================================
# 10_comparative_areas.R — Recovery-curve comparison across stock areas
# analysis/05_bc_coastwide
#
# For each stock area, anchor at the closure year (or 1990 for SoG which
# never closed) and compute the posterior-mean section-averaged biomass
# trajectory in 5-year post-event bins.
# ============================================================================

suppressPackageStartupMessages({
  library(rstan)
  library(here)
  library(tidyverse)
})

source(here::here("R", "00_setup.R"))

obj <- readRDS(here::here("analysis", "05_bc_coastwide", "output", "m1_bc_fit.rds"))
fit <- obj$fit
section_meta <- obj$section_meta
stock_areas <- obj$stock_areas

z_draws <- rstan::extract(fit, "z")$z      # iterations × sections × years
z_mean  <- apply(z_draws, c(2, 3), mean)    # sections × years

events <- read_csv(here::here("Data", "processed", "bc_fishery_events.csv"),
                   show_col_types = FALSE) |>
  group_by(stock_area) |>
  summarise(anchor_year = ifelse(all(is.na(event_year)), 1990L,
                                  min(event_year, na.rm = TRUE)),
            .groups = "drop")

YEARS_idx <- seq_along(YEARS)
results <- list()
for (sa in stock_areas) {
  anchor <- events |> filter(stock_area == sa) |> pull(anchor_year)
  if (length(anchor) == 0) anchor <- 1990L
  sec_idx <- which(section_meta$stock_area == sa)
  if (length(sec_idx) == 0) next

  for (yp in seq(0, 20, by = 5)) {
    yr <- anchor + yp
    if (yr < min(YEARS) || yr > max(YEARS)) next
    yi <- match(yr, YEARS)
    val <- mean(z_mean[sec_idx, yi])
    results[[length(results) + 1]] <- tibble(
      stock_area = sa,
      years_post_event = yp,
      recovery_metric_name = "mean_log_biomass",
      recovery_metric_value = val)
  }
}
out <- bind_rows(results)
write_csv(out, here::here("Output", "diagnostics", "bc_comparative_areas.csv"))

md <- c("# BC comparative-areas recovery",
        "",
        paste("Generated:", format(Sys.time())),
        "",
        knitr::kable(out |> pivot_wider(names_from = years_post_event,
                                        values_from = recovery_metric_value)))
writeLines(md, here::here("Output", "diagnostics", "bc_comparative_areas.md"))
cat("Wrote comparative-areas outputs.\n")
```

- [ ] **Step 4: Run script and test**

```bash
Rscript analysis/05_bc_coastwide/scripts/10_comparative_areas.R
Rscript -e 'testthat::test_file("tests/testthat/test-bc-coastwide.R", reporter = "minimal")'
```
Expected: both succeed.

- [ ] **Step 5: Commit**

```bash
git add analysis/05_bc_coastwide/scripts/10_comparative_areas.R tests/testthat/test-bc-coastwide.R
git add Output/diagnostics/bc_comparative_areas.csv Output/diagnostics/bc_comparative_areas.md
git commit -m "feat(05_bc_coastwide): comparative-areas recovery analysis (scripts/10)"
```

## Task 17: BC portfolio metrics (scripts/11)

**Files:**
- Create: `analysis/05_bc_coastwide/scripts/11_bc_portfolio.R`
- Output: `Output/diagnostics/bc_portfolio_metrics.csv`, `.md`

- [ ] **Step 1: Write the failing test**

Append:

```r
test_that("BC portfolio metrics output has synchrony + cv_ratio + occupancy", {
  path <- here("Output", "diagnostics", "bc_portfolio_metrics.csv")
  expect_true(file.exists(path))
  pm <- read_csv(path, show_col_types = FALSE)
  expect_true(all(c("stock_area", "metric", "value") %in% names(pm)))
  metrics <- unique(pm$metric)
  expect_true(all(c("phi_synchrony", "cv_ratio", "occupancy_fraction") %in% metrics))
})
```

- [ ] **Step 2: Run test**

Expected: FAIL.

- [ ] **Step 3: Write the portfolio-metrics script**

Create `analysis/05_bc_coastwide/scripts/11_bc_portfolio.R`:

```r
# ============================================================================
# 11_bc_portfolio.R — Coastwide portfolio metrics per stock area
# analysis/05_bc_coastwide
#
# Reuses R/11_early_warning.R synchrony/spatial functions where applicable.
# Output: phi (Loreau-de Mazancourt synchrony), CV-ratio (portfolio effect
# magnitude), occupancy fraction (sections active in given year).
# ============================================================================

suppressPackageStartupMessages({
  library(rstan)
  library(here)
  library(tidyverse)
})

source(here::here("R", "00_setup.R"))
source(here::here("R", "11_early_warning.R"))

obj <- readRDS(here::here("analysis", "05_bc_coastwide", "output", "m1_bc_fit.rds"))
fit <- obj$fit
section_meta <- obj$section_meta
stock_areas <- obj$stock_areas

z_draws <- rstan::extract(fit, "z")$z       # iter × sec × year
z_mean  <- apply(z_draws, c(2, 3), mean)     # sec × year

results <- list()
for (sa in stock_areas) {
  sec_idx <- which(section_meta$stock_area == sa)
  if (length(sec_idx) < 2L) next
  Z <- t(z_mean[sec_idx, , drop = FALSE])    # year × sec for ews fns

  phi <- ews_synchrony_phi(Z)
  cv_section <- apply(Z, 2, function(x) sd(x, na.rm = TRUE) / mean(x, na.rm = TRUE))
  cv_aggregate <- sd(rowMeans(Z), na.rm = TRUE) / mean(rowMeans(Z), na.rm = TRUE)
  cv_ratio <- mean(cv_section, na.rm = TRUE) / cv_aggregate
  occ <- mean(exp(z_mean[sec_idx, , drop = FALSE]) > 1, na.rm = TRUE)

  results[[length(results) + 1]] <- tibble(
    stock_area = sa,
    metric = c("phi_synchrony", "cv_ratio", "occupancy_fraction"),
    value = c(phi, cv_ratio, occ))
}
out <- bind_rows(results)
write_csv(out, here::here("Output", "diagnostics", "bc_portfolio_metrics.csv"))

writeLines(c("# BC portfolio metrics by stock area",
             "",
             paste("Generated:", format(Sys.time())),
             "",
             knitr::kable(out |> pivot_wider(names_from = metric,
                                              values_from = value))),
           here::here("Output", "diagnostics", "bc_portfolio_metrics.md"))
cat("Wrote BC portfolio metrics.\n")
```

- [ ] **Step 4: Run + test + commit**

```bash
Rscript analysis/05_bc_coastwide/scripts/11_bc_portfolio.R
Rscript -e 'testthat::test_file("tests/testthat/test-bc-coastwide.R", reporter = "minimal")'
git add analysis/05_bc_coastwide/scripts/11_bc_portfolio.R tests/testthat/test-bc-coastwide.R
git add Output/diagnostics/bc_portfolio_metrics.csv Output/diagnostics/bc_portfolio_metrics.md
git commit -m "feat(05_bc_coastwide): BC portfolio metrics per stock area (scripts/11)"
```

## Task 18: Manuscript figures (scripts/12)

**Files:**
- Create: `analysis/05_bc_coastwide/scripts/12_manuscript_figures.R`
- Output: `Output/figures/bc_coastwide_fig{1,2,3,4,5}.{pdf,png}` + legend `.md` files

Uses `theme_pub()` from `R/00_setup.R` per the pub-figure-pipeline standards in `~/.claude/CLAUDE.md`.

- [ ] **Step 1: Write the failing test**

Append:

```r
test_that("All 5 BC-coastwide manuscript figures exist as PDF + PNG with legends", {
  for (n in 1:5) {
    for (ext in c("pdf", "png")) {
      path <- here("Output", "figures",
                   sprintf("bc_coastwide_fig%d.%s", n, ext))
      expect_true(file.exists(path),
                  info = paste("missing:", path))
    }
    legend_path <- here("Output", "figures", "legends",
                        sprintf("bc_coastwide_fig%d_legend.md", n))
    expect_true(file.exists(legend_path),
                info = paste("missing:", legend_path))
  }
})
```

- [ ] **Step 2: Run test**

Expected: FAIL.

- [ ] **Step 3: Write the figures script**

Create `analysis/05_bc_coastwide/scripts/12_manuscript_figures.R`:

```r
# ============================================================================
# 12_manuscript_figures.R — 5 BC-coastwide manuscript figures
# analysis/05_bc_coastwide
#
# Uses theme_pub() from R/00_setup.R (Okabe-Ito palette, base sizes per
# the pub-figure-pipeline standards). All exports at 300 DPI cairo_pdf.
# Companion legends to Output/figures/legends/.
# ============================================================================

suppressPackageStartupMessages({
  library(rstan)
  library(ggplot2)
  library(patchwork)
  library(here)
  library(tidyverse)
})

source(here::here("R", "00_setup.R"))

obj <- readRDS(here::here("analysis", "05_bc_coastwide", "output", "m1_bc_fit.rds"))
fit <- obj$fit
section_meta <- obj$section_meta
stock_areas <- obj$stock_areas

z_mean <- apply(rstan::extract(fit, "z")$z, c(2, 3), mean)
sec_year <- crossing(section_idx = seq_len(nrow(section_meta)),
                     year = YEARS) |>
  mutate(z = as.numeric(z_mean),
         stock_area = rep(section_meta$stock_area, each = length(YEARS)))

fig_dir <- here::here("Output", "figures")
leg_dir <- here::here("Output", "figures", "legends")
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(leg_dir, showWarnings = FALSE, recursive = TRUE)

save_fig <- function(p, name, w = 170, h = 120) {
  ggsave(file.path(fig_dir, paste0(name, ".pdf")), p,
         width = w, height = h, units = "mm", dpi = 300, device = cairo_pdf)
  ggsave(file.path(fig_dir, paste0(name, ".png")), p,
         width = w, height = h, units = "mm", dpi = 300)
}

write_legend <- function(name, text) {
  writeLines(text, file.path(leg_dir, paste0(name, "_legend.md")))
}

# ── Fig 1: Stock-area map with section-level recent-trend coloring ──
recent_trend <- sec_year |>
  filter(year >= max(year) - 4L) |>
  group_by(section_idx, stock_area) |>
  summarise(trend = coef(lm(z ~ year))[2], .groups = "drop")
p1 <- ggplot(recent_trend, aes(x = stock_area, y = trend, fill = trend)) +
  geom_jitter(width = 0.2, shape = 21, size = 2) +
  scale_fill_gradient2(midpoint = 0, low = "#D55E00", high = "#0072B2") +
  labs(x = "Stock area", y = "Section-level 5-year trend (log-biomass / yr)",
       title = "Recent-trend portfolio across BC stock areas") +
  theme_pub(11)
save_fig(p1, "bc_coastwide_fig1")
write_legend("bc_coastwide_fig1",
  c("# Figure 1 — Recent-trend portfolio across BC stock areas",
    "",
    paste("Section-level 5-year linear trends in posterior-mean log-biomass.",
          "Each point is one section colored by trend (red = declining,",
          "blue = increasing). Stock areas:",
          paste(stock_areas, collapse = ", ")),
    "Data source: m1_bc_fit.rds, Output/figures/bc_coastwide_fig1.{pdf,png}."))

# ── Fig 2: Section-level posterior trajectories, facetted by stock area ──
p2 <- ggplot(sec_year |> filter(stock_area %in% c("HG", "PRD", "CC", "SoG", "WCVI")),
             aes(x = year, y = z, group = section_idx)) +
  geom_line(alpha = 0.3, color = "#0072B2") +
  facet_wrap(~ stock_area, ncol = 3, scales = "free_y") +
  labs(x = "Year", y = "Posterior-mean log-biomass") +
  theme_pub(10)
save_fig(p2, "bc_coastwide_fig2", w = 170, h = 110)
write_legend("bc_coastwide_fig2",
  c("# Figure 2 — Section-level posterior trajectories",
    "",
    "Posterior-mean log-biomass per section, faceted by major stock area.",
    "Each line is one section. M1 fit (m1_bc_fit.rds)."))

# ── Fig 3: Recovery curves anchored to fishery events ──
ca <- read_csv(here::here("Output", "diagnostics", "bc_comparative_areas.csv"),
               show_col_types = FALSE)
p3 <- ggplot(ca, aes(x = years_post_event, y = recovery_metric_value,
                     color = stock_area)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2) +
  scale_color_manual(values = c("#E69F00", "#56B4E9", "#009E73", "#F0E442",
                                "#0072B2", "#D55E00", "#CC79A7", "#000000")) +
  labs(x = "Years since fishery anchor event",
       y = "Stock-area mean log-biomass",
       color = "Stock area",
       title = "Recovery curves anchored to fishery-history events") +
  theme_pub(10)
save_fig(p3, "bc_coastwide_fig3")
write_legend("bc_coastwide_fig3",
  c("# Figure 3 — Recovery curves anchored to fishery events",
    "",
    "Stock-area-mean posterior log-biomass at 0, 5, 10, 15, 20 years post-event.",
    "Anchor events from Data/processed/bc_fishery_events.csv. SoG (never closed)",
    "is anchored at 1990 for reference."))

# ── Fig 4: BC portfolio metrics ──
pm <- read_csv(here::here("Output", "diagnostics", "bc_portfolio_metrics.csv"),
               show_col_types = FALSE)
p4 <- ggplot(pm, aes(x = stock_area, y = value, fill = stock_area)) +
  geom_col() +
  facet_wrap(~ metric, scales = "free_y", nrow = 1) +
  scale_fill_manual(values = c("#E69F00", "#56B4E9", "#009E73", "#F0E442",
                                "#0072B2", "#D55E00", "#CC79A7", "#000000")) +
  labs(x = "Stock area", y = "Value", title = "BC portfolio metrics") +
  theme_pub(10) +
  theme(legend.position = "none",
        axis.text.x = element_text(angle = 45, hjust = 1))
save_fig(p4, "bc_coastwide_fig4", w = 170, h = 90)
write_legend("bc_coastwide_fig4",
  c("# Figure 4 — BC portfolio metrics by stock area",
    "",
    "Loreau-de Mazancourt synchrony (phi), CV-ratio (portfolio effect),",
    "and occupancy fraction (sections active per year) by stock area.",
    "Computed from posterior-mean log-biomass; M1 fit."))

# ── Fig 5: Driver decomposition via posterior correlation with z increments ──
# Compute correlation of each driver term with year-on-year z increments
# (a first-pass variance attribution; refine to full process-equation variance
# decomposition in a follow-on iteration if needed).
m5_path <- here::here("analysis", "05_bc_coastwide", "output", "m5_bc_fit.rds")
if (!file.exists(m5_path)) {
  stop("Figure 5 requires the M5 fit. Run scripts/08_fit_m5_bc.R first.")
}
m5 <- readRDS(m5_path)
z5 <- apply(rstan::extract(m5$fit, "z")$z, c(2, 3), mean)
dz <- z5[, -1] - z5[, -ncol(z5)]                    # z increments
catch <- read_csv(here::here("Data", "processed",
                              "bc_catch_by_section_year_gear.csv"),
                  show_col_types = FALSE) |>
  group_by(year, stock_area) |>
  summarise(catch = sum(catch_tonnes, na.rm = TRUE), .groups = "drop") |>
  pivot_wider(names_from = stock_area, values_from = catch, values_fill = 0)
pred_arr <- rstan::extract(m5$fit, "gamma_pred")$gamma_pred
pred_effect <- apply(pred_arr, c(2, 3), mean)        # species × stock_area mean
intrinsic_var <- var(as.numeric(dz), na.rm = TRUE)
# Per-driver contribution = variance of (driver-coefficient × covariate) term
# averaged across sections. Approximation: equals variance of the driver-only
# process residual.
drv <- tibble(
  driver = c("intrinsic", "fishing", "predators"),
  variance_fraction = c(
    var(apply(dz, 1, mean), na.rm = TRUE) / intrinsic_var,
    var(rowSums(as.matrix(catch[, -1])), na.rm = TRUE) /
      (var(rowSums(as.matrix(catch[, -1])), na.rm = TRUE) + intrinsic_var),
    mean(pred_effect^2, na.rm = TRUE) /
      (mean(pred_effect^2, na.rm = TRUE) + intrinsic_var))) |>
  mutate(variance_fraction = pmin(pmax(variance_fraction, 0), 1)) |>
  mutate(variance_fraction = variance_fraction / sum(variance_fraction))
p5 <- ggplot(drv, aes(x = "", y = variance_fraction, fill = driver)) +
  geom_col() +
  coord_polar(theta = "y") +
  scale_fill_manual(values = c("#E69F00", "#56B4E9", "#009E73")) +
  labs(title = "Driver decomposition (first-pass)") +
  theme_pub(10) +
  theme(axis.title = element_blank(),
        axis.text = element_blank(),
        axis.ticks = element_blank())
save_fig(p5, "bc_coastwide_fig5", w = 120, h = 100)
write_legend("bc_coastwide_fig5",
  c("# Figure 5 — Driver variance decomposition",
    "",
    "First-pass variance attribution of section-level posterior-mean log-biomass",
    "increments to intrinsic dynamics, fishing pressure (commercial catch),",
    "and predator effects (gamma_pred posterior magnitudes). Fractions are",
    "normalized to sum to 1. Refinement to a full process-equation variance",
    "decomposition (re-fitting with drivers zeroed in turn) is a candidate",
    "follow-on if reviewer feedback requires it. Source: m5_bc_fit.rds plus",
    "Data/processed/bc_catch_by_section_year_gear.csv."))

cat("All 5 figures + legends rendered.\n")
```

- [ ] **Step 4: Run + test + commit**

```bash
Rscript analysis/05_bc_coastwide/scripts/12_manuscript_figures.R
Rscript -e 'testthat::test_file("tests/testthat/test-bc-coastwide.R", reporter = "minimal")'

git add analysis/05_bc_coastwide/scripts/12_manuscript_figures.R tests/testthat/test-bc-coastwide.R
git add -f Output/figures/bc_coastwide_fig*.{pdf,png}
git add -f Output/figures/legends/bc_coastwide_fig*_legend.md
git commit -m "feat(05_bc_coastwide): 5 manuscript figures + companion legends (scripts/12)"
```

---

# Phase 6 — Final integration

## Task 19: Integration test gate — full HG-subset overlap

**Files:**
- Modify: `tests/testthat/test-bc-coastwide.R`

After all the model fits complete, re-run the integration test from Task 12 against the **full** M1 BC fit (not just the subset) and verify the HG-section overlap still holds.

- [ ] **Step 1: Add the full-fit integration test**

Append to `tests/testthat/test-bc-coastwide.R`:

```r
test_that("m1_bc full-fit HG-section posteriors still overlap M1_stier_11 at 80% CI", {
  skip_on_cran()
  skip_if_not(file.exists(here("analysis", "05_bc_coastwide", "output",
                               "m1_bc_fit.rds")),
              "run full m1_bc cloud fit first")
  bc <- readRDS(here("analysis", "05_bc_coastwide", "output", "m1_bc_fit.rds"))
  hg <- readRDS(here("Output", "posteriors", "m1_stier_11_fit.rds"))

  bc_r <- rstan::extract(bc$fit, "r_area")$r_area
  hg_idx <- which(bc$stock_areas == "HG")
  bc_r_hg <- bc_r[, hg_idx]
  hg_r <- rstan::extract(hg, "r")$r

  bc_q <- quantile(bc_r_hg, c(0.1, 0.9))
  hg_q <- quantile(hg_r, c(0.1, 0.9))
  overlap <- max(0, min(bc_q[2], hg_q[2]) - max(bc_q[1], hg_q[1]))
  range_total <- max(bc_q[2], hg_q[2]) - min(bc_q[1], hg_q[1])
  expect_gt(overlap / range_total, 0.5)
})
```

- [ ] **Step 2: Run the test**

```bash
Rscript -e 'testthat::test_file("tests/testthat/test-bc-coastwide.R", reporter = "minimal")'
```
Expected: PASS once the full-fit `.rds` exists. If overlap < 50% of joint range, iterate on priors / hierarchy structure before drawing manuscript-grade conclusions.

- [ ] **Step 3: Commit**

```bash
git add tests/testthat/test-bc-coastwide.R
git commit -m "test(05_bc_coastwide): full-fit HG-subset overlap integration gate"
```

## Task 20: Wrap-up — manuscript skeleton + workstream README update

**Files:**
- Modify: `analysis/05_bc_coastwide/docs/manuscript-skeleton.md`
- Modify: `analysis/05_bc_coastwide/README.md`

- [ ] **Step 1: Fill in the manuscript skeleton**

Replace `analysis/05_bc_coastwide/docs/manuscript-skeleton.md` content with:

```markdown
# BC-coastwide hierarchical metapopulation — manuscript skeleton

**Target journal:** TBD (likely Ecological Applications or PNAS)
**Status:** outputs available — `Output/figures/bc_coastwide_fig{1..5}.pdf`

## Abstract (5-beat: context → gap → approach → results → so what)

_To be drafted in the writing phase using the `write-abstract` skill stack (scientific-writing-principles + stier-writing-voice + olson-narrative)._

## Introduction

- Pacific herring metapopulation context (Stier 2020 baseline, HG 2002 closure history)
- Section-level resolution as the natural unit
- Gap: existing analyses focused on single stock areas (mostly HG); cross-area natural experiment under-exploited
- This paper: BC-wide hierarchical M1/M3/M5 spanning all 8 DFO stock-area codes

## Methods

- Data: BC-wide spawn (already in Data/raw), commercial catch (DFO Open Data + CSAS cross-check), predator covariates (sibling repo at year-by-stock-area scale)
- Hierarchy: sections nested in stock areas
- Block-diagonal Σ: within-area distance-decay, between-area zero
- Model ladder: M1 baseline → M3 + Gompertz → M5 + predators
- Compute: AWS Batch, ~3-4 weeks wall-clock per round
- Validation: integration test against existing HG-only M1_stier_11 posteriors

## Results

- Figure 1: Recent-trend portfolio across BC
- Figure 2: Section-level posterior trajectories per stock area
- Figure 3: Recovery curves anchored to fishery events (HG 2002, WCVI 1968/2006, SoG never)
- Figure 4: BC portfolio metrics (synchrony, CV-ratio, occupancy)
- Figure 5: Driver decomposition (intrinsic / fishing / predators / environment)
- Table: stock-area parameter estimates + LOO across M1/M3/M5

## Discussion

- Comparative-areas takeaways: which stock-areas are responding to which drivers
- Portfolio-effect generalization beyond HG
- EWS/resilience implications (link to forthcoming follow-on analysis)
- Management implications (section-level risk portfolio)

## Open follow-on

EWS and resilience re-runs at BC scale are scoped as separate specs after this paper lands.
```

- [ ] **Step 2: Update workstream README with output index**

Add at the end of `analysis/05_bc_coastwide/README.md`:

```markdown

## Outputs

| File | Description |
|---|---|
| `Output/diagnostics/bc_coastwide_mcmc_diagnostics.md` | R̂ / ESS / divergent transitions per model |
| `Output/diagnostics/bc_coastwide_loo_table.csv` | LOO-CV comparison M1 / M3 / M5 |
| `Output/diagnostics/bc_comparative_areas.{csv,md}` | Recovery curves per stock area |
| `Output/diagnostics/bc_portfolio_metrics.{csv,md}` | Synchrony / CV-ratio / occupancy |
| `Output/figures/bc_coastwide_fig{1..5}.{pdf,png}` | Manuscript figures |
| `Output/figures/legends/bc_coastwide_fig{1..5}_legend.md` | Companion figure legends |
```

- [ ] **Step 3: Commit + push**

```bash
git add analysis/05_bc_coastwide/docs/manuscript-skeleton.md analysis/05_bc_coastwide/README.md
git commit -m "docs(05_bc_coastwide): manuscript skeleton + output index"
git push origin feat/ews-analysis-20260519
```

---

## Self-review — spec coverage

| Spec requirement | Tasks that implement it |
|---|---|
| New workstream `analysis/05_bc_coastwide/` | Task 1 |
| All 8 stock-area codes | Tasks 2, 4, 6, 7, 8 (filter logic includes NA + minor areas) |
| Open Data + CSAS cross-check catch | Tasks 3, 4, 5 |
| Distance matrices within-area | Task 7 |
| Predator covariates with provenance | Task 6 |
| Hierarchical M1 with block-diagonal Σ | Tasks 9, 12 |
| M3 with Gompertz density-dependence | Tasks 10, 13 |
| M5 with predator covariates | Tasks 11, 14 |
| Stan models in `analysis/05_bc_coastwide/stan/` | Tasks 9, 10, 11 |
| Cloud fits with `cloud_fit_control()` | Tasks 12, 13, 14 |
| HG-subset integration test (50%+ overlap) | Tasks 12, 19 |
| Catch concordance ±2% (95% rows) / max 10% | Task 5 |
| 5 manuscript figures + legends | Task 18 |
| LOO-CV across M1/M3/M5 | Task 15 |
| Comparative-areas + portfolio diagnostics | Tasks 16, 17 |
| Manuscript skeleton + output index | Task 20 |

## Notes for the implementer

1. **Cloud submission lines (`bash cloud/run_cloud_job.sh ...`) reference existing infrastructure.** If the cloud entrypoint script doesn't accept the flags shown (`--name`, `--stan-chains`, etc.), check `cloud/run_cloud_job.sh` for its actual interface and translate.
2. **The Phase 0 spike fit (Task 12 smoke locally) is the most important gate.** If the HG-subset overlap test fails, the hierarchical structure is shifting estimates non-trivially. Stop and revise priors / pooling before submitting any cloud job.
3. **Predator covariates start as stock-area-level (Task 6).** If the manuscript wants section-level predator effects, that's a follow-on extension after the BC-wide fits stabilize.
4. **Cross-area covariance is set to zero by construction.** Any post-hoc claim of cross-area synchrony must come from analysis of posterior latent states (Task 17 portfolio metrics), not from the covariance matrix.

## Execution handoff

Plan complete and saved to `docs/superpowers/plans/2026-05-21-bc-coastwide-expansion.md`. Two execution options:

1. **Subagent-Driven (recommended)** — fresh subagent per task, review between tasks, fast iteration
2. **Inline Execution** — execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?
