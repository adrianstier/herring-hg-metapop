# ============================================================================
# 07bp_humpback_section_exposure_proxy.R
# Humpback section-exposure scaffold from HG-wide predator-repo products.
#
# This intentionally does not pretend to be a true section-level humpback
# exposure layer. It converts audited HG-wide humpback demand to an 11-section
# scaffold with explicit not-model-ready flags, so future agents have a
# traceable place to attach real PRISMM/BCCSN/sightings-density products.
# ============================================================================

library(tidyverse)
library(here)
library(scales)

proj_dir <- here::here()
diag_dir <- file.path(proj_dir, "Output", "diagnostics")
fig_dir <- file.path(proj_dir, "Output", "figures")
dir.create(diag_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

find_predator_repo <- function() {
  candidates <- c(
    Sys.getenv("PREDATOR_REPO_PATH"),
    "/Users/adrianstier/pacific-herring-predators",
    file.path(dirname(proj_dir), "pacific-herring-predators")
  )
  candidates <- candidates[nzchar(candidates)]
  candidates[file.exists(file.path(
    candidates,
    "data",
    "processed",
    "consumption_budget",
    "HG_humpback_consumption_feeding_substantive_1910-2022.csv"
  ))][1]
}

z <- function(x) {
  if (sum(is.finite(x)) < 2L || sd(x, na.rm = TRUE) == 0) {
    return(rep(NA_real_, length(x)))
  }
  as.numeric((x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE))
}

fill_annual <- function(tbl, years = 1951:2025) {
  observed <- tbl %>%
    filter(is.finite(year), is.finite(C_year_tonnes)) %>%
    arrange(year)

  if (nrow(observed) < 2L) {
    stop("Need at least two humpback annual-demand points to build scaffold.")
  }

  tibble(year = years) %>%
    left_join(observed, by = "year") %>%
    mutate(
      C_year_tonnes = stats::approx(
        observed$year,
        observed$C_year_tonnes,
        xout = year,
        rule = 2,
        ties = mean
      )$y,
      N_indiv = stats::approx(
        observed$year,
        observed$N_indiv,
        xout = year,
        rule = 2,
        ties = mean
      )$y,
      source_observed_year = year %in% observed$year,
      annual_fill_method = case_when(
        source_observed_year ~ "source_observed",
        year < min(observed$year) | year > max(observed$year) ~ "edge_extrapolated",
        TRUE ~ "linear_interpolated"
      )
    )
}

predator_repo <- find_predator_repo()
if (is.na(predator_repo) || !nzchar(predator_repo)) {
  stop("Predator repo not found. Set PREDATOR_REPO_PATH to /Users/adrianstier/pacific-herring-predators.")
}

humpback_path <- file.path(
  predator_repo,
  "data",
  "processed",
  "consumption_budget",
  "HG_humpback_consumption_feeding_substantive_1910-2022.csv"
)
projection_path <- file.path(
  predator_repo,
  "data",
  "processed",
  "consumption_budget",
  "HG_humpback_projection_2022-2050.csv"
)

humpback_raw <- read_csv(humpback_path, show_col_types = FALSE) %>%
  transmute(
    year = as.integer(year),
    N_indiv = as.numeric(N_indiv),
    C_year_tonnes = as.numeric(C_year_tonnes),
    source = source,
    source_file = "HG_humpback_consumption_feeding_substantive_1910-2022.csv"
  )

projection <- read_csv(projection_path, show_col_types = FALSE) %>%
  filter(year > 2022, year <= 2025) %>%
  transmute(
    year = as.integer(year),
    N_indiv = as.numeric(N_HG),
    C_year_tonnes = as.numeric(consumption_HG_kt) * 1000,
    source = "HG_humpback_projection_2022-2050",
    source_file = "HG_humpback_projection_2022-2050.csv"
  )

humpback_annual <- bind_rows(humpback_raw, projection) %>%
  arrange(year) %>%
  group_by(year) %>%
  summarise(
    N_indiv = mean(N_indiv, na.rm = TRUE),
    C_year_tonnes = mean(C_year_tonnes, na.rm = TRUE),
    source = paste(unique(na.omit(source)), collapse = "; "),
    source_file = paste(unique(source_file), collapse = "; "),
    .groups = "drop"
  ) %>%
  fill_annual()

sections <- read_csv(
  file.path(proj_dir, "Data", "processed", "HG_Spawn_Survey_1951_2025_all_sections.csv"),
  show_col_types = FALSE
) %>%
  filter(!section %in% c(4, 11)) %>%
  group_by(section, section_name) %>%
  summarise(
    section_lat = median(latitude, na.rm = TRUE),
    section_lon = median(longitude, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(is.finite(section_lat), is.finite(section_lon)) %>%
  arrange(section) %>%
  mutate(
    section_weight = 1 / n(),
    spatial_weight_basis = "uniform_across_11_sections_no_section_sightings"
  )

humpback_section <- crossing(humpback_annual, sections) %>%
  group_by(year) %>%
  mutate(
    predator_group = "mammals",
    predator_species_or_source = "Humpback whale HG-wide proxy",
    exposure_proxy_tonnes = C_year_tonnes * section_weight,
    exposure_proxy_z = z(C_year_tonnes),
    model_readiness = "not_model_ready_no_section_exposure",
    model_use = "descriptive_hg_wide_pressure_only",
    missing_data_needed = paste(
      "PRISMM/BCCSN/effort-corrected humpback sightings or density surfaces",
      "mapped to HG sections and herring-spawn season"
    ),
    provenance_note = paste(
      "HG-wide feeding-substantive humpback demand from predator repo;",
      "distributed uniformly only to keep the 11-section scaffold explicit."
    )
  ) %>%
  ungroup() %>%
  select(
    year,
    section,
    section_name,
    section_lat,
    section_lon,
    predator_group,
    predator_species_or_source,
    N_indiv,
    C_year_tonnes,
    section_weight,
    exposure_proxy_tonnes,
    exposure_proxy_z,
    source_observed_year,
    annual_fill_method,
    spatial_weight_basis,
    model_readiness,
    model_use,
    source,
    source_file,
    missing_data_needed,
    provenance_note
  )

write_csv(
  humpback_section,
  file.path(diag_dir, "humpback_section_exposure_proxy.csv")
)

annual_summary <- humpback_section %>%
  distinct(year, N_indiv, C_year_tonnes, annual_fill_method) %>%
  summarise(
    first_year = min(year),
    last_year = max(year),
    mean_recent_consumption_kt = mean(C_year_tonnes[year >= 2015 & year <= 2024], na.rm = TRUE) / 1000,
    median_recent_consumption_kt = median(C_year_tonnes[year >= 2015 & year <= 2024], na.rm = TRUE) / 1000,
    mean_recent_N = mean(N_indiv[year >= 2015 & year <= 2024], na.rm = TRUE),
    observed_years = sum(annual_fill_method == "source_observed"),
    interpolated_years = sum(annual_fill_method == "linear_interpolated"),
    extrapolated_years = sum(annual_fill_method == "edge_extrapolated"),
    .groups = "drop"
  )

p <- humpback_section %>%
  distinct(year, C_year_tonnes, N_indiv, annual_fill_method) %>%
  ggplot(aes(x = year, y = C_year_tonnes / 1000, colour = annual_fill_method)) +
  geom_line(linewidth = 0.65, colour = "grey35") +
  geom_point(size = 1.6, alpha = 0.8) +
  scale_colour_manual(values = c(
    source_observed = "#176B87",
    linear_interpolated = "#8A7B28",
    edge_extrapolated = "#999999"
  )) +
  labs(
    x = NULL,
    y = "HG humpback demand (kt/yr)",
    colour = NULL,
    title = "HG-wide humpback demand is not yet section exposure",
    subtitle = "This scaffold is uniform across sections until spatial sighting/density data are added."
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom")

ggsave(
  file.path(fig_dir, "humpback_section_exposure_proxy.pdf"),
  p,
  width = 180,
  height = 110,
  units = "mm",
  device = cairo_pdf
)
ggsave(
  file.path(fig_dir, "humpback_section_exposure_proxy.png"),
  p,
  width = 180,
  height = 110,
  units = "mm",
  dpi = 300
)

lines <- c(
  "# Humpback Section Exposure Proxy Scaffold",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "## Main Read",
  "",
  "- The local predator repo has HG-wide humpback abundance/consumption products, but no section-level humpback sighting/density surface.",
  "- This output creates an 11-section scaffold only so the missing data product has an explicit file, schema, and provenance.",
  "- The current section weights are uniform across the 11 modeled sections. That means the proxy has no section gradient and must not be used for a section-level predator-effect Stan branch.",
  "- Model readiness is `not_model_ready_no_section_exposure` until PRISMM/BCCSN/effort-corrected sightings or density surfaces are mapped to sections and season.",
  "",
  "## Source Files",
  "",
  paste0("- Predator repo: `", predator_repo, "`."),
  paste0("- HG humpback demand: `", humpback_path, "`."),
  paste0("- HG humpback projection: `", projection_path, "`."),
  "- Herring section centroids: `Data/processed/HG_Spawn_Survey_1951_2025_all_sections.csv`.",
  "",
  "## Recent Scale",
  "",
  paste0(
    "- 2015-2024 mean HG humpback demand: `",
    number(annual_summary$mean_recent_consumption_kt, accuracy = 0.01),
    "` kt/yr."
  ),
  paste0(
    "- 2015-2024 median HG humpback demand: `",
    number(annual_summary$median_recent_consumption_kt, accuracy = 0.01),
    "` kt/yr."
  ),
  paste0(
    "- 2015-2024 mean HG feeding-substantive humpback count proxy: `",
    number(annual_summary$mean_recent_N, accuracy = 1),
    "` individuals."
  ),
  "",
  "## Required To Become Model-Ready",
  "",
  "- Section-level or gridded humpback density/sighting product for Haida Gwaii.",
  "- Effort correction or an explicit presence-only model.",
  "- Seasonal filter tied to herring spawn or herring feeding-consumption season.",
  "- A documented section-weighting rule that is independent of observed herring spawn.",
  "",
  "## Outputs",
  "",
  "- `Output/diagnostics/humpback_section_exposure_proxy.csv`",
  "- `Output/figures/humpback_section_exposure_proxy.pdf`"
)

writeLines(lines, file.path(diag_dir, "humpback_section_exposure_proxy.md"))

cat("Saved humpback section exposure proxy scaffold:\n")
cat("  Output/diagnostics/humpback_section_exposure_proxy.csv\n")
cat("  Output/diagnostics/humpback_section_exposure_proxy.md\n")
