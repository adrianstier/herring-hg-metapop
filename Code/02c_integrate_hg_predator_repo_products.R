library(tidyverse)
library(here)

proj_dir <- here::here()
out_dir <- file.path(proj_dir, "Data", "processed", "predators")
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(diag_dir, recursive = TRUE, showWarnings = FALSE)

find_predator_repo <- function() {
  candidates <- c(
    Sys.getenv("PREDATOR_REPO_PATH"),
    file.path(dirname(proj_dir), "pacific-herring-predators"),
    "/private/tmp/pacific-herring-predators"
  )
  candidates <- candidates[nzchar(candidates)]
  candidates[file.exists(file.path(
    candidates,
    "data",
    "processed",
    "consumption_budget",
    "HG_pressure_climate_predator_covariates.csv"
  ))][1]
}

standardize <- function(x) {
  as.numeric((x - mean(x, na.rm = TRUE)) / stats::sd(x, na.rm = TRUE))
}

fill_annual <- function(x, year) {
  observed <- is.finite(x)
  if (!any(observed)) {
    return(x)
  }
  stats::approx(year[observed], x[observed], xout = year, rule = 2)$y
}

repo_dir <- find_predator_repo()
report_path <- file.path(diag_dir, "hg_predator_repo_integration.md")

if (is.na(repo_dir) || !nzchar(repo_dir)) {
  writeLines(
    c(
      "# HG Predator Repo Integration",
      "",
      "Status: predator repo not available in this runtime.",
      "",
      "Set `PREDATOR_REPO_PATH` to a checkout of `stier-lab/pacific-herring-predators` ",
      "and rerun `Rscript Code/02c_integrate_hg_predator_repo_products.R`.",
      "",
      "The main analysis can still run, but predator-pressure model branches should be held."
    ),
    report_path
  )
  cat("Predator repo not found; wrote diagnostic note and exited.\n")
  quit(save = "no", status = 0)
}

consumption_dir <- file.path(repo_dir, "data", "processed", "consumption_budget")
hg_dir <- file.path(repo_dir, "data", "processed", "haida_gwaii")

pressure_path <- file.path(consumption_dir, "HG_predation_pressure_index_AUDITED.csv")
covariate_path <- file.path(consumption_dir, "HG_pressure_climate_predator_covariates.csv")
group_path <- file.path(consumption_dir, "HG_consumption_by_group_year_AUDITED.csv")
species_path <- file.path(consumption_dir, "HG_consumption_by_species_year_AUDITED.csv")

pressure_tbl <- read_csv(pressure_path, show_col_types = FALSE)
covariate_tbl <- read_csv(covariate_path, show_col_types = FALSE)
group_tbl <- read_csv(group_path, show_col_types = FALSE)
species_tbl <- read_csv(species_path, show_col_types = FALSE)

years <- 1951:2025
covariates <- tibble(year = years) %>%
  left_join(covariate_tbl, by = "year") %>%
  mutate(
    log_pressure = fill_annual(log_pressure, year),
    log_humpback = fill_annual(log_humpback, year),
    N_BC = fill_annual(N_BC, year),
    pdo = fill_annual(pdo, year),
    npgo = fill_annual(npgo, year),
    pred_pressure_log_z = standardize(log_pressure),
    humpback_log_z = standardize(log_humpback),
    n_bc_z = standardize(N_BC),
    npgo_z = standardize(npgo),
    post_2001 = as.integer(year >= 2001L)
  )

recent_species <- species_tbl %>%
  filter(year >= 2015, year <= 2024) %>%
  group_by(species, group) %>%
  summarise(
    mean_consumption_t = mean(C_year_tonnes, na.rm = TRUE),
    median_consumption_t = median(C_year_tonnes, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(mean_consumption_t))

recent_groups <- group_tbl %>%
  filter(year >= 2015, year <= 2024) %>%
  group_by(group) %>%
  summarise(mean_consumption_kt = mean(C_kt, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(mean_consumption_kt))

spatial_layers <- list()
seal_path <- file.path(hg_dir, "harbour_seal_HG_haulouts_1986-2019.csv")
ssl_breeding_path <- file.path(hg_dir, "steller_sea_lion_HG_breeding_1971-2021.csv")
ssl_non_breeding_path <- file.path(hg_dir, "steller_sea_lion_HG_non_breeding_1971-2021.csv")

if (file.exists(seal_path)) {
  spatial_layers$harbour_seal <- read_csv(seal_path, show_col_types = FALSE) %>%
    transmute(
      predator = "harbour_seal",
      site = Complex,
      year = Year,
      longitude = Longitude,
      latitude = Latitude,
      count = complex_count
    )
}
if (file.exists(ssl_breeding_path)) {
  spatial_layers$steller_sea_lion_breeding <- read_csv(ssl_breeding_path, show_col_types = FALSE) %>%
    transmute(
      predator = "steller_sea_lion_breeding",
      site = Site,
      year = Year,
      longitude = Longitude,
      latitude = Latitude,
      count = Total
    )
}
if (file.exists(ssl_non_breeding_path)) {
  spatial_layers$steller_sea_lion_non_breeding <- read_csv(ssl_non_breeding_path, show_col_types = FALSE) %>%
    transmute(
      predator = "steller_sea_lion_non_breeding",
      site = Site,
      year = Year,
      longitude = Longitude,
      latitude = Latitude,
      count = Total
    )
}

spatial_tbl <- bind_rows(spatial_layers) %>%
  filter(is.finite(longitude), is.finite(latitude))

write_csv(pressure_tbl, file.path(out_dir, "hg_predation_pressure_index_audited.csv"))
write_csv(covariates, file.path(out_dir, "hg_predation_pressure_covariates.csv"))
write_csv(group_tbl, file.path(out_dir, "hg_predator_consumption_by_group_year.csv"))
write_csv(recent_species, file.path(out_dir, "hg_predator_consumption_by_species_recent.csv"))
write_csv(spatial_tbl, file.path(out_dir, "hg_spatial_predator_sites.csv"))

recent_pressure <- pressure_tbl %>%
  filter(year >= 2015, year <= 2024) %>%
  summarise(
    mean_consumption_kt = mean(C_total_kt, na.rm = TRUE),
    mean_spawn_kt = mean(HG_spawn_kt, na.rm = TRUE),
    mean_pressure_pct = mean(pressure_pct, na.rm = TRUE),
    median_pressure_pct = median(pressure_pct, na.rm = TRUE),
    max_pressure_pct = max(pressure_pct, na.rm = TRUE)
  )

top_species_lines <- recent_species %>%
  slice_head(n = 10) %>%
  mutate(line = paste0(
    "- ", species, " (", group, "): ",
    round(mean_consumption_t), " t/yr"
  )) %>%
  pull(line)

group_lines <- recent_groups %>%
  mutate(line = paste0("- ", group, ": ", round(mean_consumption_kt, 2), " kt/yr")) %>%
  pull(line)

writeLines(
  c(
    "# HG Predator Repo Integration",
    "",
    paste0("Source repo: `", repo_dir, "`"),
    "",
    "## Outputs",
    "",
    "- `Data/processed/predators/hg_predation_pressure_index_audited.csv`",
    "- `Data/processed/predators/hg_predation_pressure_covariates.csv`",
    "- `Data/processed/predators/hg_predator_consumption_by_group_year.csv`",
    "- `Data/processed/predators/hg_predator_consumption_by_species_recent.csv`",
    "- `Data/processed/predators/hg_spatial_predator_sites.csv`",
    "",
    "## Recent HG Predation Pressure",
    "",
    paste0(
      "- 2015-2024 mean consumption: ",
      round(recent_pressure$mean_consumption_kt, 2),
      " kt/yr."
    ),
    paste0(
      "- 2015-2024 mean spawn deposition: ",
      round(recent_pressure$mean_spawn_kt, 2),
      " kt/yr."
    ),
    paste0(
      "- 2015-2024 mean pressure: ",
      round(recent_pressure$mean_pressure_pct, 1),
      "% of HG spawn deposition."
    ),
    paste0(
      "- 2015-2024 median pressure: ",
      round(recent_pressure$median_pressure_pct, 1),
      "%; max pressure: ",
      round(recent_pressure$max_pressure_pct, 1),
      "%."
    ),
    "",
    "## Consumption By Group",
    "",
    group_lines,
    "",
    "## Top Recent Species",
    "",
    top_species_lines,
    "",
    "## Modeling Decision",
    "",
    paste(
      "Use `pred_pressure_log_z` as the first HG-specific predator covariate.",
      "It is an annual regional pressure index, so it is appropriate for a",
      "Stier-aligned process branch before attempting section-specific predator exposure."
    ),
    "",
    paste(
      "Hold age and size structure for now. The predator repo currently provides",
      "stronger immediate information about recent HG predation pressure than about",
      "section-level age/size dynamics."
    )
  ),
  report_path
)

cat("Integrated HG predator repo products from:", repo_dir, "\n")
cat("Wrote predator covariates to:", out_dir, "\n")
