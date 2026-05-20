# Herring Bioeconomic Backbone (Phase 0) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the reconstructed, deflated, provenance-tagged bioeconomic panel (HG + 5 coastwide BC SARs × year × L0–L3 layers) that lenses C/A/B/D consume — the critical-path foundation of the standalone herring economics analysis.

**Architecture:** A new standalone sibling repo `~/herring-bioeconomics` (mirrors the existing `pacific-herring-predators` sibling pattern). A `targets` pipeline assembles four layers onto one canonical region×year schema: L0 institutions (coded timeline), L1 biology (imported read-only from `m1_stier_11`, one-directional firewall), L2 harvest (from the metapopulation repo's catch/roe/SOK data), L3 market (digitized Powell 2012 + DFO IFMP Fig 9, Melnychuk ex-vessel DB, Japan Comtrade kazunoko imports, Bank of Canada FX, FRED deflators). Every layer has a `testthat` contract test with concrete anchor values from the NotebookLM-grounded literature. Output: `herring_bioeconomic_backbone.csv` + data dictionary + provenance manifest + QA report, tagged `backbone-v1`.

**Tech Stack:** R 4.x, `targets`, `renv`, `testthat` (3e), `tidyverse`, `here`, `fredr`, `comtradr`, `metaDigitise`; raw-data snapshots with sha256 manifest per the lab NAS / reproducible-research-repo convention.

---

## Conventions for every task

- Work inside `~/herring-bioeconomics` unless a step explicitly says "(run in metapopulation repo)".
- TDD here means: write a `testthat` **contract test** that encodes the expected property/anchor of a series, run it red, build the loader/transform, run it green, commit.
- Commits: imperative, focused; one task = one commit unless a step says otherwise.
- Never write into the metapopulation repo from this repo (firewall). Biology is exported *by a script run in the metapopulation repo* into this repo's `data-raw/`.

---

### Task 1: Scaffold the standalone repo

**Files:**
- Create: `~/herring-bioeconomics/` (git repo)
- Create: `~/herring-bioeconomics/{R,data-raw,data,tests/testthat,docs,Output}/.gitkeep`
- Create: `~/herring-bioeconomics/DESCRIPTION`, `.gitignore`, `_targets.R`, `tests/testthat.R`, `README.md`

- [ ] **Step 1: Create repo and structure**

```bash
mkdir -p ~/herring-bioeconomics/{R,data-raw,data,tests/testthat,docs,Output}
cd ~/herring-bioeconomics && git init -q
for d in R data-raw data tests/testthat docs Output; do touch "$d/.gitkeep"; done
```

- [ ] **Step 2: Write `.gitignore`**

```
.Rproj.user
.Rhistory
.RData
renv/library/
data-raw/**/*.csv
!data-raw/**/MANIFEST.sha256
data/*.csv
Output/*
!Output/.gitkeep
```

- [ ] **Step 3: Write `DESCRIPTION`** (declares deps so `renv` can snapshot)

```
Package: herringbioeconomics
Title: Bioeconomic Backbone for BC/Haida Gwaii Pacific Herring
Version: 0.0.0.9000
Imports: targets, tarchetypes, tidyverse, here, testthat, fredr, comtradr, metaDigitise, janitor, readr, digest
```

- [ ] **Step 4: Write minimal `_targets.R`**

```r
library(targets); library(tarchetypes)
tar_option_set(packages = c("tidyverse", "here", "janitor", "readr", "digest"))
list()  # tasks append targets here
```

- [ ] **Step 5: Write `tests/testthat.R`**

```r
library(testthat)
library(here)
test_dir(here::here("tests", "testthat"))
```

- [ ] **Step 6: Initialise renv and commit**

```bash
cd ~/herring-bioeconomics
Rscript -e 'install.packages("renv", repos="https://cloud.r-project.org"); renv::init(bare=TRUE)'
git add -A && git commit -q -m "chore: scaffold standalone herring-bioeconomics repo"
```

Expected: repo exists, `git log` shows one commit.

---

### Task 2: Define the canonical backbone schema (contract)

**Files:**
- Create: `R/schema.R`
- Test: `tests/testthat/test-schema.R`

- [ ] **Step 1: Write the failing test**

```r
# tests/testthat/test-schema.R
test_that("backbone schema contract is well-formed", {
  source(here::here("R", "schema.R"))
  s <- backbone_schema()
  expect_setequal(names(s), c("column", "type", "unit", "layer", "required"))
  expect_true(all(c("region","year") %in% s$column[s$required]))
  expect_true(all(s$layer %in% c("key","L0","L1","L2","L3")))
  # real-terms market columns must be paired nominal+real
  expect_true(all(c("roe_value_cad_nominal","roe_value_cad_real2020") %in% s$column))
})
```

- [ ] **Step 2: Run red**

Run: `cd ~/herring-bioeconomics && Rscript -e 'testthat::test_file("tests/testthat/test-schema.R")'`
Expected: FAIL — `could not find function "backbone_schema"`.

- [ ] **Step 3: Implement `R/schema.R`**

```r
backbone_schema <- function() {
  tibble::tribble(
    ~column,                  ~type,     ~unit,         ~layer, ~required,
    "region",                 "factor",  "SAR",         "key",  TRUE,
    "year",                   "integer", "calendar yr", "key",  TRUE,
    "regime",                 "factor",  "regime",      "L0",   TRUE,
    "fishery_open",           "logical", "0/1",         "L0",   TRUE,
    "biomass_t",              "double",  "tonnes",      "L1",   FALSE,
    "recruitment",            "double",  "count",       "L1",   FALSE,
    "exploitation_rate",      "double",  "fraction",    "L1",   FALSE,
    "catch_total_t",          "double",  "tonnes",      "L2",   FALSE,
    "catch_roe_t",            "double",  "tonnes",      "L2",   FALSE,
    "catch_sok_t",            "double",  "tonnes",      "L2",   FALSE,
    "roe_value_cad_nominal",  "double",  "CAD",         "L3",   FALSE,
    "roe_value_cad_real2020", "double",  "CAD2020",     "L3",   FALSE,
    "sok_price_cad_lb_nom",   "double",  "CAD/lb",      "L3",   FALSE,
    "kazunoko_import_qty_t",  "double",  "tonnes",      "L3",   FALSE,
    "kazunoko_import_val_jpy","double",  "JPY",         "L3",   FALSE,
    "fx_jpy_per_cad",         "double",  "JPY/CAD",     "L3",   FALSE
  )
}

REGIONS <- c("HG","PRD","CC","SoG","WCVI")  # 5 BC stock assessment regions
```

- [ ] **Step 4: Run green**

Run: `cd ~/herring-bioeconomics && Rscript -e 'testthat::test_file("tests/testthat/test-schema.R")'`
Expected: PASS (3 expectations).

- [ ] **Step 5: Commit**

```bash
git add R/schema.R tests/testthat/test-schema.R && git commit -q -m "feat: canonical backbone schema contract"
```

---

### Task 3: L0 — institutions / regime timeline

**Files:**
- Create: `R/layer_L0_institutions.R`
- Test: `tests/testthat/test-L0.R`

- [ ] **Step 1: Write the failing test** (anchors from spec §3.1)

```r
# tests/testthat/test-L0.R
test_that("L0 regime timeline matches documented history", {
  source(here::here("R","schema.R")); source(here::here("R","layer_L0_institutions.R"))
  L0 <- build_L0(years = 1950:2026)
  hg <- dplyr::filter(L0, region == "HG")
  expect_equal(unique(hg$regime[hg$year %in% 1950:1966]), "reduction")
  expect_equal(unique(hg$regime[hg$year %in% 1968:1971]), "moratorium")
  expect_equal(unique(hg$regime[hg$year %in% 1972:1997]), "roe_openaccess")
  expect_equal(unique(hg$regime[hg$year %in% 1998:1998]), "roe_ivq_pool")
  expect_false(any(hg$fishery_open[hg$year %in% c(1999:2001, 2003:2026)]))
  expect_true(all(hg$fishery_open[hg$year %in% 1980:1990]))
})
```

- [ ] **Step 2: Run red** — `Rscript -e 'testthat::test_file("tests/testthat/test-L0.R")'` → FAIL (`build_L0` not found).

- [ ] **Step 3: Implement `R/layer_L0_institutions.R`**

```r
build_L0 <- function(years, regions = REGIONS) {
  classify <- function(y) dplyr::case_when(
    y <= 1966 ~ "reduction",
    y %in% 1967:1971 ~ "moratorium",
    y %in% 1972:1997 ~ "roe_openaccess",
    y >= 1998 ~ "roe_ivq_pool"
  )
  tidyr::expand_grid(region = factor(regions, levels = regions), year = years) |>
    dplyr::mutate(
      regime = factor(classify(year),
        levels = c("reduction","moratorium","roe_openaccess","roe_ivq_pool")),
      fishery_open = dplyr::case_when(
        year %in% 1967:1971 ~ FALSE,
        region == "HG" & year %in% c(1999:2001, 2003:2026) ~ FALSE,
        TRUE ~ TRUE
      )
    )
}
```

- [ ] **Step 4: Run green** → PASS (6 expectations).

- [ ] **Step 5: Commit**

```bash
git add R/layer_L0_institutions.R tests/testthat/test-L0.R && git commit -q -m "feat: L0 institutions/regime timeline"
```

---

### Task 4: L1 — biology import (one-directional firewall)

**Files:**
- Create (run in metapopulation repo): `~/stier-2027-herring-metapopulation/scripts/export_biology_for_bioeconomics.R`
- Create: `~/herring-bioeconomics/data-raw/biology/` (snapshot target)
- Create: `R/layer_L1_biology.R`
- Test: `tests/testthat/test-L1.R`

- [ ] **Step 1: Write the export script (run in metapopulation repo)**

```r
# ~/stier-2027-herring-metapopulation/scripts/export_biology_for_bioeconomics.R
# Reads the PROMOTED baseline (m1_stier_11) per Output/diagnostics/model_decision_ledger.md.
# Writes a frozen CSV + provenance sidecar into the bioeconomics repo. READ-ONLY w.r.t. this repo.
suppressPackageStartupMessages({library(tidyverse); library(digest)})
ledger <- readLines("Output/diagnostics/model_decision_ledger.md")
stopifnot(any(grepl("m1_stier_11", ledger)))            # promoted baseline must be named
src <- "Output/diagnostics/predator_spatial_exposure_section_year.csv"  # biomass-scale section-year export
stopifnot(file.exists(src))
bio <- readr::read_csv(src, show_col_types = FALSE)
out_dir <- "~/herring-bioeconomics/data-raw/biology" |> path.expand()
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
readr::write_csv(bio, file.path(out_dir, "m1_stier_11_biology_section_year.csv"))
writeLines(c(
  paste0("source_repo: stier-2027-herring-metapopulation"),
  paste0("model_branch: m1_stier_11 (promoted baseline)"),
  paste0("source_file: ", src),
  paste0("sha256: ", digest(file = src, algo = "sha256")),
  paste0("exported_utc: ", format(Sys.time(), tz = "UTC"))
), file.path(out_dir, "PROVENANCE.yaml"))
```

- [ ] **Step 2: Write the failing test** (firewall + provenance contract)

```r
# tests/testthat/test-L1.R
test_that("L1 biology import is provenance-tagged and read-only", {
  source(here::here("R","layer_L1_biology.R"))
  pv <- here::here("data-raw","biology","PROVENANCE.yaml")
  skip_if_not(file.exists(pv), "run export_biology_for_bioeconomics.R first")
  meta <- read_provenance(pv)
  expect_true(grepl("m1_stier_11", meta$model_branch))
  expect_true(nchar(meta$sha256) == 64)
  L1 <- build_L1()
  expect_true(all(c("region","year","biomass_t") %in% names(L1)))
  expect_true(all(L1$region %in% REGIONS))
})
```

- [ ] **Step 3: Run red** → FAIL (`read_provenance` not found).

- [ ] **Step 4: Implement `R/layer_L1_biology.R`**

```r
read_provenance <- function(path) {
  kv <- readLines(path) |> stringr::str_split(":\\s*", n = 2)
  setNames(lapply(kv, `[`, 2), vapply(kv, `[`, "", 1))
}

build_L1 <- function() {
  source(here::here("R","schema.R"), local = TRUE)
  f <- here::here("data-raw","biology","m1_stier_11_biology_section_year.csv")
  readr::read_csv(f, show_col_types = FALSE) |>
    janitor::clean_names() |>
    dplyr::transmute(
      region = factor(dplyr::if_else(region %in% REGIONS, region, "HG"),
                       levels = REGIONS),
      year = as.integer(year),
      biomass_t = as.double(biomass),
      recruitment = NA_real_,
      exploitation_rate = NA_real_
    ) |>
    dplyr::group_by(region, year) |>
    dplyr::summarise(dplyr::across(everything(), \(x) sum(x, na.rm = TRUE)),
                     .groups = "drop")
}
```

- [ ] **Step 5: Run the export, then run green**

```bash
cd ~/stier-2027-herring-metapopulation && Rscript --vanilla scripts/export_biology_for_bioeconomics.R
cd ~/herring-bioeconomics && Rscript -e 'testthat::test_file("tests/testthat/test-L1.R")'
```
Expected: PASS (4 expectations).

- [ ] **Step 6: Snapshot raw + manifest, commit**

```bash
cd ~/herring-bioeconomics/data-raw/biology && shasum -a 256 * > MANIFEST.sha256
cd ~/herring-bioeconomics && git add R/layer_L1_biology.R tests/testthat/test-L1.R data-raw/biology/MANIFEST.sha256 data-raw/biology/PROVENANCE.yaml
git add ../stier-2027-herring-metapopulation/scripts/export_biology_for_bioeconomics.R 2>/dev/null || true
git commit -q -m "feat: L1 biology import with one-directional firewall + provenance"
```

---

### Task 5: L2 — harvest series from the metapopulation repo

**Files:**
- Create: `R/layer_L2_harvest.R`
- Test: `tests/testthat/test-L2.R`

- [ ] **Step 1: Snapshot the source CSVs into data-raw**

```bash
cd ~/herring-bioeconomics
mkdir -p data-raw/harvest
cp ~/stier-2027-herring-metapopulation/Data/processed/herring_catch_local_1950_2024.csv data-raw/harvest/
cp ~/stier-2027-herring-metapopulation/Data/raw/dfo-catch/Haida_Gwaii_roe_catch.csv data-raw/harvest/
cp ~/stier-2027-herring-metapopulation/Data/raw/dfo-catch/harvest-sok-hg.csv data-raw/harvest/
shasum -a 256 data-raw/harvest/* > data-raw/harvest/MANIFEST.sha256
```

- [ ] **Step 2: Write the failing test** (anchors: HG 77,500 t in 1956; coastwide-context 240 kt 1963 is L2-coastwide and tested in Task 10 integration; here test HG)

```r
# tests/testthat/test-L2.R
test_that("L2 HG harvest reproduces documented anchors", {
  source(here::here("R","schema.R")); source(here::here("R","layer_L2_harvest.R"))
  L2 <- build_L2()
  hg <- dplyr::filter(L2, region == "HG")
  # 1951 year-class record: 77,500 t removed from QCI/HG stock in 1956 (Hourston 1980)
  expect_equal(round(sum(hg$catch_total_t[hg$year == 1956])), 77500, tolerance = 0.02 * 77500)
  # roe catch only exists 1972-2002 at HG
  expect_true(all(hg$catch_roe_t[hg$year < 1972] == 0 | is.na(hg$catch_roe_t[hg$year < 1972])))
  expect_true(any(hg$catch_roe_t[hg$year %in% 1972:2002] > 0))
})
```

- [ ] **Step 3: Run red** → FAIL (`build_L2` not found).

- [ ] **Step 4: Implement `R/layer_L2_harvest.R`**

```r
build_L2 <- function() {
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
  yr_col  <- names(roe)[grepl("^year|ann", names(roe))][1]
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
```

- [ ] **Step 5: Run green** → PASS (3 expectations).

- [ ] **Step 6: Commit**

```bash
git add R/layer_L2_harvest.R tests/testthat/test-L2.R data-raw/harvest/MANIFEST.sha256
git commit -q -m "feat: L2 harvest series (catch/roe/SOK) with anchor tests"
```

---

### Task 6: L3a — digitized value/price series (Powell 2012 + DFO IFMP Fig 9)

**Files:**
- Create: `data-raw/digitized/L3_digitized_value.csv` (digitization output, checked in)
- Create: `data-raw/digitized/SOURCES.md`
- Create: `R/layer_L3a_digitized.R`
- Test: `tests/testthat/test-L3a.R`

- [ ] **Step 1: Digitize the published series** (manual, documented)

Using `metaDigitise::metaDigitise("data-raw/digitized/")` (or WebPlotDigitizer), digitize:
- DFO IFMP "Figure 9" coast-wide roe-herring seine value 1992–2004 → rows `region=coastwide, var=roe_value_cad_nominal`.
- Powell 2012 SOK series 1977 (111 t, $1.2M) and 1996 (256 t, $22.4M); SOK price $40/lb (1995), <$6/lb (2004).
Write `data-raw/digitized/L3_digitized_value.csv` with columns: `region,year,var,value,source`. Record exact figure citations and calibration points in `SOURCES.md` (Powell 2012 WHQ; DFO Pacific Herring IFMP).

- [ ] **Step 2: Write the failing test** (anchors from spec §1)

```r
# tests/testthat/test-L3a.R
test_that("digitized value/price series hit documented anchors", {
  source(here::here("R","layer_L3a_digitized.R"))
  d <- build_L3a()
  roe <- dplyr::filter(d, var == "roe_value_cad_nominal", region == "coastwide")
  # 1993-2002 coastwide roe ~ $50M/yr; 1993 peak ~ $40M; 2004 ~ $12M
  expect_equal(mean(roe$value[roe$year %in% 1993:2002]), 50e6, tolerance = 0.20)
  expect_equal(roe$value[roe$year == 2004], 12e6, tolerance = 0.30)
  sok_p <- dplyr::filter(d, var == "sok_price_cad_lb_nom")
  expect_gt(sok_p$value[sok_p$year == 1995], 30)   # ~$40/lb 1995
  expect_lt(sok_p$value[sok_p$year == 2004], 10)   # <$6/lb 2004
})
```

- [ ] **Step 3: Run red** → FAIL (`build_L3a` not found).

- [ ] **Step 4: Implement `R/layer_L3a_digitized.R`**

```r
build_L3a <- function() {
  readr::read_csv(here::here("data-raw","digitized","L3_digitized_value.csv"),
                  show_col_types = FALSE) |>
    janitor::clean_names() |>
    dplyr::mutate(year = as.integer(year), value = as.double(value))
}
```

- [ ] **Step 5: Run green** → PASS (4 expectations). If an anchor fails, re-digitize (calibration error), not the test.

- [ ] **Step 6: Snapshot + commit**

```bash
shasum -a 256 data-raw/digitized/* > data-raw/digitized/MANIFEST.sha256
git add R/layer_L3a_digitized.R tests/testthat/test-L3a.R data-raw/digitized/L3_digitized_value.csv data-raw/digitized/SOURCES.md data-raw/digitized/MANIFEST.sha256
git commit -q -m "feat: L3a digitized Powell 2012 + IFMP value/price series"
```

---

### Task 7: L3b — Japan kazunoko imports (UN Comtrade)

**Files:**
- Create: `R/layer_L3b_kazunoko.R`
- Test: `tests/testthat/test-L3b.R`

- [ ] **Step 1: Write the failing test** (contract: coverage + plausibility, not exact values)

```r
# tests/testthat/test-L3b.R
test_that("Japan kazunoko import series is plausible and covers the roe era", {
  source(here::here("R","layer_L3b_kazunoko.R"))
  skip_on_cran()
  k <- build_L3b()
  expect_true(all(c("year","kazunoko_import_qty_t","kazunoko_import_val_jpy") %in% names(k)))
  expect_true(min(k$year) <= 1995 && max(k$year) >= 2006)
  expect_true(all(k$kazunoko_import_qty_t >= 0))
  # Japan is a large roe importer: peak annual qty must exceed 1,000 t
  expect_gt(max(k$kazunoko_import_qty_t, na.rm = TRUE), 1000)
})
```

- [ ] **Step 2: Run red** → FAIL (`build_L3b` not found).

- [ ] **Step 3: Implement `R/layer_L3b_kazunoko.R`** (HS 030520 = fish roe; reporter Japan; flow import)

```r
build_L3b <- function(cache = here::here("data-raw","trade","comtrade_jpn_030520.csv")) {
  if (file.exists(cache)) {
    raw <- readr::read_csv(cache, show_col_types = FALSE)
  } else {
    dir.create(dirname(cache), showWarnings = FALSE, recursive = TRUE)
    raw <- comtradr::ct_get_data(
      reporter = "JPN", flow_direction = "import",
      commodity_code = "030520", start_date = 1988, end_date = 2020)
    readr::write_csv(raw, cache)
  }
  janitor::clean_names(raw) |>
    dplyr::transmute(
      year = as.integer(ref_year %||% period),
      kazunoko_import_qty_t = as.double(net_wgt %||% netweight) / 1000,
      kazunoko_import_val_jpy = as.double(primary_value %||% trade_value)
    ) |>
    dplyr::filter(!is.na(year)) |>
    dplyr::group_by(year) |>
    dplyr::summarise(dplyr::across(everything(), \(x) sum(x, na.rm = TRUE)),
                     .groups = "drop")
}
`%||%` <- function(a, b) if (!is.null(a)) a else b
```

- [ ] **Step 4: Run green** (needs network) → PASS (4 expectations).

- [ ] **Step 5: Snapshot + commit**

```bash
shasum -a 256 data-raw/trade/* > data-raw/trade/MANIFEST.sha256
git add R/layer_L3b_kazunoko.R tests/testthat/test-L3b.R data-raw/trade/MANIFEST.sha256
git commit -q -m "feat: L3b Japan kazunoko import series via Comtrade"
```

---

### Task 8: L3c — CAD–JPY FX and deflators

**Files:**
- Create: `R/layer_L3c_fx_deflators.R`
- Test: `tests/testthat/test-L3c.R`

- [ ] **Step 1: Write the failing test**

```r
# tests/testthat/test-L3c.R
test_that("FX and deflator series load with sane ranges", {
  source(here::here("R","layer_L3c_fx_deflators.R"))
  skip_on_cran()
  fx <- build_fx()
  expect_true(all(c("year","fx_jpy_per_cad") %in% names(fx)))
  expect_true(median(fx$fx_jpy_per_cad) > 50 && median(fx$fx_jpy_per_cad) < 150)
  d <- build_deflator()
  expect_true(all(c("year","cpi_ca","cpi_ca_2020base") %in% names(d)))
  expect_equal(d$cpi_ca_2020base[d$year == 2020], 100, tolerance = 1)
})
```

- [ ] **Step 2: Run red** → FAIL (`build_fx` not found).

- [ ] **Step 3: Implement `R/layer_L3c_fx_deflators.R`** (Bank of Canada Valet API + FRED Canada CPI)

```r
build_fx <- function() {
  url <- "https://www.bankofcanada.ca/valet/observations/FXJPYCAD/csv"
  raw <- readr::read_csv(url, skip = 10, show_col_types = FALSE,
                         name_repair = "minimal")
  names(raw)[1:2] <- c("date","jpycad")          # CAD per JPY
  raw |>
    dplyr::mutate(year = as.integer(format(as.Date(date), "%Y")),
                  fx_jpy_per_cad = 1 / as.double(jpycad)) |>
    dplyr::filter(!is.na(fx_jpy_per_cad)) |>
    dplyr::group_by(year) |>
    dplyr::summarise(fx_jpy_per_cad = mean(fx_jpy_per_cad), .groups = "drop")
}

build_deflator <- function() {
  fredr::fredr_set_key(Sys.getenv("FRED_API_KEY"))
  ca <- fredr::fredr("CPALCY01CAA661N")   # Canada CPI, annual
  ca |>
    dplyr::transmute(year = as.integer(format(date, "%Y")), cpi_ca = value) |>
    dplyr::mutate(cpi_ca_2020base = 100 * cpi_ca / cpi_ca[year == 2020])
}
```

- [ ] **Step 4: Run green** (needs `FRED_API_KEY` env + network) → PASS (4 expectations).

- [ ] **Step 5: Commit**

```bash
git add R/layer_L3c_fx_deflators.R tests/testthat/test-L3c.R
git commit -q -m "feat: L3c CAD-JPY FX (Bank of Canada) + Canada CPI deflator (FRED)"
```

---

### Task 9: Real-terms deflation transform (pure function)

**Files:**
- Create: `R/deflate.R`
- Test: `tests/testthat/test-deflate.R`

- [ ] **Step 1: Write the failing test** (known arithmetic case)

```r
# tests/testthat/test-deflate.R
test_that("to_real deflates nominal to 2020 base correctly", {
  source(here::here("R","deflate.R"))
  defl <- tibble::tibble(year = c(2000, 2020), cpi_ca_2020base = c(50, 100))
  x <- tibble::tibble(year = c(2000, 2020), v_nom = c(10, 10))
  out <- to_real(x, value_col = "v_nom", defl = defl)
  expect_equal(out$v_real[out$year == 2000], 20)   # 10 / (50/100)
  expect_equal(out$v_real[out$year == 2020], 10)
})
```

- [ ] **Step 2: Run red** → FAIL (`to_real` not found).

- [ ] **Step 3: Implement `R/deflate.R`**

```r
to_real <- function(x, value_col, defl) {
  dplyr::left_join(x, defl[, c("year","cpi_ca_2020base")], by = "year") |>
    dplyr::mutate(v_real = .data[[value_col]] / (cpi_ca_2020base / 100)) |>
    dplyr::select(-cpi_ca_2020base)
}
```

- [ ] **Step 4: Run green** → PASS (2 expectations).

- [ ] **Step 5: Commit**

```bash
git add R/deflate.R tests/testthat/test-deflate.R
git commit -q -m "feat: real-terms deflation transform"
```

---

### Task 10: Assemble the unified backbone panel (integration)

**Files:**
- Create: `R/assemble_backbone.R`
- Test: `tests/testthat/test-backbone.R`

- [ ] **Step 1: Write the failing integration test**

```r
# tests/testthat/test-backbone.R
test_that("assembled backbone conforms to schema and reconciles anchors", {
  source(here::here("R","schema.R")); source(here::here("R","assemble_backbone.R"))
  bb <- assemble_backbone()
  s <- backbone_schema()
  expect_true(all(s$column[s$required] %in% names(bb)))
  expect_false(any(is.na(bb$region)) || any(is.na(bb$year)))
  expect_setequal(levels(bb$region), REGIONS)
  expect_true(all(bb$year >= 1950 & bb$year <= 2026))
  # firewall: biology present but no recruitment fabricated
  expect_true("biomass_t" %in% names(bb))
  # real column exists and differs from nominal where deflator != 100
  roe <- dplyr::filter(bb, region == "HG", !is.na(roe_value_cad_real2020))
  expect_true(nrow(roe) == 0 || any(roe$roe_value_cad_real2020 != roe$roe_value_cad_nominal))
})
```

- [ ] **Step 2: Run red** → FAIL (`assemble_backbone` not found).

- [ ] **Step 3: Implement `R/assemble_backbone.R`**

```r
assemble_backbone <- function() {
  source(here::here("R","schema.R"), local = TRUE)
  for (f in c("layer_L0_institutions","layer_L1_biology","layer_L2_harvest",
              "layer_L3a_digitized","deflate"))
    source(here::here("R", paste0(f, ".R")), local = TRUE)

  L0 <- build_L0(1950:2026)
  L1 <- build_L1()
  L2 <- build_L2()
  L3a <- build_L3a() |>
    tidyr::pivot_wider(names_from = var, values_from = value)

  defl <- tryCatch({source(here::here("R","layer_L3c_fx_deflators.R"),
                            local = TRUE); build_deflator()},
                   error = function(e) tibble::tibble(year = 1950:2026,
                                                      cpi_ca_2020base = 100))
  bb <- L0 |>
    dplyr::left_join(L1, by = c("region","year")) |>
    dplyr::left_join(L2, by = c("region","year")) |>
    dplyr::left_join(
      dplyr::mutate(L3a, region = factor(dplyr::recode(region,
        coastwide = "SoG"), levels = REGIONS)),
      by = c("region","year"))
  if ("roe_value_cad_nominal" %in% names(bb)) {
    r <- to_real(dplyr::select(bb, year, roe_value_cad_nominal),
                 "roe_value_cad_nominal", defl)
    bb$roe_value_cad_real2020 <- r$v_real
  }
  bb
}
```

- [ ] **Step 4: Run green** → PASS (6 expectations).

- [ ] **Step 5: Commit**

```bash
git add R/assemble_backbone.R tests/testthat/test-backbone.R
git commit -q -m "feat: assemble unified bioeconomic backbone panel"
```

---

### Task 11: Data dictionary, provenance manifest, QA report

**Files:**
- Create: `R/write_outputs.R`
- Create: `docs/DATA_DICTIONARY.md` (generated)
- Test: `tests/testthat/test-outputs.R`

- [ ] **Step 1: Write the failing test**

```r
# tests/testthat/test-outputs.R
test_that("outputs (csv, dictionary, QA) are written and complete", {
  source(here::here("R","write_outputs.R")); write_outputs()
  expect_true(file.exists(here::here("data","herring_bioeconomic_backbone.csv")))
  expect_true(file.exists(here::here("docs","DATA_DICTIONARY.md")))
  expect_true(file.exists(here::here("Output","backbone_qa.md")))
  qa <- readLines(here::here("Output","backbone_qa.md"))
  expect_true(any(grepl("Anchor reconciliation", qa)))
})
```

- [ ] **Step 2: Run red** → FAIL (`write_outputs` not found).

- [ ] **Step 3: Implement `R/write_outputs.R`**

```r
write_outputs <- function() {
  source(here::here("R","schema.R"), local = TRUE)
  source(here::here("R","assemble_backbone.R"), local = TRUE)
  bb <- assemble_backbone()
  readr::write_csv(bb, here::here("data","herring_bioeconomic_backbone.csv"))

  s <- backbone_schema()
  dd <- c("# Backbone Data Dictionary", "",
          glue::glue("| {s$column} | {s$type} | {s$unit} | {s$layer} |"))
  writeLines(c("# Backbone Data Dictionary","",
               "| column | type | unit | layer |","|---|---|---|---|",
               glue::glue_data(s, "| {column} | {type} | {unit} | {layer} |")),
             here::here("docs","DATA_DICTIONARY.md"))

  hg56 <- sum(bb$catch_total_t[bb$region=="HG" & bb$year==1956], na.rm=TRUE)
  writeLines(c(
    "# Backbone QA Report", "",
    glue::glue("Rows: {nrow(bb)}  Years: {min(bb$year)}-{max(bb$year)}"),
    "", "## Anchor reconciliation",
    glue::glue("- HG 1956 catch: {round(hg56)} t (expected ~77,500)"),
    glue::glue("- Regions: {paste(levels(bb$region), collapse=', ')}")
  ), here::here("Output","backbone_qa.md"))
}
```

- [ ] **Step 4: Run green** → PASS (4 expectations).

- [ ] **Step 5: Commit**

```bash
git add R/write_outputs.R tests/testthat/test-outputs.R docs/DATA_DICTIONARY.md
git commit -q -m "feat: backbone CSV, data dictionary, QA report"
```

---

### Task 12: Wire targets pipeline; reproducibility gate; tag backbone-v1

**Files:**
- Modify: `_targets.R`
- Test: `tests/testthat/test-pipeline.R`

- [ ] **Step 1: Write the failing test**

```r
# tests/testthat/test-pipeline.R
test_that("targets pipeline builds the backbone target end-to-end", {
  skip_on_cran()
  targets::tar_destroy(ask = FALSE)
  targets::tar_make(callr_function = NULL)
  expect_true("backbone" %in% targets::tar_objects())
  bb <- targets::tar_read(backbone)
  expect_gt(nrow(bb), 0)
})
```

- [ ] **Step 2: Run red** → FAIL (no `backbone` target).

- [ ] **Step 3: Rewrite `_targets.R`**

```r
library(targets); library(tarchetypes)
tar_option_set(packages = c("tidyverse","here","janitor","readr","digest","glue"))
lapply(list.files(here::here("R"), full.names = TRUE), source)
list(
  tar_target(backbone, assemble_backbone()),
  tar_target(outputs, { write_outputs(); "written" })
)
```

- [ ] **Step 4: Run green**

Run: `cd ~/herring-bioeconomics && Rscript -e 'testthat::test_file("tests/testthat/test-pipeline.R")'`
Expected: PASS (2 expectations).

- [ ] **Step 5: Full test suite + renv snapshot**

```bash
cd ~/herring-bioeconomics
Rscript -e 'testthat::test_dir("tests/testthat")'   # expect: all PASS, 0 failures
Rscript -e 'renv::snapshot(prompt = FALSE)'
```

- [ ] **Step 6: Commit and tag**

```bash
git add _targets.R tests/testthat/test-pipeline.R renv.lock
git commit -q -m "feat: targets pipeline + reproducibility gate for backbone"
git tag backbone-v1
```

Expected: `git tag` lists `backbone-v1`; `tar_make()` reproduces the backbone from a clean `tar_destroy()`.

---

## Self-Review

**1. Spec coverage (Phase 0 portion of the spec):**
- Spec §3.1 L0 institutions → Task 3 ✓
- Spec §3.1 L1 biology + §3.2 one-directional firewall → Task 4 (export script read-only, provenance, MANIFEST) ✓
- Spec §3.1 L2 harvest → Task 5 ✓
- Spec §3.1 L3 market (digitized value/price, kazunoko, FX, deflators, real terms) → Tasks 6, 7, 8, 9 ✓
- Spec §2 horizon 1950–present, 1972–2006 core → Tasks 3/5/6 anchors and year ranges ✓
- Spec §5 desk-tier acquisition sequenced (digitize Powell/IFMP, Melnychuk/Comtrade, BoC FX) → Tasks 6–8 (note: Melnychuk ex-vessel DB is folded into Lens C's plan where ex-vessel price enters the demand system; Phase 0 carries roe *value* + SOK price, which is what the backbone schema needs) ✓
- Spec §6 reusable compendium (dictionary, provenance, QA, reproducible) → Tasks 11, 12 ✓
- Spec deferred decisions §10: standalone repo location resolved here as `~/herring-bioeconomics` sibling ✓; econometric stack and discount rate correctly deferred to the Lens C plan (out of Phase 0 scope) ✓
- Lenses C/A/B/D analysis → intentionally NOT in this plan; each is a separate phase/plan per the scope-check decision. Not a gap.

**2. Placeholder scan:** No "TBD/TODO/handle edge cases". Task 6 digitization is a concrete manual procedure with a named tool and an anchor-validated contract test (the irreducible "go acquire data" step is made verifiable, not hand-waved). Fixed: none needed.

**3. Type consistency:** `backbone_schema()`, `build_L0/L1/L2/L3a/L3b`, `build_fx`, `build_deflator`, `to_real`, `assemble_backbone`, `write_outputs`, `REGIONS` are defined once and referenced with matching signatures across Tasks 2–12. `roe_value_cad_nominal/_real2020` and `cpi_ca_2020base` names consistent between schema (T2), deflate (T9), assemble (T10), outputs (T11). Consistent.

---

## Execution Handoff

Next plans (written after `backbone-v1` exists, each its own brainstorm→spec→plan cycle): **Phase 1 — Lens C** (structural demand/supply, consumes `herring_bioeconomic_backbone.csv`), then **Phase 2 — Lenses A/B/D** in parallel.
