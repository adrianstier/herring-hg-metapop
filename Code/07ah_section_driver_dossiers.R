library(tidyverse)
library(here)
library(glue)

proj_dir <- here::here()
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)

read_diag <- function(file) {
  readr::read_csv(file.path(diag_dir, file), show_col_types = FALSE)
}

fmt_num <- function(x, digits = 2) {
  if_else(
    is.na(x),
    "NA",
    format(round(as.numeric(x), digits), nsmall = digits, trim = TRUE)
  )
}

fmt_pct <- function(x, digits = 0) {
  if_else(
    is.na(x),
    "NA",
    paste0(format(round(100 * as.numeric(x), digits), nsmall = digits, trim = TRUE), "%")
  )
}

section_tbl <- read_diag("section_narrative_synthesis.csv")
scorecard_tbl <- read_diag("m1_stier_11_section_scorecard.csv")
postclosure_tbl <- read_diag("m1_stier_11_postclosure_recovery_by_section.csv")
density_tbl <- read_diag("density_dependence_by_section.csv") %>%
  select(site, dd_spearman_rho = spearman_rho, dd_lm_slope = lm_slope)
current_tbl <- read_diag("m1_stier_11_current_year_status.csv") %>%
  select(site, survey_status_2025 = survey_status, current_share, below_20pct_early)

driver_dossiers <- section_tbl %>%
  select(
    site,
    site_name,
    focal_status,
    talk_role,
    typology,
    recent_to_early_ratio,
    recent_biomass_share,
    current_share,
    contribution_recent_minus_early,
    contribution_recent_minus_roe,
    mean_fishing_fraction_1951_2004,
    fishing_only_resid,
    catch_share,
    survey_coverage,
    surveyed_years,
    zero_record_years,
    missing_years,
    recent_rel_width_90,
    spawn_fit_rmse,
    recent_minus_pre_mhw,
    recent_minus_mhw,
    main_caveat
  ) %>%
  left_join(
    scorecard_tbl %>%
      select(
        site,
        status,
        recent_years_below_20pct,
        recent_years_below_10pct,
        recovery_class,
        closure_pct_per_year,
        recent_pct_per_year
      ),
    by = "site"
  ) %>%
  left_join(
    postclosure_tbl %>%
      select(site, rebound_from_postclosure_min, closure_r2),
    by = "site"
  ) %>%
  left_join(density_tbl, by = "site") %>%
  left_join(current_tbl, by = "site", suffix = c("", "_current")) %>%
  mutate(
    evidence_summary = case_when(
      talk_role == "mechanism scrutiny" ~
        "Persistent depletion remains worse than expected from the simple fishing-pressure screen.",
      talk_role == "portfolio concern" ~
        "Persistent depletion or stagnation contributes to portfolio weakness.",
      talk_role == "recovery contrast" ~
        "Recovery contrast section showing that closure-era response is spatially uneven.",
      talk_role == "sensitivity caveat" ~
        "Sparse section retained in the 11-section fit but not suitable as headline evidence.",
      TRUE ~ "Intermediate section useful for context."
    ),
    driver_read = case_when(
      talk_role == "mechanism scrutiny" ~
        "Scrutinize local productivity, habitat/survey context, and governance/access history before regional predators.",
      fishing_only_resid <= -1 ~
        "More depleted than mean fishing fraction predicts; look beyond fishing alone.",
      mean_fishing_fraction_1951_2004 >= median(mean_fishing_fraction_1951_2004, na.rm = TRUE) &
        recent_to_early_ratio < 0.5 ~
        "Historical fishing is a plausible major axis, but not necessarily sufficient.",
      talk_role == "recovery contrast" ~
        "Useful positive contrast for post-closure recovery despite regional constraints.",
      talk_role == "sensitivity caveat" ~
        "Treat as uncertainty/survey-coverage sensitivity, not driver evidence.",
      TRUE ~ "Use as context for section heterogeneity."
    ),
    data_caveat = case_when(
      survey_coverage < 0.3 ~ "very sparse survey coverage",
      recent_rel_width_90 > 50 ~ "wide recent posterior uncertainty",
      spawn_fit_rmse > 1.5 ~ "weak positive-spawn fit",
      TRUE ~ "standard caveats"
    ),
    headline = glue(
      "{site_name}: {typology}; recent/early={fmt_num(recent_to_early_ratio, 2)}, ",
      "fishing residual={fmt_num(fishing_only_resid, 2)}, coverage={fmt_pct(survey_coverage)}, ",
      "post-closure trend={fmt_num(closure_pct_per_year, 1)}%/yr."
    )
  ) %>%
  arrange(
    factor(
      talk_role,
      levels = c(
        "mechanism scrutiny",
        "portfolio concern",
        "intermediate context",
        "recovery contrast",
        "sensitivity caveat"
      )
    ),
    recent_to_early_ratio
  )

readr::write_csv(driver_dossiers, file.path(diag_dir, "section_driver_dossiers.csv"))

table_tbl <- driver_dossiers %>%
  transmute(
    section = site_name,
    role = talk_role,
    recent_early = fmt_num(recent_to_early_ratio, 2),
    fishing_resid = fmt_num(fishing_only_resid, 2),
    coverage = fmt_pct(survey_coverage),
    postclosure_trend = paste0(fmt_num(closure_pct_per_year, 1), "%/yr"),
    dd_rho = fmt_num(dd_spearman_rho, 2),
    caveat = data_caveat,
    driver_read = driver_read
  )

md_lines <- c(
  "# Section Driver Dossiers",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "This file translates the current section diagnostics into one section-by-section driver read. It is analysis triage, not a causal model.",
  "",
  "## Fast Read",
  "",
  "- Mechanism scrutiny: Cumshewa and Louscoone remain depleted beyond what the simple fishing screen predicts.",
  "- Portfolio concern: Skidegate, Laskeek, and Rennell remain depleted or stagnant and weaken the spatial portfolio.",
  "- Recovery contrast: Englefield and Port Louis show that recovery is possible but spatially uneven.",
  "- Sensitivity caveat: Tasu and Naden are retained in the 11-section fit but should not carry headline inference.",
  "",
  "|section|role|recent/early|fishing residual|coverage|post-closure trend|DD rho|caveat|driver read|",
  "|:---|:---|---:|---:|---:|---:|---:|:---|:---|",
  pmap_chr(
    table_tbl,
    function(section, role, recent_early, fishing_resid, coverage, postclosure_trend, dd_rho, caveat, driver_read) {
      cells <- c(section, role, recent_early, fishing_resid, coverage, postclosure_trend, dd_rho, caveat, driver_read)
      cells <- str_replace_all(as.character(cells), "\\|", "/")
      paste0("|", paste(cells, collapse = "|"), "|")
    }
  ),
  "",
  "## Files",
  "",
  "- `Output/diagnostics/section_driver_dossiers.csv`",
  "- `Output/diagnostics/section_driver_dossiers.md`"
)

writeLines(md_lines, file.path(diag_dir, "section_driver_dossiers.md"))

cat("Saved:\n")
cat("  Output/diagnostics/section_driver_dossiers.csv\n")
cat("  Output/diagnostics/section_driver_dossiers.md\n")
